import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/integrate api services/shu/shu_api_constant.dart';
import '../../../auth/auth_provider.dart';
import 'social_health_api_service.dart';
import 'social_health_updates_screen.dart';

class SocialHealthGatewayScreen extends StatefulWidget {
  const SocialHealthGatewayScreen({
    super.key,
  });

  static const String routeName = '/social-health-gateway';

  @override
  State<SocialHealthGatewayScreen> createState() =>
      _SocialHealthGatewayScreenState();
}

class _SocialHealthGatewayScreenState extends State<SocialHealthGatewayScreen> {
  static const Color _primaryBlue = Color(0xFF0EA5E9);
  static const Color _bgBlue = Color(0xFFEFF6FF);

  final SocialHealthApiService _apiService = SocialHealthApiService();

  bool _isChecking = true;
  bool _hasAccess = false;
  bool _requiresRegistration = false;

  String _message = 'We are checking your Social Health access.';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAccess();
    });
  }

  Future<void> _checkAccess() async {
    setState(() {
      _isChecking = true;
      _hasAccess = false;
      _requiresRegistration = false;
      _message = 'We are checking your Social Health access.';
    });

    try {
      final AuthProvider authProvider = context.read<AuthProvider>();
      final String token = authProvider.token ?? '';

      if (token.trim().isEmpty) {
        setState(() {
          _isChecking = false;
          _hasAccess = false;
          _requiresRegistration = false;
          _message =
              'Please sign in to your Tawi-Tawi account first, then open Social Health again.';
        });

        return;
      }

      final SocialHealthServiceAccessResult result =
          await _apiService.verifyServiceAccess(
        token: token,
        serviceName: ShuApiConstants.serviceName,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isChecking = false;
        _hasAccess = result.hasAccess;
        _requiresRegistration = result.requiresRegistration;
        _message = _friendlyMessage(result);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isChecking = false;
        _hasAccess = false;
        _requiresRegistration = false;
        _message =
            'Social Health is temporarily unavailable. Please check your internet connection and try again.';
      });
    }
  }

  String _friendlyMessage(SocialHealthServiceAccessResult result) {
    if (result.hasAccess) {
      return 'Your Social Health account is ready.';
    }

    if (result.requiresRegistration) {
      return 'Your Tawi-Tawi account is ready. We just need to set up your Social Health profile.';
    }

    final String raw = result.message.toLowerCase();

    if (raw.contains('handshake') ||
        raw.contains('failed') ||
        raw.contains('shu') ||
        raw.contains('authentication')) {
      return 'We cannot connect to Social Health right now. Please try again in a moment.';
    }

    if (result.message.trim().isNotEmpty) {
      return result.message.trim();
    }

    return 'We cannot confirm your Social Health access right now. Please try again.';
  }

  Future<void> _openCreateRhuAccount() async {
    try {
      final AuthProvider authProvider = context.read<AuthProvider>();
      final String token = authProvider.token ?? '';

      if (token.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in again before setting up your account.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }

      setState(() {
        _isChecking = true;
        _message = 'We are setting up your Social Health profile.';
      });

      final SocialHealthServiceAccessResult result =
          await _apiService.registerForService(
        token: token,
        serviceName: ShuApiConstants.serviceName,
        payload: const <String, dynamic>{
          'phoneNumber': '',
        },
      );

      if (!mounted) {
        return;
      }

      if (result.hasAccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your Social Health profile is ready.'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );

        await _checkAccess();
        return;
      }

      setState(() {
        _isChecking = false;
        _hasAccess = false;
        _requiresRegistration = result.requiresRegistration;
        _message = _friendlyMessage(result);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isChecking = false;
        _hasAccess = false;
        _requiresRegistration = true;
        _message =
            'We could not set up your Social Health profile right now. Please try again.';
      });
    }
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: _bgBlue,
        body: SafeArea(
          child: Center(
            child: _CheckingAccessView(
              message: _message,
            ),
          ),
        ),
      );
    }

    if (_hasAccess) {
      return const SocialHealthUpdatesScreen();
    }

    return Scaffold(
      backgroundColor: _bgBlue,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'RHU Social Health',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ),
              child: _AccessRequiredCard(
                message: _message,
                requiresRegistration: _requiresRegistration,
                onRetry: _checkAccess,
                onCreateAccount: _openCreateRhuAccount,
                onBack: _goBack,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckingAccessView extends StatelessWidget {
  const _CheckingAccessView({
    required this.message,
  });

  static const Color _primaryBlue = Color(0xFF0EA5E9);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: const BorderSide(
            color: Color(0xFFBAE6FD),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: _primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Preparing Social Health',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textDark,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textMuted,
                  height: 1.45,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'This will only take a moment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessRequiredCard extends StatelessWidget {
  const _AccessRequiredCard({
    required this.message,
    required this.requiresRegistration,
    required this.onRetry,
    required this.onCreateAccount,
    required this.onBack,
  });

  static const Color _primaryBlue = Color(0xFF0EA5E9);
  static const Color _darkBlue = Color(0xFF075985);
  static const Color _green = Color(0xFF16A34A);
  static const Color _red = Color(0xFFDC2626);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);

  final String message;
  final bool requiresRegistration;
  final Future<void> Function() onRetry;
  final Future<void> Function() onCreateAccount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final String title =
        requiresRegistration ? 'Set Up Social Health' : 'Unable to Connect';

    final String description = requiresRegistration
        ? 'Your Tawi-Tawi account is valid. To continue, we need to create your Social Health profile.'
        : 'Social Health could not be opened right now. This may be caused by a weak connection or a temporary service issue.';

    final IconData heroIcon =
        requiresRegistration ? Icons.health_and_safety_rounded : Icons.wifi_off_rounded;

    final Color heroColor = requiresRegistration ? _green : _red;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: const BorderSide(
          color: Color(0xFFBAE6FD),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 106,
              decoration: BoxDecoration(
                color: requiresRegistration
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                heroIcon,
                color: heroColor,
                size: 54,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style: const TextStyle(
                color: _textDark,
                fontSize: 28,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                color: _textMuted,
                height: 1.45,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            _FriendlyMessageBox(
              message: message,
              iconColor: requiresRegistration ? _green : _primaryBlue,
            ),
            const SizedBox(height: 22),
            if (requiresRegistration) ...<Widget>[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: onCreateAccount,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text(
                  'Set Up My Social Health Profile',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _darkBlue,
                minimumSize: const Size.fromHeight(54),
                side: const BorderSide(
                  color: Color(0xFF7DD3FC),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text(
                'Back',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (!requiresRegistration) ...<Widget>[
              const SizedBox(height: 8),
              const _HelpNote(),
            ],
          ],
        ),
      ),
    );
  }
}

class _FriendlyMessageBox extends StatelessWidget {
  const _FriendlyMessageBox({
    required this.message,
    required this.iconColor,
  });

  final String message;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final String cleanMessage = message.trim().isEmpty
        ? 'Please try again.'
        : message.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline_rounded,
            color: iconColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              cleanMessage,
              style: const TextStyle(
                color: Color(0xFF475569),
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpNote extends StatelessWidget {
  const _HelpNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.lightbulb_outline_rounded,
            color: Color(0xFFD97706),
            size: 21,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Tip: Make sure your internet connection is stable. If this continues, please try again later.',
              style: TextStyle(
                color: Color(0xFF92400E),
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}