// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../auth/login_screen.dart';
import 'about_screen.dart';
import 'settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color darkText = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color buttonColor = isDark ? const Color(0xFF14B8A6) : const Color(0xFF064E3B);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Log out?',
            style: TextStyle(
              color: darkText,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'You will be returned to the login screen.',
            style: TextStyle(color: mutedText),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: mutedText),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    final AuthProvider authProvider = context.read<AuthProvider>();

    await authProvider.logout();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mainGreen = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$title will be added next.',
          style: TextStyle(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: mainGreen,
      ),
    );
  }

  String _getInitials(String name) {
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

  @override
  Widget build(BuildContext context) {
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final String fullName = user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : 'Public User';

    final String email = user?.email.trim().isNotEmpty == true
        ? user!.email.trim()
        : 'No email';

    final String status = user?.status.trim().isNotEmpty == true
        ? user!.status.trim()
        : 'Active';

    final String initials = _getInitials(fullName);

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: <Widget>[
                const _AccountAppBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    children: <Widget>[
                      _AccountHeader(
                        fullName: fullName,
                        email: email,
                        initials: initials,
                        status: status,
                      ),
                      const SizedBox(height: 24),
                      _AccountMenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Personal Information',
                        subtitle: 'View your name, email, and account status',
                        onTap: () {
                          _showPersonalInfoSheet(
                            context: context,
                            fullName: fullName,
                            email: email,
                            status: status,
                            userId: user?.id ?? 'N/A',
                          );
                        },
                      ),
                      _AccountMenuItem(
                        icon: Icons.help_outline_rounded,
                        title: 'FAQs',
                        subtitle: 'Frequently asked questions',
                        onTap: () {
                          _showComingSoon(context, 'FAQs');
                        },
                      ),
                      _AccountMenuItem(
                        icon: Icons.info_outline_rounded,
                        title: 'About Kawman',
                        subtitle: 'Learn about this public portal',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutScreen(),
                            ),
                          );
                        },
                      ),
                      _AccountMenuItem(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Notice',
                        subtitle: 'How your account information is handled',
                        onTap: () {
                          _showInfoSheet(
                            context,
                            title: 'Privacy Notice',
                            message:
                                'Your account information is used only for login, profile access, and app-related services. RHU Social Health has a separate login and account session.',
                          );
                        },
                      ),
                      _AccountMenuItem(
                        icon: Icons.call_outlined,
                        title: 'Contact Us',
                        subtitle: 'Reach the app support team',
                        onTap: () {
                          _showInfoSheet(
                            context,
                            title: 'Contact Us',
                            message:
                                'For support, contact your system administrator or the assigned Kawman app support team.',
                          );
                        },
                      ),
                      _AccountMenuItem(
                        icon: Icons.thumb_up_alt_outlined,
                        title: 'Rate our app',
                        subtitle: 'Share feedback about your experience',
                        onTap: () {
                          _showComingSoon(context, 'Rate our app');
                        },
                      ),
                      _AccountMenuItem(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        subtitle: 'Manage app preferences',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _AccountMenuItem(
                        icon: Icons.logout_rounded,
                        title: 'Log out',
                        subtitle: 'Sign out from your Tawi-Tawi account',
                        isDanger: true,
                        onTap: () {
                          _logout(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPersonalInfoSheet({
    required BuildContext context,
    required String fullName,
    required String email,
    required String status,
    required String userId,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color darkText = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color buttonColor = isDark ? const Color(0xFF14B8A6) : const Color(0xFF064E3B);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _BottomSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const _SheetHandle(),
              const SizedBox(height: 14),
              Text(
                'Personal Information',
                style: TextStyle(
                  color: darkText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              _InfoRow(
                icon: Icons.person_rounded,
                label: 'Full Name',
                value: fullName,
              ),
              _InfoRow(
                icon: Icons.email_rounded,
                label: 'Email',
                value: email,
              ),
              _InfoRow(
                icon: Icons.verified_user_rounded,
                label: 'Status',
                value: status.toUpperCase(),
              ),
              _InfoRow(
                icon: Icons.badge_rounded,
                label: 'User ID',
                value: userId,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInfoSheet(
    BuildContext context, {
    required String title,
    required String message,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color darkText = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color buttonColor = isDark ? const Color(0xFF14B8A6) : const Color(0xFF064E3B);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _BottomSheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const _SheetHandle(),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: darkText,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mutedText,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AccountAppBar extends StatelessWidget {
  const _AccountAppBar();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color darkText = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Center(
        child: Text(
          'Account',
          style: TextStyle(
            color: darkText,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({
    required this.fullName,
    required this.email,
    required this.initials,
    required this.status,
  });

  final String fullName;
  final String email;
  final String initials;
  final String status;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color softGreen = isDark ? const Color(0xFF134E4A) : const Color(0xFFEFFAF5);
    final Color mainGreen = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
    final Color darkText = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(0, 22, 78, 22),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 34,
                backgroundColor: softGreen,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: mainGreen,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Hi, ${fullName.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: darkText,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mainGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: -8,
          top: 8,
          child: _DecorativeMark(),
        ),
      ],
    );
  }
}

class _DecorativeMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color centerColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color innerCircleColor = isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final Color innerBorderColor = isDark ? const Color(0xFF475569) : Colors.grey.shade400;

    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: 8,
            left: 14,
            child: Transform.rotate(
              angle: -0.70,
              child: Container(
                width: 28,
                height: 28,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 20,
            child: Transform.rotate(
              angle: 0.78,
              child: Container(
                width: 24,
                height: 24,
                color: const Color(0xFFFACC15),
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 10,
            child: Transform.rotate(
              angle: 0.78,
              child: Container(
                width: 22,
                height: 22,
                color: const Color(0xFF2563EB),
              ),
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: centerColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
                width: 7,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: innerCircleColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: innerBorderColor,
                width: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountMenuItem extends StatelessWidget {
  const _AccountMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.isDanger = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color darkText = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final Color mainGreen = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
    final Color activeColor = isDanger ? const Color(0xFFEF4444) : mainGreen;
    final Color arrowColor = isDanger ? const Color(0xFFEF4444) : mainGreen;
    final Color dangerText = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 34,
                child: Icon(
                  icon,
                  color: activeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: isDanger ? dangerText : darkText,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: arrowColor,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSheetContainer extends StatelessWidget {
  const _BottomSheetContainer({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color handleColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);

    return Container(
      width: 46,
      height: 5,
      decoration: BoxDecoration(
        color: handleColor,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color rowBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);
    final Color mainGreen = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
    final Color darkText = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            color: mainGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: darkText,
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