import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart'; // <-- ADDED THEME IMPORT
import '../../auth/screen/role_selection_screen.dart';
import 'driver_edit_profile_screen.dart'; 

class DriverSettingsScreen extends StatefulWidget {
  final String driverName;
  final String initials;
  final String franchiseNumber;

  const DriverSettingsScreen({
    super.key,
    required this.driverName,
    required this.initials,
    required this.franchiseNumber,
  });

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  late String _currentName;
  late String _currentInitials;

  @override
  void initState() {
    super.initState();
    _currentName = widget.driverName;
    _currentInitials = widget.initials;
  }

  @override
  void didUpdateWidget(DriverSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driverName != widget.driverName) {
      setState(() {
        _currentName = widget.driverName;
        _currentInitials = widget.initials;
      });
    }
  }

  void _handleLogout(BuildContext context) {
    ApiClient.instance.options.headers.remove('Authorization');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false, 
    );
  }

  @override
  Widget build(BuildContext context) {
    // Access the dynamic theme state
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.softBg,
      appBar: AppBar(
        // FIXED: Now uses White in Light Mode, Dark in Dark Mode
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        foregroundColor: context.dynamicText,
        elevation: 0,
        centerTitle: true,
        title: const Text('Account Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48, 
                  backgroundColor: AppColors.deepOcean.withOpacity(0.1), 
                  child: Text(_currentInitials, style: const TextStyle(color: AppColors.deepOcean, fontSize: 36, fontWeight: FontWeight.bold))
                ),
                const SizedBox(height: 16),
                // FIXED: Font uses context.dynamicText
                Text(_currentName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.dynamicText)),
                const SizedBox(height: 4),
                // FIXED: Font uses context.dynamicMuted
                Text('Operator ID: ${widget.franchiseNumber}', style: TextStyle(color: context.dynamicMuted, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          Text('PREFERENCES', style: TextStyle(color: context.dynamicMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          
          _buildSettingsTile(context, Icons.person_outline, 'Edit Profile', onTap: () async {
            final updatedName = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DriverEditProfileScreen(
                  currentName: _currentName,
                  franchiseNumber: widget.franchiseNumber,
                ),
              ),
            );
            
            if (updatedName != null && updatedName is String) {
              setState(() {
                _currentName = updatedName;
                _currentInitials = updatedName.isNotEmpty ? updatedName[0].toUpperCase() : 'D';
              });
            }
          }),
          _buildSettingsTile(context, Icons.lock_outline, 'Change Password'),
          _buildSettingsTile(context, Icons.language, 'Language (English)'),
          
          const SizedBox(height: 24),
          Text('SYSTEM', style: TextStyle(color: context.dynamicMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          _buildSettingsTile(context, Icons.info_outline, 'About Platform'),
          _buildSettingsTile(context, Icons.help_outline, 'Help & Support'),
          const SizedBox(height: 40),
          
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: context.dynamicCard, // FIXED: Dynamic Card Color
            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.logout, color: Colors.redAccent)),
            title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
            onTap: () => _handleLogout(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tileColor: context.dynamicCard, // FIXED: Dynamic Card Color
        leading: Container(
          padding: const EdgeInsets.all(8), 
          decoration: BoxDecoration(color: context.isDarkMode ? AppColors.darkBg : AppColors.softBg, borderRadius: BorderRadius.circular(8)), 
          child: Icon(icon, color: context.dynamicText, size: 20) // FIXED: Icon Color
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: context.dynamicText, fontSize: 15)), // FIXED: Text Color
        trailing: Icon(Icons.arrow_forward_ios, size: 14, color: context.dynamicMuted), // FIXED: Arrow Color
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title coming soon.'), backgroundColor: AppColors.neonTeal, behavior: SnackBarBehavior.floating));
        },
      ),
    );
  }
}