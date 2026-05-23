import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../constants/api_constants.dart';

class GoogleAuthService {
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    if (ApiConstants.googleWebClientId.isEmpty) {
      throw Exception(
        'GOOGLE_WEB_CLIENT_ID is missing. Run Flutter with --dart-define=GOOGLE_WEB_CLIENT_ID=your_client_id',
      );
    }

    if (kIsWeb) {
      await GoogleSignIn.instance.initialize(
        clientId: ApiConstants.googleWebClientId,
      );
    } else {
      await GoogleSignIn.instance.initialize(
        serverClientId: ApiConstants.googleWebClientId,
      );
    }

    _initialized = true;
  }

  Future<String> getGoogleIdToken() async {
    await initialize();

    final account = await GoogleSignIn.instance.authenticate();

    final authentication = account.authentication;
    final idToken = authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google ID token was not returned.');
    }

    return idToken;
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
  }
}