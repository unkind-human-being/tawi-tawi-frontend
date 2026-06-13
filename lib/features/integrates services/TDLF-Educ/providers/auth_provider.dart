import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isGuest = false;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  /// True when the module is opened embedded in a host app (e.g. Tawi-Tawi)
  /// that already authenticated the user, so our own login is skipped and the
  /// session is a read-only guest.
  bool get isGuest => _isGuest;

  /// [guest] is set by the host launcher (TdlfEducApp(guestMode: true)) so the
  /// module opens straight into its content with no sign-in/sign-up screen.
  AuthProvider({bool guest = false}) {
    if (guest) {
      _seedGuest();
    } else {
      _initializeUser();
    }
  }

  Future<void> _initializeUser() async {
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  /// Synthetic, read-only identity used when embedded in a host super-app.
  void _seedGuest() {
    _isGuest = true;
    _currentUser = {
      'id': 'guest',
      'username': 'Guest',
      'full_name': 'Guest',
      'email': '',
      'role': 'Student',
      'course': '',
      'student_id': '',
      'grade_level': '',
    };
    notifyListeners();
  }

  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
    required String role,
    String course = '',
    String fullName = '',
    String studentId = '',
    String gradeLevel = '',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        _errorMessage = 'All fields are required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final error = await _authService.signUp(
        username: username,
        email: email,
        password: password,
        role: role,
        course: course,
        fullName: fullName,
        studentId: studentId,
        gradeLevel: gradeLevel,
      );

      _isLoading = false;
      _errorMessage = error;
      notifyListeners();
      return error == null;
    } catch (e) {
      _errorMessage = 'An error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (email.isEmpty || password.isEmpty) {
        _errorMessage = 'Email and password are required';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final error = await _authService.signIn(email: email, password: password);

      if (error == null) {
        _currentUser = await _authService.getCurrentUser();
      }

      _isLoading = false;
      _errorMessage = error;
      notifyListeners();
      return error == null;
    } catch (e) {
      _errorMessage = 'An error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCurrentUser(Map<String, dynamic> data) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    notifyListeners();

    final success = await _authService.updateUser(_currentUser!['id'] as String, data);
    if (success) {
      _currentUser = await _authService.getCurrentUser();
    }
    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<List<Map<String, dynamic>>> getAllTeachers() async {
    return await _authService.getAllTeachers();
  }

  Future<List<Map<String, dynamic>>> getAllStudents() async {
    return await _authService.getAllStudents();
  }

  Future<void> logout() async {
    await _authService.logOut();
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
