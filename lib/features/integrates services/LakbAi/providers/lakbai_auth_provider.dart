import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../lakbai_config.dart';

class LakbaiAuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  bool get isAdmin => _user != null && _user!['role'] == 'admin';
  bool get isTourismOffice => _user != null && _user!['role'] == 'tourism_office';

  final _storage = const FlutterSecureStorage();

  LakbaiAuthProvider() { initAuth(); }

  Future<void> initAuth() async {
    try {
      final token = await _storage.read(key: 'lakbai_jwt_token');
      final savedUser = await _storage.read(key: 'lakbai_user_data');
      if (token != null && savedUser != null) _user = jsonDecode(savedUser);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ HANDSHAKE: Checks the internal route and forces Auto-Login if successful
  Future<String> verifyHandshake(String tawiId, String email) async {
    final safeEmail = email.trim().toLowerCase();
    try {
      final url = '${LakbaiAppConfig.baseUrl}/internal/verify-user';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'x-internal-gateway-secret': LakbaiAppConfig.gatewaySecret
        },
        body: jsonEncode({'tawiTawiUserId': tawiId, 'email': safeEmail}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['requiresRegistration'] == true) {
          return "SIGNUP"; // User does not exist, send to Signup
        } else if (data['isLinked'] == true && data['token'] != null) {
          _user = data['user'];
          await _storage.write(key: 'lakbai_jwt_token', value: data['token']);
          await _storage.write(key: 'lakbai_user_data', value: jsonEncode(data['user']));
          notifyListeners();
          return "SUCCESS"; // User exists! Token saved. Bypass signup.
        }
      }
    } catch (e) {
      debugPrint('Handshake Error: $e');
    }
    return "ERROR";
  }

  // ✅ INTERNAL REGISTER: Registers cleanly using the Gateway
  Future<void> registerHandshake(String tawiId, String name, String email, String role, String region, String contactNumber) async {
    final url = '${LakbaiAppConfig.baseUrl}/internal/register-user';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'x-internal-gateway-secret': LakbaiAppConfig.gatewaySecret
      },
      body: jsonEncode({
        'tawiTawiUserId': tawiId,
        'fullName': name,
        'email': email.trim().toLowerCase(),
        'role': role,
        'region': region,
        'contactNumber': contactNumber
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _user = data['user'];
      await _storage.write(key: 'lakbai_jwt_token', value: data['token']);
      await _storage.write(key: 'lakbai_user_data', value: jsonEncode(data['user']));
      notifyListeners();
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Registration failed');
    }
  }

  Future<void> logout() async {
    _user = null;
    await _storage.delete(key: 'lakbai_jwt_token');
    await _storage.delete(key: 'lakbai_user_data');
    notifyListeners();
  }
}