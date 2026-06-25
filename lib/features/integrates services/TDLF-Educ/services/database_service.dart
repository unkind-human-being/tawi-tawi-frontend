import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../config/app_config.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, AppConfig.databaseName);

    return openDatabase(
      path,
      version: AppConfig.databaseVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Users Table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        course TEXT DEFAULT '',
        full_name TEXT DEFAULT '',
        student_id TEXT DEFAULT '',
        grade_level TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        is_logged_in BOOLEAN DEFAULT 0
      )
    ''');

    // Books Table
    await db.execute('''
      CREATE TABLE books (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        link TEXT NOT NULL,
        picture_url TEXT,
        course_id TEXT DEFAULT '',
        downloaded_path TEXT,
        is_downloaded BOOLEAN DEFAULT 0,
        downloaded_at TEXT
      )
    ''');

    // Courses Table
    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        creator_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (creator_id) REFERENCES users(id)
      )
    ''');

    // Quizzes Table
    await db.execute('''
      CREATE TABLE quizzes (
        id TEXT PRIMARY KEY,
        question TEXT NOT NULL,
        quiz_type TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        reason TEXT,
        course_id TEXT NOT NULL,
        options TEXT DEFAULT '',
        FOREIGN KEY (course_id) REFERENCES courses(id)
      )
    ''');

    // Quiz Attempts Table (synced = 0 until uploaded to the cloud)
    await db.execute('''
      CREATE TABLE quiz_attempts (
        id TEXT PRIMARY KEY,
        quiz_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_answer TEXT,
        is_correct BOOLEAN,
        attempted_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (quiz_id) REFERENCES quizzes(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Quiz Results — local copy of each submission so offline results aren't
    // lost; uploaded to the cloud when a connection is available (synced = 1).
    await db.execute('''
      CREATE TABLE quiz_results (
        id TEXT PRIMARY KEY,
        student_id TEXT,
        student_name TEXT,
        score REAL,
        total_questions INTEGER,
        passed INTEGER,
        course_id TEXT,
        submitted_at TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE users ADD COLUMN course TEXT DEFAULT ''");
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE books ADD COLUMN course_id TEXT DEFAULT ''");
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE users ADD COLUMN full_name TEXT DEFAULT ''");
      await db.execute("ALTER TABLE users ADD COLUMN student_id TEXT DEFAULT ''");
      await db.execute("ALTER TABLE users ADD COLUMN grade_level TEXT DEFAULT ''");
    }
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE quizzes ADD COLUMN options TEXT DEFAULT ''");
    }
    if (oldVersion < 6) {
      // Early v5 installs created the books table without course_id (it was
      // only added via the v<3 upgrade path). Add it here; ignore the error if
      // the column already exists from that earlier migration.
      try {
        await db.execute("ALTER TABLE books ADD COLUMN course_id TEXT DEFAULT ''");
      } catch (_) {
        // Column already present — nothing to do.
      }
    }
    if (oldVersion < 7) {
      // Offline outbox: track which attempts/results still need uploading.
      try {
        await db.execute(
            "ALTER TABLE quiz_attempts ADD COLUMN synced INTEGER DEFAULT 0");
        // Existing attempts were already pushed when taken online; mark them
        // synced so the outbox flush doesn't re-upload them as duplicates.
        await db.execute("UPDATE quiz_attempts SET synced = 1");
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS quiz_results (
            id TEXT PRIMARY KEY,
            student_id TEXT,
            student_name TEXT,
            score REAL,
            total_questions INTEGER,
            passed INTEGER,
            course_id TEXT,
            submitted_at TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');
      } catch (_) {}
    }
  }

  Future<void> closeDatabase() async {
    _database?.close();
    _database = null;
  }
}
