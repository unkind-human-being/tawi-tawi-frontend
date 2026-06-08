package com.rhyn.reach.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.rhyn.reach.data.local.DeliveryState
import com.rhyn.reach.data.local.LocalMessageEntity
import com.rhyn.reach.data.local.SyncState
import kotlinx.coroutines.flow.Flow

@Dao
interface MessageDao {
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertMessage(message: LocalMessageEntity)

    @Query("SELECT * FROM local_messages WHERE threadId = :threadId AND ownerId = :ownerId ORDER BY timestamp ASC")
    fun getMessagesForThread(threadId: String, ownerId: String): Flow<List<LocalMessageEntity>>

    @Query("UPDATE local_messages SET deliveryState = :newState WHERE messageId = :messageId AND ownerId = :ownerId")
    suspend fun updateDeliveryState(messageId: String, newState: DeliveryState, ownerId: String)

    @Query("""
        SELECT * FROM local_messages a 
        WHERE ownerId = :ownerId AND timestamp = (
            SELECT MAX(timestamp) FROM local_messages b 
            WHERE b.threadId = a.threadId AND b.ownerId = :ownerId
        ) 
        ORDER BY timestamp DESC
    """)
    fun getRecentThreads(ownerId: String): Flow<List<LocalMessageEntity>>

    @Query("SELECT * FROM local_messages WHERE threadId = :targetUserId AND deliveryState = 'PENDING' AND ownerId = :ownerId")
    suspend fun getPendingMessagesForUser(targetUserId: String, ownerId: String): List<LocalMessageEntity>

    @Query("""
        SELECT m.* FROM local_messages m
        INNER JOIN local_users u ON m.threadId = u.userId AND m.ownerId = u.ownerId
        WHERE m.syncState = 'UNSYNCED' AND u.isBackupEnabled = 1 AND m.ownerId = :ownerId
    """)
    suspend fun getMessagesAllowedForBackup(ownerId: String): List<LocalMessageEntity>

    @Query("UPDATE local_messages SET syncState = :state WHERE messageId IN (:messageIds) AND ownerId = :ownerId")
    suspend fun updateSyncState(messageIds: List<String>, state: SyncState, ownerId: String)

    @Query("UPDATE local_messages SET syncState = :state WHERE threadId = :threadId AND ownerId = :ownerId")
    suspend fun resetSyncStateForThread(threadId: String, state: SyncState, ownerId: String)

    // --- Offline-to-Cloud Migration Queries ---

    @Query("UPDATE local_messages SET senderId = :newId WHERE senderId = :oldId AND ownerId = :ownerId")
    suspend fun updateSenderId(oldId: String, newId: String, ownerId: String)

    @Query("UPDATE local_messages SET threadId = :newId WHERE threadId = :oldId AND ownerId = :ownerId")
    suspend fun updateThreadId(oldId: String, newId: String, ownerId: String)

    // Shifts the actual ownership of the messages once the cloud assigns the permanent user_id
    @Query("UPDATE local_messages SET ownerId = :newId WHERE ownerId = :oldId")
    suspend fun updateMessageOwnerId(oldId: String, newId: String)

    // Optional: Keep this if you ever want to build a "Clear App Data" or "Hard Logout" button
    @Query("DELETE FROM local_messages")
    suspend fun clearAllMessages()

    @Query("SELECT DISTINCT threadId FROM local_messages WHERE deliveryState = 'PENDING' AND ownerId = :ownerId")
    suspend fun getPendingTargetUsers(ownerId: String): List<String>

    // ---> NEW: Get total unread message count <---
    @Query("SELECT COUNT(*) FROM local_messages WHERE isFromMe = 0 AND deliveryState != 'READ' AND ownerId = :ownerId")
    fun getTotalUnreadCount(ownerId: String): Flow<Int>

    @Query("UPDATE local_messages SET deliveryState = 'READ' WHERE threadId = :threadId AND isFromMe = 0 AND ownerId = :ownerId")
    suspend fun markThreadAsRead(threadId: String, ownerId: String)

    @Query("DELETE FROM local_messages WHERE messageId = :messageId AND ownerId = :ownerId")
    suspend fun deleteMessageById(messageId: String, ownerId: String)
}