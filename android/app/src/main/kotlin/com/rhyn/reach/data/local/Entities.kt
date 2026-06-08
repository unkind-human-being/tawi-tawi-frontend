package com.rhyn.reach.data.local

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

// --- ENUMS ---

enum class MessageType { TEXT, IMAGE, FILE }

enum class DeliveryState {
    PENDING, LAN_DELIVERED, MESH_ROUTED, CLOUD_DELIVERED, READ, FAILED
}

enum class SyncStatus {
    WAITING_FOR_PEER,
    SYNCED_TO_CLOUD
}

// 🆕 NEW: Enum specifically for tracking cloud backups of your messages
enum class SyncState {
    UNSYNCED, // Created offline, not backed up yet
    SYNCING,  // Currently uploading to cloud
    SYNCED    // Safely backed up
}

// --- TABLES ---

@Entity(
    tableName = "local_messages",
    primaryKeys = ["messageId", "ownerId"]
)
data class LocalMessageEntity(
    val messageId: String,
    val ownerId: String,
    val threadId: String,
    val senderId: String,
    val plaintextContent: String, // Acts as caption for media
    val attachmentUri: String? = null, // Local file path or content URI
    val messageType: MessageType = MessageType.TEXT,
    val isFromMe: Boolean,
    val timestamp: Long,
    val deliveryState: DeliveryState,
    val syncState: SyncState = SyncState.UNSYNCED
)

@Entity(
    tableName = "local_users",
    primaryKeys = ["userId", "ownerId"]
)
data class LocalUserEntity(
    val userId: String,
    val ownerId: String, // NEW
    val username: String,
    val isGroup: Boolean = false,
    val publicKey: String? = null,
    val isBackupEnabled: Boolean = true,
    val signingPublicKey: String? = null
)

@Entity(
    tableName = "device_registry",
    indices = [Index(value = ["userId", "deviceId"], unique = true)]
)
data class DeviceRegistryEntity(
    @PrimaryKey val deviceId: String,
    val userId: String,
    val publicKey: String,
    val lastKeyRotation: Long
)

@Entity(
    tableName = "mesh_relay_queue",
    indices = [Index(value = ["targetDeviceId"])]
)
data class MeshRelayQueueEntity(
    @PrimaryKey val payloadId: String,
    val originMessageId: String,
    val senderId: String,
    val targetDeviceId: String,
    val encryptedBlob: String,
    val timestamp: Long,
    val timeToLive: Long,
    val isFromMe: Boolean,
    val syncStatus: SyncStatus,
    val path: String = ""
)


