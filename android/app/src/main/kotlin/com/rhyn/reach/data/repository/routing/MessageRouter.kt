package com.rhyn.reach.data.repository.routing

import android.util.Log
import com.rhyn.reach.core.crypto.CryptoManager
import com.rhyn.reach.core.utils.FileHelper
import com.rhyn.reach.presentation.feature.nearby.NearbyManager
import com.rhyn.reach.presentation.feature.nearby.LanManager
import com.rhyn.reach.data.local.DeliveryState
import com.rhyn.reach.data.local.dao.MessageDao
import com.rhyn.reach.data.local.dao.UserDao
import com.rhyn.reach.data.local.dao.MeshRelayDao
import com.rhyn.reach.data.local.prefs.SessionManager
import com.rhyn.reach.data.remote.ApiService
import com.rhyn.reach.data.remote.model.MeshEnvelope
import io.ktor.client.plugins.websocket.DefaultClientWebSocketSession
import io.ktor.websocket.Frame
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.withTimeoutOrNull
import java.io.File

@Singleton
class MessageRouter @Inject constructor(
    private val messageDao: MessageDao,
    private val userDao: UserDao,
    private val meshRelayDao: MeshRelayDao,
    private val nearbyManager: NearbyManager,
    private val lanManager: LanManager,
    private val cryptoManager: CryptoManager,
    private val apiService: ApiService,
    private val sessionManager: SessionManager,
    private val fileHelper: FileHelper,
    private val routePlanner: RoutePlanner
) {

    private val tag = "ReachRouter"
    
    private val verifiedCloudUsers = java.util.Collections.newSetFromMap(java.util.concurrent.ConcurrentHashMap<String, Boolean>())

    private suspend fun isCloudUserVerified(targetUserId: String): Boolean {
        if (verifiedCloudUsers.contains(targetUserId)) return true
        
        val token = sessionManager.getJwtToken() ?: return false
        
        return try {
            val response = withTimeoutOrNull(3000) {
                apiService.getPublicKey(targetUserId, token)
            }
            if (response != null && response.public_key.isNotEmpty()) {
                verifiedCloudUsers.add(targetUserId)
                true
            } else {
                false
            }
        } catch (e: Exception) {
            if (e.message?.contains("404") == true) {
                Log.w(tag, "Target $targetUserId not found on cloud (404). Blocking cloud transmission.")
            } else {
                Log.e(tag, "Error verifying cloud user $targetUserId", e)
            }
            false
        }
    }

    suspend fun routeAllPendingMessages(webSocketSession: DefaultClientWebSocketSession?) {
        withContext(Dispatchers.IO) {
            val myId = sessionManager.getUserId() ?: return@withContext
            flushRelayQueue(webSocketSession)

            val pendingUsers = messageDao.getPendingTargetUsers(myId)
            pendingUsers.forEach { targetUserId ->
                routePendingMessages(targetUserId, webSocketSession)
            }
        }
    }

    suspend fun routePendingMessages(targetUserId: String, webSocketSession: DefaultClientWebSocketSession?) {
        withContext(Dispatchers.IO) {
            val myId = sessionManager.getUserId() ?: return@withContext

            flushRelayQueue(webSocketSession)

            val pendingMessages = messageDao.getPendingMessagesForUser(targetUserId, myId)
            if (pendingMessages.isEmpty()) return@withContext

            var targetPublicKey = userDao.getUserById(targetUserId, myId)?.publicKey

            if (targetPublicKey.isNullOrEmpty() && webSocketSession?.isActive == true) {
                try {
                    val token = sessionManager.getJwtToken() ?: return@withContext
                    val response = withTimeoutOrNull(3000) {
                        apiService.getPublicKey(targetUserId, token)
                    }
                    if (response != null && response.public_key.isNotEmpty()) {
                        targetPublicKey = response.public_key
                        userDao.updatePublicKey(targetUserId, targetPublicKey, myId)
                        verifiedCloudUsers.add(targetUserId)
                    }
                } catch (e: Exception) {
                    Log.e(tag, "Failed to fetch public key from cloud", e)
                }
            }

            val myPublicKey = sessionManager.getPublicKey() ?: userDao.getUserById(myId, myId)?.publicKey

            val myName = sessionManager.getUsername() ?: "Unknown"

            if (targetPublicKey.isNullOrEmpty()) {
                Log.w(tag, "Missing public key for $targetUserId. Broadcasting KEY_REQUEST to mesh/LAN.")
                // Appending the sender name to the key request
                val keyRequestPayload = "KEY_REQUEST:$targetUserId:$myId:$myName"

                if (nearbyManager.hasAnyActiveConnections()) {
                    nearbyManager.broadcastToAllNeighbors(keyRequestPayload)
                }
                if (lanManager.discoveredLanPeers.value.isNotEmpty()) {
                    lanManager.broadcastToAllNeighbors(keyRequestPayload)
                }
                return@withContext
            }

            if (myPublicKey.isNullOrEmpty()) return@withContext

            val mySigningPrivateKey = sessionManager.getSigningPrivateKey() ?: ""

            pendingMessages.forEach { msg ->
                try {
                    if (msg.messageType == com.rhyn.reach.data.local.MessageType.TEXT) {
                        val targetEncrypted = cryptoManager.encryptMessage(msg.plaintextContent, targetPublicKey)
                        val selfEncrypted = cryptoManager.encryptMessage(msg.plaintextContent, myPublicKey)

                        val calculatedRoute = routePlanner.getShortestPath(myId, targetUserId)

                        val sourceRoute = if (!calculatedRoute.isNullOrEmpty()) {
                            Log.d(tag, "Source Route found for $targetUserId: $calculatedRoute")
                            calculatedRoute
                        } else {
                            Log.d(tag, "No Source Route (or direct neighbor). Falling back to Direct/Epidemic Delivery.")
                            emptyList()
                        }

                        val payloadToSign = "${msg.messageId}:$myId:$targetUserId:$targetEncrypted"
                        val signature = if (mySigningPrivateKey.isNotEmpty()) cryptoManager.signData(payloadToSign, mySigningPrivateKey) else null

                        val envelope = MeshEnvelope(
                            messageId = msg.messageId,
                            senderId = myId,
                            targetId = targetUserId,
                            encryptedPayload = targetEncrypted,
                            payloadType = msg.messageType.name,
                            ttl = 5,
                            sourceRoute = sourceRoute,
                            pathHistory = listOf(myId),
                            signature = signature,
                            senderUsername = myName // Append the sender username
                        )
                        val meshPayloadJson = Json.encodeToString(envelope)

                        val targetIpAddress = lanManager.getActiveIpAddress(targetUserId)
                        val activeNearbyEndpointId = nearbyManager.getActiveEndpointId(targetUserId)

                        var currentNearbyEndpointId = activeNearbyEndpointId
                        var deliveredLocally = false

                        if (targetIpAddress != null) {
                            Log.d(tag, "Attempting LAN delivery to IP: $targetIpAddress")
                            val lanSuccess = lanManager.sendMessage(targetIpAddress, meshPayloadJson)

                            if (lanSuccess) {
                                messageDao.updateDeliveryState(msg.messageId, DeliveryState.LAN_DELIVERED, myId)
                                deliveredLocally = true
                            } else {
                                Log.w(tag, "LAN delivery failed. Falling back to Mesh socket.")
                            }
                        }

                        var pushedToNextHop = false

                        if (!deliveredLocally && currentNearbyEndpointId != null) {
                            Log.d(tag, "Routing via Bluetooth Mesh to: $currentNearbyEndpointId")
                            nearbyManager.sendMessage(currentNearbyEndpointId, meshPayloadJson)
                            messageDao.updateDeliveryState(msg.messageId, DeliveryState.MESH_ROUTED, myId)
                            deliveredLocally = true
                        }

                        val hasBluetooth = nearbyManager.hasAnyActiveConnections()
                        val hasLan = lanManager.discoveredLanPeers.value.isNotEmpty()

                        if (!deliveredLocally && (hasBluetooth || hasLan)) {
                            if (sourceRoute.isNotEmpty() && hasBluetooth) {
                                val nextHopNodeId = sourceRoute[0]
                                val nextHopEndpoint = nearbyManager.getActiveEndpointId(nextHopNodeId)
                                if (nextHopEndpoint != null) {
                                    Log.d(tag, "Source Route exact match from sender. Attempting direct push to $nextHopNodeId")
                                    try {
                                        nearbyManager.sendMessage(nextHopEndpoint, meshPayloadJson)
                                        messageDao.updateDeliveryState(msg.messageId, DeliveryState.MESH_ROUTED, myId)
                                        deliveredLocally = true
                                        pushedToNextHop = true
                                    } catch (e: Exception) {
                                        Log.w(tag, "Source Route direct push failed from sender. Falling back to Epidemic Flooding!")
                                    }
                                }
                            }

                            if (!pushedToNextHop) {
                                Log.d(tag, "Target not directly connected. Broadcasting to ALL networks epidemically.")
                                val epidemicEnvelope = envelope.copy(sourceRoute = emptyList())
                                val epidemicPayloadJson = Json.encodeToString(epidemicEnvelope)
                                
                                // THE FIX: Push to any active network, bridging the gap so Phone A can intercept it
                                if (hasBluetooth) nearbyManager.broadcastToAllNeighbors(epidemicPayloadJson)
                                if (hasLan) lanManager.broadcastToAllNeighbors(epidemicPayloadJson)
                                
                                messageDao.updateDeliveryState(msg.messageId, DeliveryState.MESH_ROUTED, myId)
                                deliveredLocally = true
                            }
                        }

                        // ---> REMOVED: Impatient manual GATT reconnection attempt was here. <---

                        if (!deliveredLocally && webSocketSession?.isActive == true) {
                            if (isCloudUserVerified(targetUserId)) {
                                val cloudMessageJson = """{
                                    "message_id": "${msg.messageId}", 
                                    "sender_id": "$myId",
                                    "target_id": "$targetUserId", 
                                    "target_payload": "$targetEncrypted",
                                    "self_payload": "$selfEncrypted",
                                    "timestamp": ${msg.timestamp},
                                    "payload_type": "${msg.messageType.name}"
                                }"""
    
                                val sendResult = withTimeoutOrNull(3000) {
                                    webSocketSession.send(Frame.Text(cloudMessageJson))
                                    true
                                }
    
                                if (sendResult == true) {
                                    messageDao.updateDeliveryState(msg.messageId, DeliveryState.CLOUD_DELIVERED, myId)
                                    messageDao.updateSyncState(listOf(msg.messageId), com.rhyn.reach.data.local.SyncState.SYNCED, myId)
                                } else {
                                    Log.w(tag, "Cloud send timed out on dead network. Retaining PENDING state.")
                                }
                            } else {
                                Log.w(tag, "Target $targetUserId is not verified on cloud. Retaining PENDING state.")
                            }
                        }
                    } else {
                        val uriString = msg.attachmentUri
                        if (uriString != null) {
                            Log.d(tag, "Re-processing pending file: ${msg.messageId}")
                            val inputStream = fileHelper.getInputStreamFromUri(uriString)
                            if (inputStream != null) {
                                val encryptedTempFile = fileHelper.createTempEncryptedFile()
                                val outputStream = java.io.FileOutputStream(encryptedTempFile)

                                cryptoManager.encryptStream(inputStream, outputStream, targetPublicKey)

                                routeEncryptedFile(
                                    messageId = msg.messageId,
                                    targetId = targetUserId,
                                    encryptedFile = encryptedTempFile,
                                    fileType = msg.messageType.name,
                                    webSocketSession = webSocketSession
                                )
                            }
                        }
                    }
                } catch (e: Exception) {
                    Log.e(tag, "Failed to route message: ${msg.messageId}", e)
                }
            }
        }
    }

    suspend fun routeEncryptedFile(
        messageId: String,
        targetId: String,
        encryptedFile: File,
        fileType: String,
        webSocketSession: DefaultClientWebSocketSession? = null
    ) {
        withContext(Dispatchers.IO) {
            try {
                val myId = sessionManager.getUserId() ?: return@withContext
                val myName = sessionManager.getUsername() ?: "Unknown"

                val envelope = MeshEnvelope(
                    messageId = messageId,
                    senderId = myId,
                    targetId = targetId,
                    encryptedPayload = encryptedFile.name,
                    payloadType = fileType,
                    ttl = 5,
                    pathHistory = listOf(myId),
                    senderUsername = myName // Append the sender username
                )
                val metadataJson = Json.encodeToString(envelope)

                val targetIpAddress = lanManager.getActiveIpAddress(targetId)
                val activeNearbyEndpointId = nearbyManager.getActiveEndpointId(targetId)

                var currentNearbyEndpointId = activeNearbyEndpointId
                var deliveredLocally = false
                
                val isOversized = encryptedFile.length() > 5L * 1024 * 1024

                if (!isOversized && targetIpAddress != null) {
                    Log.d(tag, "Attempting LAN File delivery to IP: $targetIpAddress")
                    val lanSuccess = lanManager.sendFile(targetIpAddress, metadataJson, encryptedFile)
                    if (lanSuccess) {
                        messageDao.updateDeliveryState(messageId, DeliveryState.LAN_DELIVERED, myId)
                        deliveredLocally = true
                    } else {
                        Log.w(tag, "LAN file delivery failed. Falling back to Mesh socket.")
                    }
                }

                if (!isOversized && !deliveredLocally && currentNearbyEndpointId != null) {
                    Log.d(tag, "Routing File via Bluetooth Mesh to: $currentNearbyEndpointId")
                    nearbyManager.sendFile(currentNearbyEndpointId, metadataJson, encryptedFile)
                    messageDao.updateDeliveryState(messageId, DeliveryState.MESH_ROUTED, myId)
                    deliveredLocally = true
                }
                
                if (isOversized) {
                    Log.w(tag, "File is over 5MB. Bypassing offline mesh delivery to Cloud Fallback.")
                }

                // ---> REMOVED: Impatient manual GATT reconnection attempt was here. <---

                if (!deliveredLocally) {
                    val token = sessionManager.getJwtToken()
                    if (token != null && webSocketSession?.isActive == true) {
                        if (isCloudUserVerified(targetId)) {
                            Log.d(tag, "No local route for file. Delegating to Cloud API Upload.")
    
                            try {
                                val uploadResponse = apiService.uploadMedia(encryptedFile, token)
                                val targetPublicKey = userDao.getUserById(targetId, myId)?.publicKey
                                val myPublicKey = sessionManager.getPublicKey()
    
                                if (targetPublicKey != null && myPublicKey != null) {
                                    val targetEncryptedUrl = cryptoManager.encryptMessage(uploadResponse.file_url, targetPublicKey)
                                    val selfEncryptedUrl = cryptoManager.encryptMessage(uploadResponse.file_url, myPublicKey)
    
                                    val timestamp = System.currentTimeMillis()
    
                                    val cloudMessageJson = """{
                                        "message_id": "$messageId", 
                                        "sender_id": "$myId",
                                        "target_id": "$targetId", 
                                        "target_payload": "$targetEncryptedUrl",
                                        "self_payload": "$selfEncryptedUrl",
                                        "timestamp": $timestamp,
                                        "payload_type": "$fileType"
                                    }"""
    
                                    webSocketSession.send(Frame.Text(cloudMessageJson))
    
                                    messageDao.updateDeliveryState(messageId, DeliveryState.CLOUD_DELIVERED, myId)
                                    messageDao.updateSyncState(listOf(messageId), com.rhyn.reach.data.local.SyncState.SYNCED, myId)
                                    Log.d(tag, "Cloud media upload and routing successful.")
                                }
                            } catch (e: Exception) {
                                Log.e(tag, "Cloud upload failed. Will retry when connection stabilizes.", e)
                            }
                        } else {
                            Log.w(tag, "Target $targetId is not verified on cloud. Bypassing cloud upload.")
                        }
                    } else {
                        Log.w(tag, "User is offline and peer is out of range. File transfer pending.")
                    }
                }
            } catch (e: Exception) {
                Log.e(tag, "Failed to route encrypted file.", e)
            }
        }
    }


    suspend fun syncEpidemicRelaysToNewNeighbor(endpointId: String, stableUserId: String) {
        withContext(Dispatchers.IO) {
            val pendingRelays = meshRelayDao.getAllPendingPayloads()
            if (pendingRelays.isEmpty()) return@withContext

            Log.d(tag, "Epidemic Sync: Sending ${pendingRelays.size} stored relays to new neighbor $stableUserId")

            pendingRelays.forEach { relayMsg ->
                if (relayMsg.senderId != stableUserId && !relayMsg.path.contains(stableUserId)) {

                    val newPath = if (relayMsg.path.isNotBlank()) "${relayMsg.path},$stableUserId" else stableUserId

                    val envelope = MeshEnvelope(
                        messageId = relayMsg.payloadId,
                        senderId = relayMsg.senderId,
                        targetId = relayMsg.targetDeviceId,
                        encryptedPayload = relayMsg.encryptedBlob,
                        payloadType = "TEXT",
                        ttl = relayMsg.timeToLive.toInt(),
                        pathHistory = newPath.split(",")
                    )
                    val meshPayloadJson = Json.encodeToString(envelope)

                    nearbyManager.sendMessage(endpointId, meshPayloadJson)

                    delay(100)
                }
            }
        }
    }

    private suspend fun flushRelayQueue(webSocketSession: DefaultClientWebSocketSession?) {
        val pendingRelays = meshRelayDao.getAllPendingPayloads()
        if (pendingRelays.isEmpty()) return

        Log.d(tag, "Evaluating ${pendingRelays.size} relay payloads across all networks.")

        pendingRelays.forEach { relayMsg ->
            try {
                // --- GARBAGE COLLECTOR ---
                val currentTime = System.currentTimeMillis()
                if (currentTime - relayMsg.timestamp > 24 * 60 * 60 * 1000L) {
                    Log.d(tag, "Garbage Collector: Expired relay payload ${relayMsg.payloadId}. Deleting.")
                    meshRelayDao.deleteRelayPayload(relayMsg.payloadId)
                    fileHelper.deleteSecureCacheFile(relayMsg.encryptedBlob)
                    return@forEach
                }
                if (webSocketSession?.isActive == true) {
                    if (isCloudUserVerified(relayMsg.targetDeviceId)) {
                        val cloudMessageJson = """{
                            "message_id": "${relayMsg.payloadId}", 
                            "sender_id": "${relayMsg.senderId}",
                            "target_id": "${relayMsg.targetDeviceId}", 
                            "target_payload": "${relayMsg.encryptedBlob}",
                            "self_payload": "RELAYED_PAYLOAD", 
                            "timestamp": ${relayMsg.timestamp}
                        }"""
    
                        val sendResult = withTimeoutOrNull(3000) {
                            webSocketSession.send(Frame.Text(cloudMessageJson))
                            true
                        }
    
                        if (sendResult == true) {
                            Log.d(tag, "Smart Path: Bridged offline message to the Cloud. Deleting local relay.")
                            meshRelayDao.deleteRelayPayload(relayMsg.payloadId)
                            return@forEach
                        }
                    } else {
                        Log.w(tag, "Relay target ${relayMsg.targetDeviceId} not verified on cloud. Will only route via mesh.")
                    }
                }

                if (!nearbyManager.hasAnyActiveConnections() && lanManager.discoveredLanPeers.value.isEmpty()) {
                    Log.w(tag, "No active connections to route relay. Retaining for later.")
                    return@forEach
                }

                val envelope = MeshEnvelope(
                    messageId = relayMsg.payloadId,
                    senderId = relayMsg.senderId,
                    targetId = relayMsg.targetDeviceId,
                    encryptedPayload = relayMsg.encryptedBlob,
                    payloadType = "TEXT",
                    ttl = relayMsg.timeToLive.toInt(),
                    pathHistory = if (relayMsg.path.isNotBlank()) relayMsg.path.split(",") else emptyList()
                )
                val meshPayloadJson = Json.encodeToString(envelope)

                val targetIpAddress = lanManager.getActiveIpAddress(relayMsg.targetDeviceId)
                val targetEndpointId = nearbyManager.getActiveEndpointId(relayMsg.targetDeviceId)

                var deliveredLocally = false

                if (targetIpAddress != null) {
                    Log.d(tag, "Relay Target is on LAN. Attempting direct delivery.")
                    val lanSuccess = lanManager.sendMessage(targetIpAddress, meshPayloadJson)
                    if (lanSuccess) {
                        deliveredLocally = true
                    } else {
                        Log.w(tag, "LAN relay failed (Possible Double NAT). Falling back to Bluetooth.")
                    }
                }

                if (!deliveredLocally && targetEndpointId != null) {
                    Log.d(tag, "Relay Target is on Bluetooth. Delivering directly.")
                    nearbyManager.sendMessage(targetEndpointId, meshPayloadJson)
                    deliveredLocally = true
                }

                if (deliveredLocally) {
                    Log.d(tag, "Delivered relay locally. Retaining in cache to prevent loops.")
                    return@forEach
                }

                if (nearbyManager.hasAnyActiveConnections() || lanManager.discoveredLanPeers.value.isNotEmpty()) {
                    Log.d(tag, "No direct route. Broadcasting relay to LAN and Bluetooth neighbors.")
                    lanManager.broadcastToAllNeighbors(meshPayloadJson)
                    nearbyManager.broadcastToAllNeighbors(meshPayloadJson)
                }

            } catch (e: Exception) {
                Log.e(tag, "Failed to route relay message: ${relayMsg.payloadId}", e)
            }
        }
    }
}