import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;
import 'package:provider/provider.dart';

import '../../core/constants/api_constants.dart';
import 'auth_provider.dart';

class GoogleWebButton extends StatefulWidget {
  final VoidCallback onSuccess;

  const GoogleWebButton({
    super.key,
    required this.onSuccess,
  });

  @override
  State<GoogleWebButton> createState() => _GoogleWebButtonState();
}

class _GoogleWebButtonState extends State<GoogleWebButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeGoogle();
  }

  Future<void> _initializeGoogle() async {
    if (_initialized) return;

    if (ApiConstants.googleWebClientId.isEmpty ||
        ApiConstants.googleWebClientId == 'YOUR_CLIENT_ID_HERE') {
      return;
    }

    final signIn = GoogleSignIn.instance;

    await signIn.initialize(
      clientId: ApiConstants.googleWebClientId,
    );

    _subscription = signIn.authenticationEvents.listen(
      _handleAuthenticationEvent,
      onError: _handleAuthenticationError,
    );

    _initialized = true;
  }

  Future<void> _handleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    final user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    if (user == null) return;

    final idToken = user.authentication.idToken;

    if (idToken == null || idToken.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google ID token was not returned.'),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.loginWithGoogleIdToken(idToken);

    if (!mounted) return;

    if (success) {
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Google login failed.'),
        ),
      );
    }
  }

  void _handleAuthenticationError(Object error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Google login error: $error'),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ApiConstants.googleWebClientId.isEmpty ||
        ApiConstants.googleWebClientId == 'YOUR_CLIENT_ID_HERE') {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.g_mobiledata),
          label: const Text('Google Client ID Missing'),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Center(
        child: web.renderButton(),
      ),
    );
  }
}