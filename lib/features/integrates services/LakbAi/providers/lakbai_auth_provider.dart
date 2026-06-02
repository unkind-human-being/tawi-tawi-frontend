import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../lakbai_config.dart'; // <-- Import centralized config

class LakbaiAuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  bool get isAdmin => _user != null && _user!['role'] == 'admin';
  bool get isTourismOffice => _user != null && _user!['role'] == 'tourism_office';

  final _storage = const FlutterSecureStorage();

  Future<void> initAuth() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      final savedUser = await _storage.read(key: 'user_data');
      
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
    final response = await http.post(
      Uri.parse('${LakbaiAppConfig.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _user = data['user'];
      
      await _storage.write(key: 'jwt_token', value: data['token']);
      await _storage.write(key: 'user_data', value: jsonEncode(data['user']));
      
      notifyListeners();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Invalid credentials'); 
    }
  }

  Future<void> register(String name, String email, String password, String role, String region, String contactNumber) async {
    final response = await http.post(
      Uri.parse('${LakbaiAppConfig.baseUrl}/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'region': region,
        'contactNumber': contactNumber,
      }),
    );

    if (response.statusCode == 201) {
      // FIX: Removed the token saving and user assignment here.
      // We just notify listeners that loading is done, keeping the user logged out.
      notifyListeners();
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Registration failed');
    }
  }

  Future<void> logout() async {
    _user = null;
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_data');
    notifyListeners();
  }
}