package com.rhyn.reach.data.repository.cloud

import android.content.Context
import android.util.Log
import com.google.firebase.messaging.FirebaseMessaging
import com.rhyn.reach.core.crypto.CryptoManager
import com.rhyn.reach.data.local.DeliveryState
import com.rhyn.reach.data.local.LocalMessageEntity
import com.rhyn.reach.data.local.LocalUserEntity
import com.rhyn.reach.data.local.dao.MessageDao
import com.rhyn.reach.data.local.dao.UserDao
import com.rhyn.reach.data.local.prefs.SessionManager
import com.rhyn.reach.data.remote.ApiService
import com.rhyn.reach.data.repository.routing.MessageRouter

import io.ktor.client.call.body
import io.ktor.client.plugins.websocket.DefaultClientWebSocketSession
import io.ktor.http.isSuccess
import io.ktor.websocket.Frame
import io.ktor.websocket.readText
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CloudSyncManager @Inject constructor(
    private val apiService: ApiService,
    private val cryptoManager: CryptoManager,
    private val messageDao: MessageDao,
    private val userDao: UserDao,
    private val sessionManager: SessionManager,
    private val messageRouter: MessageRouter,
    private val context: Context
) {
    var activeWebSocketSession: DefaultClientWebSocketSession? = null
        private set

    @Volatile
    private var isSyncRunning = false

    suspend fun startCloudSync(getActiveThreadId: () -> String?) {
        if (isSyncRunning) return

        // Validate existing session is truly alive with a ping
        activeWebSocketSession?.let { session ->
            try {
                session.send(Frame.Ping(ByteArray(0)))
                // Session is genuinely alive, nothing to do
                return
            } catch (_: Exception) {
                Log.d("ReachApp", "Stale WebSocket detected. Reconnecting...")
                activeWebSocketSession = null
            }
        }

        isSyncRunning = true
        try {

        while (true) {
            try {
                val token = sessionManager.getJwtToken() ?: break
                val myId = sessionManager.getUserId() ?: break

                try {
                    val fcmToken = FirebaseMessaging.getInstance().token.await()
                    apiService.updateFcmToken(token, fcmToken)
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    Log.e("ReachApp", "Could not fetch or send FCM token", e)
                }

                activeWebSocketSession = apiService.connectToMeshPipe(token)
                Log.d("ReachApp", "Successfully connected to Cloud WebSocket!")

                pullMissedMessages(token, myId)

                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        userDao.getOnlyRealUsers(myId).first().forEach { user ->
                            messageRouter.routePendingMessages(user.userId, activeWebSocketSession)
                        }
                        syncOfflineMessagesToCloud()
                    } catch (e: CancellationException) {
                        throw e
                    } catch (e: Exception) {
                        Log.e("ReachApp", "Error during bulk cloud flush", e)
                    }
                }

                val jsonParser = Json { ignoreUnknownKeys = true }
                for (frame in activeWebSocketSession!!.incoming) {
                    frame as? Frame.Text ?: continue
                    processIncomingMessage(frame.readText(), myId, jsonParser, getActiveThreadId)
                }

            } catch (e: CancellationException) {
                Log.d("ReachApp", "Cloud sync stopped: Job cancelled")
                activeWebSocketSession = null
                break
            } catch (e: Exception) {
                Log.e("ReachApp", "WebSocket disconnected! Retrying in 3 seconds...", e)
                activeWebSocketSession = null
                delay(3000)
            }
        }
        } finally {
            isSyncRunning = false
        }
    }

    private suspend fun pullMissedMessages(token: String, myId: String) {
        try {
            val response = apiService.syncInbox(token)
            if (response.status.isSuccess()) {
                val inboxData = response.body<com.rhyn.reach.data.remote.model.SyncInboxResponse>()
                val myPrivateKey = sessionManager.getPrivateKey() ?: ""

                inboxData.messages.forEach { cloudMsg ->
                    // --- THE FIX: Cross-Account Bleed Prevention ---
                    if (cloudMsg.target_id != myId && cloudMsg.sender_id != myId) {
                        Log.w("ReachApp", "Dropped missed message intended for ${cloudMsg.target_id}.")
                        return@forEach
                    }

                    val rawEncryptedData = if (cloudMsg.sender_id == myId) cloudMsg.self_payload else cloudMsg.target_payload

                    val decryptedText = try {
                        cryptoManager.decryptMessage(rawEncryptedData, myPrivateKey)
                    } catch (e: Exception) {
                        "Decryption failed"
                    }

                    saveUnknownUser(cloudMsg.sender_id, cloudMsg.sender_username, myId)

                    val resolvedThreadId = if (cloudMsg.target_id == myId) cloudMsg.sender_id else cloudMsg.target_id
                    val isFromMe = cloudMsg.sender_id == myId

                    messageDao.insertMessage(
                        LocalMessageEntity(
                            messageId = cloudMsg.message_id,
                            ownerId = myId,
                            threadId = resolvedThreadId,
                            senderId = cloudMsg.sender_id,
                            plaintextContent = decryptedText,
                            timestamp = cloudMsg.timestamp,
                            isFromMe = isFromMe,
                            deliveryState = DeliveryState.CLOUD_DELIVERED
                        )
                    )
                }
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e("ReachApp", "Failed to pull missed messages", e)
        }
    }

    suspend fun restoreAccountHistory() {
        withContext(Dispatchers.IO) {
            try {
                val token = sessionManager.getJwtToken() ?: return@withContext
                val myId = sessionManager.getUserId() ?: return@withContext
                val myPrivateKey = sessionManager.getPrivateKey() ?: return@withContext

                val response = apiService.restoreMessageHistory(token)

                if (response.status.isSuccess()) {
                    val historyData = response.body<com.rhyn.reach.data.remote.model.SyncInboxResponse>()

                    val localMessages = historyData.messages.mapNotNull { cloudMsg ->
                        // --- THE FIX: Cross-Account Bleed Prevention ---
                        if (cloudMsg.target_id != myId && cloudMsg.sender_id != myId) {
                            return@mapNotNull null
                        }

                        val rawEncryptedData = if (cloudMsg.sender_id == myId) cloudMsg.self_payload else cloudMsg.target_payload

                        val decryptedText = try {
                            cryptoManager.decryptMessage(rawEncryptedData, myPrivateKey)
                        } catch (e: Exception) {
                            return@mapNotNull null
                        }

                        saveUnknownUser(cloudMsg.sender_id, cloudMsg.sender_username, myId)

                        val resolvedThreadId = if (cloudMsg.target_id == myId) cloudMsg.sender_id else cloudMsg.target_id
                        val isFromMe = cloudMsg.sender_id == myId

                        LocalMessageEntity(
                            messageId = cloudMsg.message_id,
                            ownerId = myId,
                            threadId = resolvedThreadId,
                            senderId = cloudMsg.sender_id,
                            plaintextContent = decryptedText,
                            timestamp = cloudMsg.timestamp,
                            isFromMe = isFromMe,
                            deliveryState = DeliveryState.CLOUD_DELIVERED,
                            syncState = com.rhyn.reach.data.local.SyncState.SYNCED
                        )
                    }

                    localMessages.forEach { msg ->
                        messageDao.insertMessage(msg)
                    }

                    Log.d("ReachApp", "Successfully restored ${localMessages.size} historical messages.")
                }
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Log.e("ReachApp", "Failed to restore account history", e)
            }
        }
    }

    private suspend fun processIncomingMessage(
        receivedText: String,
        myId: String,
        jsonParser: Json,
        getActiveThreadId: () -> String?
    ) {
        try {
            val cloudMsg = jsonParser.decodeFromString<com.rhyn.reach.data.remote.model.CloudMessageResponse>(receivedText)

            // --- THE FIX: Cross-Account Bleed Prevention ---
            if (cloudMsg.target_id != myId && cloudMsg.sender_id != myId) {
                Log.w("ReachApp", "Cross-account bleed prevented: Message intended for ${cloudMsg.target_id}, but active user is $myId. Dropping.")
                return
            }

            val isFromMe = cloudMsg.sender_id == myId

            if (isFromMe) {
                messageDao.updateDeliveryState(cloudMsg.message_id, DeliveryState.CLOUD_DELIVERED, myId)
            }

            val rawEncryptedData = if (isFromMe) cloudMsg.self_payload else cloudMsg.target_payload
            val myPrivateKey = sessionManager.getPrivateKey() ?: ""
            val decryptedText = try {
                cryptoManager.decryptMessage(rawEncryptedData, myPrivateKey)
            } catch (e: Exception) {
                "Decryption failed"
            }

            saveUnknownUser(cloudMsg.sender_id, cloudMsg.sender_username, myId)

            val resolvedThreadId = if (cloudMsg.target_id == myId) cloudMsg.sender_id else cloudMsg.target_id

            messageDao.insertMessage(
                LocalMessageEntity(
                    messageId = cloudMsg.message_id,
                    ownerId = myId,
                    threadId = resolvedThreadId,
                    senderId = cloudMsg.sender_id,
                    plaintextContent = decryptedText,
                    timestamp = cloudMsg.timestamp,
                    isFromMe = isFromMe,
                    deliveryState = DeliveryState.CLOUD_DELIVERED
                )
            )

            if (!isFromMe && resolvedThreadId != getActiveThreadId()) {
                com.rhyn.reach.core.notifications.NotificationHelper.showNotification(
                    context = context,
                    title = cloudMsg.sender_username ?: "New Message",
                    message = decryptedText,
                    threadId = resolvedThreadId
                )
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.e("ReachApp", "Failed to process incoming message", e)
        }
    }

    private suspend fun saveUnknownUser(userId: String, username: String?, myId: String) {
        if (userDao.getUserById(userId, myId) == null) {
            userDao.insertUser(
                LocalUserEntity(
                    userId = userId,
                    ownerId = myId,
                    username = username ?: "Unknown",
                    publicKey = "",
                    isGroup = false
                )
            )
        }
    }

    suspend fun syncOfflineMessagesToCloud() {
        withContext(Dispatchers.IO) {
            val myId = sessionManager.getUserId() ?: return@withContext

            val unsyncedMessages = messageDao.getMessagesAllowedForBackup(myId)
            if (unsyncedMessages.isEmpty()) return@withContext

            val messageIds = unsyncedMessages.map { it.messageId }
            messageDao.updateSyncState(messageIds, com.rhyn.reach.data.local.SyncState.SYNCING, myId)

            try {
                val backupPayloads = unsyncedMessages.mapNotNull { msg ->
                    val targetPublicKey = userDao.getUserById(msg.threadId, myId)?.publicKey
                    val myPublicKey = sessionManager.getPublicKey() ?: userDao.getUserById(myId, myId)?.publicKey

                    if (!targetPublicKey.isNullOrEmpty() && !myPublicKey.isNullOrEmpty()) {
                        val targetEncrypted = cryptoManager.encryptMessage(msg.plaintextContent, targetPublicKey)
                        val selfEncrypted = cryptoManager.encryptMessage(msg.plaintextContent, myPublicKey)

                        com.rhyn.reach.data.remote.model.BackupMessageDto(
                            message_id = msg.messageId,
                            thread_id = msg.threadId,
                            sender_id = msg.senderId,
                            target_payload = targetEncrypted,
                            self_payload = selfEncrypted,
                            timestamp = msg.timestamp
                        )
                    } else null
                }

                val token = sessionManager.getJwtToken() ?: throw Exception("No token")
                val response = apiService.backupMessagesBatch(token, backupPayloads)

                if (response.status.isSuccess()) {
                    messageDao.updateSyncState(messageIds, com.rhyn.reach.data.local.SyncState.SYNCED, myId)
                } else throw Exception("Server rejected backup batch")

            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                messageDao.updateSyncState(messageIds, com.rhyn.reach.data.local.SyncState.UNSYNCED, myId)
            }
        }
    }

    fun disconnect() {
        activeWebSocketSession?.cancel()
        activeWebSocketSession = null
    }
}