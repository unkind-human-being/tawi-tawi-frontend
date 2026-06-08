package com.rhyn.reach.data.remote.model

import kotlinx.serialization.Serializable

@Serializable
data class UserCreateRequest(
    val user_id: String,
    val username: String,
    val password: String,
    val public_key: String,
    val signing_public_key: String,
    val private_key: String
)

@Serializable
data class UserLoginRequest(
    val username: String,
    val password: String,
    val public_key: String? = null
)

@Serializable
data class LoginResponse(
    val access_token: String,
    val token_type: String,
    val user_id: String,
    val public_key: String,
    val private_key: String
)

@Serializable
data class UserResponse(
    val user_id: String,
    val username: String,
    val public_key: String,
    val is_online: Boolean
)

@Serializable
data class CloudMessageResponse(
    val message_id: String,
    val sender_id: String,
    val target_id: String,
    val target_payload: String,
    val self_payload: String,
    val sender_username: String? = "Unknown",
    val digital_signature: String? = null,
    val timestamp: Long = System.currentTimeMillis()
)

@Serializable
data class GroupCreateRequest(
    val group_name: String,
    val member_ids: List<String>,
    val group_avatar_url: String? = null
)

@Serializable
data class GroupResponse(
    val group_id: String,
    val group_name: String,
    val group_avatar_url: String? = null,
    val members: List<String>,
    val created_by: String,
    val created_at: Double
)

@Serializable
data class FCMTokenRequest(
    val fcm_token: String
)

@Serializable
data class OutgoingCloudMessage(
    val message_id: String,
    val sender_id: String,
    val sender_username: String?,
    val target_id: String,
    val target_payload: String,
    val self_payload: String,
    val digital_signature: String
)

@Serializable
data class PublicKeyResponse(
    val user_id: String,
    val public_key: String,
    val signing_public_key: String? = null
)

@Serializable
data class BackupMessageDto(
    val message_id: String,
    val thread_id: String,
    val sender_id: String,
    val target_payload: String,
    val self_payload: String,
    val timestamp: Long
)

@Serializable
data class SyncInboxResponse(
    val status: String,
    val messages: List<CloudMessageResponse>
)

@Serializable
data class MeshEnvelope(
    val messageId: String,
    val senderId: String,
    val targetId: String,
    val encryptedPayload: String,
    val payloadType: String = "TEXT",
    val ttl: Int,
    val path: List<String> = emptyList(),
    val sourceRoute: List<String> = emptyList(),
    val pathHistory: List<String> = emptyList(),
    val signature: String? = null,
    val senderUsername: String? = null
)

// --- NEW GOOGLE AUTH MODELS ---

@Serializable
data class GoogleBackupRequest(
    val id_token: String,
    val public_key: String,
    val encrypted_private_key: String
)

@Serializable
data class GoogleAuthRequest(
    val id_token: String,
    val public_key: String? = null,
    val signing_public_key: String? = null,
    val encrypted_private_key: String? = null
)

@Serializable
data class GoogleAuthResponse(
    val access_token: String,
    val token_type: String,
    val user_id: String,
    val username: String,
    val public_key: String,
    val private_key: String,
    val is_backed_up: Boolean,
    val is_new_user: Boolean,
    val signing_public_key: String,
)