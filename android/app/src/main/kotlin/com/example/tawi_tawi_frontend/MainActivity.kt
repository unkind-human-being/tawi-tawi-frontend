package com.example.tawi_tawi_frontend

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.room.Room
import com.rhyn.reach.core.crypto.CryptoManager
import com.rhyn.reach.core.nearby.MeshRelayBroadcaster
import com.rhyn.reach.core.utils.FileHelper
import com.rhyn.reach.data.local.prefs.SessionManager
import com.rhyn.reach.data.remote.ApiService
import com.rhyn.reach.data.repository.ChatRepositoryImpl
import com.rhyn.reach.data.repository.cloud.CloudSyncManager
import com.rhyn.reach.data.repository.routing.MessageRouter
import com.rhyn.reach.data.repository.routing.RoutePlanner
import com.rhyn.reach.presentation.feature.nearby.LanManager
import com.rhyn.reach.presentation.feature.nearby.LanServer
import com.rhyn.reach.presentation.feature.nearby.NearbyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.ktor.client.HttpClient
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.websocket.WebSockets
import io.ktor.serialization.kotlinx.json.json
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import javax.inject.Provider

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.rhyn.reach/messaging"

    private val chatRepository get() = com.rhyn.reach.core.DependencyLocator.chatRepository
    private val nearbyManager get() = com.rhyn.reach.core.DependencyLocator.nearbyManager
    private val lanManager get() = com.rhyn.reach.core.DependencyLocator.lanManager
    private val sessionManager get() = com.rhyn.reach.core.DependencyLocator.sessionManager
    private val cryptoManager get() = com.rhyn.reach.core.DependencyLocator.cryptoManager
    private val messageDao get() = com.rhyn.reach.core.DependencyLocator.messageDao
    private val userDao get() = com.rhyn.reach.core.DependencyLocator.userDao

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // --- REQUEST RUNTIME PERMISSIONS FOR NEARBY CONNECTIONS ---
        val requiredPermissions = mutableListOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            requiredPermissions.add(Manifest.permission.BLUETOOTH_SCAN)
            requiredPermissions.add(Manifest.permission.BLUETOOTH_ADVERTISE)
            requiredPermissions.add(Manifest.permission.BLUETOOTH_CONNECT)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requiredPermissions.add(Manifest.permission.NEARBY_WIFI_DEVICES)
            requiredPermissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }

        val missingPermissions = requiredPermissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (missingPermissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, missingPermissions.toTypedArray(), 100)
        }

        com.rhyn.reach.core.DependencyLocator.initialize(applicationContext)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Setup EventChannels for real-time streams
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.rhyn.reach/inbox_events").setStreamHandler(
            object : EventChannel.StreamHandler {
                private var job: kotlinx.coroutines.Job? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    job = CoroutineScope(Dispatchers.IO).launch {
                        val ownerId = sessionManager.getUserId()
                        if (ownerId == null) {
                            launch(Dispatchers.Main) {
                                events?.success(listOf("System: No active session. Please log in to view messages."))
                            }
                            return@launch
                        }

                        messageDao.getRecentThreads(ownerId).collect { recentMessages ->
                            if (recentMessages.isEmpty()) {
                                launch(Dispatchers.Main) {
                                    events?.success(listOf("System: Mesh active. No messages yet.", "Start a conversation nearby!"))
                                }
                            } else {
                                val formattedMessages = mutableListOf<String>()
                                for (msg in recentMessages) {
                                    val otherUser = userDao.getUserById(msg.threadId, ownerId)
                                    val displayName = otherUser?.username ?: msg.threadId
                                    formattedMessages.add("${msg.threadId}:::$displayName:::${msg.plaintextContent}:::${msg.timestamp}:::${msg.deliveryState.name}")
                                }
                                launch(Dispatchers.Main) {
                                    events?.success(formattedMessages)
                                }
                            }
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    job?.cancel()
                    job = null
                }
            }
        )

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "com.rhyn.reach/chat_events").setStreamHandler(
            object : EventChannel.StreamHandler {
                private var job: kotlinx.coroutines.Job? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    val threadId = arguments as? String ?: return
                    job = CoroutineScope(Dispatchers.IO).launch {
                        val ownerId = sessionManager.getUserId() ?: "unknown"
                        messageDao.getMessagesForThread(threadId, ownerId).collect { messages ->
                            val formattedMessages = mutableListOf<String>()
                            for (msg in messages) {
                                if (msg.isFromMe) {
                                    formattedMessages.add("You:::${msg.plaintextContent}:::${msg.timestamp}:::${msg.deliveryState.name}")
                                } else {
                                    val senderUser = userDao.getUserById(msg.senderId, ownerId)
                                    val senderName = senderUser?.username ?: msg.senderId
                                    formattedMessages.add("$senderName:::${msg.plaintextContent}:::${msg.timestamp}:::${msg.deliveryState.name}")
                                }
                            }
                            launch(Dispatchers.Main) {
                                events?.success(formattedMessages)
                            }
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    job?.cancel()
                    job = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInboxMessages" -> {
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val ownerId = sessionManager.getUserId()
                            if (ownerId == null) {
                                launch(Dispatchers.Main) {
                                    result.success(listOf("System: No active session. Please log in to view messages."))
                                }
                            } else {
                                val recentMessages = messageDao.getRecentThreads(ownerId).first()
                                if (recentMessages.isEmpty()) {
                                    launch(Dispatchers.Main) {
                                        result.success(listOf("System: Mesh active. No messages yet.", "Start a conversation nearby!"))
                                    }
                                } else {
                                    val formattedMessages = mutableListOf<String>()
                                    for (msg in recentMessages) {
                                        val otherUser = userDao.getUserById(msg.threadId, ownerId)
                                        val displayName = otherUser?.username ?: msg.threadId
                                        formattedMessages.add("${msg.threadId}:::$displayName:::${msg.plaintextContent}")
                                    }
                                    launch(Dispatchers.Main) {
                                        result.success(formattedMessages)
                                    }
                                }
                            }
                        } catch (e: Exception) {
                            launch(Dispatchers.Main) {
                                result.error("DB_ERROR", e.message, null)
                            }
                        }
                    }
                }
                "startMesh" -> {
                    // Generate keys for guests if missing
                    if (sessionManager.getPublicKey() == null) {
                        val (pub, priv) = cryptoManager.generateNewKeyPair()
                        sessionManager.savePublicKey(pub)
                        sessionManager.savePrivateKey(priv)
                    }
                    if (sessionManager.getSigningPublicKey() == null) {
                        val (signPub, signPriv) = cryptoManager.generateEd25519KeyPair()
                        sessionManager.saveSigningPublicKey(signPub)
                        sessionManager.saveSigningPrivateKey(signPriv)
                    }

                    val userId = sessionManager.getUserId() ?: ("guest_" + java.util.UUID.randomUUID().toString().substring(0, 8))
                    val username = sessionManager.getUsername() ?: "Guest_Device"
                    
                    val startIntent = android.content.Intent(this@MainActivity, com.rhyn.reach.core.nearby.MeshService::class.java).apply {
                        action = com.rhyn.reach.core.nearby.MeshService.ACTION_START
                    }
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        startForegroundService(startIntent)
                    } else {
                        startService(startIntent)
                    }
                    
                    result.success("Mesh networking started")
                }
                "getNearbyDevices" -> {
                    if (!nearbyManager.isMeshActive.value) {
                        // Generate keys for guests if missing
                        if (sessionManager.getPublicKey() == null) {
                            val (pub, priv) = cryptoManager.generateNewKeyPair()
                            sessionManager.savePublicKey(pub)
                            sessionManager.savePrivateKey(priv)
                        }
                        if (sessionManager.getSigningPublicKey() == null) {
                            val (signPub, signPriv) = cryptoManager.generateEd25519KeyPair()
                            sessionManager.saveSigningPublicKey(signPub)
                            sessionManager.saveSigningPrivateKey(signPriv)
                        }

                        val userId = sessionManager.getUserId() ?: ("guest_" + java.util.UUID.randomUUID().toString().substring(0, 8))
                        val username = sessionManager.getUsername() ?: "Guest_Device"
                        
                        val startIntent = android.content.Intent(this@MainActivity, com.rhyn.reach.core.nearby.MeshService::class.java).apply {
                            action = com.rhyn.reach.core.nearby.MeshService.ACTION_START
                        }
                        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                            startForegroundService(startIntent)
                        } else {
                            startService(startIntent)
                        }
                    }
                    val btPeers = nearbyManager.discoveredPeers.value.map { "${it.stableUserId}:::${it.username} (Bluetooth/WiFi Direct)" }
                    val lanPeers = lanManager.discoveredLanPeers.value.values.map { "${it.stableUserId}:::${it.username} (LAN)" }
                    
                    val allPeers = btPeers + lanPeers
                    if (allPeers.isEmpty()) {
                        result.success(listOf("No devices found nearby. Searching..."))
                    } else {
                        result.success(allPeers)
                    }
                }
                "syncSession" -> {
                    val userId = call.argument<String>("userId")
                    val username = call.argument<String>("username")
                    val token = call.argument<String>("token")

                    if (userId != null) sessionManager.saveUserId(userId)
                    if (username != null) sessionManager.saveUsername(username)
                    if (token != null) sessionManager.saveToken(token)

                    // Ensure crypto keys exist so MessageRouter can encrypt payloads
                    if (sessionManager.getPublicKey() == null) {
                        val (pub, priv) = cryptoManager.generateNewKeyPair()
                        sessionManager.savePublicKey(pub)
                        sessionManager.savePrivateKey(priv)
                    }
                    if (sessionManager.getSigningPublicKey() == null) {
                        val (signPub, signPriv) = cryptoManager.generateEd25519KeyPair()
                        sessionManager.saveSigningPublicKey(signPub)
                        sessionManager.saveSigningPrivateKey(signPriv)
                    }

                    // Also restart mesh to pick up new identity if running
                    if (nearbyManager.isMeshActive.value) {
                        nearbyManager.restartMesh()
                    }

                    result.success(true)
                }
                "sendMessage" -> {
                    val threadId = call.argument<String>("threadId")
                    val messageText = call.argument<String>("messageText")
                    if (threadId != null && messageText != null) {
                        CoroutineScope(Dispatchers.IO).launch {
                            try {
                                chatRepository.sendMessage(threadId, messageText)
                                launch(Dispatchers.Main) {
                                    result.success(true)
                                }
                            } catch (e: Exception) {
                                launch(Dispatchers.Main) {
                                    result.error("SEND_ERROR", e.message, null)
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGS", "Missing threadId or messageText", null)
                    }
                }
                "getMessagesForThread" -> {
                    val threadId = call.argument<String>("threadId")
                    val ownerId = sessionManager.getUserId() ?: "unknown"
                    if (threadId != null) {
                        CoroutineScope(Dispatchers.IO).launch {
                            try {
                                val messages = messageDao.getMessagesForThread(threadId, ownerId).first()
                                val formattedMessages = mutableListOf<String>()
                                for (msg in messages) {
                                    if (msg.isFromMe) {
                                        formattedMessages.add("You:::${msg.plaintextContent}")
                                    } else {
                                        val senderUser = userDao.getUserById(msg.senderId, ownerId)
                                        val senderName = senderUser?.username ?: msg.senderId
                                        formattedMessages.add("$senderName:::${msg.plaintextContent}")
                                    }
                                }
                                launch(Dispatchers.Main) {
                                    result.success(formattedMessages)
                                }
                            } catch (e: Exception) {
                                launch(Dispatchers.Main) {
                                    result.error("DB_ERROR", e.message, null)
                                }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGS", "Missing threadId", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
