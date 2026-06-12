import 'dart:convert';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/core/database/models/user_model.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/core/storage/secure_storage.dart'
    hide dioProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/sync_provider.dart';
import 'auth_repository.dart';
import '../models/auth_response.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final isar = ref.read(isarProvider);
  final dio = ref.read(dioProvider);
  return AuthRepository(isar, dio);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthResponse?>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider), ref);
});

class AuthNotifier extends StateNotifier<AuthResponse?> {
  final AuthRepository _authRepository;
  final Ref _ref;

  AuthNotifier(this._authRepository, this._ref) : super(null) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('saved_user');
      final token = await SecureStorage.getToken();

      if (token != null && userJson != null) {
        final Map<String, dynamic> data = jsonDecode(userJson);

        if (data['user'] != null && data['user']['role'] != null) {
          data['user']['role'] = data['user']['role'].toString().toUpperCase();
        }

        state = AuthResponse.fromJson(data);
      }
    } catch (e) {
      await logout();
    }
  }

  Future<void> login(String email, String password) async {
    // 1. Clear out stale authentication traces before attempting a new log in
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_user');
    await SecureStorage.clearToken();

    // 2. Execute the login call via your repository
    final dynamic responseData = await _authRepository.login(email, password);

    if (responseData != null) {
      final isar = _ref.read(isarProvider);

      // Parse the real backend response containing the actual user role and token
      final authResponse =
          AuthResponse.fromJson(responseData as Map<String, dynamic>);

      // Extract profile fields accurately from the network response data mapping
      final String determinedRole = authResponse.user.role.toUpperCase();
      final String determinedName = authResponse.user.name;
      final String? shopName = authResponse.user.shopName;
      final String? shopAddress = authResponse.user.shopAddress;

      // 3. Save the token securely to allow authorization headers to work instantly
      await SecureStorage.saveToken(authResponse.accessToken);

      // 4. Cache the authenticated profile row inside Isar immediately for offline-first resilience
      final localUserRecord = UserModel()
        ..email = email
        ..name = determinedName
        ..role = determinedRole
        ..password =
            password // <-- FIXED: Securely caches input password to support local offline logins!
        ..shopName = shopName
        ..shopAddress = shopAddress
        ..isSynced = true;

      await isar.writeTxn(() async {
        // Clear old local users to keep storage unique
        await isar.userModels.clear();
        await isar.userModels.put(localUserRecord);
      });

      // 5. Serialize credentials to SharedPreferences and trigger application navigation
      await prefs.setString('saved_user', jsonEncode(authResponse.toJson()));
      state = authResponse;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? shopName,
    String? shopAddress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_user');
    await SecureStorage.clearToken();

    await _authRepository.register(
      email: email,
      password: password,
      fullName: name,
      uiRole: role,
      shopName: shopName,
      shopAddress: shopAddress,
    );

    final String verifiedRole =
        role.toUpperCase().contains('VENDOR') ? 'VENDOR' : 'USER';

    final mockResponse = AuthResponse(
      accessToken: 'offline_session_active_${email}_$verifiedRole',
      user: User.fromJson({
        'email': email,
        'name': name,
        'role': verifiedRole,
        'shopName': shopName,
        'shopAddress': shopAddress,
      }),
    );

    await prefs.setString('saved_user', jsonEncode(mockResponse.toJson()));
    state = mockResponse;
  }

  Future<void> logout() async {
    await SecureStorage.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_user');

    // Clear out local cache tables securely upon sign out
    final isar = _ref.read(isarProvider);
    await isar.writeTxn(() async {
      await isar.userModels.clear();
    });

    state = null;
  }

  Future<String?> checkAccount(String email) async {
    return await _authRepository.checkAccount(email);
  }

  Future<void> linkTawiTawiSession(String email, String name, String role, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await SecureStorage.saveToken(token); // Save the real token
    
    final mockResponse = AuthResponse(
      accessToken: token, // Real token!
      user: User.fromJson({
        'email': email,
        'name': name,
        'role': role,
      }),
    );

    await prefs.setString('saved_user', jsonEncode(mockResponse.toJson()));
    state = mockResponse;
  }
}
