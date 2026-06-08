// lib/features/profile/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color pageBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color appBarBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color darkText = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        foregroundColor: darkText,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkText),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'App Theme',
              style: TextStyle(
                color: darkText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Customize your viewing experience',
              style: TextStyle(
                color: mutedText,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Column(
                  children: [
                    _ThemeOptionTile(
                      title: 'System Theme',
                      icon: Icons.brightness_auto_rounded,
                      isSelected: themeProvider.themeMode == ThemeMode.system,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                    ),
                    _ThemeOptionTile(
                      title: 'Light Theme',
                      icon: Icons.light_mode_rounded,
                      isSelected: themeProvider.themeMode == ThemeMode.light,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                    ),
                    _ThemeOptionTile(
                      title: 'Dark Theme',
                      icon: Icons.dark_mode_rounded,
                      isSelected: themeProvider.themeMode == ThemeMode.dark,
                      onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color mainGreen = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
    final Color darkText = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    
    final Color defaultBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color selectedBg = isDark ? mainGreen.withValues(alpha: 0.15) : const Color(0xFFF0FDF4);
    final Color defaultBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE5E7EB);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected ? selectedBg : defaultBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? mainGreen : defaultBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? mainGreen : mutedText,
                  size: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? darkText : mutedText,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: mainGreen,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}