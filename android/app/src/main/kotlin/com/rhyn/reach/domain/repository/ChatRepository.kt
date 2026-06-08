package com.rhyn.reach.domain.repository

import com.rhyn.reach.data.local.LocalMessageEntity
import com.rhyn.reach.data.local.LocalUserEntity
import com.rhyn.reach.data.remote.model.UserResponse
import com.rhyn.reach.data.remote.model.GroupResponse
import kotlinx.coroutines.flow.Flow

interface ChatRepository {
    var currentActiveThreadId: String?

    // For the UI to observe messages
    fun getMessages(threadId: String): Flow<List<LocalMessageEntity>>

    // The core routing logic
    suspend fun sendMessage(
        targetUserId: String,
        text: String
    ): Result<Unit>

    suspend fun sendImageMessage(
        targetId: String,
        uriString: String
    )

    suspend fun sendFileMessage(
        targetId: String,
        uriString: String
    )

    // --- AUTHENTICATION & KEY MANAGEMENT ---
    suspend fun registerCurrentDevice(username: String, password: String, pin: String): Result<Unit>
    suspend fun login(username: String, password: String, pin: String): Result<Unit>
    suspend fun createLocalAccount(username: String, password: String, pin: String): Result<Unit>

    // NEW: Replaces syncAccountToCloud. Takes the Google Auth token and the 6-digit PIN.
    suspend fun backupIdentityToCloud(idToken: String, pin: String): Result<Unit>

    suspend fun logout()

    // --- CLOUD & SYNC ---
    suspend fun connectAndListenToCloud()
    suspend fun flushPendingMessages(targetUserId: String)
    suspend fun syncOfflineMessagesToCloud()
    suspend fun toggleCloudBackup(targetUserId: String, enableBackup: Boolean)

    // --- USER & GROUP LOOKUP ---
    suspend fun lookupUser(username: String): Result<UserResponse>
    suspend fun createGroup(groupName: String, memberIds: List<String>): Result<GroupResponse>
    suspend fun syncUserPublicKey(userId: String)

    // --- LOCAL DATA QUERIES ---
    fun getRecentThreads(): Flow<List<LocalMessageEntity>>
    fun isUserLoggedIn(): Boolean
    fun getAllUsers(): Flow<List<LocalUserEntity>>
    fun getOnlyRealUsers(): Flow<List<LocalUserEntity>>
    fun getCurrentUserId(): String?
    fun getCurrentUsername(): String?

    suspend fun processIncomingMeshPayload(payloadJson: String)

    fun getTotalUnreadCount(): Flow<Int>

    suspend fun markThreadAsRead(threadId: String)

    suspend fun deleteMessageLocally(messageId: String)
    suspend fun authenticateWithGoogle(idToken: String, pin: String): Result<Unit>
}