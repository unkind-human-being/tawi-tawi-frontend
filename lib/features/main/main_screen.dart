// lib/features/main/main_screen.dart
import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/history/history_screen.dart';
import '../integrates services/mesh_messaging/app service introduction/inbox_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(onSwitchTab: _onNavTapped),
      const InboxScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];
  }

  void _onNavTapped(int index) {
    if (index >= 0 && index <= 3) {
      setState(() {
        _currentIndex = index;
      });
    } else {
      final bool isDark = Theme.of(context).brightness == Brightness.dark;
      final Color primaryColor = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_getLabel(index)} will be added next.'),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getLabel(int index) {
    switch (index) {
      case 1:
        return 'Message';
      case 2:
        return 'History';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _SharedBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavTapped,
      ),
    );
  }
}

class _SharedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SharedBottomNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color shadowColor = isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05);

    return SafeArea(
      top: false,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _ModernNavButton(
                icon: Icons.space_dashboard_rounded,
                label: 'Home',
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
            ),
            Expanded(
              child: _ModernNavButton(
                icon: Icons.chat_bubble_rounded,
                label: 'Message',
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
            ),
            Expanded(
              child: _ModernNavButton(
                icon: Icons.receipt_long_rounded,
                label: 'History',
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ),
            Expanded(
              child: _ModernNavButton(
                icon: Icons.person_rounded,
                label: 'Account',
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModernNavButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color activeColor = isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E);
    final Color inactiveColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final Color color = isSelected ? activeColor : inactiveColor;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}