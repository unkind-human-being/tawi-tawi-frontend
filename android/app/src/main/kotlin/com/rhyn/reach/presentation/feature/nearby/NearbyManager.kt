package com.rhyn.reach.presentation.feature.nearby

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.os.ParcelFileDescriptor
import android.util.Log
import com.google.android.gms.nearby.Nearby
import com.google.android.gms.nearby.connection.*
import com.rhyn.reach.core.crypto.CryptoManager
import com.rhyn.reach.core.utils.FileHelper
import com.rhyn.reach.data.local.DeliveryState
import com.rhyn.reach.data.local.LocalMessageEntity
import com.rhyn.reach.data.local.LocalUserEntity
import com.rhyn.reach.data.local.MeshRelayQueueEntity
import com.rhyn.reach.data.local.MessageType
import com.rhyn.reach.data.local.SyncStatus
import com.rhyn.reach.data.local.dao.MeshEdgeDao
import com.rhyn.reach.data.local.dao.MeshRelayDao
import com.rhyn.reach.data.local.dao.MessageDao
import com.rhyn.reach.data.local.dao.UserDao
import com.rhyn.reach.data.local.prefs.SessionManager
import com.rhyn.reach.data.remote.model.MeshEnvelope
import com.rhyn.reach.data.repository.routing.MessageRouter
import com.rhyn.reach.core.nearby.MeshRelayBroadcaster

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File
import java.io.FileInputStream
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.io.InputStream
import java.util.concurrent.ConcurrentHashMap
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NearbyManager @Inject constructor(
    private val context: Context,
    private val messageDao: MessageDao,
    private val userDao: UserDao,
    private val meshRelayDao: MeshRelayDao,
    private val meshEdgeDao: MeshEdgeDao,
    private val sessionManager: SessionManager,
    private val cryptoManager: CryptoManager,
    private val fileHelper: FileHelper,
    private val messageRouterLazy: javax.inject.Provider<MessageRouter>,
    private val meshRelayBroadcasterLazy: javax.inject.Provider<MeshRelayBroadcaster>
) {
    private val connectionsClient = Nearby.getConnectionsClient(context)
    private val SERVICE_ID = "com.rhyn.reach.MESH_SERVICE"

    private val jsonParser = Json { ignoreUnknownKeys = true }

    private val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    data class NearbyDevice(val endpointId: String, val stableUserId: String, val username: String)

    private val _discoveredPeers = MutableStateFlow<List<NearbyDevice>>(emptyList())
    val discoveredPeers = _discoveredPeers.asStateFlow()

    private val endpointToStableIdMap = mutableMapOf<String, String>()
    private val connectedEndpoints = mutableSetOf<String>()

    private val incomingFileMetadata = mutableMapOf<String, MeshEnvelope>()
    private val activeFileTransfers = mutableMapOf<Long, Pair<MeshEnvelope, Payload.File>>()

    private val outgoingTransfers = ConcurrentHashMap<Long, String>()
    private val outgoingFiles = ConcurrentHashMap<Long, File>()
    private val activeTextWatchdogs = ConcurrentHashMap<Long, Job>()

    private val recentNetworkRequests = mutableSetOf<String>()

    // ---> NEW: Hardware Connection Cooldowns
    private val connectionCooldowns = ConcurrentHashMap<String, Long>()

    private var restartJob: Job? = null
    private var gossipJob: Job? = null
    private var heartbeatJob: Job? = null

    // ---> NEW: Background Watchdogs
    private var autoConnectJob: Job? = null
    private var discoveryPulseJob: Job? = null

    private var isIntentionallyRunning = false

    private var localUserId: String = "Unknown"
    private var localUsername: String = "Guest"

    // ---> Hardware Safety Limits
    private var advertisingRetryCount = 0
    private var discoveryRetryCount = 0

    val isMeshActive = MutableStateFlow(false)
    val hasRadioError = MutableStateFlow(false) // Tracks hardware crashes
    val activeConnectionCount = MutableStateFlow(0) // Tracks established direct links

    // --------------------------------------------------------
    // BACKGROUND WATCHDOGS
    // --------------------------------------------------------

    private fun startAutoConnectWatchdog() {
        autoConnectJob?.cancel()
        autoConnectJob = CoroutineScope(Dispatchers.IO).launch {
            while (isActive) {
                delay(4000) // Check every 4 seconds for disconnected peers
                if (isIntentionallyRunning) {
                    val currentPeers = _discoveredPeers.value.toList()
                    val myIdentity = "$localUserId|$localUsername"

                    for (peer in currentPeers) {
                        val endpointId = peer.endpointId
                        val stableId = peer.stableUserId

                        if (!connectedEndpoints.contains(endpointId)) {
                            // Track cooldown using the permanent stableId instead of ephemeral endpointId
                            val cooldownUntil = connectionCooldowns[stableId] ?: 0L
                            if (System.currentTimeMillis() > cooldownUntil) {
                                // Apply identical master/slave rule to prevent collision
                                if (localUserId > stableId) {
                                    Log.d("ReachMesh", "Watchdog: Initiating recovery to $endpointId")
                                    requestConnection(endpointId, myIdentity)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private fun startDiscoveryPulse() {
        discoveryPulseJob?.cancel()
        discoveryPulseJob = CoroutineScope(Dispatchers.IO).launch {
            while (isActive) {
                delay(45000) // Every 45 seconds, silently clear OS BLE caches
                if (isIntentionallyRunning) {
                    Log.d("ReachMesh", "Silently pulsing Discovery to bypass Android battery filters.")
                    val options = DiscoveryOptions.Builder()
                        .setStrategy(Strategy.P2P_CLUSTER)
                        .setLowPower(false)
                        .build()
                    connectionsClient.stopDiscovery()
                    connectionsClient.startDiscovery(SERVICE_ID, endpointDiscoveryCallback, options)
                }
            }
        }
    }

    // --------------------------------------------------------
    // CORE MESH LOGIC
    // --------------------------------------------------------

    private fun startHeartbeat() {
        if (heartbeatJob?.isActive == true) return

        heartbeatJob = CoroutineScope(Dispatchers.IO).launch {
            while (isActive) {
                delay(15000)

                val connectedList = connectedEndpoints.toList()
                for (endpointId in connectedList) {
                    try {
                        val pingPayload = Payload.fromBytes("PING".toByteArray(Charsets.UTF_8))
                        connectionsClient.sendPayload(endpointId, pingPayload)
                    } catch (e: Exception) {
                        Log.e("ReachMesh", "Heartbeat failed for $endpointId. Pruning ghost endpoint.")
                        disconnectAndPurge(endpointId)
                    }
                }
            }
        }
    }

    private fun stopHeartbeat() {
        heartbeatJob?.cancel()
        heartbeatJob = null
    }

    private fun purgeStaleEndpoint(endpointId: String) {
        endpointToStableIdMap.remove(endpointId)
        connectedEndpoints.remove(endpointId)
        _discoveredPeers.value = _discoveredPeers.value.filter { it.endpointId != endpointId }
        incomingFileMetadata.remove(endpointId)
        Log.d("ReachMesh", "Purged stale endpoint: $endpointId.")
    }

    private fun softDisconnect(endpointId: String, cooldownMs: Long = 8000) {
        Log.w("ReachMesh", "Soft disconnecting socket: $endpointId")
        
        val stableId = endpointToStableIdMap[endpointId]
        if (stableId != null) {
            // Apply cooldown to the stable ID to keep it quiet temporarily
            connectionCooldowns[stableId] = System.currentTimeMillis() + cooldownMs
        }
        
        connectionsClient.disconnectFromEndpoint(endpointId)
        connectedEndpoints.remove(endpointId)
        
        // Crucial: Clear the dead endpoint string so the watchdog avoids it
        _discoveredPeers.value = _discoveredPeers.value.filter { it.endpointId != endpointId }
        endpointToStableIdMap.remove(endpointId)
    }

    fun disconnectAndPurge(endpointId: String) {
        Log.w("ReachMesh", "Forcefully disconnecting poisoned socket: $endpointId")
        connectionsClient.disconnectFromEndpoint(endpointId)
        purgeStaleEndpoint(endpointId)
    }

    private fun registerNetworkCallback() {
        if (networkCallback == null) {
            networkCallback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    Log.d("ReachMesh", "Network interface available. Fast-Restarting Mesh.")
                    restartMesh()
                }
                override fun onLost(network: Network) {
                    Log.d("ReachMesh", "Network interface lost. Fast-Restarting Mesh.")
                    restartMesh()
                }
            }
            val request = NetworkRequest.Builder()
                .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                .build()
            connectivityManager.registerNetworkCallback(request, networkCallback!!)
        }
    }

    fun restartMesh() {
        restartJob?.cancel()
        restartJob = CoroutineScope(Dispatchers.Main).launch {
            if (isIntentionallyRunning) {
                Log.d("ReachMesh", "Cycling Nearby Connections to clear zombie sockets.")
                stopHeartbeat()

                connectionsClient.stopAdvertising()
                connectionsClient.stopDiscovery()
                connectionsClient.stopAllEndpoints()

                _discoveredPeers.value = emptyList()
                endpointToStableIdMap.clear()
                connectedEndpoints.clear()
                incomingFileMetadata.clear()
                activeFileTransfers.clear()
                outgoingTransfers.clear()
                outgoingFiles.values.forEach { it.delete() }
                outgoingFiles.clear()
                connectionCooldowns.clear()

                isMeshActive.value = false
                advertisingRetryCount = 0
                discoveryRetryCount = 0
                activeConnectionCount.value = 0

                delay(3000)

                startAdvertising(localUserId, localUsername)
                startDiscovery()
            }
        }
    }

    private val endpointDiscoveryCallback = object : EndpointDiscoveryCallback() {
        override fun onEndpointFound(endpointId: String, info: DiscoveredEndpointInfo) {
            val parts = info.endpointName.split("|", limit = 2)
            val stableId = if (parts.size == 2) parts[0] else endpointId
            val name = if (parts.size == 2) parts[1] else info.endpointName

            Log.i("ReachMesh", "=> OS DETECTED NEARBY RADIO! Endpoint: $endpointId | Identity: ${info.endpointName}")

            if (stableId == localUserId) {
                Log.e("ReachMesh", "=> REJECTED: The nearby device is logged into the exact same account ($localUserId) as this device! Mesh rules require unique accounts.")
                return
            }

            // Check if this endpoint recently crashed the hardware
            val cooldownUntil = connectionCooldowns[stableId] ?: 0L
            if (System.currentTimeMillis() < cooldownUntil) {
                Log.w("ReachMesh", "Endpoint $endpointId is on cooldown. Ignoring discovery to let hardware breathe.")
                return
            }

            endpointToStableIdMap[endpointId] = stableId

            val newList = _discoveredPeers.value.toMutableList()
            if (newList.none { it.endpointId == endpointId }) {
                newList.add(NearbyDevice(endpointId, stableId, name))
                _discoveredPeers.value = newList
            }

            if (!connectedEndpoints.contains(endpointId)) {
                val myIdentity = "$localUserId|$localUsername"
                
                CoroutineScope(Dispatchers.Main).launch {
                    if (localUserId > stableId) {
                        // Master node initiates connection immediately
                        delay(200)
                        requestConnection(endpointId, myIdentity)
                    } else {
                        // Slave node yields and waits for incoming connection request
                        Log.d("ReachMesh", "Yielding connection initiation to peer $stableId")
                    }
                }
            }
        }

        override fun onEndpointLost(endpointId: String) {
            // Protect active connections from aggressive OS caches dropping them
            if (connectedEndpoints.contains(endpointId)) {
                Log.d("ReachMesh", "Ignored onEndpointLost for active connection: $endpointId")
                return
            }
            purgeStaleEndpoint(endpointId)
        }
    }

    private val connectionLifecycleCallback = object : ConnectionLifecycleCallback() {
        override fun onConnectionInitiated(endpointId: String, info: ConnectionInfo) {
            val parts = info.endpointName.split("|", limit = 2)
            val stableId = if (parts.size == 2) parts[0] else endpointId
            val name = if (parts.size == 2) parts[1] else info.endpointName

            val existingEndpointId = endpointToStableIdMap.entries.firstOrNull { it.value == stableId }?.key
            if (existingEndpointId != null && existingEndpointId != endpointId) {
                Log.e("ReachMesh", "Ghost connection detected for $name. Rejecting and rebooting daemon.")
                connectionsClient.rejectConnection(endpointId)
                restartMesh()
                return
            }

            endpointToStableIdMap[endpointId] = stableId

            CoroutineScope(Dispatchers.IO).launch {
                val myId = sessionManager.getUserId() ?: return@launch
                if (userDao.getUserById(stableId, myId) == null) {
                    userDao.insertUser(LocalUserEntity(
                        userId = stableId,
                        ownerId = myId,
                        username = name,
                        isGroup = false,
                        publicKey = null
                    ))
                }
            }
            // Accept the connection automatically
            connectionsClient.acceptConnection(endpointId, payloadCallback)
        }

        override fun onConnectionResult(endpointId: String, result: ConnectionResolution) {
            if (result.status.isSuccess) {
                Log.i("NearbyManager", "CONNECTION ESTABLISHED: Endpoint [$endpointId]")
                // Increment counter when a link is secured
                activeConnectionCount.update { it + 1 }

                Log.d("ReachMesh", "Tunnel opened to $endpointId")
                connectedEndpoints.add(endpointId)

                // The stableId is needed for the relay sync
                val stableId = endpointToStableIdMap[endpointId] ?: return

                CoroutineScope(Dispatchers.IO).launch {
                    delay(250)

                    val myId = sessionManager.getUserId() ?: return@launch
                    val myPublicKey = sessionManager.getPublicKey() ?: return@launch
                    val mySigningPublicKey = sessionManager.getSigningPublicKey() ?: return@launch

                    val handshakePayload = "KEY_EXCHANGE:$myId:$myPublicKey:$mySigningPublicKey"
                    sendMessage(endpointId, handshakePayload)

                    // Immediately announce the new connection to the rest of the mesh
                    forceGossip()

                    // Dump any stranded messages to the new phone
                    messageRouterLazy.get().syncEpidemicRelaysToNewNeighbor(endpointId, stableId)

                    delay(100)
                    messageRouterLazy.get().routeAllPendingMessages(null)
                }
            } else {
                Log.w("ReachMesh", "Connection failed to $endpointId. Watchdog will retry.")
                softDisconnect(endpointId, 8000)
            }
        }

        override fun onDisconnected(endpointId: String) {
            Log.i("NearbyManager", "CONNECTION LOST: Endpoint [$endpointId]")
            // Decrement counter when a link drops
            activeConnectionCount.update { count -> if (count > 0) count - 1 else 0 }

            // THE FIX: Do not purge! Soft disconnect so the watchdog reconnects.
            softDisconnect(endpointId)

            // Immediately tell the mesh network that this path is dead
            forceGossip()
        }
    }

    private val payloadCallback = object : PayloadCallback() {
        override fun onPayloadReceived(endpointId: String, payload: Payload) {
            when (payload.type) {
                Payload.Type.BYTES -> {
                    val rawStringData = String(payload.asBytes()!!, Charsets.UTF_8)

                    if (rawStringData == "PING") return

                    val stableUserId = endpointToStableIdMap[endpointId] ?: return

                    if (!rawStringData.startsWith("KEY_")) {
                        try {
                            val envelope = jsonParser.decodeFromString<MeshEnvelope>(rawStringData)
                            if (envelope.payloadType == "IMAGE" || envelope.payloadType == "FILE") {
                                incomingFileMetadata[endpointId] = envelope
                                return
                            }
                        } catch (e: Exception) {}
                    }

                    CoroutineScope(Dispatchers.IO).launch {
                        val myId = sessionManager.getUserId() ?: return@launch

                        // Prevent Infinite Network Storms
                        if (rawStringData.startsWith("KEY_") || rawStringData.startsWith("ANNOUNCE:")) {
                            if (recentNetworkRequests.contains(rawStringData)) return@launch
                            recentNetworkRequests.add(rawStringData)
                            if (recentNetworkRequests.size > 500) recentNetworkRequests.clear() // Prevent memory leak
                        }

                        if (rawStringData.startsWith("ANNOUNCE:")) {
                            val parts = rawStringData.split(":")
                            if (parts.size == 3) {
                                val reportingNode = parts[1]
                                val neighbors = parts[2].split(",").filter { it.isNotBlank() }
                                val timestamp = System.currentTimeMillis()
                                val edges = neighbors.map { neighbor ->
                                    com.rhyn.reach.data.local.MeshEdgeEntity(
                                        nodeA = reportingNode, nodeB = neighbor, lastSeenTimestamp = timestamp
                                    )
                                }
                                if (edges.isNotEmpty()) {
                                    val directEdge = com.rhyn.reach.data.local.MeshEdgeEntity(
                                        nodeA = myId, nodeB = reportingNode, lastSeenTimestamp = timestamp
                                    )
                                    meshEdgeDao.insertEdges(edges + directEdge)

                                    // Propagate the gossip to other neighbors
                                    broadcastToAllNeighborsExcept(rawStringData, endpointId)
                                }
                                meshEdgeDao.deleteStaleEdges(timestamp - 60000)
                            }
                            return@launch
                        }

                        if (rawStringData.startsWith("KEY_EXCHANGE:")) {
                            val parts = rawStringData.split(":", limit = 4)
                            if (parts.size == 4) {
                                userDao.updatePublicKeys(stableUserId, parts[2], parts[3], myId)
                                messageRouterLazy.get().routeAllPendingMessages(null)
                            }
                            return@launch
                        }

                        if (rawStringData.startsWith("KEY_REQUEST:")) {
                            val parts = rawStringData.split(":", limit = 4)
                            if (parts.size >= 3) {
                                val requestedUserId = parts[1]
                                val requesterId = parts[2]
                                val requesterName = if (parts.size >= 4) parts[3] else "Unknown (Mesh)"

                                if (requestedUserId == myId) {
                                    val myKey = sessionManager.getPublicKey()
                                    val mySignKey = sessionManager.getSigningPublicKey()
                                    val myName = sessionManager.getUsername() ?: "Guest"
                                    if (!myKey.isNullOrEmpty() && !mySignKey.isNullOrEmpty()) {
                                        broadcastToAllNeighbors("KEY_RESPONSE:$myId:$requesterId:$myKey:$mySignKey:$myName")
                                    }

                                    // Save the requester's real name proactively
                                    val existingUser = userDao.getUserById(requesterId, myId)
                                    if (existingUser == null) {
                                        userDao.insertUser(com.rhyn.reach.data.local.LocalUserEntity(
                                            userId = requesterId, ownerId = myId, username = requesterName, isGroup = false
                                        ))
                                    } else if (existingUser.username.startsWith("Unknown")) {
                                        userDao.insertUser(existingUser.copy(username = requesterName))
                                    }
                                    return@launch
                                }

                                val knownUser = userDao.getUserById(requestedUserId, myId)
                                if (knownUser != null && !knownUser.publicKey.isNullOrEmpty() && !knownUser.signingPublicKey.isNullOrEmpty()) {
                                    broadcastToAllNeighbors("KEY_RESPONSE:$requestedUserId:$requesterId:${knownUser.publicKey}:${knownUser.signingPublicKey}:${knownUser.username}")
                                } else {
                                    broadcastToAllNeighborsExcept(rawStringData, endpointId)
                                }
                            }
                            return@launch
                        }

                        if (rawStringData.startsWith("KEY_RESPONSE:")) {
                            val parts = rawStringData.split(":", limit = 6)
                            if (parts.size >= 5) {
                                val requestedUserId = parts[1]
                                val requesterId = parts[2]
                                val foundKey = parts[3]
                                val foundSignKey = parts[4]
                                val foundName = if (parts.size >= 6) parts[5] else "Unknown"

                                if (requesterId == myId) {
                                    val existingUser = userDao.getUserById(requestedUserId, myId)
                                    if (existingUser == null) {
                                        userDao.insertUser(com.rhyn.reach.data.local.LocalUserEntity(
                                            userId = requestedUserId, ownerId = myId, username = foundName,
                                            isGroup = false, publicKey = foundKey, signingPublicKey = foundSignKey
                                        ))
                                    } else {
                                        userDao.insertUser(existingUser.copy(
                                            username = if (existingUser.username.startsWith("Unknown")) foundName else existingUser.username,
                                            publicKey = foundKey,
                                            signingPublicKey = foundSignKey
                                        ))
                                    }
                                    messageRouterLazy.get().routeAllPendingMessages(null)
                                } else {
                                    broadcastToAllNeighborsExcept(rawStringData, endpointId)
                                }
                            }
                            return@launch
                        }

                        try {
                            val envelope = jsonParser.decodeFromString<MeshEnvelope>(rawStringData)

                            if (envelope.targetId == myId) {
                                val myPrivateKey = sessionManager.getPrivateKey() ?: ""
                                val decryptedText = try {
                                    cryptoManager.decryptMessage(envelope.encryptedPayload, myPrivateKey)
                                } catch (e: Exception) {
                                    "Decryption failed"
                                }

                                val localMessage = LocalMessageEntity(
                                    messageId = envelope.messageId, ownerId = myId, threadId = envelope.senderId,
                                    senderId = envelope.senderId, plaintextContent = decryptedText,
                                    timestamp = System.currentTimeMillis(), isFromMe = false,
                                    deliveryState = DeliveryState.MESH_ROUTED
                                )
                                messageDao.insertMessage(localMessage)

                            } else {
                                // RELAY INTERCEPTION BLOCK
                                // Log the routing event using structured tags for logcat filtering
                                Log.i("MeshRouting", "RELAY_EVENT: Packet intercepted.")
                                Log.i("MeshRouting", "  -> Packet ID: ${envelope.messageId}")
                                Log.i("MeshRouting", "  -> Source: ${envelope.senderId}")
                                Log.i("MeshRouting", "  -> Target: ${envelope.targetId}")
                                Log.i("MeshRouting", "  -> Action: Pushing to MeshRelayBroadcaster")

                                meshRelayBroadcasterLazy.get().processIncomingRelay(envelope, myId, endpointId)
                            }
                        } catch (e: Exception) {
                            Log.e("ReachMesh", "Failed to parse JSON envelope", e)
                        }
                    }
                }
                Payload.Type.FILE -> {
                    val envelope = incomingFileMetadata.remove(endpointId)
                    val payloadFile = payload.asFile()

                    if (envelope != null && payloadFile != null) {
                        activeFileTransfers[payload.id] = Pair(envelope, payloadFile)
                    }
                }
            }
        }

        override fun onPayloadTransferUpdate(endpointId: String, update: PayloadTransferUpdate) {
            val payloadId = update.payloadId

            if (update.status == PayloadTransferUpdate.Status.SUCCESS ||
                update.status == PayloadTransferUpdate.Status.FAILURE ||
                update.status == PayloadTransferUpdate.Status.CANCELED) {
                activeTextWatchdogs.remove(payloadId)?.cancel()
                outgoingFiles.remove(payloadId)?.delete()
            }

            when (update.status) {
                PayloadTransferUpdate.Status.SUCCESS -> {
                    outgoingTransfers.remove(payloadId)

                    val transferData = activeFileTransfers.remove(payloadId)
                    if (transferData != null) {
                        val (envelope, payloadFile) = transferData
                        CoroutineScope(Dispatchers.IO).launch {
                            try {
                                val myId = sessionManager.getUserId() ?: return@launch
                                val myPrivateKey = sessionManager.getPrivateKey() ?: return@launch

                                if (envelope.targetId == myId) {
                                    val ext = if (envelope.payloadType == "IMAGE") "jpg" else "bin"
                                    val decryptedFile = fileHelper.createDecryptedMediaFile(ext)

                                    val pfd = payloadFile.asParcelFileDescriptor()
                                    val inputStream: InputStream = when {
                                        payloadFile.asUri() != null -> context.contentResolver.openInputStream(payloadFile.asUri()!!)
                                            ?: throw Exception("Failed to open URI stream")
                                        payloadFile.asJavaFile() != null -> FileInputStream(payloadFile.asJavaFile())
                                        pfd != null -> ParcelFileDescriptor.AutoCloseInputStream(pfd)
                                        else -> throw Exception("Both JavaFile and URI are null in Payload.File")
                                    }

                                    cryptoManager.decryptStream(inputStream, FileOutputStream(decryptedFile), myPrivateKey)

                                    val uriString = fileHelper.getInternalUriForFile(decryptedFile)
                                    val localMessage = LocalMessageEntity(
                                        messageId = envelope.messageId, ownerId = myId, threadId = envelope.senderId,
                                        senderId = envelope.senderId, plaintextContent = "", attachmentUri = uriString,
                                        messageType = if (envelope.payloadType == "IMAGE") MessageType.IMAGE else MessageType.FILE,
                                        timestamp = System.currentTimeMillis(), isFromMe = false,
                                        deliveryState = DeliveryState.MESH_ROUTED
                                    )
                                    messageDao.insertMessage(localMessage)
                                    payloadFile.asJavaFile()?.delete()
                                } else {
                                    payloadFile.asJavaFile()?.delete()
                                }
                            } catch (e: Exception) {
                                Log.e("ReachMesh", "Failed to decrypt incoming mesh file stream", e)
                            }
                        }
                    }
                }
                PayloadTransferUpdate.Status.FAILURE, PayloadTransferUpdate.Status.CANCELED -> {
                    Log.e("ReachMesh", "Payload delivery failed/canceled to $endpointId. Disconnecting broken peer.")

                    // THE FIX: Soft disconnect instead of purging and restarting
                    softDisconnect(endpointId, cooldownMs = 10000)

                    val failedMessageId = outgoingTransfers.remove(payloadId)
                    if (failedMessageId != null) {
                        CoroutineScope(Dispatchers.IO).launch {
                            Log.d("ReachMesh", "State-Healer active: Reverting message $failedMessageId back to PENDING.")
                            messageDao.updateDeliveryState(failedMessageId, DeliveryState.PENDING, localUserId)
                        }
                    }
                }
                else -> {}
            }
        }
    }

    // Prevent infinite duplicate requests by stopping before retrying
    fun startAdvertising(userId: String, username: String) {
        isIntentionallyRunning = true
        localUserId = userId
        localUsername = username

        if (isMeshActive.value) return

        val endpointName = "$userId|$username"
        val options = AdvertisingOptions.Builder()
            .setStrategy(Strategy.P2P_CLUSTER)
            .setLowPower(false)
            .setDisruptiveUpgrade(true)
            .build()

        connectionsClient.startAdvertising(endpointName, SERVICE_ID, connectionLifecycleCallback, options)
            .addOnSuccessListener {
                Log.d("ReachMesh", "Advertising as $endpointName")
                isMeshActive.value = true
                hasRadioError.value = false // Clear the error if the hardware wakes up!
                advertisingRetryCount = 0 // Reset on success
                registerNetworkCallback()
                startGossip()
                startHeartbeat()

                // Start Watchdogs
                startAutoConnectWatchdog()
                startDiscoveryPulse()
            }
            .addOnFailureListener { e ->
                if (e is com.google.android.gms.common.api.ApiException) {
                    when (e.statusCode) {
                        ConnectionsStatusCodes.STATUS_ALREADY_ADVERTISING -> {
                            Log.d("ReachMesh", "Google API reports advertising is already active. Healing UI State.")
                            isMeshActive.value = true
                            advertisingRetryCount = 0
                        }
                        8007, ConnectionsStatusCodes.STATUS_RADIO_ERROR -> {
                            // Stop fighting the OS. Nuke the state cleanly.
                            Log.e("ReachMesh", "CRITICAL: Hardware Radio crashed. Halting mesh to prevent loop of death.")
                            hasRadioError.value = true // Tell the UI the hardware is frozen!
                            stopAll() // Completely shuts down the mesh and resets the UI to "Scan"
                        }
                        ConnectionsStatusCodes.STATUS_BLUETOOTH_ERROR, 13 -> {
                            if (advertisingRetryCount < 3) {
                                advertisingRetryCount++
                                Log.w("ReachMesh", "Samsung BT lockup (Attempt $advertisingRetryCount). Clearing stack and retrying...")
                                CoroutineScope(Dispatchers.Main).launch {
                                    connectionsClient.stopAdvertising()
                                    delay(3000)
                                    if (isIntentionallyRunning) {
                                        startAdvertising(userId, username)
                                    }
                                }
                            } else {
                                Log.e("ReachMesh", "Failed to start advertising after 3 attempts. Hardware unresponsive.")
                                stopAll() // Failsafe
                            }
                        }
                        else -> {
                            Log.e("ReachMesh", "Advertising failed: ${e.statusCode}")
                            isMeshActive.value = false
                        }
                    }
                } else {
                    isMeshActive.value = false
                }
            }
    }


    private fun startGossip() {
        gossipJob?.cancel()
        gossipJob = CoroutineScope(Dispatchers.IO).launch {
            while (isActive) {
                delay(15000)
                if (connectedEndpoints.isNotEmpty()) {
                    val myId = sessionManager.getUserId() ?: continue
                    val directNeighbors = endpointToStableIdMap.values.distinct()
                    val announcePayload = "ANNOUNCE:$myId:${directNeighbors.joinToString(",")}"
                    broadcastToAllNeighbors(announcePayload)
                }
            }
        }
    }

    private fun forceGossip() {
        CoroutineScope(Dispatchers.IO).launch {
            val myId = sessionManager.getUserId() ?: return@launch
            val directNeighbors = endpointToStableIdMap.values.distinct()
            val announcePayload = "ANNOUNCE:$myId:${directNeighbors.joinToString(",")}"
            broadcastToAllNeighbors(announcePayload)
        }
    }

    fun sendFile(endpointId: String, metadataJson: String, file: File) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val metaPayload = Payload.fromBytes(metadataJson.toByteArray(Charsets.UTF_8))
                try {
                    val envelope = jsonParser.decodeFromString<MeshEnvelope>(metadataJson)
                    outgoingTransfers[metaPayload.id] = envelope.messageId
                } catch(e: Exception){}

                connectionsClient.sendPayload(endpointId, metaPayload)

                delay(150)

                val pfd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                val filePayload = Payload.fromFile(pfd)
                outgoingFiles[filePayload.id] = file

                try {
                    val envelope = jsonParser.decodeFromString<MeshEnvelope>(metadataJson)
                    outgoingTransfers[filePayload.id] = envelope.messageId
                } catch(e: Exception){}

                connectionsClient.sendPayload(endpointId, filePayload)
            } catch (e: FileNotFoundException) {
                Log.e("ReachMesh", "Target file not disk found on disk: ${file.absolutePath}", e)
            } catch (e: Exception) {
                Log.e("ReachMesh", "Failed to dispatch file payload to Nearby Connections API", e)
            }
        }
    }

    // Prevent infinite duplicate requests by stopping before retrying
    fun startDiscovery() {
        val options = DiscoveryOptions.Builder()
            .setStrategy(Strategy.P2P_CLUSTER)
            .setLowPower(false)
            .build()

        connectionsClient.stopDiscovery()

        connectionsClient.startDiscovery(SERVICE_ID, endpointDiscoveryCallback, options)
            .addOnSuccessListener {
                Log.d("ReachMesh", "Discovery started cleanly")
                hasRadioError.value = false // Clear the error if the hardware wakes up!
                discoveryRetryCount = 0
            }
            .addOnFailureListener { e ->
                if (e is com.google.android.gms.common.api.ApiException) {
                    when (e.statusCode) {
                        ConnectionsStatusCodes.STATUS_ALREADY_DISCOVERING -> {
                            Log.d("ReachMesh", "Already discovering.")
                            discoveryRetryCount = 0
                        }
                        8007, ConnectionsStatusCodes.STATUS_RADIO_ERROR -> {
                            // Stop fighting the OS. Nuke the state cleanly.
                            Log.e("ReachMesh", "CRITICAL: Hardware Radio crashed. Halting mesh to prevent loop of death.")
                            hasRadioError.value = true // Tell the UI the hardware is frozen!
                            stopAll()
                        }
                        ConnectionsStatusCodes.STATUS_BLUETOOTH_ERROR, 13 -> {
                            if (discoveryRetryCount < 3) {
                                discoveryRetryCount++
                                Log.w("ReachMesh", "Samsung BT lockup (Attempt $discoveryRetryCount). Clearing stack and retrying...")
                                CoroutineScope(Dispatchers.Main).launch {
                                    connectionsClient.stopDiscovery()
                                    delay(3000)
                                    if (isIntentionallyRunning) {
                                        startDiscovery()
                                    }
                                }
                            } else {
                                Log.e("ReachMesh", "Failed to start discovery after 3 attempts.")
                                stopAll() // Failsafe
                            }
                        }
                        else -> {
                            Log.e("ReachMesh", "Discovery failed: ${e.statusCode}")
                        }
                    }
                } else {
                    Log.e("ReachMesh", "Discovery completely failed: ${e?.message}")
                }
            }
    }


    fun requestConnection(endpointId: String, myIdentity: String) {
        val connectionOptions = ConnectionOptions.Builder()
            .setLowPower(false)
            .setDisruptiveUpgrade(true)
            .build()
        connectionsClient.requestConnection(myIdentity, endpointId, connectionLifecycleCallback, connectionOptions)
            .addOnSuccessListener {
                Log.d("ReachMesh", "Connection request dispatched to $endpointId")
            }
            .addOnFailureListener { e ->
                if (e is com.google.android.gms.common.api.ApiException && e.statusCode == ConnectionsStatusCodes.STATUS_ALREADY_CONNECTED_TO_ENDPOINT) {
                    Log.w("ReachMesh", "Loop-Breaker: Already connected to $endpointId! Healing state.")
                    connectedEndpoints.add(endpointId)

                    CoroutineScope(Dispatchers.IO).launch {
                        delay(1000)
                        val myId = sessionManager.getUserId() ?: return@launch
                        val myPublicKey = sessionManager.getPublicKey() ?: return@launch
                        val mySigningPublicKey = sessionManager.getSigningPublicKey() ?: return@launch

                        val handshakePayload = "KEY_EXCHANGE:$myId:$myPublicKey:$mySigningPublicKey"
                        sendMessage(endpointId, handshakePayload)
                        delay(100)
                        messageRouterLazy.get().routeAllPendingMessages(null)
                    }
                } else {
                    Log.e("ReachMesh", "Connection request failed. Endpoint likely stale.", e)
                    softDisconnect(endpointId, 15000)
                }
            }
    }

    fun sendMessage(endpointId: String, message: String) {
        val payload = Payload.fromBytes(message.toByteArray(Charsets.UTF_8))
        val payloadId = payload.id

        try {
            val envelope = jsonParser.decodeFromString<MeshEnvelope>(message)
            outgoingTransfers[payloadId] = envelope.messageId
        } catch(e: Exception){}

        connectionsClient.sendPayload(endpointId, payload)

        val watchdogJob = CoroutineScope(Dispatchers.Default).launch {
            delay(20000)
            Log.e("ReachMesh", "Watchdog timeout. Socket $endpointId is a black hole. Rebooting Daemon.")

            val msgId = outgoingTransfers.remove(payloadId)
            if (msgId != null) {
                Log.d("ReachMesh", "State-Healer active: Reverting message $msgId back to PENDING.")
                messageDao.updateDeliveryState(msgId, DeliveryState.PENDING, localUserId)
            }

            restartMesh()
        }
        activeTextWatchdogs[payloadId] = watchdogJob
    }

    fun hasAnyActiveConnections(): Boolean {
        return connectedEndpoints.isNotEmpty()
    }

    fun broadcastToAllNeighbors(message: String) {
        if (connectedEndpoints.isEmpty()) return
        val payload = Payload.fromBytes(message.toByteArray(Charsets.UTF_8))
        connectionsClient.sendPayload(connectedEndpoints.toList(), payload)
    }

    fun broadcastToAllNeighborsExcept(message: String, excludeEndpointId: String) {
        val targets = connectedEndpoints.filter { it != excludeEndpointId }
        if (targets.isEmpty()) return
        val payload = Payload.fromBytes(message.toByteArray(Charsets.UTF_8))
        connectionsClient.sendPayload(targets, payload)
    }

    fun stopAll() {
        restartJob?.cancel()
        gossipJob?.cancel()
        stopHeartbeat()

        // Clean up watchdogs
        autoConnectJob?.cancel()
        discoveryPulseJob?.cancel()

        isIntentionallyRunning = false
        connectionsClient.stopAdvertising()
        connectionsClient.stopDiscovery()
        connectionsClient.stopAllEndpoints()
        _discoveredPeers.value = emptyList()
        endpointToStableIdMap.clear()
        connectedEndpoints.clear()
        activeFileTransfers.clear()
        incomingFileMetadata.clear()
        outgoingTransfers.clear()
        outgoingFiles.values.forEach { it.delete() }
        outgoingFiles.clear()
        connectionCooldowns.clear()
        activeTextWatchdogs.values.forEach { it.cancel() }
        activeTextWatchdogs.clear()

        isMeshActive.value = false
        advertisingRetryCount = 0
        discoveryRetryCount = 0
        activeConnectionCount.value = 0

        networkCallback?.let {
            try { connectivityManager.unregisterNetworkCallback(it) } catch (e: Exception) {}
        }
        networkCallback = null
    }

    fun getActiveEndpointId(stableUserId: String): String? {
        val endpoint = endpointToStableIdMap.entries.firstOrNull { it.value == stableUserId }?.key
        return if (endpoint != null && connectedEndpoints.contains(endpoint)) {
            endpoint
        } else {
            null
        }
    }

    fun getDiscoveredEndpointId(stableUserId: String): String? {
        return endpointToStableIdMap.entries.firstOrNull { it.value == stableUserId }?.key
    }
}