import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/integrate api services/shu_api_constant.dart';
import '../../auth/auth_provider.dart';
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
  String _message = 'Checking RHU Social Health access...';

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
      _message = 'Checking RHU Social Health access...';
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
              'Please login to your Tawi-Tawi account before opening RHU Social Health.';
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
        _message = result.message.trim().isEmpty
            ? _defaultMessage(result)
            : result.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isChecking = false;
        _hasAccess = false;
        _requiresRegistration = false;
        _message = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _defaultMessage(SocialHealthServiceAccessResult result) {
    if (result.hasAccess) {
      return 'Access granted to RHU Social Health.';
    }

    if (result.requiresRegistration) {
      return 'Your Tawi-Tawi account is not connected to RHU Social Health yet.';
    }

    return 'Unable to verify RHU Social Health access.';
  }

  Future<void> _openCreateRhuAccount() async {
    try {
      final AuthProvider authProvider = context.read<AuthProvider>();

      final String token = authProvider.token ?? '';

      if (token.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login again before creating RHU account.'),
            backgroundColor: Color(0xFFDC2626),
          ),
        );
        return;
      }

      setState(() {
        _isChecking = true;
        _message = 'Creating and linking your RHU Social Health account...';
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
          SnackBar(
            content: Text(
              result.message.trim().isEmpty
                  ? 'RHU account created and linked successfully.'
                  : result.message,
            ),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );

        await _checkAccess();
        return;
      }

      setState(() {
        _isChecking = false;
        _hasAccess = false;
        _requiresRegistration = result.requiresRegistration;
        _message = result.message.trim().isEmpty
            ? 'Unable to create RHU account.'
            : result.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isChecking = false;
        _hasAccess = false;
        _requiresRegistration = true;
        _message = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _openLinkExistingRhuAccount() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Link Existing RHU Account will be added next. For now, use Create RHU Account if this Tawi-Tawi email is new in RHU.',
        ),
        backgroundColor: _primaryBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: _bgBlue,
        body: SafeArea(
          child: Center(
            child: _CheckingAccessView(),
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
                onLinkExisting: _openLinkExistingRhuAccount,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckingAccessView extends StatelessWidget {
  const _CheckingAccessView();

  static const Color _primaryBlue = Color(0xFF0EA5E9);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);

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
        child: const Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 54,
                height: 54,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  color: _primaryBlue,
                ),
              ),
              SizedBox(height: 22),
              Text(
                'Checking Access',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait while we verify your RHU Social Health access through the Tawi-Tawi backend gateway.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textMuted,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
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
    required this.onLinkExisting,
  });

  static const Color _primaryBlue = Color(0xFF0EA5E9);
  static const Color _darkBlue = Color(0xFF075985);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);

  final String message;
  final bool requiresRegistration;
  final Future<void> Function() onRetry;
  final VoidCallback onCreateAccount;
  final VoidCallback onLinkExisting;

  @override
  Widget build(BuildContext context) {
    final String title = requiresRegistration
        ? 'Connect RHU Social Health'
        : 'Access Check Failed';

    final String description = requiresRegistration
        ? 'Your Tawi-Tawi account was found, but it is not connected to RHU Social Health yet.'
        : 'We could not verify your RHU Social Health access. You may retry or contact the RHU administrator.';

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
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                requiresRegistration
                    ? Icons.link_rounded
                    : Icons.warning_amber_rounded,
                color: _primaryBlue,
                size: 46,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: _textDark,
                fontSize: 27,
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
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _MessageBox(
              message: message,
            ),
            const SizedBox(height: 22),
            if (requiresRegistration) ...<Widget>[
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: onCreateAccount,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text(
                  'Create RHU Account',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                onPressed: onLinkExisting,
                icon: const Icon(Icons.verified_user_rounded),
                label: const Text(
                  'I already have an RHU account',
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
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Check Again',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF0EA5E9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
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