import 'package:flutter/foundation.dart';

import '../social_health_api_service.dart';
import '../social_health_secure_storage.dart';

enum SocialHealthAuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

class SocialHealthAuthProvider extends ChangeNotifier {
  SocialHealthAuthProvider({
    SocialHealthApiService? apiService,
    SocialHealthSecureStorage? storage,
  })  : _apiService = apiService ?? SocialHealthApiService(),
        _storage = storage ?? SocialHealthSecureStorage();

  final SocialHealthApiService _apiService;
  final SocialHealthSecureStorage _storage;

  SocialHealthAuthStatus _status = SocialHealthAuthStatus.initial;
  bool _isLoading = false;
  String? _errorMessage;

  String? _token;
  String? _name;
  String? _email;
  String? _role;

  SocialHealthAuthStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get token => _token;
  String get name => _name ?? 'Social Health User';
  String get email => _email ?? '';
  String get role => _role ?? 'public_user';

  Future<void> initialize() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final String? savedToken = await _storage.getToken();

      if (savedToken == null || savedToken.trim().isEmpty) {
        _status = SocialHealthAuthStatus.unauthenticated;
        return;
      }

      final bool valid = await _apiService.checkToken(savedToken);

      if (!valid) {
        await _storage.clearSession();
        _clearSession();
        _status = SocialHealthAuthStatus.unauthenticated;
        return;
      }

      _token = savedToken;
      _name = await _storage.getUserName();
      _email = await _storage.getUserEmail();
      _role = await _storage.getUserRole();

      _status = SocialHealthAuthStatus.authenticated;
    } catch (_) {
      _status = SocialHealthAuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final SocialHealthLoginResult result = await _apiService.login(
        email: email,
        password: password,
      );

      await _storage.saveSession(
        token: result.token,
        name: result.name,
        email: result.email,
        role: result.role,
      );

      _token = result.token;
      _name = result.name;
      _email = result.email;
      _role = result.role;
      _status = SocialHealthAuthStatus.authenticated;

      notifyListeners();

      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _status = SocialHealthAuthStatus.unauthenticated;
      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);

    await _storage.clearSession();

    _clearSession();
    _status = SocialHealthAuthStatus.unauthenticated;

    _setLoading(false);
  }

  void _clearSession() {
    _token = null;
    _name = null;
    _email = null;
    _role = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}