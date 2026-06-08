import 'dart:convert';
import 'package:dio/dio.dart';

import '../../../core/database/local_db.dart';
import '../../../core/network/api_client.dart';

class SyncService {
  // This flag prevents the engine from running multiple syncs at the exact same time
  static bool _isSyncing = false;

  /// Attempts to push all offline data (Queued actions + Metrics) to the FastAPI backend
  static Future<void> syncOfflineData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final db = LocalDatabase.instance;
      
      // ==========================================
      // 1. SYNC GENERAL QUEUED ACTIONS
      // ==========================================
      final pendingItems = await db.getPendingSyncs();

      if (pendingItems.isNotEmpty) {
        print("Found ${pendingItems.length} items in the offline queue. Starting sync...");

        // Loop through the waiting room (SQLite table)
        for (var item in pendingItems) {
          final id = item['id'] as int;
          final endpoint = item['endpoint'] as String;
          final payload = jsonDecode(item['payload'] as String);

          try {
            // Push the saved data to your Python FastAPI server
            final response = await ApiClient.instance.post(endpoint, data: payload);

            if (response.statusCode == 200 || response.statusCode == 201) {
              // Success! The server received it. 
              await db.deleteQueuedItem(id);
              print("Successfully synced item $id to $endpoint");
            }
          } on DioException catch (e) {
            // NEW LOGIC: Differentiate between "No Internet" and "Bad Code/URL"
            if (e.response != null) {
              final int statusCode = e.response!.statusCode ?? 0;
              
              // If the server says the URL doesn't exist (404) or the data is formatted wrong (422),
              // it will NEVER work. Delete it so we don't get stuck in an infinite loop!
              if (statusCode == 404 || statusCode == 422 || statusCode == 500) {
                print("Permanent error (Status $statusCode) for item $id to $endpoint. Deleting from queue.");
                await db.deleteQueuedItem(id);
              } else {
                print("Temporary server error (Status $statusCode). Will retry item $id later.");
              }
            } else {
              // If response is null, it usually means the phone has absolutely no internet connection.
              print("No network connection. Will retry item $id later.");
            }
          }
        }
      } else {
        print("No general offline actions to sync.");
      }

      // ==========================================
      // 2. SYNC DRIVER & COMMUTER METRICS
      // ==========================================
      await _syncMetricsToCloud(db);

    } catch (e) {
      print("Sync Engine Error: $e");
    } finally {
      _isSyncing = false;
      print("Sync process finished.");
    }
  }

  /// Internal helper to sync distances and trip counts
  static Future<void> _syncMetricsToCloud(LocalDatabase db) async {
    try {
      print("Checking for unsynced metrics...");
      
      // Sync Commuter Distances
      final unsyncedCommuters = await db.getUnsyncedCommuterMetrics();
      for (var row in unsyncedCommuters) {
        await ApiClient.instance.post('/commuters/sync-distance', data: {
          "commuter_id": row['id'],
          "total_distance_km": row['total_distance_km'],
          "timestamp": row['last_calculated_at']
        });
        await db.markCommuterAsSynced(row['id']);
        print("Synced distance for commuter ${row['id']}");
      }

      // Sync Driver Trip Counts
      final unsyncedDrivers = await db.getUnsyncedDriverMetrics();
      for (var row in unsyncedDrivers) {
        await ApiClient.instance.post('/drivers/sync-trips', data: {
          "franchise_number": row['franchise_number'],
          "total_trips": row['total_trips'],
          "timestamp": row['last_trip_at']
        });
        await db.markDriverAsSynced(row['id']);
        print("Synced trips for driver ${row['franchise_number']}");
      }
      
    } on DioException catch (e) {
      print("Sync metrics payload submission paused: ${e.message}");
    } catch (e) {
      print("Error syncing metrics: $e");
    }
  }
}