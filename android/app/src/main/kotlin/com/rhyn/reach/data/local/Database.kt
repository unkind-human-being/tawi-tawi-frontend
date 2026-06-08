package com.rhyn.reach.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.rhyn.reach.data.local.dao.DeviceDao
import com.rhyn.reach.data.local.dao.MeshEdgeDao
import com.rhyn.reach.data.local.dao.MeshRelayDao
import com.rhyn.reach.data.local.dao.MessageDao
import com.rhyn.reach.data.local.dao.UserDao

@Database(
    entities = [
        DeviceRegistryEntity::class, 
        LocalMessageEntity::class, 
        MeshRelayQueueEntity::class,
        LocalUserEntity::class,
        MeshEdgeEntity::class
    ],
    version = 3,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class Database : RoomDatabase() {
    abstract fun deviceDao(): DeviceDao
    abstract fun messageDao(): MessageDao
    abstract fun meshRelayDao(): MeshRelayDao
    abstract fun userDao(): UserDao
    abstract fun meshEdgeDao(): MeshEdgeDao
}