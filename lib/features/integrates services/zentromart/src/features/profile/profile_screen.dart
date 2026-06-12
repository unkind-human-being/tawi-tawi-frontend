import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/auth/providers/auth_provider.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/vendor/screens/vendor_dashboard_screen.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/profile/edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read directly from your verified active session state
    final authState = ref.watch(authProvider);

    // If there's no active session, show a clean fallback screen
    if (authState == null) {
      return const Scaffold(
        body: Center(child: Text("No active profile session found.")),
      );
    }

    // FIXED: Removed '!' because authState.user is already non-nullable in AuthResponse
    final user = authState.user;

    // FIXED: Removed '?.' and '??' because role is a non-nullable String in the User model
    final String role = user.role.toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(iconTheme: const IconThemeData(color: Colors.black), 
        title: const Text("My Profile",
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                const CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.blueGrey,
                    child: Icon(Icons.person, size: 50, color: Colors.white)),
                const SizedBox(height: 16),
                // FIXED: Removed '??' because name is non-nullable
                Text(user.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                // FIXED: Removed '??' because email is non-nullable
                Text(user.email, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Chip(
                  label: Text(role,
                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                  backgroundColor: role == 'VENDOR'
                      ? Colors.purple.shade50
                      : Colors.blue.shade50,
                  labelStyle: TextStyle(
                      color: role == 'VENDOR' ? Colors.purple : Colors.blue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account & Settings Section
          _buildActionCard(context, [
            _buildTile(
                Icons.edit,
                "Edit Profile & Address",
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EditProfileScreen(currentUser: {
                              'name': user.name,
                              'email': user.email,
                              'role': role,
                              'shopName': user.shopName,
                              'shopAddress': user.shopAddress
                            })))),
            _buildTile(Icons.location_on,
                "Delivery Address: ${user.shopAddress ?? 'Not set'}", 
                () => _showComingSoon(context)),
          ]),

          if (role == 'VENDOR') ...[
            const SizedBox(height: 16),
            _buildActionCard(context, [
              _buildTile(
                  Icons.dashboard,
                  "Vendor Dashboard",
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const VendorDashboardScreen())),
                  color: Colors.deepPurple),
            ]),
          ],

          const SizedBox(height: 16),
          _buildActionCard(context, [
            _buildTile(Icons.settings, "App Settings", () => _showComingSoon(context)),
          ]),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(children: children),
    );
  }

  Widget _buildTile(IconData icon, String title, VoidCallback onTap,
      {Color color = Colors.blueAccent}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Coming soon!"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
