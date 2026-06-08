package com.rhyn.reach.core.notifications

import android.content.SharedPreferences
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.rhyn.reach.core.crypto.CryptoManager
import com.rhyn.reach.data.local.DeliveryState
import com.rhyn.reach.data.local.LocalMessageEntity
import com.rhyn.reach.data.local.LocalUserEntity
import com.rhyn.reach.data.local.dao.MessageDao
import com.rhyn.reach.data.local.dao.UserDao

import kotlinx.coroutines.runBlocking
import java.util.UUID
import javax.inject.Inject

class MessagingService : FirebaseMessagingService() {

    @Inject
    lateinit var cryptoManager: CryptoManager

    @Inject
    lateinit var prefs: SharedPreferences

    @Inject
    lateinit var userDao: UserDao

    @Inject
    lateinit var messageDao: MessageDao

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        Log.d("ReachApp", "New Firebase Token generated: $token")
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        val data = remoteMessage.data
        Log.d("ReachApp", "FCM PAYLOAD RECEIVED: $data")

        val encryptedBody = data["encrypted_data"]
        val hasRealEncryptedData = encryptedBody != null
        val threadId = data["thread_id"] ?: return
        val senderId = data["sender_id"]
        val targetId = data["target_id"]

        val myId = prefs.getString("user_id", null)

        if (myId == null) {
            Log.d("ReachApp", "Ignored push notification: No user is currently logged in.")
            return
        }

        // --- THE FIX: Cross-Account Bleed Prevention ---
        // If the message's intended target doesn't match the currently logged-in user, drop it.
        // This handles cases where Firebase sends a push intended for a previously logged-in account.
        if (targetId != null && targetId != myId && senderId != myId) {
            Log.w("ReachApp", "Cross-account bleed prevented: Received FCM for user $targetId, but active user is $myId. Dropping payload.")
            return
        }

        if (senderId != null && senderId == myId) {
            Log.d("ReachApp", "Ignored push notification for local user's own message.")
            return
        }

        // 2. Decrypt the message securely
        var isDecryptionFailed = false
        val decryptedText = try {
            if (hasRealEncryptedData && encryptedBody!!.isNotEmpty()) {
                val myPrivateKey = prefs.getString("my_private_key", "") ?: ""
                cryptoManager.decryptMessage(encryptedBody, myPrivateKey)
            } else {
                // FCM payload lacks encrypted_data (backend sent a fallback notification).
                // Don't save garbage to the DB — pullMissedMessages will fetch the real content on reconnect.
                Log.d("ReachApp", "FCM payload lacks encrypted_data. Will sync real message on reconnect.")
                isDecryptionFailed = true
                "You have a new message"
            }
        } catch (e: Exception) {
            Log.e("ReachApp", "Background decryption crashed", e)
            isDecryptionFailed = true
            "You have a new message"
        }

        runBlocking {
            try {
                val localUser = userDao.getUserById(threadId, myId)

                val rawTitle = data["sender_username"] ?: data["title"] ?: "New Message"
                val finalTitle = localUser?.username ?: rawTitle

                Log.d("ReachApp", "Showing notification for: $finalTitle")

                // Insert the message directly into the local database
                // This ensures the UI updates immediately even if the WebSocket is asleep.
                if (senderId != null && !isDecryptionFailed) {

                    // Ensure the sender exists in our contacts list so the Inbox displays their name
                    if (localUser == null && userDao.getUserById(senderId, myId) == null) {
                        userDao.insertUser(
                            LocalUserEntity(
                                userId = senderId,
                                ownerId = myId,
                                username = rawTitle,
                                isGroup = false,
                                publicKey = ""
                            )
                        )
                    }

                    // Map the correct thread ID for direct vs group chats
                    val resolvedThreadId = if (targetId == myId) senderId else (targetId ?: threadId)

                    // Fallback to a generated UUID if the backend didn't supply a message_id in the push payload
                    val messageId = data["message_id"] ?: UUID.randomUUID().toString()
                    val timestamp = data["timestamp"]?.toLongOrNull() ?: System.currentTimeMillis()

                    val messageEntity = LocalMessageEntity(
                        messageId = messageId,
                        ownerId = myId,
                        threadId = resolvedThreadId,
                        senderId = senderId,
                        plaintextContent = decryptedText,
                        isFromMe = false,
                        timestamp = timestamp,
                        deliveryState = DeliveryState.CLOUD_DELIVERED
                    )

                    // Note: insertMessage uses OnConflictStrategy.IGNORE.
                    // If the WebSocket wakes up later and pulls this exact message via syncInbox, it won't duplicate.
                    messageDao.insertMessage(messageEntity)
                }

                NotificationHelper.showNotification(
                    context = applicationContext,
                    title = finalTitle,
                    message = decryptedText,
                    threadId = threadId
                )
            } catch (e: Exception) {
                Log.e("ReachApp", "Failed to process and save push notification", e)
            }
        }
    }
}