import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/models/user_model.dart';

class SecureStorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> saveUser(UserModel user) async {
    await _storage.write(
      key: _userKey,
      value: jsonEncode(user.toJson()),
    );
  }

  Future<UserModel?> getUser() async {
    final String? rawUser = await _storage.read(key: _userKey);

    if (rawUser == null || rawUser.trim().isEmpty) {
      return null;
    }

    try {
      final dynamic decoded = jsonDecode(rawUser);

      if (decoded is Map<String, dynamic>) {
        return UserModel.fromJson(decoded);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAuthSession({
    required String token,
    required UserModel user,
  }) async {
    await saveToken(token);
    await saveUser(user);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  Future<void> clearSession() async {
    await clearToken();
  }
}