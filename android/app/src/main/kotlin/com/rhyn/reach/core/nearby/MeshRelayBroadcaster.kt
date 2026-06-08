package com.rhyn.reach.core.nearby

import android.util.Log
import com.rhyn.reach.data.local.dao.MeshRelayDao
import com.rhyn.reach.data.local.MeshRelayQueueEntity
import com.rhyn.reach.data.local.SyncStatus
import com.rhyn.reach.data.remote.model.MeshEnvelope
import com.rhyn.reach.presentation.feature.nearby.NearbyManager
import kotlinx.coroutines.launch
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton
import java.util.concurrent.ConcurrentHashMap

@Singleton
class MeshRelayBroadcaster @Inject constructor(
    private val nearbyManager: javax.inject.Provider<NearbyManager>,
    private val lanManager: javax.inject.Provider<com.rhyn.reach.presentation.feature.nearby.LanManager>,
    private val meshRelayDao: MeshRelayDao
) {
    private val tag = "MeshRelayBroadcaster"
    private val jsonParser = Json { ignoreUnknownKeys = true }

    // ---> THE FIX: Ultra-fast memory cache to stop Reconnect Storms
    private val seenPacketCache = ConcurrentHashMap<String, Long>()

    init {
        // ---> THE FIX: Pre-load cache from DB so it survives radio crashes and restarts
        kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.IO).launch {
            try {
                val existingQueue = meshRelayDao.getAllPendingPayloads()
                existingQueue.forEach {
                    seenPacketCache[it.payloadId] = it.timestamp
                }
                Log.d(tag, "Memory cache initialized with ${existingQueue.size} past relays.")
            } catch (e: Exception) {
                Log.e(tag, "Failed to load cache", e)
            }
        }
    }

    suspend fun processIncomingRelay(envelope: MeshEnvelope, myId: String, senderEndpointId: String) {
        val newTtl = envelope.ttl - 1
        if (newTtl <= 0) return

        // ---> THE FIX: Instant In-Memory Deduplication. Bypasses the slow SQLite check.
        if (seenPacketCache.containsKey(envelope.messageId) || envelope.pathHistory.contains(myId)) {
            Log.d(tag, "Relay payload dropped by fast cache. Echo loop prevented.")
            return
        }

        seenPacketCache[envelope.messageId] = System.currentTimeMillis()

        // Keep cache memory managed to prevent leaks
        if (seenPacketCache.size > 1000) {
            val oldest = seenPacketCache.entries.minByOrNull { it.value }?.key
            oldest?.let { seenPacketCache.remove(it) }
        }

        val newPathHistory = envelope.pathHistory + myId
        val relayEntity = MeshRelayQueueEntity(
            payloadId = envelope.messageId,
            originMessageId = envelope.messageId,
            senderId = envelope.senderId,
            targetDeviceId = envelope.targetId,
            encryptedBlob = envelope.encryptedPayload,
            timestamp = System.currentTimeMillis(),
            timeToLive = newTtl.toLong(),
            isFromMe = false,
            syncStatus = SyncStatus.WAITING_FOR_PEER,
            path = newPathHistory.joinToString(",")
        )
        meshRelayDao.insertRelayPayloads(listOf(relayEntity))

        val forwardedEnvelope = envelope.copy(ttl = newTtl, pathHistory = newPathHistory)
        val forwardJson = jsonParser.encodeToString(forwardedEnvelope)

        if (envelope.sourceRoute.isNotEmpty()) {
            val myIndex = envelope.sourceRoute.indexOf(myId)

            if (myIndex != -1) {
                val nextHopNodeId = if (myIndex + 1 < envelope.sourceRoute.size) {
                    envelope.sourceRoute[myIndex + 1]
                } else {
                    envelope.targetId
                }

                Log.d(tag, "Source Route exact match. Attempting direct push to $nextHopNodeId")

                val nextHopEndpoint = nearbyManager.get().getActiveEndpointId(nextHopNodeId)
                if (nextHopEndpoint != null) {
                    val success = try {
                        nearbyManager.get().sendMessage(nextHopEndpoint, forwardJson)
                        true
                    } catch (e: Exception) {
                        false
                    }
                    if (success) return
                }

                Log.w(tag, "Source Route direct push failed. Falling back to Epidemic Flooding!")
            } else {
                Log.w(tag, "Packet has a source route but this node is not in it! Dropping.")
                return
            }
        }

        // SMART LAN INTERCEPT
        val targetIp = lanManager.get().getActiveIpAddress(envelope.targetId)
        if (targetIp != null) {
            Log.d(tag, "Smart Path Intercept: Target is on local LAN. Delivering directly.")
            kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.IO).launch {
                lanManager.get().sendMessage(targetIp, forwardJson)
            }
            return
        }

        // Epidemic Flooding Fallback
        Log.d(tag, "Broadcasting epidemically to all connected neighbors.")
        val epidemicEnvelope = forwardedEnvelope.copy(sourceRoute = emptyList())
        val epidemicJson = jsonParser.encodeToString(epidemicEnvelope)

        nearbyManager.get().broadcastToAllNeighborsExcept(epidemicJson, senderEndpointId)

        kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.IO).launch {
            lanManager.get().broadcastToAllNeighbors(epidemicJson)
        }
    }
}