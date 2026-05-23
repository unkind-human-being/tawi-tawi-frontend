import 'package:flutter/foundation.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider(this._authRepository);

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _setLoading(true);

    try {
      final currentUser = await _authRepository.getCurrentUser();

      if (currentUser == null) {
        _status = AuthStatus.unauthenticated;
      } else {
        _user = currentUser;
        _status = AuthStatus.authenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
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
    } catch (_) {
      // Still logout locally even if something fails.
    } finally {
      _user = null;
      _status = AuthStatus.unauthenticated;
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }





  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authRepository.loginWithGoogle();

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



  Future<bool> loginWithGoogleIdToken(String idToken) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authRepository.loginWithGoogleIdToken(idToken);

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


  Future<bool> loginWithMeta() async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authRepository.loginWithMeta();

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
}