package com.rhyn.reach.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.rhyn.reach.data.local.MeshRelayQueueEntity

@Dao
interface MeshRelayDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRelayPayloads(payloads: List<MeshRelayQueueEntity>)

    @Query("SELECT * FROM mesh_relay_queue WHERE syncStatus = 'WAITING_FOR_PEER'")
    suspend fun getAllPendingPayloads(): List<MeshRelayQueueEntity>

    @Query("DELETE FROM mesh_relay_queue WHERE payloadId = :id")
    suspend fun deleteRelayPayload(id: String)
}