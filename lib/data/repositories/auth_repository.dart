import '../../core/services/google_auth_service.dart';
import '../../core/services/meta_auth_service.dart';
import '../../core/services/secure_storage_service.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';

class AuthRepository {
  final AuthApiService _authApiService;
  final SecureStorageService _secureStorageService;
  final GoogleAuthService _googleAuthService;
  final MetaAuthService _metaAuthService;

  AuthRepository({
    required AuthApiService authApiService,
    required SecureStorageService secureStorageService,
    required GoogleAuthService googleAuthService,
    required MetaAuthService metaAuthService,
  })  : _authApiService = authApiService,
        _secureStorageService = secureStorageService,
        _googleAuthService = googleAuthService,
        _metaAuthService = metaAuthService;

  Future<String?> getToken() async {
    return _secureStorageService.getToken();
  }

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> response = await _authApiService.register(
      fullName: fullName,
      email: email,
      password: password,
    );

    return _saveAuthResponse(response);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> response = await _authApiService.login(
      email: email,
      password: password,
    );

    return _saveAuthResponse(response);
  }

  Future<UserModel> loginWithGoogle() async {
    final String idToken = await _googleAuthService.getGoogleIdToken();

    final Map<String, dynamic> response = await _authApiService.loginWithGoogle(
      idToken: idToken,
    );

    return _saveAuthResponse(response);
  }

  Future<UserModel> loginWithGoogleIdToken(String idToken) async {
    final Map<String, dynamic> response = await _authApiService.loginWithGoogle(
      idToken: idToken,
    );

    return _saveAuthResponse(response);
  }

  Future<UserModel> loginWithMeta() async {
    final String accessToken = await _metaAuthService.getMetaAccessToken();

    final Map<String, dynamic> response = await _authApiService.loginWithMeta(
      accessToken: accessToken,
    );

    return _saveAuthResponse(response);
  }

  Future<UserModel?> getCurrentUser() async {
    final String? token = await _secureStorageService.getToken();

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return await _secureStorageService.getUser();
  }

  Future<UserModel?> refreshUser() async {
    final String? token = await _secureStorageService.getToken();

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> response = await _authApiService.getMe(
        token: token,
      );

      final dynamic data = response['data'];

      if (data is! Map<String, dynamic>) {
        return await _secureStorageService.getUser();
      }

      final dynamic userJson = data['user'];

      if (userJson is! Map<String, dynamic>) {
        return await _secureStorageService.getUser();
      }

      final UserModel user = UserModel.fromJson(userJson);

      await _secureStorageService.saveAuthSession(
        token: token,
        user: user,
      );

      return user;
    } catch (_) {
      final UserModel? savedUser = await _secureStorageService.getUser();

      if (savedUser != null) {
        return savedUser;
      }

      await _secureStorageService.clearSession();
      return null;
    }
  }

  Future<UserModel> updateProfile({
    required String fullName,
  }) async {
    final String? token = await _secureStorageService.getToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Authentication token is missing.');
    }

    final Map<String, dynamic> response = await _authApiService.updateMe(
      token: token,
      fullName: fullName,
    );

    final dynamic data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid profile update response.');
    }

    final dynamic userJson = data['user'];

    if (userJson is! Map<String, dynamic>) {
      throw Exception('User data was not returned.');
    }

    final UserModel user = UserModel.fromJson(userJson);

    await _secureStorageService.saveAuthSession(
      token: token,
      user: user,
    );

    return user;
  }

  Future<void> logout() async {
    final String? token = await _secureStorageService.getToken();

    await _secureStorageService.clearSession();

    try {
      if (token != null && token.trim().isNotEmpty) {
        await _authApiService.logout(token: token);
      }
    } catch (_) {
      // Ignore backend logout errors.
    }

    try {
      await _googleAuthService.signOut();
    } catch (_) {
      // Ignore Google logout errors.
    }

    try {
      await _metaAuthService.signOut();
    } catch (_) {
      // Ignore Meta logout errors.
    }
  }

  Future<UserModel> _saveAuthResponse(Map<String, dynamic> response) async {
    final dynamic data = response['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid authentication response.');
    }

    final dynamic token = data['token'];
    final dynamic userJson = data['user'];

    if (token == null || token.toString().trim().isEmpty) {
      throw Exception('Authentication token was not returned.');
    }

    if (userJson is! Map<String, dynamic>) {
      throw Exception('User data was not returned.');
    }

    final UserModel user = UserModel.fromJson(userJson);

    await _secureStorageService.saveAuthSession(
      token: token.toString(),
      user: user,
    );

    return user;
  }
}