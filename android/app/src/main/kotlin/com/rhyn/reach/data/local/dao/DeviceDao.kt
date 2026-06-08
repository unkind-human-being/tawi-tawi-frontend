package com.rhyn.reach.data.local.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.rhyn.reach.data.local.DeviceRegistryEntity

@Dao
interface DeviceDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOrUpdateDevice(device: DeviceRegistryEntity)

    @Query("SELECT * FROM device_registry WHERE userId = :userId")
    suspend fun getAllDevicesForUser(userId: String): List<DeviceRegistryEntity>
}