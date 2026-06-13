import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const FlutterSecureStorage storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await storage.write(key: 'jwt_token', value: token);
  }

  static Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  static Future<void> clearToken() async {
    await storage.delete(key: 'jwt_token');
  }
}

// ==========================================================================
// DIO HTTP CLIENT PROVIDER
// ==========================================================================
final dioProvider = Provider<Dio>((ref) {
  // Updated with your current computer local network hotspot configuration
  const String computerIp = "10.0.26.26";
  String baseUrl;

  if (kIsWeb) {
    baseUrl = "http://localhost:10000";
  } else {
    // Web safe execution environment mapping
    final isAndroidDevice = defaultTargetPlatform == TargetPlatform.android;
    final isProfileOrDebug =
        !const bool.fromEnvironment('dart.vm.product', defaultValue: false);

    if (isAndroidDevice) {
      baseUrl = (isProfileOrDebug)
          ? "http://10.0.2.2:10000" // Genymotion/Android Studio Emulator loopback
          : "http://$computerIp:10000"; // Physical Local Hardware Target
    } else {
      baseUrl =
          "http://$computerIp:10000"; // iOS Simulator or alternate system route
    }
  }

  print("Using Base URL: $baseUrl");

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {"Content-Type": "application/json"},
    ),
  );

  const storage = FlutterSecureStorage();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Automatically skip token injection for authentication pipelines
        if (options.path.contains('/auth/login') ||
            options.path.contains('/auth/register')) {
          print("Login/Register detected. Skipping Auth token injection.");
          return handler.next(options);
        }

        final token = await storage.read(key: 'jwt_token');

        print("====== DIO INTERCEPTOR ======");
        print("Requesting Path: ${options.path}");

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print("Token attached successfully.");
        } else {
          print(
              "WARNING: Token is null! Request is sending without authentication.");
        }
        print("=============================");

        return handler.next(options);
      },
    ),
  );

  // Debugging logger for development environments
  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      error: true,
    ),
  );

  return dio;
});
