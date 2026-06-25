import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

/// Holds the list of course categories. Courses live in the Supabase `courses`
/// table (so teachers can add their own); they're cached locally so the filters
/// still work offline. Falls back to four built-in categories until the cloud
/// list has loaded.
class CourseProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final DatabaseService _db = DatabaseService();

  static const List<Map<String, dynamic>> _defaults = [
    {'id': 'course-001', 'title': 'Computer Fundamentals'},
    {'id': 'course-002', 'title': 'Basic Mathematics'},
    {'id': 'course-003', 'title': 'Science and Technology'},
    {'id': 'course-004', 'title': 'English Communication'},
  ];

  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get courses =>
      _courses.isNotEmpty ? _courses : _defaults;
  bool get isLoading => _isLoading;

  // Guard async notifyListeners() after dispose (leaving the module mid-fetch).
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  /// Resolves a course id to its title (or '' / the raw id if unknown).
  String titleFor(String? id) {
    if (id == null || id.isEmpty) return '';
    for (final c in courses) {
      if (c['id'] == id) return (c['title'] ?? id).toString();
    }
    return id;
  }

  Future<void> fetchCourses() async {
    await _loadCache();
    _isLoading = _courses.isEmpty;
    notifyListeners();
    try {
      final fetched = await _api.getCourses();
      if (fetched.isNotEmpty) {
        _courses = fetched
            .map((c) => <String, dynamic>{
                  'id': c['id'].toString(),
                  'title': (c['title'] ?? '').toString(),
                })
            .toList();
        _sort();
        await _writeCache();
      }
    } catch (_) {
      // Offline — keep whatever cache/defaults we have.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCourse(String title) async {
    final t = title.trim();
    if (t.isEmpty) return false;
    final id = 'course-${const Uuid().v4().substring(0, 8)}';
    final ok = await _api.addCourse({'id': id, 'title': t});
    if (ok) await fetchCourses();
    return ok;
  }

  Future<bool> updateCourse(String id, String title) async {
    final t = title.trim();
    if (t.isEmpty) return false;
    final ok = await _api.updateCourse(id, {'title': t});
    if (ok) {
      final i = _courses.indexWhere((c) => c['id'] == id);
      if (i != -1) {
        _courses[i] = {..._courses[i], 'title': t};
        _sort();
      }
      try {
        final db = await _db.database;
        await db.update('courses', {'title': t},
            where: 'id = ?', whereArgs: [id]);
      } catch (_) {}
      notifyListeners();
    }
    return ok;
  }

  Future<bool> deleteCourse(String id) async {
    final ok = await _api.deleteCourse(id);
    if (ok) {
      _courses.removeWhere((c) => c['id'] == id);
      try {
        final db = await _db.database;
        await db.delete('courses', where: 'id = ?', whereArgs: [id]);
      } catch (_) {}
      notifyListeners();
    }
    return ok;
  }

  Future<void> _loadCache() async {
    try {
      final db = await _db.database;
      final rows = await db.query('courses', orderBy: 'title');
      if (rows.isNotEmpty) {
        _courses = rows
            .map((r) => <String, dynamic>{'id': r['id'], 'title': r['title']})
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _writeCache() async {
    try {
      final db = await _db.database;
      for (final c in _courses) {
        await db.insert(
          'courses',
          {
            'id': c['id'],
            'title': c['title'],
            'description': '',
            'creator_id': '',
            'created_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (_) {}
  }

  void _sort() {
    _courses.sort((a, b) => (a['title'] ?? '')
        .toString()
        .toLowerCase()
        .compareTo((b['title'] ?? '').toString().toLowerCase()));
  }
}
