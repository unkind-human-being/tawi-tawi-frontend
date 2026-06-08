package com.rhyn.reach.data.local

import androidx.room.Entity

@Entity(tableName = "mesh_edges", primaryKeys = ["nodeA", "nodeB"])
data class MeshEdgeEntity(
    val nodeA: String,
    val nodeB: String,
    val lastSeenTimestamp: Long
)
