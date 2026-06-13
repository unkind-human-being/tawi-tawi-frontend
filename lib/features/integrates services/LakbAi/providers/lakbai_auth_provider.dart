import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ Added SharedPreferences
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
    _isLoading = false; // ✅ FIXED: Changed __isLoading to _isLoading
    notifyListeners();
  }
}

  // ✅ NEW: Silently recovers the session if Kawman wiped the secure storage
  Future<bool> attemptSilentRecovery(String tawiEmail) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('lakbai_recovery_email');
      final savedPassword = prefs.getString('lakbai_recovery_password');

      // Only auto-login if the saved LakbAi email matches the currently logged-in Kawman email!
      if (savedEmail != null && savedPassword != null && savedEmail == tawiEmail) {
        await login(savedEmail, savedPassword); // Silently get a new backend token
        return true; 
      }
    } catch (e) {
      debugPrint('Silent recovery failed: $e');
    }
    return false;
  }

  Future<void> login(String email, String password) async {
    final url = '${LakbaiAppConfig.baseUrl}/auth/login';
    
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

      // ✅ VAULT: Save backup for silent auto-login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lakbai_recovery_email', email);
      await prefs.setString('lakbai_recovery_password', password);

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
    final url = '${LakbaiAppConfig.baseUrl}/auth/signup';

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

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _user = data['user'];
      await _storage.write(key: 'lakbai_jwt_token', value: data['token']);
      await _storage.write(key: 'lakbai_user_data', value: jsonEncode(data['user']));

      // ✅ VAULT: Save backup for silent auto-login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lakbai_recovery_email', email);
      await prefs.setString('lakbai_recovery_password', password);

      notifyListeners();
    } else {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Registration failed');
    }
  }

  Future<void> logout() async {
    _user = null;
    await _storage.delete(key: 'lakbai_jwt_token');
    await _storage.delete(key: 'lakbai_user_data');

    // ✅ VAULT: Wipe backup ONLY if they explicitly click Logout in LakbAi
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('lakbai_recovery_email');
    await prefs.remove('lakbai_recovery_password');

    notifyListeners();
  }
}