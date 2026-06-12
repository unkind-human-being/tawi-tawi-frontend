import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  // 1. Direct routing to your active Render backend
  const String baseUrl = "https://tawi-tawi-backend.onrender.com/api/ecommerce";

  if (kDebugMode) {
    print("ROUTING APP TRAFFIC TO: $baseUrl");
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 45),
      headers: {"Content-Type": "application/json"},
    ),
  );

  const storage = FlutterSecureStorage();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final String path = options.path.toLowerCase();

        // Skip adding tokens for public auth endpoints
        if (path.contains('login') ||
            path.contains('register') ||
            path.contains('auth')) {
          if (kDebugMode) {
            print(
                "Public Auth Route Detected: ${options.path}. Skipping Auth token injection.");
          }
          return handler.next(options);
        }

        // --- FIXED: Check multiple common keys to prevent null token injection bugs ---
        String? token = await storage.read(key: 'jwt_token');
        token ??= await storage.read(key: 'access_token');
        token ??= await storage.read(key: 'token');

        if (kDebugMode) {
          print("====== DIO INTERCEPTOR ======");
          print("Requesting Path: ${options.path}");
        }

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          if (kDebugMode) print("Token attached successfully.");
        } else {
          if (kDebugMode) {
            print(
                "CRITICAL WARNING: Token is null across all storage keys! Sending unauthenticated.");
          }
        }
        if (kDebugMode) print("=============================");

        return handler.next(options);
      },
    ),
  );

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    );
  }

  return dio;
});
