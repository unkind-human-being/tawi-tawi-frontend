import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transport_platform.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // FIXED: Incremented version to 3 and added onUpgrade for safe database migration
    return await openDatabase(
      path, 
      version: 3, 
      onCreate: _createDB,
      onUpgrade: _upgradeDB, 
    );
  }

  // Runs ONLY when the app is installed for the very first time
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        endpoint TEXT NOT NULL, 
        payload TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS commuter_metrics (
        id TEXT PRIMARY KEY,
        total_distance_km REAL,
        last_calculated_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS driver_metrics (
        id TEXT PRIMARY KEY,
        franchise_number TEXT,
        total_trips INTEGER,
        last_trip_at TEXT,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        message TEXT,
        type TEXT,
        timestamp TEXT
      )
    ''');
  }

  // FIXED: Runs when the app detects an older version of the database on the phone
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // If the user is on version 1, add the missing tables safely
      await db.execute('''
        CREATE TABLE IF NOT EXISTS commuter_metrics (
          id TEXT PRIMARY KEY,
          total_distance_km REAL,
          last_calculated_at TEXT,
          is_synced INTEGER DEFAULT 0
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS driver_metrics (
          id TEXT PRIMARY KEY,
          franchise_number TEXT,
          total_trips INTEGER,
          last_trip_at TEXT,
          is_synced INTEGER DEFAULT 0
        )
      ''');
    }
    
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notifications (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          message TEXT,
          type TEXT,
          timestamp TEXT
        )
      ''');
    }
  }

  // --- CRUD OPERATIONS ---

  /// Saves an action to the local database when offline
  Future<int> queueOfflineAction(String endpoint, Map<String, dynamic> payload) async {
    final db = await instance.database;
    
    final data = {
      'endpoint': endpoint,
      'payload': jsonEncode(payload), 
      'timestamp': DateTime.now().toIso8601String(),
    };

    return await db.insert('sync_queue', data);
  }

  /// Retrieves all pending items to send to the FastAPI backend
  Future<List<Map<String, dynamic>>> getPendingSyncs() async {
    final db = await instance.database;
    return await db.query('sync_queue', orderBy: 'timestamp ASC');
  }

  /// Deletes an item from the queue after it successfully reaches the server
  Future<int> deleteQueuedItem(int id) async {
    final db = await instance.database;
    return await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================
  // METRICS: COMMUTER DISTANCE
  // ==========================================

  Future<List<Map<String, dynamic>>> getUnsyncedCommuterMetrics() async {
    final db = await instance.database;
    return await db.query(
      'commuter_metrics',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
  }

  Future<int> markCommuterAsSynced(String id) async {
    final db = await instance.database;
    return await db.update(
      'commuter_metrics',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // METRICS: DRIVER TRIPS
  // ==========================================

  Future<List<Map<String, dynamic>>> getUnsyncedDriverMetrics() async {
    final db = await instance.database;
    return await db.query(
      'driver_metrics',
      where: 'is_synced = ?',
      whereArgs: [0],
    );
  }

  Future<int> markDriverAsSynced(String id) async {
    final db = await instance.database;
    return await db.update(
      'driver_metrics',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  // ==========================================
  // SAVE NEW DATA FROM UI BUTTONS
  // ==========================================

  /// Called when a Driver completes a trip
  Future<void> recordCompletedTrip(String franchiseNumber) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    
    // UPSERT: If driver exists, increment trips. If not, create them.
    await db.execute('''
      INSERT INTO driver_metrics (id, franchise_number, total_trips, last_trip_at, is_synced)
      VALUES (?, ?, 1, ?, 0)
      ON CONFLICT(id) DO UPDATE SET 
        total_trips = total_trips + 1,
        last_trip_at = excluded.last_trip_at,
        is_synced = 0
    ''', [franchiseNumber, franchiseNumber, now]);
  }

  /// Called when a Commuter finishes a route
  Future<void> addCommuterDistance(String commuterId, double distanceKm) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();

    await db.execute('''
      INSERT INTO commuter_metrics (id, total_distance_km, last_calculated_at, is_synced)
      VALUES (?, ?, ?, 0)
      ON CONFLICT(id) DO UPDATE SET 
        total_distance_km = total_distance_km + excluded.total_distance_km,
        last_calculated_at = excluded.last_calculated_at,
        is_synced = 0
    ''', [commuterId, distanceKm, now]);
  }

  // ==========================================
  // NOTIFICATIONS CACHE
  // ==========================================

  Future<void> saveNotifications(List<dynamic> notifications) async {
    final db = await instance.database;
    final batch = db.batch();
    
    // Clear old cache to replace with new data
    batch.delete('notifications');
    
    final now = DateTime.now().toIso8601String();
    for (var notif in notifications) {
      batch.insert('notifications', {
        'title': notif['title'] ?? 'Alert',
        'message': notif['message'] ?? '',
        'type': notif['type'] ?? 'info',
        'timestamp': now,
      });
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedNotifications() async {
    final db = await instance.database;
    return await db.query('notifications', orderBy: 'id DESC');
  }
}