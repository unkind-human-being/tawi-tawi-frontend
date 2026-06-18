import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isEmbedded = false;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  /// True for the whole lifetime of an embedded launch (host super-app), so the
  /// "return to host" controls stay available.
  bool get isEmbedded => _isEmbedded;

  /// [embedded] is set by the host launcher (TdlfEducApp(embedded: true)).
  /// In that mode the module stays signed-out until the welcome screen signs
  /// the user in — automatically from their host (Tawi-Tawi) account, or
  /// manually with their own TDLF-Educ account.
  AuthProvider({bool embedded = false}) {
    _isEmbedded = embedded;
    // Load any persisted session on both standalone and embedded, so exiting
    // and re-opening the module doesn't force a re-sign-in (the welcome only
    // shows when there's no signed-in user).
    _initializeUser();
  }

  // Guard async notifyListeners() after dispose (leaving the module mid-call).
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

  Future<void> _initializeUser() async {
    // Adopt an existing session synchronously (runs during construction, before
    // the first await) so `isLoggedIn` is already true on the first frame — this
    // is what stops the welcome/login screen flashing on embedded re-entry.
    final cached = _authService.sessionUserSync();
    if (cached != null) {
      _currentUser = cached;
      notifyListeners();
    }
    // Then refresh the full profile (course, student_id, etc.) from cloud/cache.
    final full = await _authService.getCurrentUser();
    if (full != null) _currentUser = full;
    notifyListeners();
  }

  /// Re-fetches the current session's profile from the cloud (or cache).
  /// Used by the Profile screen's pull-to-refresh / reload so a stalled or
  /// not-yet-loaded session can be recovered without restarting the app.
  Future<void> refreshUser() async {
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  /// Signs in using the host (Tawi-Tawi) account — a Supabase account derived
  /// from their email, so it "flows in" with no extra sign-up. Returns `null`
  /// on success, otherwise a message (e.g. the email already has its own
  /// TDLF-Educ account → the caller routes to a normal password sign-in).
  Future<String?> signInAsHostUser(String email, String fullName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final error =
        await _authService.signInAsHostUser(email: email, fullName: fullName);
    if (error == null) {
      _currentUser = await _authService.getCurrentUser();
    }
    _isLoading = false;
    _errorMessage = error;
    notifyListeners();
    return error;
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
