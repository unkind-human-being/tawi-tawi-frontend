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
    try {
      _cloudResults = await _apiService.getMyResults(studentId);
      notifyListeners();
    } catch (_) {}
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
          'attempted_at': DateTime.now().toIso8601String(),
        });
        _answeredQuizIds.add(quizId.toString()); // lock from being retaken
      }

      _quizScore = _activeQuizzes.isNotEmpty ? (correctAnswers / _activeQuizzes.length) * 100 : 0;
      _showResults = true;
      notifyListeners();

      await _apiService.submitQuizResults({
        'student_id': userId,
        'student_name': userName,
        'score': _quizScore,
        'total_questions': _activeQuizzes.length,
        'passed': _quizScore >= AppConfig.passingScore,
        'course_id': courseId, // lets teachers see only their course's results
        'submitted_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _errorMessage = 'Error submitting quiz: $e';
      notifyListeners();
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
