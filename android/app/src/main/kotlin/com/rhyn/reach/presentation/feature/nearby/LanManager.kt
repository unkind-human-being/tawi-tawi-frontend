package com.rhyn.reach.presentation.feature.nearby

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.util.Log

import io.ktor.client.HttpClient
import io.ktor.client.request.*
import io.ktor.client.request.forms.*
import io.ktor.http.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class LanManager @Inject constructor(
    private val context: Context,
    val lanServer: LanServer,
    private val httpClient: HttpClient
) {
    private val nsdManager = context.getSystemService(Context.NSD_SERVICE) as NsdManager
    private val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    private val SERVICE_TYPE = "_reach._tcp."
    private val SERVER_PORT = 8080

    data class LanPeer(val ipAddress: String, val stableUserId: String, val username: String)

    private val _discoveredLanPeers = MutableStateFlow<Map<String, LanPeer>>(emptyMap())
    val discoveredLanPeers = _discoveredLanPeers.asStateFlow()

    private var registrationListener: NsdManager.RegistrationListener? = null
    private var discoveryListener: NsdManager.DiscoveryListener? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null
    private var nsdRestartJob: kotlinx.coroutines.Job? = null

    fun startAdvertising(userId: String, username: String) {
        val serviceInfo = NsdServiceInfo().apply {
            serviceName = "$userId|$username"
            serviceType = SERVICE_TYPE
            port = SERVER_PORT
        }

        registrationListener = object : NsdManager.RegistrationListener {
            override fun onServiceRegistered(NsdServiceInfo: NsdServiceInfo) {
                Log.d("ReachLAN", "Successfully advertising on LAN as: ${NsdServiceInfo.serviceName}")
            }
            override fun onRegistrationFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                Log.e("ReachLAN", "LAN Advertising failed: Error $errorCode")
            }
            override fun onServiceUnregistered(arg0: NsdServiceInfo) {}
            override fun onUnregistrationFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {}
        }

        nsdManager.registerService(serviceInfo, NsdManager.PROTOCOL_DNS_SD, registrationListener)
    }

    fun startDiscovery(myUserId: String) {
        discoveryListener = object : NsdManager.DiscoveryListener {
            override fun onDiscoveryStarted(regType: String) {
                Log.d("ReachLAN", "LAN Discovery started")
            }

            override fun onServiceFound(service: NsdServiceInfo) {
                if (service.serviceType == SERVICE_TYPE) {
                    // Filter out own device broadcast
                    if (service.serviceName.contains(myUserId)) {
                        Log.d("ReachLAN", "Ignored own LAN echo: ${service.serviceName}")
                        return
                    }

                    // Found another device. Resolve its IP address
                    nsdManager.resolveService(service, object : NsdManager.ResolveListener {
                        override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                            Log.e("ReachLAN", "Failed to resolve IP: Error $errorCode")
                        }

                        override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
                            val ipAddress = serviceInfo.host.hostAddress ?: return
                            val parts = serviceInfo.serviceName.split("|", limit = 2)
                            val stableId = if (parts.size == 2) parts[0] else "Unknown"
                            val name = if (parts.size == 2) parts[1] else serviceInfo.serviceName

                            Log.d("ReachLAN", "Resolved $name at IP: $ipAddress")

                            val currentPeers = _discoveredLanPeers.value.toMutableMap()
                            currentPeers[stableId] = LanPeer(ipAddress, stableId, name)
                            _discoveredLanPeers.value = currentPeers
                        }
                    })
                }
            }

            override fun onServiceLost(service: NsdServiceInfo) {
                val parts = service.serviceName.split("|", limit = 2)
                val stableId = if (parts.size == 2) parts[0] else return

                val currentPeers = _discoveredLanPeers.value.toMutableMap()
                currentPeers.remove(stableId)
                _discoveredLanPeers.value = currentPeers
            }

            override fun onDiscoveryStopped(serviceType: String) {}

            override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                Log.e("ReachLAN", "Start Discovery failed with error code: $errorCode")
            }

            override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
                Log.e("ReachLAN", "Stop Discovery failed with error code: $errorCode")
            }
        }

        nsdManager.discoverServices(SERVICE_TYPE, NsdManager.PROTOCOL_DNS_SD, discoveryListener)
    }

    fun getActiveIpAddress(userId: String): String? {
        return _discoveredLanPeers.value[userId]?.ipAddress
    }

    private fun evictPeerByIp(ipAddress: String) {
        val currentPeers = _discoveredLanPeers.value.toMutableMap()
        val keysToRemove = currentPeers.filterValues { it.ipAddress == ipAddress }.keys
        if (keysToRemove.isNotEmpty()) {
            keysToRemove.forEach { currentPeers.remove(it) }
            _discoveredLanPeers.value = currentPeers
            Log.d("ReachLAN", "Evicted stale LAN peer at $ipAddress")
        }
    }

    suspend fun sendMessage(ipAddress: String, messagePayload: String): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                val url = "http://$ipAddress:${lanServer.SERVER_PORT}/lan/message"
                val response = withTimeoutOrNull(2000) {
                    httpClient.post(url) {
                        contentType(ContentType.Application.Json)
                        setBody(messagePayload)
                    }
                }

                if (response?.status?.isSuccess() == true) {
                    Log.d("ReachLAN", "Successfully POSTed message to $ipAddress")
                    true
                } else {
                    Log.w("ReachLAN", "LAN message rejected or timed out by $ipAddress")
                    false
                }
            } catch (e: Exception) {
                Log.e("ReachLAN", "Failed to send LAN message to $ipAddress (Firewall/NAT block)", e)
                false
            }
        }
    }

    suspend fun broadcastToAllNeighbors(messagePayload: String) {
        val peers = _discoveredLanPeers.value.values
        if (peers.isEmpty()) return

        withContext(Dispatchers.IO) {
            peers.forEach { peer ->
                launch {
                    sendMessage(peer.ipAddress, messagePayload)
                }
            }
        }
    }

    suspend fun sendFile(ipAddress: String, metadataJson: String, file: File): Boolean {
        return withContext(Dispatchers.IO) {
            try {
                val url = "http://$ipAddress:${lanServer.SERVER_PORT}/lan/file"
                val response = withTimeoutOrNull(15000) {
                    httpClient.post(url) {
                        setBody(
                            MultiPartFormDataContent(
                                formData {
                                    append("metadata", metadataJson)
                                    append("file", file.readBytes(), Headers.build {
                                        append(HttpHeaders.ContentDisposition, "filename=\"${file.name}\"")
                                    })
                                }
                            )
                        )
                    }
                }

                if (response?.status?.isSuccess() == true) {
                    Log.d("ReachLAN", "Successfully POSTed file to $ipAddress")
                    true
                } else {
                    Log.w("ReachLAN", "LAN file transfer rejected or timed out by $ipAddress")
                    false
                }
            } catch (e: Exception) {
                Log.e("ReachLAN", "Failed to send LAN file to $ipAddress", e)
                false
            }
        }
    }

    private fun startNsd(userId: String, username: String) {
        startAdvertising(userId, username)
        startDiscovery(userId)
    }

    private fun stopNsd() {
        try {
            registrationListener?.let { nsdManager.unregisterService(it) }
        } catch (e: Exception) {
            Log.e("ReachLAN", "Error unregistering service", e)
        }
        try {
            discoveryListener?.let { nsdManager.stopServiceDiscovery(it) }
        } catch (e: Exception) {
            Log.e("ReachLAN", "Error stopping discovery", e)
        }
        registrationListener = null
        discoveryListener = null
        _discoveredLanPeers.value = emptyMap()
    }

    fun startAll(userId: String, username: String) {
        lanServer.startServer()
        startNsd(userId, username)

        if (networkCallback == null) {
            networkCallback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    Log.d("ReachLAN", "Wi-Fi Network available. Restarting NSD.")
                    nsdRestartJob?.cancel()
                    nsdRestartJob = CoroutineScope(Dispatchers.IO).launch {
                        stopNsd()
                        delay(3000) // 3s delay to let Android settle the routing table for the new interface
                        if (registrationListener == null && discoveryListener == null) {
                            startNsd(userId, username)
                        }
                    }
                }

                override fun onLost(network: Network) {
                    Log.d("ReachLAN", "Wi-Fi Network lost. Stopping NSD.")
                    nsdRestartJob?.cancel()
                    stopNsd()
                }
            }
            val request = NetworkRequest.Builder()
                .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                .build()
            connectivityManager.registerNetworkCallback(request, networkCallback!!)
        }
    }

    fun stopAll() {
        stopNsd()
        lanServer.stopServer()
        try {
            networkCallback?.let { connectivityManager.unregisterNetworkCallback(it) }
        } catch (e: Exception) {
            Log.e("ReachLAN", "Error unregistering network callback", e)
        }
        networkCallback = null
    }
}