package com.rhyn.reach.data.local


import androidx.room.TypeConverter

class Converters {
    @TypeConverter
    fun fromDeliveryState(value: DeliveryState): String = value.name

    @TypeConverter
    fun toDeliveryState(value: String): DeliveryState = enumValueOf(value)

    @TypeConverter
    fun fromSyncStatus(value: SyncStatus): String = value.name

    @TypeConverter
    fun toSyncStatus(value: String): SyncStatus = enumValueOf(value)

    // Added the missing SyncState converters
    @TypeConverter
    fun fromSyncState(value: SyncState): String = value.name

    @TypeConverter
    fun toSyncState(value: String): SyncState = enumValueOf(value)
}