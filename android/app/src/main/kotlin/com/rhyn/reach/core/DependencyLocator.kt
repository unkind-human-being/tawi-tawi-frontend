package com.rhyn.reach.core

import android.content.Context
import androidx.room.Room
import com.rhyn.reach.core.crypto.CryptoManager
import com.rhyn.reach.core.nearby.MeshRelayBroadcaster
import com.rhyn.reach.core.utils.FileHelper
import com.rhyn.reach.data.local.dao.MessageDao
import com.rhyn.reach.data.local.dao.UserDao
import com.rhyn.reach.data.local.prefs.SessionManager
import com.rhyn.reach.data.remote.ApiService
import com.rhyn.reach.data.repository.ChatRepositoryImpl
import com.rhyn.reach.data.repository.cloud.CloudSyncManager
import com.rhyn.reach.data.repository.routing.MessageRouter
import com.rhyn.reach.data.repository.routing.RoutePlanner
import com.rhyn.reach.presentation.feature.nearby.LanManager
import com.rhyn.reach.presentation.feature.nearby.LanServer
import com.rhyn.reach.presentation.feature.nearby.NearbyManager
import io.ktor.client.HttpClient
import io.ktor.client.engine.cio.CIO
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.websocket.WebSockets
import io.ktor.serialization.kotlinx.json.json
import kotlinx.serialization.json.Json
import javax.inject.Provider

object DependencyLocator {
    var isInitialized = false

    lateinit var chatRepository: ChatRepositoryImpl
    lateinit var nearbyManager: NearbyManager
    lateinit var lanManager: LanManager
    lateinit var sessionManager: SessionManager
    lateinit var cryptoManager: CryptoManager
    lateinit var messageDao: MessageDao
    lateinit var userDao: UserDao
    lateinit var fileHelper: FileHelper

    @Synchronized
    fun initialize(context: Context) {
        if (isInitialized) return
        val appContext = context.applicationContext

        val db = Room.databaseBuilder(
            appContext,
            com.rhyn.reach.data.local.Database::class.java,
            "reach_db"
        ).fallbackToDestructiveMigration().build()

        cryptoManager = CryptoManager()
        sessionManager = SessionManager(appContext)
        fileHelper = FileHelper(appContext)
        messageDao = db.messageDao()
        userDao = db.userDao()

        val httpClient = HttpClient(CIO) {
            install(ContentNegotiation) {
                json(Json { ignoreUnknownKeys = true })
            }
            install(WebSockets)
        }
        
        val apiService = ApiService(httpClient)
        val routePlanner = RoutePlanner(db.meshEdgeDao())
        
        val lanServer = LanServer(appContext)
        lanManager = LanManager(appContext, lanServer, httpClient)

        var messageRouterInstance: MessageRouter? = null
        val messageRouterProvider = Provider { messageRouterInstance!! }

        var meshRelayBroadcasterInstance: MeshRelayBroadcaster? = null
        val meshRelayProvider = Provider { meshRelayBroadcasterInstance!! }

        nearbyManager = NearbyManager(
            appContext,
            db.messageDao(),
            db.userDao(),
            db.meshRelayDao(),
            db.meshEdgeDao(),
            sessionManager,
            cryptoManager,
            fileHelper,
            messageRouterProvider,
            meshRelayProvider
        )

        val nearbyProvider = Provider { nearbyManager }
        val lanProvider = Provider { lanManager }

        meshRelayBroadcasterInstance = MeshRelayBroadcaster(
            nearbyProvider,
            lanProvider,
            db.meshRelayDao()
        )

        messageRouterInstance = MessageRouter(
            db.messageDao(),
            db.userDao(),
            db.meshRelayDao(),
            nearbyManager,
            lanManager,
            cryptoManager,
            apiService,
            sessionManager,
            fileHelper,
            routePlanner
        )

        val cloudSyncManager = CloudSyncManager(
            apiService,
            cryptoManager,
            db.messageDao(),
            db.userDao(),
            sessionManager,
            messageRouterInstance,
            appContext
        )

        chatRepository = ChatRepositoryImpl(
            appContext,
            apiService,
            cryptoManager,
            db.messageDao(),
            db.userDao(),
            db.meshRelayDao(),
            sessionManager,
            messageRouterInstance,
            fileHelper,
            cloudSyncManager,
            meshRelayProvider
        )

        isInitialized = true
    }
}
