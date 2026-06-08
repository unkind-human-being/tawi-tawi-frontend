package com.rhyn.reach.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.rhyn.reach.data.local.MeshEdgeEntity

@Dao
interface MeshEdgeDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEdges(edges: List<MeshEdgeEntity>)

    @Query("SELECT * FROM mesh_edges")
    suspend fun getAllActiveEdges(): List<MeshEdgeEntity>

    @Query("DELETE FROM mesh_edges WHERE lastSeenTimestamp < :cutoffTime")
    suspend fun deleteStaleEdges(cutoffTime: Long)
    
    @Query("DELETE FROM mesh_edges")
    suspend fun clearAllEdges()
}
