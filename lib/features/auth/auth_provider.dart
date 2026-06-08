import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  static const platform = MethodChannel('com.rhyn.reach/messaging');

  final AuthRepository _authRepository;

  AuthProvider(this._authRepository);

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  String get userName {
    final UserModel? currentUser = _user;
    if (currentUser == null) return '';
    return currentUser.fullName;
  }

  String get userEmail {
    final UserModel? currentUser = _user;
    if (currentUser == null) return '';
    return currentUser.email;
  }

  Future<void> initialize() async {
    try {
      final UserModel? currentUser = await _authRepository.getCurrentUser();
      final String? savedToken = await _authRepository.getToken();

      if (currentUser == null ||
          savedToken == null ||
          savedToken.trim().isEmpty) {
        _user = null;
        _token = null;
        _status = AuthStatus.unauthenticated;
      } else {
        _user = currentUser;
        _token = savedToken;
        _status = AuthStatus.authenticated;
        _syncToNative(currentUser, savedToken);

        // Refresh in background without blocking UI
        _authRepository.refreshUser().then((user) {
          if (user != null) {
            _user = user;
            notifyListeners();
          }
        }).catchError((_) {});
      }
    } catch (_) {
      _user = null;
      _token = null;
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authRepository.register(
        fullName: fullName,
        email: email,
        password: password,
      );

      _token = await _authRepository.getToken();

      _status = AuthStatus.authenticated;
      if (_user != null && _token != null) {
        _syncToNative(_user!, _token!);
      }

      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _cleanError(error);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authRepository.login(
        email: email,
        password: password,
      );

      _token = await _authRepository.getToken();

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _cleanError(error);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile({
    required String fullName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authRepository.updateProfile(fullName: fullName);
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _cleanError(error);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authRepository.logout();
      await platform.invokeMethod('syncSession', {
        'userId': null,
        'username': null,
        'token': null,
      });
    } catch (_) {
      // Still logout locally even if something fails.
    } finally {
      _user = null;
      _token = null;
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authRepository.loginWithGoogle();

      _token = await _authRepository.getToken();

      _status = AuthStatus.authenticated;
      if (_user != null && _token != null) {
        _syncToNative(_user!, _token!);
      }
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _cleanError(error);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithGoogleIdToken(String idToken) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authRepository.loginWithGoogleIdToken(idToken);

      _token = await _authRepository.getToken();

      _status = AuthStatus.authenticated;
      if (_user != null && _token != null) {
        _syncToNative(_user!, _token!);
      }
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _cleanError(error);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithMeta() async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authRepository.loginWithMeta();

      _token = await _authRepository.getToken();

      _status = AuthStatus.authenticated;
      if (_user != null && _token != null) {
        _syncToNative(_user!, _token!);
      }
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _cleanError(error);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _cleanError(Object e) {
    if (e.toString().contains('Invalid token')) {
      return 'Session expired. Please login again.';
    }

    return e.toString().replaceAll('Exception: ', '');
  }

  Future<void> _syncToNative(UserModel user, String token) async {
    try {
      await platform.invokeMethod('syncSession', {
        'userId': user.id,
        'username': user.fullName,
        'token': token,
      });
    } catch (e) {
      debugPrint("Failed to sync session natively: $e");
    }
  }
}