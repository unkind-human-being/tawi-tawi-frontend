import 'package:dio/dio.dart';

class ProfileService {
  final Dio _dio;

  ProfileService(this._dio);

  Future<Map<String, dynamic>> getMe() async {
    try {
      // The Dio interceptor will automatically add the token,
      // but this ensures the path is correct.
      final response = await _dio.get('/users/me');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
          'Failed to fetch user profile: ${e.response?.data['message'] ?? e.message}');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _dio.patch('/users/me', data: data);
    } on DioException catch (e) {
      throw Exception('Failed to update profile: ${e.message}');
    }
  }
}
