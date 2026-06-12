import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/auth/providers/auth_provider.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/vendor/screens/vendor_dashboard_screen.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/profile/edit_profile_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState == null) {
      return const Scaffold(
        body: Center(child: Text("No active profile session found.")),
      );
    }

    final user = authState.user;
    final String role = user.role.toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // Premium Header
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: Colors.blueAccent.shade700,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent.shade700, Colors.blue.shade600],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40, left: 24, right: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 40, color: Colors.blueGrey),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: const TextStyle(fontSize: 13, color: Colors.white70),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  role == 'VENDOR' ? '🏅 Zentro Vendor' : '🛍️ Zentro Member',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          onPressed: () => _showComingSoon(context),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Body Content
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Column(
                children: [
                  // Wallet & Points Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(Icons.account_balance_wallet, "ZentroPay", "₱0.00", Colors.blueAccent),
                          Container(width: 1, height: 40, color: Colors.grey.shade200),
                          _buildStatItem(Icons.generating_tokens, "Zentro Coins", "0", Colors.orange.shade600),
                          Container(width: 1, height: 40, color: Colors.grey.shade200),
                          _buildStatItem(Icons.local_offer, "Vouchers", "2", Colors.redAccent),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("My Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              _buildListTile(
                                icon: Icons.person_outline,
                                color: Colors.blueAccent,
                                title: "Account Details",
                                subtitle: "Edit your profile & password",
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditProfileScreen(currentUser: {
                                      'name': user.name,
                                      'email': user.email,
                                      'role': role,
                                      'shopName': user.shopName,
                                      'shopAddress': user.shopAddress
                                    }),
                                  ),
                                ),
                              ),
                              const Divider(height: 1, indent: 60),
                              _buildListTile(
                                icon: Icons.location_on_outlined,
                                color: Colors.green,
                                title: "Delivery Address",
                                subtitle: user.shopAddress ?? "Add your shipping address",
                                onTap: () => _showComingSoon(context),
                              ),
                              const Divider(height: 1, indent: 60),
                              _buildListTile(
                                icon: Icons.payment,
                                color: Colors.orange,
                                title: "Payment Methods",
                                subtitle: "Manage your linked cards & GCash",
                                onTap: () => _showComingSoon(context),
                              ),
                            ],
                          ),
                        ),

                        if (role == 'VENDOR') ...[
                          const SizedBox(height: 24),
                          const Text("Seller Tools", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.purple.shade100),
                            ),
                            child: _buildListTile(
                              icon: Icons.storefront,
                              color: Colors.purple,
                              title: "Vendor Dashboard",
                              subtitle: "Manage your products and orders",
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorDashboardScreen())),
                              isHighlight: true,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        const Text("Support", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              _buildListTile(
                                icon: Icons.help_outline,
                                color: Colors.blueGrey,
                                title: "Help Center",
                                subtitle: "Get assistance with your orders",
                                onTap: () => _showComingSoon(context),
                              ),
                              const Divider(height: 1, indent: 60),
                              _buildListTile(
                                icon: Icons.info_outline,
                                color: Colors.grey.shade600,
                                title: "About ZentroMart",
                                subtitle: "Version 1.0.0",
                                onTap: () => _showAboutDialog(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isHighlight = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isHighlight ? color : Colors.black87)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Coming soon!", style: TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(24),
          title: const Column(
            children: [
              Icon(Icons.storefront, size: 60, color: Colors.blueAccent),
              SizedBox(height: 16),
              Text("ZentroMart", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87)),
              Text("Version 1.0.0", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Welcome to ZentroMart, your ultimate multi-vendor e-commerce destination built right inside Tawi-Tawi!\n\n"
                "Shop the best deals, connect directly with local sellers, and experience seamless, secure shopping.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFEEEEEE)),
              const SizedBox(height: 12),
              const Text("Developed by the ZentroMart Team", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
