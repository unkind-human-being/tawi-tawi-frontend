import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:isar/isar.dart';
import '../../../core/database/models/user_model.dart';

class AuthRepository {
  final Isar _isar;
  final Dio _dio;
  final _storage = const FlutterSecureStorage();

  AuthRepository(this._isar, this._dio);

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String uiRole,
    String? shopName,
    String? shopAddress,
  }) async {
    final String serverRole =
        uiRole.toUpperCase().contains('VENDOR') ? 'VENDOR' : 'USER';

    final localUser = UserModel()
      ..email = email
      ..password = password
      ..name = fullName
      ..role = serverRole
      ..shopName = shopName
      ..shopAddress = shopAddress
      ..isSynced = false;

    await _isar.writeTxn(() async {
      await _isar.userModels.put(localUser);
    });

    await _storage.write(
        key: 'jwt_token', value: 'offline_session_active_$email');

    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': fullName,
        'role': serverRole,
        if (shopName != null) 'shopName': shopName,
        if (shopAddress != null) 'shopAddress': shopAddress,
      });

      // Matches snake_case access token returned by NestJS server backend
      final serverToken =
          response.data['access_token'] ?? response.data['token'];
      if (serverToken != null) {
        await _storage.write(key: 'jwt_token', value: serverToken.toString());

        await _isar.writeTxn(() async {
          localUser.isSynced = true;
          await _isar.userModels.put(localUser);
        });
        if (kDebugMode) {
          print("Registration synchronized with server successfully.");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            "Server offline. Profile seamlessly cached on internal device disk storage.");
      }
    }

    return true;
  }

  // CHANGED: Returns Future<dynamic> instead of a rigid boolean flag to pass live payloads
  Future<dynamic> login(String email, String password) async {
    final localAccount =
        await _isar.userModels.filter().emailEqualTo(email).findFirst();

    // --- OFFLINE FAST PASS HANDSHAKE ---
    if (localAccount != null) {
      if (localAccount.password == password) {
        final String offlineToken =
            'offline_session_active_${email}_${localAccount.role}';
        await _storage.write(key: 'jwt_token', value: offlineToken);

        if (kDebugMode) {
          print("Offline matching successful. Unlocking storage access keys.");
        }

        // Return structured map resembling server responses for AuthResponse parsing stability
        return {
          'access_token': offlineToken,
          'user': {
            'id': localAccount.id.toString(),
            'name': localAccount.name,
            'email': localAccount.email,
            'role': localAccount.role.toUpperCase(),
            'shopName': localAccount.shopName,
            'shopAddress': localAccount.shopAddress,
          }
        };
      } else {
        throw Exception("Invalid credentials matched on device registry.");
      }
    }

    // --- ONLINE SERVER Handshake HANDLER ---
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data as Map<String, dynamic>;

      // FIXED: Safely reads the exact access_token map field returned by your NestJS logging
      final serverToken = data['access_token'];
      final userPayload = data['user'];

      if (serverToken != null && userPayload != null) {
        await _storage.write(key: 'jwt_token', value: serverToken.toString());

        // Sanitize raw server responses to prevent case variability bugs
        final String checkedRole =
            (userPayload['role'] ?? 'USER').toString().toUpperCase();
        final String standardizedRole =
            checkedRole.contains('VENDOR') ? 'VENDOR' : 'USER';

        await _isar.writeTxn(() async {
          final synchronizedUser = UserModel()
            ..email = email
            ..password = password
            ..name = userPayload['name'] ?? 'User Profile'
            ..role = standardizedRole
            ..shopName = userPayload['shopName']
            ..shopAddress = userPayload['shopAddress']
            ..isSynced = true;

          await _isar.userModels.clear(); // Wipes previous logins cleanly
          await _isar.userModels.put(synchronizedUser);
        });

        return data; // Returns full payload map straight to our provider notifier
      }
    } catch (e) {
      throw Exception(
          "Network unavailable and account not found cached on this device.");
    }
    return null;
  }

  Future<String?> checkAccount(String email) async {
    final localAccount =
        await _isar.userModels.filter().emailEqualTo(email).findFirst();
    if (localAccount != null) {
      return localAccount.role;
    }
    return null;
  }
}
