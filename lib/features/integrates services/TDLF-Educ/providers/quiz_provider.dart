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
        await db.insert(
          'quizzes',
          {
            'id': quiz['quiz_id'] ?? const Uuid().v4(),
            'question': quiz['question'] ?? '',
            'quiz_type': quiz['quiz_type'] ?? '',
            'correct_answer': quiz['correct_answer'] ?? '',
            'reason': quiz['reason'] ?? '',
            'course_id': quiz['course_id'] ?? '',
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
      _quizzes = rows.map((r) => Map<String, dynamic>.from(r)).toList();
    } catch (_) {
      // No cache yet.
    }
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
        final isCorrect = userAnswer.trim().toLowerCase() ==
            (quiz['correct_answer'] ?? '').toString().trim().toLowerCase();

        if (isCorrect) correctAnswers++;

        await db.insert('quiz_attempts', {
          'id': const Uuid().v4(),
          'quiz_id': quizId,
          'user_id': userId,
          'user_answer': userAnswer,
          'is_correct': isCorrect ? 1 : 0,
          'attempted_at': DateTime.now().toIso8601String(),
        });
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
