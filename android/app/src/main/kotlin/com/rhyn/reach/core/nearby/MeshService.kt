package com.rhyn.reach.core.nearby

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import com.example.tawi_tawi_frontend.MainActivity
import com.example.tawi_tawi_frontend.R
import com.rhyn.reach.core.crypto.CryptoManager
import com.rhyn.reach.core.DependencyLocator
import com.rhyn.reach.core.utils.FileHelper
import com.rhyn.reach.data.local.DeliveryState
import com.rhyn.reach.data.local.LocalMessageEntity
import com.rhyn.reach.data.local.LocalUserEntity
import com.rhyn.reach.data.local.MessageType
import com.rhyn.reach.data.local.dao.MessageDao
import com.rhyn.reach.data.local.dao.UserDao
import com.rhyn.reach.data.local.prefs.SessionManager
import com.rhyn.reach.data.remote.model.MeshEnvelope
import com.rhyn.reach.domain.repository.ChatRepository
import com.rhyn.reach.presentation.feature.nearby.LanManager
import com.rhyn.reach.presentation.feature.nearby.NearbyManager

import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import java.io.FileInputStream
import java.io.FileOutputStream
import javax.inject.Inject

class MeshService : Service() {

    private val nearbyManager get() = DependencyLocator.nearbyManager
    private val lanManager get() = DependencyLocator.lanManager
    private val repository get() = DependencyLocator.chatRepository

    // --- NEW INJECTIONS FOR MEDIA HANDLING ---
    private val fileHelper get() = DependencyLocator.fileHelper
    private val cryptoManager get() = DependencyLocator.cryptoManager
    private val sessionManager get() = DependencyLocator.sessionManager
    private val messageDao get() = DependencyLocator.messageDao
    private val userDao get() = DependencyLocator.userDao

    // 1. Declare the WakeLock
    private var wakeLock: PowerManager.WakeLock? = null

    companion object {
        private const val CHANNEL_ID = "reach_mesh_channel"
        private const val NOTIFICATION_ID = 888
        const val ACTION_START = "ACTION_START_MESH"
        const val ACTION_STOP = "ACTION_STOP_MESH"
    }

    override fun onCreate() {
        super.onCreate()
        com.rhyn.reach.core.DependencyLocator.initialize(applicationContext)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action != ACTION_STOP) {
            try {
                startForeground(NOTIFICATION_ID, createNotification())
            } catch (e: Exception) {
                Log.e("ReachMeshService", "Failed to start foreground", e)
            }
        }

        when (intent?.action) {
            ACTION_START -> {
                val userId = repository.getCurrentUserId()
                if (userId == null) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                    stopSelf()
                    return START_NOT_STICKY
                }

                // 2. Acquire the WakeLock to keep the CPU running!
                acquireWakeLock()

                val username = repository.getCurrentUsername() ?: "Guest"

                // --- Handle incoming LAN messages ---
                lanManager.lanServer.onMessageReceived = { payload ->
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            if (payload.startsWith("KEY_REQUEST:")) {
                                Log.i("ReachMeshService", "Received LAN KEY_REQUEST payload")
                                val parts = payload.split(":", limit = 4)
                                if (parts.size >= 3) {
                                    val requestedUserId = parts[1].trim()
                                    val requesterId = parts[2].trim()
                                    val requesterName = if (parts.size >= 4) parts[3].trim() else "Unknown (LAN)"

                                    val myId = sessionManager.getUserId()?.trim()

                                    if (myId == requestedUserId) {
                                        val myKey = sessionManager.getPublicKey()?.trim() ?: ""
                                        val mySignKey = sessionManager.getSigningPublicKey()?.trim() ?: ""
                                        val myName = sessionManager.getUsername()?.trim() ?: "Guest"

                                        if (myKey.isNotBlank() && mySignKey.isNotBlank()) {
                                            val response = "KEY_RESPONSE:$myId:$requesterId:$myKey:$mySignKey:$myName"
                                            lanManager.broadcastToAllNeighbors(response)
                                        }

                                        // Save requester's real name proactively
                                        val existingUser = userDao.getUserById(requesterId, myId)
                                        if (existingUser == null) {
                                            userDao.insertUser(
                                                LocalUserEntity(
                                                    userId = requesterId,
                                                    ownerId = myId,
                                                    username = requesterName,
                                                    isGroup = false
                                                )
                                            )
                                        } else if (existingUser.username.startsWith("Unknown")) {
                                            userDao.insertUser(existingUser.copy(username = requesterName))
                                        }
                                    } else {
                                        Log.w("ReachMeshService", "Ignored LAN KEY_REQUEST because it was meant for someone else.")
                                    }
                                }
                                return@launch
                            }
                            
                            if (payload.startsWith("KEY_RESPONSE:")) {
                                val parts = payload.split(":", limit = 6)
                                if (parts.size >= 5) {
                                    val requestedUserId = parts[1]
                                    val requesterId = parts[2]
                                    val foundKey = parts[3]
                                    val foundSignKey = parts[4]
                                    val foundName = if (parts.size >= 6) parts[5] else "Unknown"
                                    
                                    val myId = sessionManager.getUserId()
                                    if (requesterId == myId) {
                                        val existingUser = userDao.getUserById(requestedUserId, myId!!)
                                        if (existingUser == null) {
                                            userDao.insertUser(com.rhyn.reach.data.local.LocalUserEntity(
                                                userId = requestedUserId,
                                                ownerId = myId,
                                                username = foundName,
                                                isGroup = false,
                                                publicKey = foundKey,
                                                signingPublicKey = foundSignKey
                                            ))
                                        } else {
                                            userDao.insertUser(existingUser.copy(
                                                username = if (existingUser.username.startsWith("Unknown")) foundName else existingUser.username,
                                                publicKey = foundKey,
                                                signingPublicKey = foundSignKey
                                            ))
                                        }
                                    }
                                }
                                return@launch
                            }
                            
                            if (payload.startsWith("ANNOUNCE:")) {
                                return@launch // LAN doesn't need to process Bluetooth Gossip
                            }
                            
                            repository.processIncomingMeshPayload(payload)
                        } catch (e: Exception) {
                            Log.e("ReachMeshService", "Failed to process LAN payload", e)
                        }
                    }
                }

                // ---> NEW: FILE LISTENER <---
                lanManager.lanServer.onFileReceived = { metadataJson, encryptedFile ->
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val envelope = Json { ignoreUnknownKeys = true }.decodeFromString<MeshEnvelope>(metadataJson)
                            val myId = sessionManager.getUserId() ?: return@launch

                            if (envelope.targetId == myId) {
                                val myPrivateKey = sessionManager.getPrivateKey() ?: return@launch
                                Log.d("ReachMeshService", "LAN File transfer received. Decrypting...")

                                // Setup output decrypted file
                                val ext = if (envelope.payloadType == "IMAGE") "jpg" else "bin"
                                val decryptedFile = fileHelper.createDecryptedMediaFile(ext)

                                // Decrypt Stream
                                cryptoManager.decryptStream(
                                    FileInputStream(encryptedFile),
                                    FileOutputStream(decryptedFile),
                                    myPrivateKey
                                )

                                val uriString = fileHelper.getInternalUriForFile(decryptedFile)

                                // Save to DB
                                val localMessage = LocalMessageEntity(
                                    messageId = envelope.messageId,
                                    ownerId = myId,
                                    threadId = envelope.senderId,
                                    senderId = envelope.senderId,
                                    plaintextContent = "", // No caption for now
                                    attachmentUri = uriString,
                                    messageType = if (envelope.payloadType == "IMAGE") MessageType.IMAGE else MessageType.FILE,
                                    timestamp = System.currentTimeMillis(),
                                    isFromMe = false,
                                    deliveryState = DeliveryState.LAN_DELIVERED
                                )

                                messageDao.insertMessage(localMessage)

                                // Cleanup raw encrypted cache file
                                encryptedFile.delete()
                                Log.d("ReachMeshService", "LAN File successfully decrypted and saved to local DB.")

                            } else {
                                Log.w("ReachMeshService", "Received LAN file meant for ${envelope.targetId}. Relay not supported yet. Discarding.")
                                encryptedFile.delete()
                            }
                        } catch (e: Exception) {
                            Log.e("ReachMeshService", "Failed to process incoming LAN file", e)
                            encryptedFile.delete()
                        }
                    }
                }

                // Start Bluetooth/WiFi Direct Mesh
                nearbyManager.startAdvertising(userId, username)
                nearbyManager.startDiscovery()

                // Start Local Network (mDNS) Discovery & Server
                lanManager.startAll(userId, username)
            }
            ACTION_STOP -> {
                nearbyManager.stopAll()
                lanManager.stopAll() // <-- Stop LAN discovery

                // 3. Release the WakeLock when stopping
                releaseWakeLock()

                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_STICKY
    }

    private fun acquireWakeLock() {
        if (wakeLock == null) {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "Reach::MeshWakeLock"
            ).apply {
                // Failsafe timeout: Automatically release after 12 hours
                // to prevent permanent battery drain if the app crashes hard.
                acquire(12 * 60 * 60 * 1000L)
            }
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
    }

    private fun createNotification(): android.app.Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Reach Mesh Active")
            .setContentText("Routing offline messages...")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannel() {
        val serviceChannel = NotificationChannel(
            CHANNEL_ID,
            "Mesh Network Service",
            NotificationManager.IMPORTANCE_LOW
        )
        val manager = getSystemService(NotificationManager::class.java)
        manager?.createNotificationChannel(serviceChannel)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        nearbyManager.stopAll()
        lanManager.stopAll() // <-- Stop LAN discovery on destroy

        // 4. Ensure WakeLock is released if Android destroys the service
        releaseWakeLock()
    }
}