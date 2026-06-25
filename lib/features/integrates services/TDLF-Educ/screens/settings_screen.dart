import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const _SectionLabel(label: 'Appearance'),
          _buildThemeTile(context, cs),
          const SizedBox(height: 16),
          const _SectionLabel(label: 'Account'),
          _buildAccountCard(context, cs),
          const SizedBox(height: 16),
          const _SectionLabel(label: 'About'),
          _buildAboutCard(context, cs),
        ],
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, ColorScheme cs) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        return _SettingsTile(
          icon: theme.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          title: 'Dark Mode',
          subtitle: theme.isDarkMode ? 'Dark theme active' : 'Light theme active',
          trailing: Switch(
            value: theme.isDarkMode,
            onChanged: theme.setDarkMode,
          ),
        );
      },
    );
  }

  Widget _buildAccountCard(BuildContext context, ColorScheme cs) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.currentUser;
        final username = user?['username'] ?? 'Not signed in';
        final fullName = (user?['full_name'] as String? ?? '').trim();
        final email = user?['email'] ?? '';
        final role = user?['role'] ?? 'Guest';
        final studentId = (user?['student_id'] as String? ?? '').trim();
        final gradeLevel = (user?['grade_level'] as String? ?? '').trim();
        final isStudent = role == 'Student';

        return Column(
          children: [
            _SettingsTile(
              icon: Icons.person_rounded,
              title: 'Username',
              subtitle: username,
            ),
            if (fullName.isNotEmpty)
              _SettingsTile(
                icon: Icons.badge_outlined,
                title: 'Full Name',
                subtitle: fullName,
              ),
            if (email.isNotEmpty)
              _SettingsTile(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: email,
              ),
            if (isStudent && studentId.isNotEmpty)
              _SettingsTile(
                icon: Icons.tag_rounded,
                title: 'Student ID',
                subtitle: studentId,
              ),
            if (isStudent && gradeLevel.isNotEmpty)
              _SettingsTile(
                icon: Icons.school_outlined,
                title: 'Grade Level',
                subtitle: gradeLevel,
              ),
            _SettingsTile(
              icon: Icons.verified_user_outlined,
              title: 'Role',
              subtitle: role,
            ),
            const SizedBox(height: 4),
            _LogoutTile(cs: cs),
          ],
        );
      },
    );
  }

  Widget _buildAboutCard(BuildContext context, ColorScheme cs) {
    return Column(
      children: [
        const _SettingsTile(
          icon: Icons.info_outline_rounded,
          title: 'App Version',
          subtitle: '1.0.0',
        ),
        _SettingsTile(
          icon: Icons.description_outlined,
          title: 'About TDLF-Educ',
          subtitle: 'Tap to learn more',
          onTap: () => showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('About TDLF-Educ'),
              content: const SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'TDLF-Educ is a multiplatform education app for ITE101. '
                      'It supports offline-first usage — download books and take '
                      'quizzes anytime, anywhere.',
                      style: TextStyle(fontSize: 13, height: 1.6),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Features',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Download books for offline reading\n'
                      '• Take quizzes and track progress\n'
                      '• Teacher role: manage books & quizzes\n'
                      '• Teacher role: monitor student scores\n'
                      '• Dark mode support',
                      style: TextStyle(fontSize: 13, height: 1.6),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Developers',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Abdu, Kamrashier Imlani\n'
                      'Jumad, Harsamer Rabah\n'
                      'Isbala, Ali-Risha Marjukin',
                      style: TextStyle(fontSize: 13, height: 1.6),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Components
// ──────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: cs.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: AppDecoration.of(context).softShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: GradientIconBadge(
          icon: icon,
          size: 42,
          iconSize: 20,
          radius: 13,
          shadow: const [],
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        trailing: trailing ?? (onTap != null ? Icon(Icons.arrow_forward_ios_rounded, size: 14, color: cs.onSurfaceVariant) : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final ColorScheme cs;
  const _LogoutTile({required this.cs});

  @override
  Widget build(BuildContext context) {
    final embedded = context.watch<AuthProvider>().isEmbedded;
    // Embedded (Tawi-Tawi): offer both "Back to Tawi-Tawi" (keeps you signed in)
    // and an explicit "Log out". Standalone: just "Logout".
    if (embedded) {
      return Column(
        children: [
          const SizedBox(height: 6),
          _tile(
            context,
            icon: Icons.arrow_back_rounded,
            title: 'Back to Tawi-Tawi',
            subtitle: 'Leave the module — stay signed in',
            onTap: () => Navigator.of(context, rootNavigator: true).maybePop(),
          ),
          const SizedBox(height: 8),
          _tile(
            context,
            icon: Icons.logout_rounded,
            title: 'Log out',
            subtitle: 'Sign out of this TDLF-Educ account',
            onTap: () => _confirmLogout(context, embedded: true),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: _tile(
        context,
        icon: Icons.logout_rounded,
        title: 'Logout',
        subtitle: 'Sign out of your account',
        onTap: () => _confirmLogout(context, embedded: false),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.error.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          title: Text(title,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: cs.error)),
          subtitle: Text(subtitle,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onTap: onTap,
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, {required bool embedded}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cs.error),
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              Navigator.pop(ctx);
              await auth.logout();
              if (!context.mounted) return;
              if (embedded) {
                // Back to the host; re-entering will show the welcome again.
                Navigator.of(context, rootNavigator: true).maybePop();
              } else {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
