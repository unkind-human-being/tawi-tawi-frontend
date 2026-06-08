package com.rhyn.reach.data.repository

import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.firebase.messaging.FirebaseMessaging
import com.rhyn.reach.core.crypto.CryptoManager
import com.rhyn.reach.core.nearby.MeshService
import com.rhyn.reach.core.notifications.NotificationHelper
import com.rhyn.reach.core.utils.FileHelper
import com.rhyn.reach.data.local.DeliveryState
import com.rhyn.reach.data.local.LocalMessageEntity
import com.rhyn.reach.data.local.LocalUserEntity
import com.rhyn.reach.data.local.MessageType
import com.rhyn.reach.data.local.dao.MessageDao
import com.rhyn.reach.data.local.dao.UserDao
import com.rhyn.reach.data.local.prefs.SessionManager
import com.rhyn.reach.data.remote.ApiService
import com.rhyn.reach.data.remote.model.GroupCreateRequest
import com.rhyn.reach.data.remote.model.GroupResponse
import com.rhyn.reach.data.remote.model.UserCreateRequest
import com.rhyn.reach.data.remote.model.UserLoginRequest
import com.rhyn.reach.data.remote.model.UserResponse
import com.rhyn.reach.data.repository.cloud.CloudSyncManager
import com.rhyn.reach.data.repository.routing.MessageRouter
import com.rhyn.reach.domain.repository.ChatRepository

import io.ktor.http.isSuccess
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import java.util.UUID
import javax.inject.Inject
import com.rhyn.reach.data.local.dao.MeshRelayDao
import com.rhyn.reach.data.remote.model.GoogleAuthRequest
import kotlinx.serialization.json.Json
import com.rhyn.reach.data.remote.model.MeshEnvelope
import java.io.FileOutputStream
import com.rhyn.reach.data.remote.model.GoogleBackupRequest

class ChatRepositoryImpl @Inject constructor(
    private val context: Context,
    private val apiService: ApiService,
    private val cryptoManager: CryptoManager,
    private val messageDao: MessageDao,
    private val userDao: UserDao,
    private val meshRelayDao: MeshRelayDao,
    private val sessionManager: SessionManager,
    private val messageRouter: MessageRouter,
    private val fileHelper: FileHelper,
    private val cloudSyncManager: CloudSyncManager,
    private val meshRelayBroadcasterLazy: javax.inject.Provider<com.rhyn.reach.core.nearby.MeshRelayBroadcaster>
) : ChatRepository {

    private val tag = "ChatRepositoryImpl"
    override var currentActiveThreadId: String? = null

    override fun getMessages(threadId: String): Flow<List<LocalMessageEntity>> {
        val ownerId = sessionManager.getUserId() ?: ""
        return messageDao.getMessagesForThread(threadId, ownerId)
    }

    override fun getRecentThreads(): Flow<List<LocalMessageEntity>> {
        val ownerId = sessionManager.getUserId() ?: ""
        return messageDao.getRecentThreads(ownerId)
    }

    override fun getAllUsers(): Flow<List<LocalUserEntity>> {
        val ownerId = sessionManager.getUserId() ?: ""
        return userDao.getAllUsers(ownerId)
    }

    override fun getOnlyRealUsers(): Flow<List<LocalUserEntity>> {
        val ownerId = sessionManager.getUserId() ?: ""
        return userDao.getOnlyRealUsers(ownerId)
    }

    override fun isUserLoggedIn(): Boolean = sessionManager.getUserId() != null || sessionManager.getJwtToken() != null
    override fun getCurrentUsername(): String? = sessionManager.getUsername()
    override fun getCurrentUserId(): String? = sessionManager.getUserId()

    override suspend fun connectAndListenToCloud() {
        cloudSyncManager.startCloudSync { currentActiveThreadId }
    }

    override suspend fun syncOfflineMessagesToCloud() {
        cloudSyncManager.syncOfflineMessagesToCloud()
    }

    override suspend fun flushPendingMessages(targetUserId: String) {
        messageRouter.routeAllPendingMessages(cloudSyncManager.activeWebSocketSession)
    }

    override suspend fun registerCurrentDevice(username: String, password: String, pin: String): Result<Unit> {
        return try {
            val newUserId = UUID.randomUUID().toString()

            // 1. Generate BOTH keys
            val (pubKey, rawPrivKey) = cryptoManager.generateNewKeyPair()
            val (edPubKey, edPrivKey) = cryptoManager.generateEd25519KeyPair()

            val lockedPrivKey = cryptoManager.encryptPrivateKeyWithPin(rawPrivKey, pin)

            // 2. Save the Ed25519 signing keys locally using the unified methods
            sessionManager.saveSigningPublicKey(edPubKey)
            sessionManager.saveSigningPrivateKey(edPrivKey)

            // 3. Upload BOTH public keys to the server
            apiService.registerUser(UserCreateRequest(newUserId, username, password, pubKey, edPubKey, lockedPrivKey))
            login(username, password, pin)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun login(username: String, password: String, pin: String): Result<Unit> {
        return try {
            val response = apiService.loginUser(UserLoginRequest(username, password))
            val lockedPrivKey = response.private_key
            val unlockResult = cryptoManager.decryptPrivateKeyWithPin(lockedPrivKey, pin)

            if (unlockResult.isSuccess) {
                val rawPrivKey = unlockResult.getOrThrow()

                // Save cloud tokens using the unified individual setters
                sessionManager.saveToken(response.access_token)
                sessionManager.saveUserId(response.user_id)
                sessionManager.saveUsername(username)
                sessionManager.savePrivateKey(rawPrivKey)
                sessionManager.savePublicKey(response.public_key)
                sessionManager.setCloudSynced(true)

                // Ensure the device has a valid signing key pair upon login
                var signingPubKey = sessionManager.getSigningPublicKey()
                if (signingPubKey == null) {
                    val (newEdPub, newEdPriv) = cryptoManager.generateEd25519KeyPair()
                    sessionManager.saveSigningPublicKey(newEdPub)
                    sessionManager.saveSigningPrivateKey(newEdPriv)
                    signingPubKey = newEdPub
                }

                userDao.insertUser(
                    LocalUserEntity(
                        userId = response.user_id,
                        ownerId = response.user_id,
                        username = username,
                        isGroup = false,
                        publicKey = response.public_key,
                        signingPublicKey = signingPubKey
                    )
                )

                kotlinx.coroutines.CoroutineScope(Dispatchers.IO).launch {
                    cloudSyncManager.restoreAccountHistory()
                }

                Result.success(Unit)
            } else {
                Result.failure(Exception("Incorrect PIN. Cannot unlock account history."))
            }
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun createLocalAccount(username: String, password: String, pin: String): Result<Unit> {
        return try {
            val newUserId = UUID.randomUUID().toString()

            // 1. Generate BOTH Key Pairs
            val (rsaPublicKey, rsaPrivateKey) = cryptoManager.generateNewKeyPair()
            val (edPublicKey, edPrivateKey) = cryptoManager.generateEd25519KeyPair()

            // 2. Save to Session
            sessionManager.saveLocalOfflineIdentity(newUserId, username, password, rsaPublicKey, rsaPrivateKey)
            sessionManager.saveSigningPublicKey(edPublicKey)
            sessionManager.saveSigningPrivateKey(edPrivateKey)

            // 3. Save to Database
            val userEntity = LocalUserEntity(
                userId = newUserId,
                ownerId = newUserId,
                username = username,
                isGroup = false,
                publicKey = rsaPublicKey,
                signingPublicKey = edPublicKey
            )
            userDao.insertUser(userEntity)

            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // --- SEND IMAGE METHOD ---
    override suspend fun sendImageMessage(targetId: String, uriString: String) {
        withContext(Dispatchers.IO) {
            try {
                val currentUserId = sessionManager.getUserId() ?: run {
                    Log.e(tag, "Cannot send image. User is not logged in.")
                    return@withContext
                }

                val targetUser = userDao.getUserById(targetId, currentUserId)

                if (targetUser == null || targetUser.publicKey.isNullOrBlank()) {
                    Log.e(tag, "Cannot send image. Target user or public key is missing for ID: $targetId")
                    return@withContext
                }

                val messageId = UUID.randomUUID().toString()

                val realFileName = fileHelper.getFileName(uriString)
                val permanentUriString = fileHelper.copyUriToInternalStorage(uriString, realFileName) ?: uriString

                val inputStream = fileHelper.getInputStreamFromUri(permanentUriString) ?: throw Exception("Could not read source file")
                
                // Aggressive Compression for Images
                val bitmap = android.graphics.BitmapFactory.decodeStream(inputStream)
                val compressedTempFile = java.io.File(context.cacheDir, "${UUID.randomUUID()}_compressed.jpg")
                val compressedOutputStream = java.io.FileOutputStream(compressedTempFile)
                bitmap.compress(android.graphics.Bitmap.CompressFormat.JPEG, 60, compressedOutputStream)
                compressedOutputStream.close()
                inputStream.close()
                
                val compressedInputStream = java.io.FileInputStream(compressedTempFile)

                val encryptedTempFile = fileHelper.createTempEncryptedFile()
                val outputStream = FileOutputStream(encryptedTempFile)

                cryptoManager.encryptStream(compressedInputStream, outputStream, targetUser.publicKey)
                compressedTempFile.delete()

                val localMessage = LocalMessageEntity(
                    messageId = messageId,
                    ownerId = currentUserId,
                    threadId = targetId,
                    senderId = currentUserId,
                    plaintextContent = "",
                    attachmentUri = permanentUriString,
                    messageType = MessageType.IMAGE,
                    isFromMe = true,
                    timestamp = System.currentTimeMillis(),
                    deliveryState = DeliveryState.PENDING,
                    syncState = com.rhyn.reach.data.local.SyncState.UNSYNCED
                )
                messageDao.insertMessage(localMessage)

                messageRouter.routeEncryptedFile(
                    messageId = messageId,
                    targetId = targetId,
                    encryptedFile = encryptedTempFile,
                    fileType = "IMAGE",
                    webSocketSession = cloudSyncManager.activeWebSocketSession
                )

            } catch (e: Exception) {
                Log.e(tag, "Failed to process and send image message", e)
            }
        }
    }

    // --- SEND GENERIC FILE METHOD ---
    override suspend fun sendFileMessage(targetId: String, uriString: String) {
        withContext(Dispatchers.IO) {
            try {
                val currentUserId = sessionManager.getUserId() ?: return@withContext
                val targetUser = userDao.getUserById(targetId, currentUserId)

                if (targetUser == null || targetUser.publicKey.isNullOrBlank()) return@withContext

                val messageId = UUID.randomUUID().toString()

                val realFileName = fileHelper.getFileName(uriString)
                val ext = realFileName.substringAfterLast('.', "").lowercase()
                val allowedExtensions = listOf("pdf", "doc", "docx", "ppt", "pptx")
                
                if (!allowedExtensions.contains(ext)) {
                    Log.w(tag, "Document not allowed. Extension: $ext")
                    return@withContext
                }

                val permanentUriString = fileHelper.copyUriToInternalStorage(uriString, realFileName) ?: uriString

                val inputStream = fileHelper.getInputStreamFromUri(permanentUriString) ?: throw Exception("Could not read file")
                val encryptedTempFile = fileHelper.createTempEncryptedFile()
                val outputStream = FileOutputStream(encryptedTempFile)

                cryptoManager.encryptStream(inputStream, outputStream, targetUser.publicKey)

                val localMessage = LocalMessageEntity(
                    messageId = messageId,
                    ownerId = currentUserId,
                    threadId = targetId,
                    senderId = currentUserId,
                    plaintextContent = realFileName,
                    attachmentUri = permanentUriString,
                    messageType = MessageType.FILE,
                    isFromMe = true,
                    timestamp = System.currentTimeMillis(),
                    deliveryState = DeliveryState.PENDING,
                    syncState = com.rhyn.reach.data.local.SyncState.UNSYNCED
                )
                messageDao.insertMessage(localMessage)

                messageRouter.routeEncryptedFile(
                    messageId = messageId,
                    targetId = targetId,
                    encryptedFile = encryptedTempFile,
                    fileType = "FILE",
                    webSocketSession = cloudSyncManager.activeWebSocketSession
                )

            } catch (e: Exception) {
                Log.e(tag, "Failed to process and send file message", e)
            }
        }
    }

    // --- DELETE MESSAGE LOCALLY ---
    override suspend fun deleteMessageLocally(messageId: String) {
        withContext(Dispatchers.IO) {
            try {
                val myId = sessionManager.getUserId() ?: return@withContext
                messageDao.deleteMessageById(messageId, myId)
                Log.d(tag, "Successfully deleted message: $messageId locally.")
            } catch (e: Exception) {
                Log.e(tag, "Failed to delete message: $messageId", e)
            }
        }
    }

    override suspend fun logout() {
        try {
            FirebaseMessaging.getInstance().deleteToken().await()
        } catch (e: Exception) {
            Log.e(tag, "Failed to clear FCM token on logout", e)
        }

        // ---> THE ZOMBIE FIX: Formally stop the Mesh Service <---
        try {
            val stopIntent = Intent(context, MeshService::class.java).apply {
                action = MeshService.ACTION_STOP
            }
            context.startService(stopIntent)
        } catch (e: Exception) {
            Log.e(tag, "Failed to stop MeshService during logout", e)
        }

        // Now safely clear the data and active connections
        sessionManager.logout()
        cloudSyncManager.disconnect()
        currentActiveThreadId = null
    }

    override suspend fun sendMessage(targetUserId: String, text: String): Result<Unit> {
        return withContext(Dispatchers.IO) {
            try {
                val myId = sessionManager.getUserId() ?: return@withContext Result.failure(Exception("Not logged in"))

                val localMessage = LocalMessageEntity(
                    messageId = UUID.randomUUID().toString(),
                    ownerId = myId,
                    threadId = targetUserId,
                    senderId = myId,
                    plaintextContent = text,
                    isFromMe = true,
                    timestamp = System.currentTimeMillis(),
                    deliveryState = DeliveryState.PENDING
                )
                messageDao.insertMessage(localMessage)
                flushPendingMessages(targetUserId)
                Result.success(Unit)
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    override suspend fun createGroup(groupName: String, memberIds: List<String>): Result<GroupResponse> {
        return try {
            val token = sessionManager.getJwtToken() ?: throw Exception("User is not logged in")
            val myId = sessionManager.getUserId() ?: throw Exception("User ID not found")

            val response = apiService.createGroup(GroupCreateRequest(groupName, memberIds, null), token)

            userDao.insertUser(LocalUserEntity(userId = response.group_id, ownerId = myId, username = response.group_name, isGroup = true))
            sendMessage(response.group_id, "Created the group '${response.group_name}'")

            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun lookupUser(username: String): Result<UserResponse> {
        return try {
            val myId = sessionManager.getUserId() ?: throw Exception("User ID not found")
            val response = apiService.lookupUser(username)

            userDao.insertUser(LocalUserEntity(userId = response.user_id, ownerId = myId, username = response.username, publicKey = response.public_key))
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    override suspend fun syncUserPublicKey(userId: String) {
        try {
            val token = sessionManager.getJwtToken() ?: return
            val myId = sessionManager.getUserId() ?: return

            val keyResponse = apiService.getPublicKey(userId, token)
            userDao.updatePublicKey(userId, keyResponse.public_key, myId)
        } catch (e: Exception) {
            Log.w(tag, "Could not sync public key (User might be offline)")
        }
    }

    override suspend fun toggleCloudBackup(targetUserId: String, enableBackup: Boolean) {
        withContext(Dispatchers.IO) {
            val myId = sessionManager.getUserId() ?: return@withContext

            userDao.updateBackupPreference(targetUserId, enableBackup, myId)

            if (!enableBackup) {
                try {
                    val token = sessionManager.getJwtToken() ?: return@withContext
                    val response = apiService.deleteThreadBackups(targetUserId, token)
                    if (response.status.isSuccess()) {
                        messageDao.resetSyncStateForThread(targetUserId, com.rhyn.reach.data.local.SyncState.UNSYNCED, myId)
                    }
                } catch (e: Exception) {
                    Log.e("ReachPrivacy", "Failed to purge backups", e)
                }
            }
        }
    }

    override suspend fun processIncomingMeshPayload(payloadJson: String) {
        withContext(Dispatchers.IO) {
            try {
                val envelope = Json.decodeFromString<MeshEnvelope>(payloadJson)
                val myId = sessionManager.getUserId() ?: return@withContext

                if (envelope.targetId == myId) {
                    val rawPrivateKey = sessionManager.getPrivateKey() ?: return@withContext
                    val decryptedText = cryptoManager.decryptMessage(envelope.encryptedPayload, rawPrivateKey)

                    val localMessage = LocalMessageEntity(
                        messageId = envelope.messageId,
                        ownerId = myId,
                        threadId = envelope.senderId,
                        senderId = envelope.senderId,
                        plaintextContent = decryptedText,
                        isFromMe = false,
                        timestamp = System.currentTimeMillis(),
                        deliveryState = if (currentActiveThreadId == envelope.senderId) DeliveryState.READ else DeliveryState.LAN_DELIVERED
                    )

                    // Extract name from envelope or fallback
                    val senderNameFromEnvelope = envelope.senderUsername
                    var finalSenderName = senderNameFromEnvelope ?: "Unknown (Mesh)"
                    val existingUser = userDao.getUserById(envelope.senderId, myId)

                    if (existingUser == null) {
                        userDao.insertUser(LocalUserEntity(
                            userId = envelope.senderId,
                            ownerId = myId,
                            username = finalSenderName,
                            isGroup = false,
                            publicKey = "",
                            signingPublicKey = null
                        ))
                    } else if (existingUser.username.startsWith("Unknown") && senderNameFromEnvelope != null) {
                        // Automatically heal "Unknown" identity if a real name is provided
                        userDao.insertUser(existingUser.copy(username = senderNameFromEnvelope))
                        finalSenderName = senderNameFromEnvelope
                    } else {
                        finalSenderName = existingUser.username
                    }

                    messageDao.insertMessage(localMessage)
                    Log.d(tag, "Received and decrypted offline message: ${envelope.messageId} from $finalSenderName")

                    if (currentActiveThreadId != envelope.senderId) {
                        NotificationHelper.showNotification(
                            context = context,
                            title = finalSenderName,
                            message = decryptedText,
                            threadId = envelope.senderId
                        )
                    }
                } else {
                    // RELAY INTERCEPTION BLOCK
                    // Log the routing event using structured tags for logcat filtering
                    Log.i("MeshRouting", "RELAY_EVENT: Packet intercepted.")
                    Log.i("MeshRouting", "  -> Packet ID: ${envelope.messageId}")
                    Log.i("MeshRouting", "  -> Source: ${envelope.senderId}")
                    Log.i("MeshRouting", "  -> Target: ${envelope.targetId}")
                    Log.i("MeshRouting", "  -> Action: Pushing to MeshRelayBroadcaster")
                    
                    meshRelayBroadcasterLazy.get().processIncomingRelay(envelope, myId, "LAN_ENDPOINT")
                }
            } catch (e: Exception) {
                Log.e(tag, "Failed to process incoming mesh payload", e)
            }
        }
    }

    override fun getTotalUnreadCount(): Flow<Int> {
        val ownerId = sessionManager.getUserId() ?: ""
        if (ownerId.isEmpty()) return kotlinx.coroutines.flow.flowOf(0)
        return messageDao.getTotalUnreadCount(ownerId)
    }

    override suspend fun markThreadAsRead(threadId: String) {
        val myId = sessionManager.getUserId() ?: return
        messageDao.markThreadAsRead(threadId, myId)
    }

    override suspend fun backupIdentityToCloud(idToken: String, pin: String): Result<Unit> {
        return try {
            // 1. Retrieve the local cryptographic keys from your session manager
            val publicKey = sessionManager.getPublicKey()
                ?: throw Exception("Public key missing from local session")
            val rawPrivateKey = sessionManager.getPrivateKey()
                ?: throw Exception("Private key missing from local session")

            // 2. SECURITY REQUIREMENT: Encrypt the private key with the user's PIN before transmission
            // FIX: Use the correct method name 'encryptPrivateKeyWithPin' from CryptoManager
            val encryptedPrivateKey = cryptoManager.encryptPrivateKeyWithPin(rawPrivateKey, pin)

            // 3. Construct the API request payload
            val backupRequest = GoogleBackupRequest(
                id_token = idToken,
                public_key = publicKey,
                encrypted_private_key = encryptedPrivateKey
            )

            // 4. Send to the FastAPI backend
            apiService.backupIdentity(backupRequest)

            // 5. Mark the session as backed up locally
            sessionManager.setCloudSynced(true)

            Log.i("ChatRepositoryImpl", "Identity successfully backed up to cloud.")
            Result.success(Unit)

        } catch (e: Exception) {
            Log.e("ChatRepositoryImpl", "Failed to backup identity to cloud", e)
            Result.failure(e)
        }
    }


    // Update the interface and implementation signature:
    override suspend fun authenticateWithGoogle(idToken: String, pin: String): Result<Unit> {
        return try {
            var publicKey = sessionManager.getPublicKey()
            var signPublicKey = sessionManager.getSigningPublicKey()
            var rawPrivateKey = sessionManager.getPrivateKey()

            // 1. Generate keys if the device doesn't have them
            if (publicKey.isNullOrBlank() || signPublicKey.isNullOrBlank() || rawPrivateKey.isNullOrBlank()) {
                val (rsaPub, rsaPriv) = cryptoManager.generateNewKeyPair()
                val (edPub, edPriv) = cryptoManager.generateEd25519KeyPair()

                publicKey = rsaPub
                signPublicKey = edPub
                rawPrivateKey = rsaPriv

                // Save locally
                sessionManager.savePublicKey(rsaPub)
                sessionManager.savePrivateKey(rsaPriv)
                sessionManager.saveSigningPublicKey(edPub)
                sessionManager.saveSigningPrivateKey(edPriv)
            }

            // 2. LOCK the private key using the user's PIN before it leaves the device
            val encryptedPrivateKeyForCloud = cryptoManager.encryptPrivateKeyWithPin(rawPrivateKey!!, pin)

            // 3. Send to Backend
            val request = GoogleAuthRequest(
                id_token = idToken,
                public_key = publicKey,
                signing_public_key = signPublicKey,
                encrypted_private_key = encryptedPrivateKeyForCloud // Send the locked key!
            )
            val response = apiService.authenticateWithGoogle(request)

            // 4. Save Identity
            sessionManager.saveToken(response.access_token)
            sessionManager.saveUserId(response.user_id)
            sessionManager.saveUsername(response.username)

            if (response.public_key.isNotBlank()) sessionManager.savePublicKey(response.public_key)
            if (response.signing_public_key.isNotBlank()) sessionManager.saveSigningPublicKey(response.signing_public_key)

            // 5. DECRYPT the cloud key if the user already existed
            if (response.is_backed_up && response.private_key.isNotBlank()) {
                val unlockResult = cryptoManager.decryptPrivateKeyWithPin(response.private_key, pin)
                if (unlockResult.isSuccess) {
                    sessionManager.savePrivateKey(unlockResult.getOrThrow())
                    sessionManager.setCloudSynced(true)
                } else {
                    throw Exception("Incorrect PIN. Cannot unlock E2EE keys.")
                }
            } else {
                sessionManager.setCloudSynced(true) // New user was backed up automatically
            }

            Result.success(Unit)
        } catch(e: Exception) {
            Result.failure(e)
        }
    }
}