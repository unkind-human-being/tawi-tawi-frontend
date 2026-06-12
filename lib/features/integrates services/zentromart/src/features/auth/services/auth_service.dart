import 'package:dio/dio.dart';
import '../models/auth_response.dart';

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  // --- 1. LOGIN METHOD ---
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(res.data);
  }

  // --- 2. REGISTER METHOD (UPDATED) ---
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? shopName, // Added optional param
    String? shopAddress, // Added optional param
  }) async {
    final res = await _dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'shopName': shopName, // Included in payload
        'shopAddress': shopAddress, // Included in payload
      },
    );
    return AuthResponse.fromJson(res.data);
  }

  // --- 3. LOGOUT METHOD ---
  Future<void> logout() async {
    // Keep as is
  }
}
