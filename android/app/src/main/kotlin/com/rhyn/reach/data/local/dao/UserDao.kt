package com.rhyn.reach.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.rhyn.reach.data.local.LocalUserEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface UserDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUser(user: LocalUserEntity)

    // A live stream of all contacts known for the current user
    @Query("SELECT * FROM local_users WHERE ownerId = :ownerId")
    fun getAllUsers(ownerId: String): Flow<List<LocalUserEntity>>

    @Query("SELECT * FROM local_users WHERE isGroup = 0 AND ownerId = :ownerId")
    fun getOnlyRealUsers(ownerId: String): Flow<List<LocalUserEntity>>

    @Query("SELECT * FROM local_users WHERE userId = :userId AND ownerId = :ownerId LIMIT 1")
    suspend fun getUserById(userId: String, ownerId: String): LocalUserEntity?

    @Query("UPDATE local_users SET publicKey = :publicKey WHERE userId = :userId AND ownerId = :ownerId")
    suspend fun updatePublicKey(userId: String, publicKey: String, ownerId: String)

    // ---> NEW: The Dual-Key Updater
    @Query("UPDATE local_users SET publicKey = :rsaKey, signingPublicKey = :ed25519Key WHERE userId = :userId AND ownerId = :ownerId")
    suspend fun updatePublicKeys(userId: String, rsaKey: String, ed25519Key: String, ownerId: String)

    @Query("UPDATE local_users SET isBackupEnabled = :isEnabled WHERE userId = :userId AND ownerId = :ownerId")
    suspend fun updateBackupPreference(userId: String, isEnabled: Boolean, ownerId: String)

    // --- Offline-to-Cloud Migration Queries ---

    @Query("UPDATE local_users SET userId = :newId WHERE userId = :oldId AND ownerId = :ownerId")
    suspend fun updateUserId(oldId: String, newId: String, ownerId: String)

    // Shifts the actual ownership of the user records once the cloud assigns the permanent user_id
    @Query("UPDATE local_users SET ownerId = :newId WHERE ownerId = :oldId")
    suspend fun updateUserOwnerId(oldId: String, newId: String)

    // Optional: Keep this to build a "Clear App Data" or "Hard Logout" button
    @Query("DELETE FROM local_users")
    suspend fun clearAllUsers()
}