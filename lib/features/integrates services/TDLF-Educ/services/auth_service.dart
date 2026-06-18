import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

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
      return _friendlyAuthError(e, signingUp: true);
    } catch (e) {
      return _friendlyAuthError(e, signingUp: true);
    }
  }

  /// Translates raw Supabase/network auth errors into clear, actionable
  /// messages for users (instead of cryptic text like
  /// "Database error saving new user").
  String _friendlyAuthError(Object e, {required bool signingUp}) {
    final msg = (e is AuthException ? e.message : e.toString()).toLowerCase();

    // The sign-up trigger throws on a duplicate username (the only unique
    // constraint), which Supabase surfaces as "Database error saving new user".
    if (msg.contains('saving new user') ||
        msg.contains('unexpected_failure') ||
        msg.contains('duplicate key') ||
        msg.contains('profiles_username_key')) {
      return 'That username is already taken. Please choose a different username.';
    }
    if (msg.contains('already registered') ||
        msg.contains('already been registered') ||
        msg.contains('user already exists')) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
      return 'Incorrect email or password.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Your email isn\'t confirmed yet. Check your inbox, or ask your '
          'admin to turn off email confirmation.';
    }
    if (msg.contains('password') &&
        (msg.contains('at least') || msg.contains('should be') || msg.contains('weak'))) {
      return 'Password is too short — use at least 6 characters.';
    }
    if (msg.contains('valid email') ||
        msg.contains('validate email') ||
        msg.contains('invalid email') ||
        msg.contains('invalid format')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('failed host') ||
        msg.contains('timeout') ||
        msg.contains('connection')) {
      return 'Couldn\'t reach the server. Check your internet connection and try again.';
    }
    // Sensible fallback.
    return signingUp
        ? 'Sign up failed. Please try again with a different username or email.'
        : 'Could not sign in. Please try again.';
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
      if (res.user == null) return 'Incorrect email or password.';
      await _fetchAndCacheProfile(res.user!.id);
      return null;
    } on AuthException catch (e) {
      return _friendlyAuthError(e, signingUp: false);
    } catch (e) {
      return _friendlyAuthError(e, signingUp: false);
    }
  }

  /// Signs the user in using their **host (Tawi-Tawi) account**: a Supabase
  /// account is derived from their email so it "flows in" with no extra sign-up.
  /// Returns `null` on success, otherwise a message. If the email already has a
  /// (separately created) TDLF-Educ account, the caller should fall back to a
  /// normal password sign-in.
  Future<String?> signInAsHostUser({
    required String email,
    required String fullName,
  }) async {
    final mail = email.trim();
    if (mail.isEmpty) return 'No host account email was provided.';
    final pw = _hostPassword(mail);

    // 1) Try to sign in (account already provisioned on a previous open).
    try {
      final res = await _sb.auth.signInWithPassword(email: mail, password: pw);
      if (res.user != null) {
        await _fetchAndCacheProfile(res.user!.id);
        return null;
      }
    } catch (_) {
      // Not signed in yet — fall through to create the account.
    }

    // 2) Create it, then sign in.
    try {
      await _sb.auth.signUp(
        email: mail,
        password: pw,
        data: {
          'username': mail.split('@').first,
          'full_name': fullName,
          'role': 'Student',
        },
      );
      if (_sb.auth.currentSession == null) {
        await _sb.auth.signInWithPassword(email: mail, password: pw);
      }
      final uid = _sb.auth.currentUser?.id;
      if (uid != null) await _fetchAndCacheProfile(uid);
      return null;
    } on AuthException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('already registered') ||
          m.contains('already been registered') ||
          m.contains('user already exists')) {
        return 'This email already has a TDLF-Educ account. '
            'Please sign in with your password.';
      }
      return _friendlyAuthError(e, signingUp: true);
    } catch (e) {
      return _friendlyAuthError(e, signingUp: true);
    }
  }

  /// Deterministic Supabase password for a host user (stable across devices).
  String _hostPassword(String email) {
    final digest = sha256.convert(
        utf8.encode('${email.toLowerCase()}|${AppConfig.hostAccountSecret}'));
    return 'tt_${digest.toString().substring(0, 28)}';
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

  /// All students (for the teacher directory / roster).
  Future<List<Map<String, dynamic>>> getAllStudents() async {
    try {
      final data = await _sb
          .from('profiles')
          .select()
          .eq('role', 'Student')
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
