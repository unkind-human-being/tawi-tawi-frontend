package com.rhyn.reach.presentation.feature.nearby

import android.content.Context
import android.util.Log

import io.ktor.http.HttpStatusCode
import io.ktor.http.content.PartData
import io.ktor.http.content.forEachPart
import io.ktor.http.content.streamProvider
import io.ktor.server.application.*
import io.ktor.server.cio.*
import io.ktor.server.engine.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.CoroutineExceptionHandler
import java.io.File
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class LanServer @Inject constructor(
    // FIX: Renamed from 'context' to 'appContext' to avoid Ktor shadowing
    private val appContext: Context
) {
    private var server: ApplicationEngine? = null
    private var isStarting = false
    val SERVER_PORT = 8080

    var onMessageReceived: ((String) -> Unit)? = null
    var onFileReceived: ((String, File) -> Unit)? = null

    fun startServer() {
        if (server != null || isStarting) return
        isStarting = true

        val handler = CoroutineExceptionHandler { _, exception ->
            Log.e("ReachLanServer", "Ktor server async exception", exception)
            isStarting = false
            server = null
        }

        CoroutineScope(Dispatchers.IO + handler).launch {
            try {
                if (!isPortAvailable(SERVER_PORT)) {
                    Log.e("ReachLanServer", "Port $SERVER_PORT is not available. Cannot start server.")
                    isStarting = false
                    return@launch
                }

                server = embeddedServer(CIO, port = SERVER_PORT) {
                    routing {
                        post("/lan/message") {
                            val payload = call.receiveText()
                            Log.d("ReachLanServer", "Received LAN payload: $payload")

                            onMessageReceived?.invoke(payload)

                            call.respondText("OK")
                        }

                        post("/lan/file") {
                            var metadataJson = ""
                            var tempFile: File? = null

                            try {
                                val multipart = call.receiveMultipart()

                                multipart.forEachPart { part ->
                                    when (part) {
                                        is PartData.FormItem -> {
                                            if (part.name == "metadata") {
                                                metadataJson = part.value
                                            }
                                        }
                                        is PartData.FileItem -> {
                                            if (part.name == "file") {
                                                val fileBytes = part.streamProvider().readBytes()

                                                // FIX: Using appContext explicitly here
                                                val cacheDir = File(appContext.cacheDir, "reach_lan_incoming").apply { mkdirs() }
                                                tempFile = File(cacheDir, "${UUID.randomUUID()}_incoming.bin")
                                                tempFile.writeBytes(fileBytes)
                                            }
                                        }
                                        else -> {}
                                    }
                                    part.dispose()
                                }

                                if (metadataJson.isNotEmpty() && tempFile != null) {
                                    Log.d("ReachLanServer", "Received LAN File transfer. Handing to processor.")
                                    onFileReceived?.invoke(metadataJson, tempFile)
                                    call.respondText("OK")
                                } else {
                                    tempFile?.delete()
                                    call.respondText("Bad Request: Missing metadata or file", status = HttpStatusCode.BadRequest)
                                }
                            } catch (e: Exception) {
                                Log.e("ReachLanServer", "Error processing LAN file upload", e)
                                tempFile?.delete()
                                call.respondText("Internal Error", status = HttpStatusCode.InternalServerError)
                            }
                        }
                    }
                }.start(wait = false)
                Log.d("ReachLanServer", "Embedded Ktor Server started on port $SERVER_PORT")
            } catch (e: Exception) {
                Log.e("ReachLanServer", "Failed to start LAN server (Port might be in use)", e)
            } finally {
                isStarting = false
            }
        }
    }

    fun stopServer() {
        try {
            server?.stop(1000, 2000)
        } catch (e: Exception) {
            Log.e("ReachLanServer", "Error stopping server", e)
        } finally {
            server = null
            isStarting = false
            Log.d("ReachLanServer", "Embedded Ktor Server stopped")
        }
    }

    private fun isPortAvailable(port: Int): Boolean {
        var serverSocket: java.net.ServerSocket? = null
        return try {
            serverSocket = java.net.ServerSocket(port)
            serverSocket.reuseAddress = true
            true
        } catch (e: Exception) {
            false
        } finally {
            serverSocket?.close()
        }
    }
}