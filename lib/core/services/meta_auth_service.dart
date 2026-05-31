import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class MetaAuthService {
  Future<String> getMetaAccessToken() async {
    final isInitialized = FacebookAuth.i.isWebSdkInitialized;

    if (isInitialized == false) {
      throw Exception(
        'Facebook Web SDK is not initialized. Check META_APP_ID and Meta app settings.',
      );
    }

    final result = await FacebookAuth.instance.login(
      permissions: [
        'email',
        'public_profile',
      ],
    );

    if (result.status != LoginStatus.success) {
      throw Exception(result.message ?? 'Meta login was cancelled.');
    }

    final accessToken = result.accessToken;

    if (accessToken == null) {
      throw Exception('Meta access token was not returned.');
    }

    final tokenString = accessToken.tokenString;

    if (tokenString.isEmpty) {
      throw Exception('Meta access token is empty.');
    }

    return tokenString;
  }

  Future<void> signOut() async {
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {
      // Ignore logout error.
    }
  }
}