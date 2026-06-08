import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/auth_provider.dart';
import '../auth/social_health_auth_provider.dart';

class SocialHealthProfileScreen extends StatelessWidget {
  const SocialHealthProfileScreen({super.key});

  static const String routeName = '/social-health-profile';

  Future<void> _logoutSocialHealth(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Logout from Social Health?',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'This will only log you out from the RHU Social Health module. Your main Tawi-Tawi account can still stay logged in.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await context.read<SocialHealthAuthProvider>().logout();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  void _goToTawiTawiHome(BuildContext context) {
    Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider mainAuth = context.watch<AuthProvider>();
    final SocialHealthAuthProvider socialHealthAuth =
        context.watch<SocialHealthAuthProvider>();

    final dynamic mainUser = mainAuth.user;

    final String mainName = _fallback(
      _readUserString(
        mainUser,
        <String>['fullName', 'name', 'displayName'],
      ),
      fallback: socialHealthAuth.name.isEmpty
          ? 'Tawi-Tawi User'
          : socialHealthAuth.name,
    );

    final String mainEmail = _fallback(
      _readUserString(
        mainUser,
        <String>['email', 'username'],
      ),
      fallback: socialHealthAuth.email.isEmpty
          ? 'No email available'
          : socialHealthAuth.email,
    );

    final String socialName = socialHealthAuth.name.trim().isEmpty
        ? mainName
        : socialHealthAuth.name.trim();

    final String socialEmail = socialHealthAuth.email.trim().isEmpty
        ? mainEmail
        : socialHealthAuth.email.trim();

    final String role = socialHealthAuth.role.trim().isEmpty
        ? 'public_user'
        : socialHealthAuth.role.trim();

    final String status = _socialHealthStatusText(socialHealthAuth.status);

    final String initials = _initials(socialName);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        title: const Text(
          'Social Health Profile',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: <Color>[
                    Color(0xFF0EA5E9),
                    Color(0xFF0284C7),
                  ],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Color(0xFF0EA5E9),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    socialName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    socialEmail,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFE0F2FE),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Text(
                      _prettyEnum(role),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _ProfileSection(
              title: 'Tawi-Tawi Account',
              children: <Widget>[
                _ProfileInfoTile(
                  icon: Icons.person_rounded,
                  label: 'Name',
                  value: mainName,
                ),
                _ProfileInfoTile(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  value: mainEmail,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ProfileSection(
              title: 'Social Health Access',
              children: <Widget>[
                _ProfileInfoTile(
                  icon: Icons.badge_rounded,
                  label: 'RHU Name',
                  value: socialName,
                ),
                _ProfileInfoTile(
                  icon: Icons.alternate_email_rounded,
                  label: 'RHU Email',
                  value: socialEmail,
                ),
                _ProfileInfoTile(
                  icon: Icons.verified_user_rounded,
                  label: 'Role',
                  value: _prettyEnum(role),
                ),
                _ProfileInfoTile(
                  icon: Icons.check_circle_rounded,
                  label: 'Status',
                  value: _prettyEnum(status),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFFDE68A),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFD97706),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This profile is for the RHU Social Health module. Main account settings can be added later in the Tawi-Tawi app profile.',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        height: 1.4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: const Color(0xFF0EA5E9),
                side: const BorderSide(
                  color: Color(0xFF7DD3FC),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text(
                'Back to Social Health',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {
                _goToTawiTawiHome(context);
              },
              icon: const Icon(Icons.home_rounded),
              label: const Text(
                'Go to Tawi-Tawi Home',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {
                _logoutSocialHealth(context);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Logout from Social Health',
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

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(
          color: Color(0xFFBAE6FD),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDBEAFE),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0EA5E9),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.trim().isEmpty ? 'N/A' : value,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _readUserString(
  dynamic user,
  List<String> keys, {
  String fallback = '',
}) {
  if (user == null) {
    return fallback;
  }

  for (final String key in keys) {
    try {
      if (key == 'fullName') {
        final dynamic value = user.fullName;
        final String text = value?.toString().trim() ?? '';
        if (text.isNotEmpty && text != 'null') return text;
      }

      if (key == 'name') {
        final dynamic value = user.name;
        final String text = value?.toString().trim() ?? '';
        if (text.isNotEmpty && text != 'null') return text;
      }

      if (key == 'displayName') {
        final dynamic value = user.displayName;
        final String text = value?.toString().trim() ?? '';
        if (text.isNotEmpty && text != 'null') return text;
      }

      if (key == 'email') {
        final dynamic value = user.email;
        final String text = value?.toString().trim() ?? '';
        if (text.isNotEmpty && text != 'null') return text;
      }

      if (key == 'username') {
        final dynamic value = user.username;
        final String text = value?.toString().trim() ?? '';
        if (text.isNotEmpty && text != 'null') return text;
      }
    } catch (_) {
      // Continue checking other possible fields.
    }
  }

  return fallback;
}

String _fallback(
  String value, {
  required String fallback,
}) {
  if (value.trim().isEmpty || value.trim() == 'null') {
    return fallback;
  }

  return value.trim();
}

String _initials(String name) {
  final List<String> parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((String part) => part.trim().isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return 'U';
  }

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

String _socialHealthStatusText(dynamic status) {
  final String raw = status.toString().trim();

  if (raw.isEmpty || raw == 'null') {
    return 'active';
  }

  final String clean = raw.contains('.') ? raw.split('.').last : raw;

  switch (clean) {
    case 'authenticated':
    case 'success':
    case 'ready':
      return 'active';
    case 'loading':
      return 'loading';
    case 'error':
      return 'error';
    case 'unauthenticated':
      return 'not_connected';
    default:
      return clean;
  }
}

String _prettyEnum(String value) {
  if (value.trim().isEmpty) {
    return 'N/A';
  }

  return value
      .split('_')
      .where((String item) => item.trim().isNotEmpty)
      .map((String item) {
    return item[0].toUpperCase() + item.substring(1);
  }).join(' ');
}