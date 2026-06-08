package com.rhyn.reach.data.remote

import android.util.Log
import com.rhyn.reach.data.remote.model.*
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.client.request.forms.*
import io.ktor.http.*
import io.ktor.client.plugins.websocket.*
import io.ktor.client.statement.HttpResponse
import javax.inject.Inject
import javax.inject.Singleton
import io.ktor.client.statement.bodyAsText
import io.ktor.http.isSuccess
import java.io.File
import kotlinx.serialization.Serializable
import com.rhyn.reach.data.remote.model.GoogleBackupRequest

@Serializable
data class MediaUploadResponse(val file_url: String)

@Singleton
class ApiService @Inject constructor(
    private val client: HttpClient
) {
    private val BASE_URL = "https://reach-backend-zlf2.onrender.com"
    private val WS_BASE_URL = "wss://reach-backend-zlf2.onrender.com"
    private val API_KEY = "sk-v1-2751ad5e202169cbcd2646896a6ec32fde017d3d11128d106a325e0150e013e54d713c6bb5840589cd195f1497666effc59793bb1f40e5bec5c1b09d91254991"

    suspend fun registerUser(request: UserCreateRequest): UserResponse {
        val response = client.post("$BASE_URL/api/auth/register") {
            header("X-API-KEY", API_KEY)
            contentType(ContentType.Application.Json)
            setBody(request)
        }

        if (response.status.isSuccess()) {
            return response.body()
        } else {
            val errorText = response.bodyAsText()
            throw Exception("Registration Failed (${response.status.value}): $errorText")
        }
    }

    suspend fun loginUser(request: UserLoginRequest): LoginResponse {
        val response = client.post("$BASE_URL/api/auth/login") {
            header("X-API-KEY", API_KEY)
            contentType(ContentType.Application.Json)
            setBody(request)
        }

        if (response.status.isSuccess()) {
            return response.body()
        } else {
            val errorText = response.bodyAsText()
            throw Exception("Login Failed (${response.status.value}): $errorText")
        }
    }

    suspend fun connectToMeshPipe(token: String): DefaultClientWebSocketSession {
        return client.webSocketSession {
            url("$WS_BASE_URL/api/mesh/ws/$token")
            header("X-API-KEY", API_KEY)
        }
    }

    suspend fun lookupUser(username: String): UserResponse {
        val response = client.get("$BASE_URL/api/auth/user/$username") {
            header("X-API-KEY", API_KEY)
        }

        if (response.status.isSuccess()) {
            return response.body()
        } else {
            throw Exception("User '$username' not found")
        }
    }

    suspend fun createGroup(request: GroupCreateRequest, token: String): GroupResponse {
        val response = client.post("$BASE_URL/api/groups/create") {
            header("X-API-KEY", API_KEY)
            header("Authorization", "Bearer $token")
            contentType(ContentType.Application.Json)
            setBody(request)
        }

        if (response.status.isSuccess()) {
            return response.body()
        } else {
            val errorText = response.bodyAsText()
            throw Exception("Failed to create group (${response.status.value}): $errorText")
        }
    }

    suspend fun updateFcmToken(token: String, fcmToken: String) {
        val response = client.post("$BASE_URL/api/auth/fcm-token") {
            header("X-API-KEY", API_KEY)
            header("Authorization", "Bearer $token")
            contentType(ContentType.Application.Json)
            setBody(FCMTokenRequest(fcmToken))
        }
        if (!response.status.isSuccess()) {
            Log.e("ReachApp", "Failed to update FCM token on backend")
        }
    }

    suspend fun getPublicKey(targetUserId: String, token: String): PublicKeyResponse {
        val response = client.get("$BASE_URL/api/auth/public-key/$targetUserId") {
            header("Authorization", "Bearer $token")
        }

        if (response.status.isSuccess()) {
            return response.body()
        } else {
            val errorText = response.bodyAsText()
            throw Exception("Failed to fetch public key (${response.status.value}): $errorText")
        }
    }

    suspend fun backupMessagesBatch(token: String, payloads: List<BackupMessageDto>): HttpResponse {
        return client.post("$BASE_URL/api/mesh/backup") {
            header("X-API-KEY", API_KEY)
            header("Authorization", "Bearer $token")
            contentType(ContentType.Application.Json)
            setBody(payloads)
        }
    }

    suspend fun deleteThreadBackups(threadId: String, token: String): HttpResponse {
        return client.delete("$BASE_URL/api/mesh/backup/$threadId") {
            header("X-API-KEY", API_KEY)
            header("Authorization", "Bearer $token")
        }
    }

    suspend fun syncInbox(token: String): HttpResponse {
        return client.get("$BASE_URL/api/mesh/sync-inbox") {
            header("X-API-KEY", API_KEY)
            header("Authorization", "Bearer $token")
        }
    }

    suspend fun restoreMessageHistory(token: String): HttpResponse {
        return client.get("$BASE_URL/api/mesh/restore-history") {
            header("X-API-KEY", API_KEY)
            header("Authorization", "Bearer $token")
        }
    }

    // THE FIX: Overriding the headers manually to bypass the Ktor disposition bug
    suspend fun uploadMedia(file: File, token: String): MediaUploadResponse {
        val response = client.post("$BASE_URL/api/media/upload") {
            header("X-API-KEY", API_KEY)
            header("Authorization", "Bearer $token")
            setBody(
                MultiPartFormDataContent(
                    formData {
                        append("file", file.readBytes(), Headers.build {
                            append(HttpHeaders.ContentType, "application/octet-stream")
                            // Using set() instead of append() explicitly blocks the comma bug
                            set(HttpHeaders.ContentDisposition, "form-data; name=\"file\"; filename=\"${file.name}\"")
                        })
                    }
                )
            )
        }

        if (response.status.isSuccess()) {
            return response.body()
        } else {
            val errorText = response.bodyAsText()
            throw Exception("Failed to upload media (${response.status.value}): $errorText")
        }
    }

    suspend fun backupIdentity(request: GoogleBackupRequest) {
        val response = client.post("$BASE_URL/api/auth/backup-identity") {
            header("X-API-KEY", API_KEY)
            contentType(ContentType.Application.Json)
            setBody(request)
        }

        if (!response.status.isSuccess()) {
            val errorText = response.bodyAsText()
            throw Exception("Backup Failed (${response.status.value}): $errorText")
        }
    }

    suspend fun authenticateWithGoogle(request: GoogleAuthRequest): GoogleAuthResponse {
        val response = client.post("$BASE_URL/api/auth/google") {
            header("X-API-KEY", API_KEY)
            contentType(ContentType.Application.Json)
            setBody(request)
        }

        if (response.status.isSuccess()) {
            return response.body()
        } else {
            val errorText = response.bodyAsText()
            throw Exception("Google Auth Failed (${response.status.value}): $errorText")
        }
    }
}