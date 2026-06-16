import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isGuest = false;
  bool _isEmbedded = false;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  /// True while browsing without a real account (the synthetic guest identity).
  /// Becomes false once the user signs in. Guests can't edit their profile.
  bool get isGuest => _isGuest;

  /// True for the whole lifetime of an embedded launch (host super-app), even
  /// after a guest signs in — so the "return to host" controls stay available.
  bool get isEmbedded => _isEmbedded;

  /// [guest] is set by the host launcher (TdlfEducApp(guestMode: true)) so the
  /// module opens straight into its content with no sign-in/sign-up screen.
  AuthProvider({bool guest = false}) {
    if (guest) {
      _isEmbedded = true;
      _seedGuest();
    } else {
      _initializeUser();
    }
  }

  Future<void> _initializeUser() async {
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  /// Re-fetches the current session's profile from the cloud (or cache).
  /// Used by the Profile screen's pull-to-refresh / reload so a stalled or
  /// not-yet-loaded session can be recovered without restarting the app.
  Future<void> refreshUser() async {
    if (_isGuest) return; // guest identity is synthetic; nothing to refresh
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
        _isGuest = false; // promoted from guest to a real, synced account
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
