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

  LakbaiAuthProvider() {
    initAuth();
  }

  Future<void> initAuth() async {
    try {
      final token = await _storage.read(key: 'lakbai_jwt_token');
      final savedUser = await _storage.read(key: 'lakbai_user_data');
      
      if (token != null && savedUser != null) {
        _user = jsonDecode(savedUser);
      }
    } catch (e) {
      debugPrint('Secure storage initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    // ✅ PUT BACK TO ORIGINAL: /auth/login
    final url = '${LakbaiAppConfig.baseUrl}/auth/login';
    debugPrint('➡️ Calling Login URL: $url');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _user = data['user'];
      
      await _storage.write(key: 'lakbai_jwt_token', value: data['token']);
      await _storage.write(key: 'lakbai_user_data', value: jsonEncode(data['user']));
      notifyListeners();
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
    }
  }

  Future<void> register(
    String name, 
    String email, 
    String password, 
    String role, 
    String region, 
    String contactNumber
  ) async {
    // ✅ PUT BACK TO ORIGINAL: /auth/signup
    final url = '${LakbaiAppConfig.baseUrl}/auth/signup';
    debugPrint('➡️ Calling Register URL: $url'); 

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'region': region, 
        'contactNumber': contactNumber
      }),
    );

    debugPrint('⬅️ Response Status: ${response.statusCode}');
    debugPrint('⬅️ Response Body: ${response.body}');

    if (response.statusCode != 201 && response.statusCode != 200) {
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