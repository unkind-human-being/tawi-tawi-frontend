import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/chat/inbox_screen.dart';
import '../providers/vendor_provider.dart';
import 'vendor_inventory_screen.dart';
import 'vendor_product_form_screen.dart';
import 'vendor_profile_screen.dart';
import 'vendor_orders_screen.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(vendorStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Soft cool grey background
      body: statsAsync.when(
        data: (stats) {
          final totalRevenue = double.tryParse(stats['totalRevenue']?.toString() ?? '0') ?? 0.0;
          final int lowStockCount = int.tryParse(stats['lowStockCount']?.toString() ?? '0') ?? 0;
          final int pendingOrders = int.tryParse(stats['pendingOrders']?.toString() ?? '0') ?? 0;
          final int totalProducts = int.tryParse(stats['totalProducts']?.toString() ?? '0') ?? 0;

          final Map<String, dynamic> profile = stats['profile'] as Map<String, dynamic>? ?? {};
          final String shopName = profile['shopName']?.toString() ?? stats['name']?.toString() ?? 'My Store';
          final String rawAvatarPath = profile['avatarUrl']?.toString() ?? '';
          final String completeImageUrl = "http://10.0.26.26:10000$rawAvatarPath";

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(vendorStatsProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Premium Gradient App Bar & Profile Header
                SliverAppBar(
                  expandedHeight: 220.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.blue.shade900,
                  iconTheme: const IconThemeData(color: Colors.white),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.mail_outline, color: Colors.white),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InboxScreen())),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Colors.white),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorProfileScreen())),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade900, Colors.blue.shade600],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
                                ),
                                child: CircleAvatar(
                                  radius: 34,
                                  backgroundColor: Colors.white,
                                  child: rawAvatarPath.isNotEmpty
                                      ? ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: completeImageUrl,
                                            fit: BoxFit.cover,
                                            width: 68,
                                            height: 68,
                                            errorWidget: (context, url, error) => const Icon(Icons.storefront, size: 34, color: Colors.grey),
                                          ),
                                        )
                                      : Icon(Icons.storefront, size: 34, color: Colors.blue.shade900),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shopName,
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.star, size: 12, color: Colors.amber),
                                          SizedBox(width: 4),
                                          Text("4.9 Rating", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -15),
                    child: Column(
                      children: [
                        // Overlapping Main Revenue Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Total Revenue", style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w600)),
                                    Icon(Icons.trending_up, color: Colors.green.shade500, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "₱${totalRevenue.toStringAsFixed(2)}",
                                  style: const TextStyle(color: Colors.black87, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMiniStatCard("Products", "$totalProducts", Icons.inventory_2_outlined, Colors.purple),
                                    ),
                                    Container(width: 1, height: 40, color: const Color(0xFFEEEEEE)),
                                    Expanded(
                                      child: _buildMiniStatCard("Pending", "$pendingOrders", Icons.local_shipping_outlined, Colors.orange),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Low Stock Warning
                        if (lowStockCount > 0)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED), // Soft orange bg
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFFEDD5)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                    child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Low Stock Alert", style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text("$lowStockCount products need restock", style: TextStyle(color: Colors.orange.shade800, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorInventoryScreen())),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade600,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    child: const Text("Fix", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                            ),
                          ),

                        // App Tools Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Store Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 4,
                                  childAspectRatio: 0.85,
                                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                                  mainAxisSpacing: 24,
                                  crossAxisSpacing: 12,
                                  children: [
                                    _buildModernTool(context, "Products", Icons.inventory_2, const Color(0xFF3B82F6), () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorInventoryScreen()));
                                    }),
                                    _buildModernTool(context, "Orders", Icons.receipt_long, const Color(0xFFF59E0B), () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorOrdersScreen()));
                                    }),
                                    _buildModernTool(context, "Finance", Icons.account_balance_wallet, const Color(0xFF10B981), () {
                                      _showComingSoon(context, "Finance Center");
                                    }),
                                    _buildModernTool(context, "Marketing", Icons.campaign, const Color(0xFFEF4444), () {
                                      _showComingSoon(context, "Marketing Tools");
                                    }),
                                    _buildModernTool(context, "Analytics", Icons.insert_chart, const Color(0xFF8B5CF6), () {
                                      _showComingSoon(context, "Store Analytics");
                                    }),
                                    _buildModernTool(context, "Shop Decor", Icons.format_paint, const Color(0xFFEC4899), () {
                                      _showComingSoon(context, "Shop Decoration");
                                    }),
                                    _buildModernTool(context, "Help", Icons.support_agent, const Color(0xFF06B6D4), () {
                                      _showComingSoon(context, "Seller Support");
                                    }),
                                    _buildModernTool(context, "Settings", Icons.settings, const Color(0xFF64748B), () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorProfileScreen()));
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 80), // Fab space
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
        error: (err, _) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.redAccent))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorProductFormScreen())),
        label: const Text("Add Product", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        icon: const Icon(Icons.add_circle_outline),
      ),
    );
  }

  Widget _buildMiniStatCard(String title, String value, IconData icon, Color iconColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildModernTool(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$feature is coming soon!", style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blueGrey.shade900,
      ),
    );
  }
}
