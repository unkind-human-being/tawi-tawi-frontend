import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cloud authentication backed by Supabase Auth.
///
/// Offline-first behaviour:
/// - Supabase persists the login session locally, so a user who has signed in
///   once stays signed in on later launches — even with no internet.
/// - The user's `profiles` row is cached in [SharedPreferences] after every
///   successful fetch, so the profile is available offline.
class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() => _instance;

  AuthService._internal();

  SupabaseClient get _sb => Supabase.instance.client;
  static const String _profileCacheKey = 'cached_profile';

  /// Registers a new account. Returns `null` on success, otherwise a
  /// human-readable error message.
  Future<String?> signUp({
    required String username,
    required String email,
    required String password,
    required String role,
    String course = '',
    String fullName = '',
    String studentId = '',
    String gradeLevel = '',
  }) async {
    try {
      await _sb.auth.signUp(
        email: email,
        password: password,
        // Picked up by the `handle_new_user` trigger to build the profile row.
        data: {
          'username': username,
          'full_name': fullName,
          'role': role,
          'course': course,
          'student_id': studentId,
          'grade_level': gradeLevel,
        },
      );
      // If email confirmation is disabled, sign-up creates a session. Sign out
      // so the user explicitly signs in next (keeps the existing UX/flow).
      if (_sb.auth.currentSession != null) {
        await _sb.auth.signOut();
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Sign up failed. Check your internet connection and try again.';
    }
  }

  /// Signs in. Returns `null` on success, otherwise an error message.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _sb.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user == null) return 'Invalid email or password';
      await _fetchAndCacheProfile(res.user!.id);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (_) {
      return 'Could not sign in. Check your internet connection.';
    }
  }

  /// Returns the current user's profile, or `null` if not signed in.
  /// Refreshes from Supabase when online, falls back to the local cache offline.
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final user = _sb.auth.currentUser;
    if (user == null) return null;
    final fresh = await _fetchAndCacheProfile(user.id);
    return fresh ?? await _readCachedProfile();
  }

  Future<void> logOut() async {
    try {
      await _sb.auth.signOut();
    } catch (_) {
      // Ignore network errors on sign-out.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileCacheKey);
  }

  /// Updates the current user's profile row.
  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      await _sb.from('profiles').update(data).eq('id', userId);
      await _fetchAndCacheProfile(userId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// All teachers (for the faculty directory).
  Future<List<Map<String, dynamic>>> getAllTeachers() async {
    try {
      final data = await _sb
          .from('profiles')
          .select()
          .eq('role', 'Teacher')
          .order('username');
      return List<Map<String, dynamic>>.from(data);
    } catch (_) {
      return [];
    }
  }

  Future<bool> isUserLoggedIn() async => _sb.auth.currentUser != null;

  // ── Profile cache helpers ───────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _fetchAndCacheProfile(String id) async {
    try {
      final data =
          await _sb.from('profiles').select().eq('id', id).maybeSingle();
      if (data == null) return null;
      final map = Map<String, dynamic>.from(data);
      await _cacheProfile(map);
      return map;
    } catch (_) {
      return null; // Offline or transient error.
    }
  }

  Future<void> _cacheProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileCacheKey, jsonEncode(profile));
  }

  Future<Map<String, dynamic>?> _readCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileCacheKey);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }
}
