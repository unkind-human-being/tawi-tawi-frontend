package com.example.tawi_tawi_frontend

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.room.Room
import com.rhyn.reach.core.crypto.CryptoManager
import com.rhyn.reach.core.nearby.MeshRelayBroadcaster
import com.rhyn.reach.core.utils.FileHelper
import com.rhyn.reach.data.local.prefs.SessionManager
import com.rhyn.reach.data.remote.ApiService
import com.rhyn.reach.data.repository.ChatRepositoryImpl
import com.rhyn.reach.data.repository.cloud.CloudSyncManager
import com.rhyn.reach.data.repository.routing.MessageRouter
import com.rhyn.reach.data.repository.routing.RoutePlanner
import com.rhyn.reach.presentation.feature.nearby.LanManager
import com.rhyn.reach.presentation.feature.nearby.LanServer
import com.rhyn.reach.presentation.feature.nearby.NearbyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.ktor.client.HttpClient
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.websocket.WebSockets
import io.ktor.serialization.kotlinx.json.json
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import javax.inject.Provider

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // --- REQUEST RUNTIME PERMISSIONS FOR NEARBY CONNECTIONS ---
        val requiredPermissions = mutableListOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION
        )
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            requiredPermissions.add(Manifest.permission.BLUETOOTH_SCAN)
            requiredPermissions.add(Manifest.permission.BLUETOOTH_ADVERTISE)
            requiredPermissions.add(Manifest.permission.BLUETOOTH_CONNECT)
        }
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            requiredPermissions.add(Manifest.permission.NEARBY_WIFI_DEVICES)
            requiredPermissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }

        val missingPermissions = requiredPermissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (missingPermissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, missingPermissions.toTypedArray(), 100)
        }

        com.rhyn.reach.core.DependencyLocator.initialize(applicationContext)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Delegate channel setup to PlatformChannelHandler
        val channelHandler = com.example.tawi_tawi_frontend.channels.PlatformChannelHandler(this)
        channelHandler.setupChannels(flutterEngine)
    }
}
