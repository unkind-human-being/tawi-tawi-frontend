package com.example.tawi_tawi_frontend.channels

import android.content.Context
import android.content.Intent
import android.os.Build
import com.rhyn.reach.core.DependencyLocator
import com.rhyn.reach.core.nearby.MeshService
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

class PlatformChannelHandler(private val context: Context) {
    private val CHANNEL = "com.rhyn.reach/messaging"

    private val chatRepository get() = DependencyLocator.chatRepository
    private val nearbyManager get() = DependencyLocator.nearbyManager
    private val lanManager get() = DependencyLocator.lanManager
    private val sessionManager get() = DependencyLocator.sessionManager
    private val cryptoManager get() = DependencyLocator.cryptoManager
    private val messageDao get() = DependencyLocator.messageDao
    private val userDao get() = DependencyLocator.userDao

    fun setupChannels(flutterEngine: FlutterEngine) {
        val binaryMessenger = flutterEngine.dartExecutor.binaryMessenger

        // Setup EventChannels for real-time streams
        EventChannel(binaryMessenger, "com.rhyn.reach/inbox_events").setStreamHandler(
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

        EventChannel(binaryMessenger, "com.rhyn.reach/chat_events").setStreamHandler(
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

        MethodChannel(binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
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

                    val startIntent = Intent(context, MeshService::class.java).apply {
                        action = MeshService.ACTION_START
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(startIntent)
                    } else {
                        context.startService(startIntent)
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

                        val startIntent = Intent(context, MeshService::class.java).apply {
                            action = MeshService.ACTION_START
                        }
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            context.startForegroundService(startIntent)
                        } else {
                            context.startService(startIntent)
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
