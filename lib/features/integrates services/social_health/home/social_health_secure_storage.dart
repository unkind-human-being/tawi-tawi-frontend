import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SocialHealthSecureStorage {
  static const String _tokenKey = 'social_health_token';
  static const String _userNameKey = 'social_health_user_name';
  static const String _userEmailKey = 'social_health_user_email';
  static const String _userRoleKey = 'social_health_user_role';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveSession({
    required String token,
    required String name,
    required String email,
    required String role,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userNameKey, value: name);
    await _storage.write(key: _userEmailKey, value: email);
    await _storage.write(key: _userRoleKey, value: role);
  }

  Future<String?> getToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<String?> getUserName() {
    return _storage.read(key: _userNameKey);
  }

  Future<String?> getUserEmail() {
    return _storage.read(key: _userEmailKey);
  }

  Future<String?> getUserRole() {
    return _storage.read(key: _userRoleKey);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _userRoleKey);
  }
}