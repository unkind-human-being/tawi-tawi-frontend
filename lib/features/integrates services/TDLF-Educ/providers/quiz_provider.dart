import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';

class QuizProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final DatabaseService _dbService = DatabaseService();

  List<Map<String, dynamic>> _quizzes = [];
  List<Map<String, dynamic>> _activeQuizzes = [];
  List<Map<String, dynamic>> _quizHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentQuestionIndex = 0;
  Map<String, String> _userAnswers = {};
  double _quizScore = 0.0;
  bool _showResults = false;

  List<Map<String, dynamic>> get quizzes => _quizzes;
  List<Map<String, dynamic>> get activeQuizzes => _activeQuizzes;
  List<Map<String, dynamic>> get quizHistory => _quizHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentQuestionIndex => _currentQuestionIndex;
  Map<String, String> get userAnswers => _userAnswers;
  double get quizScore => _quizScore;
  bool get showResults => _showResults;
  bool get isPassed => _quizScore >= AppConfig.passingScore;

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

  Future<void> fetchQuizzes() async {
    // Offline-first: show the local cache immediately…
    await _loadCachedQuizzes();
    _isLoading = _quizzes.isEmpty;
    _errorMessage = null;
    notifyListeners();

    try {
      // …then refresh from the cloud and write through to the cache.
      final fetchedQuizzes = await _apiService.getQuizzes();
      final db = await _dbService.database;

      for (var quiz in fetchedQuizzes) {
        quiz['options'] = _parseOptions(quiz['options']); // normalize to List
        await db.insert(
          'quizzes',
          {
            'id': quiz['quiz_id'] ?? const Uuid().v4(),
            'question': quiz['question'] ?? '',
            'quiz_type': quiz['quiz_type'] ?? '',
            'correct_answer': quiz['correct_answer'] ?? '',
            'reason': quiz['reason'] ?? '',
            'course_id': quiz['course_id'] ?? '',
            'options': jsonEncode(quiz['options']),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      _quizzes = fetchedQuizzes;
      _errorMessage = null;
    } catch (e) {
      // Offline or fetch failed — keep the cached quizzes we already loaded.
      if (_quizzes.isEmpty) {
        _errorMessage = 'You are offline and have no cached quizzes yet.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads quizzes from the local SQLite cache. Cached rows expose `id` (the
  /// UI reads `quiz['quiz_id'] ?? quiz['id']`, so both online/offline work).
  Future<void> _loadCachedQuizzes() async {
    try {
      final db = await _dbService.database;
      final rows = await db.query('quizzes');
      _quizzes = rows.map((r) {
        final m = Map<String, dynamic>.from(r);
        m['options'] = _parseOptions(m['options']);
        return m;
      }).toList();
    } catch (_) {
      // No cache yet.
    }
  }

  /// Normalizes a quiz's `options` (jsonb List from Supabase, or a JSON string
  /// from the SQLite cache) into a plain `List<String>`.
  List<String> _parseOptions(dynamic raw) {
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
    }
    return const [];
  }

  /// Grades one answer. Enumeration passes when every expected item appears in
  /// the user's answer (order/extra items ignored); all other types are an
  /// exact, case-insensitive, trimmed match.
  bool _isCorrect(Map<String, dynamic> quiz, String userAnswer) {
    final type = (quiz['quiz_type'] ?? '').toString();
    final correct = (quiz['correct_answer'] ?? '').toString();
    if (type == 'enumeration') {
      Set<String> items(String s) => s
          .split(RegExp(r'[,\n;]'))
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet();
      final expected = items(correct);
      final given = items(userAnswer);
      return expected.isNotEmpty && expected.every(given.contains);
    }
    return userAnswer.trim().toLowerCase() == correct.trim().toLowerCase();
  }

  Future<void> loadQuizHistory(String userId) async {
    // Push any offline submissions to the cloud first so they show up here.
    await syncPendingResults(userId);

    // Prefer the cloud so history follows the account across devices / the
    // embedded app; fall back to the local cache when offline (or before the
    // quiz_attempts table SQL has been run).
    List<Map<String, dynamic>>? cloud;
    try {
      final rows = await _apiService.getMyAttempts(userId);
      cloud = rows.map((r) {
        final m = Map<String, dynamic>.from(r);
        m['attempted_at'] = m['submitted_at'] ?? m['attempted_at'];
        m['is_correct'] =
            (m['is_correct'] == true || m['is_correct'] == 1) ? 1 : 0;
        return m;
      }).toList();
    } catch (_) {
      cloud = null; // Cloud unavailable — fall through to the local cache.
    }

    if (cloud != null) {
      // Add any attempts still waiting to upload (synced = 0) so an offline
      // quiz appears right away; they don't duplicate cloud rows (synced = 1).
      try {
        final db = await _dbService.database;
        final pending = await db.query(
          'quiz_attempts',
          where: 'user_id = ? AND synced = 0',
          whereArgs: [userId],
          orderBy: 'attempted_at DESC',
        );
        _quizHistory = [...pending, ...cloud];
      } catch (_) {
        _quizHistory = cloud;
      }
      notifyListeners();
      return;
    }

    // Fully offline — show everything from the local attempts table.
    try {
      final db = await _dbService.database;
      final List<Map<String, dynamic>> result = await db.query(
        'quiz_attempts',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'attempted_at DESC',
      );
      _quizHistory = result;
      notifyListeners();
    } catch (_) {}
  }

  // ── Cloud-synced results (for the profile, across devices) ──────────────────
  List<Map<String, dynamic>> _cloudResults = [];
  List<Map<String, dynamic>> get cloudResults => _cloudResults;

  Future<void> loadCloudResults(String studentId) async {
    // Upload any offline submissions first so the cloud copy is complete.
    await syncPendingResults(studentId);

    List<Map<String, dynamic>> cloud;
    try {
      cloud = await _apiService.getMyResults(studentId);
    } catch (_) {
      cloud = [];
    }

    // Add results still waiting to upload (synced = 0) so an offline quiz counts
    // toward the profile immediately; they don't double-count cloud rows, which
    // are synced = 1 and therefore excluded here.
    try {
      final db = await _dbService.database;
      final pending = await db.query(
        'quiz_results',
        where: 'student_id = ? AND synced = 0',
        whereArgs: [studentId],
      );
      cloud = [
        ...cloud,
        ...pending.map((r) => <String, dynamic>{
              'total_questions': r['total_questions'],
              'score': r['score'],
              'passed': r['passed'] == 1,
              'submitted_at': r['submitted_at'],
            }),
      ];
    } catch (_) {}

    _cloudResults = cloud;
    notifyListeners();
  }

  /// Total questions answered across all submitted quizzes (cloud).
  int get cloudTotalAnswered => _cloudResults.fold(
      0, (s, r) => s + ((r['total_questions'] as num?)?.toInt() ?? 0));

  /// Correct answers derived from each session's score % × its question count.
  int get cloudTotalCorrect => _cloudResults.fold(0, (s, r) {
        final tq = (r['total_questions'] as num?)?.toInt() ?? 0;
        final score = (r['score'] as num?)?.toDouble() ?? 0;
        return s + (score / 100 * tq).round();
      });

  double get cloudAccuracy =>
      cloudTotalAnswered > 0 ? cloudTotalCorrect / cloudTotalAnswered * 100 : 0.0;

  // ── "Already answered" tracking ─────────────────────────────────────────────
  // A student can't retake a quiz they've already submitted. Tracked from the
  // local quiz_attempts table (per device/account).
  final Set<String> _answeredQuizIds = {};
  bool isQuizAnswered(String quizId) => _answeredQuizIds.contains(quizId);

  Future<void> loadAnsweredQuizzes(String userId) async {
    try {
      final db = await _dbService.database;
      final rows = await db.query(
        'quiz_attempts',
        columns: ['quiz_id'],
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      _answeredQuizIds
        ..clear()
        ..addAll(rows
            .map((r) => (r['quiz_id'] ?? '').toString())
            .where((s) => s.isNotEmpty));
      notifyListeners();
    } catch (_) {}
  }

  void prepareQuiz(List<Map<String, dynamic>> quizzes) {
    _activeQuizzes = List.from(quizzes);
    _currentQuestionIndex = 0;
    _userAnswers = {};
    _quizScore = 0.0;
    _showResults = false;
    notifyListeners();
  }

  void resetQuiz() {
    _activeQuizzes = [];
    _currentQuestionIndex = 0;
    _userAnswers = {};
    _quizScore = 0.0;
    _showResults = false;
    notifyListeners();
  }

  void answerQuestion(String quizId, String answer) {
    _userAnswers[quizId] = answer;
    notifyListeners();
  }

  void nextQuestion() {
    if (_currentQuestionIndex < _activeQuizzes.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _currentQuestionIndex--;
      notifyListeners();
    }
  }

  Future<void> submitQuiz(String userId, String userName, String courseId) async {
    try {
      int correctAnswers = 0;
      final db = await _dbService.database;
      final now = DateTime.now().toIso8601String();

      for (var quiz in _activeQuizzes) {
        final quizId = quiz['quiz_id'] ?? quiz['id'];
        final userAnswer = _userAnswers[quizId] ?? '';
        final isCorrect = _isCorrect(quiz, userAnswer);

        if (isCorrect) correctAnswers++;

        await db.insert('quiz_attempts', {
          'id': const Uuid().v4(),
          'quiz_id': quizId,
          'user_id': userId,
          'user_answer': userAnswer,
          'is_correct': isCorrect ? 1 : 0,
          'attempted_at': now,
          'synced': 0,
        });
        _answeredQuizIds.add(quizId.toString()); // lock from being retaken
      }

      _quizScore = _activeQuizzes.isNotEmpty
          ? (correctAnswers / _activeQuizzes.length) * 100
          : 0;
      _showResults = true;
      notifyListeners();

      // Save the session result locally too, so an OFFLINE submission isn't lost.
      await db.insert('quiz_results', {
        'id': const Uuid().v4(),
        'student_id': userId,
        'student_name': userName,
        'score': _quizScore,
        'total_questions': _activeQuizzes.length,
        'passed': _quizScore >= AppConfig.passingScore ? 1 : 0,
        'course_id': courseId,
        'submitted_at': now,
        'synced': 0,
      });

      // Try to push this (and any earlier offline) result to the cloud now.
      await syncPendingResults(userId);
    } catch (e) {
      _errorMessage = 'Error submitting quiz: $e';
      notifyListeners();
    }
  }

  /// Uploads locally-stored attempts/results that haven't reached the cloud yet
  /// (e.g. submitted while offline). Safe to call often: on failure the records
  /// stay pending and are retried the next time the app reaches the cloud.
  Future<void> syncPendingResults(String userId) async {
    if (userId.isEmpty) return;
    try {
      final db = await _dbService.database;

      final pendingAttempts = await db.query('quiz_attempts',
          where: 'synced = 0 AND user_id = ?', whereArgs: [userId]);
      if (pendingAttempts.isNotEmpty) {
        final payload = pendingAttempts
            .map((a) => <String, dynamic>{
                  'student_id': a['user_id'],
                  'quiz_id': (a['quiz_id'] ?? '').toString(),
                  'user_answer': a['user_answer'] ?? '',
                  'is_correct': a['is_correct'] == 1,
                  'submitted_at': a['attempted_at'],
                })
            .toList();
        await _apiService.insertAttemptsOrThrow(payload); // throws if offline
        for (final a in pendingAttempts) {
          await db.update('quiz_attempts', {'synced': 1},
              where: 'id = ?', whereArgs: [a['id']]);
        }
      }

      final pendingResults = await db.query('quiz_results',
          where: 'synced = 0 AND student_id = ?', whereArgs: [userId]);
      for (final r in pendingResults) {
        await _apiService.insertResultOrThrow(<String, dynamic>{
          'student_id': r['student_id'],
          'student_name': r['student_name'],
          'score': r['score'],
          'total_questions': r['total_questions'],
          'passed': r['passed'] == 1,
          'course_id': r['course_id'] ?? '',
          'submitted_at': r['submitted_at'],
        });
        await db.update('quiz_results', {'synced': 1},
            where: 'id = ?', whereArgs: [r['id']]);
      }
    } catch (_) {
      // Offline (or cloud tables missing) — leave pending, retry next time.
    }
  }

  Future<bool> addQuiz(Map<String, dynamic> data) async {
    try {
      final quiz = await _apiService.addQuiz(data);
      if (quiz != null) {
        _quizzes.add(quiz);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) { return false; }
  }

  Future<bool> deleteQuiz(String quizId) async {
    try {
      final success = await _apiService.deleteQuiz(quizId);
      if (success) {
        _quizzes.removeWhere((q) => (q['quiz_id'] ?? q['id']) == quizId);
        notifyListeners();
      }
      return success;
    } catch (_) { return false; }
  }

  Future<bool> updateQuiz(String quizId, Map<String, dynamic> data) async {
    try {
      final success = await _apiService.updateQuiz(quizId, data);
      if (success) {
        final i = _quizzes.indexWhere((q) => (q['quiz_id'] ?? q['id']) == quizId);
        if (i != -1) {
          _quizzes[i] = {..._quizzes[i], ...data};
          notifyListeners();
        }
      }
      return success;
    } catch (_) { return false; }
  }

  List<Map<String, dynamic>> getQuizzesByCourse(String courseId) {
    return _quizzes
        .where((quiz) => (quiz['course_id'] ?? '') == courseId)
        .toList();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
