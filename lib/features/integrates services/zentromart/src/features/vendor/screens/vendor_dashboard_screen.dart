import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/chat/inbox_screen.dart';
import '../providers/vendor_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'vendor_inventory_screen.dart';
import 'vendor_product_form_screen.dart';
import 'vendor_profile_screen.dart'; // Import the settings screen for editing navigation

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(vendorStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(iconTheme: const IconThemeData(color: Colors.black), 
        title: const Text('Store Analytics',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const VendorProfileScreen()))),
          IconButton(
              icon: const Icon(Icons.mail_outline),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const InboxScreen()))),
        ],
      ),
      body: statsAsync.when(
        data: (stats) {
          final totalRevenue =
              double.tryParse(stats['totalRevenue']?.toString() ?? '0') ?? 0.0;

          final int lowStockCount =
              int.tryParse(stats['lowStockCount']?.toString() ?? '0') ?? 0;

          // Safe extraction of the nested shop profile attributes package
          final Map<String, dynamic> profile =
              stats['profile'] as Map<String, dynamic>? ?? {};
          final String shopName = profile['shopName']?.toString() ??
              stats['name']?.toString() ??
              'My Store';
          final String shopAddress =
              profile['shopAddress']?.toString() ?? 'No location configured';
          final String rawAvatarPath = profile['avatarUrl']?.toString() ?? '';

          // Compute full target network path pointing to the static assets port matching NestJS configuration
          final String completeImageUrl =
              "http://10.0.26.26:10000$rawAvatarPath";

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(vendorStatsProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // NEW ADDITION: Premium Storefront Branding Info Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.grey.shade100,
                          child: rawAvatarPath.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: completeImageUrl,
                                    fit: BoxFit.cover,
                                    width: 64,
                                    height: 64,
                                    placeholder: (context, url) =>
                                        const CircularProgressIndicator(
                                            strokeWidth: 2),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.storefront, size: 32),
                                  ),
                                )
                              : const Icon(Icons.storefront,
                                  size: 32, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shopName,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      shopAddress,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.blueAccent, size: 20),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const VendorProfileScreen())),
                        ),
                      ],
                    ),
                  ),

                  // Revenue Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.blue.shade800, Colors.blue.shade600]),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const Text("Total Revenue",
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16)),
                        Text("₱${totalRevenue.toStringAsFixed(2)}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  if (lowStockCount > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.orangeAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.orangeAccent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Warning: You have $lowStockCount item(s) running low or out of stock!",
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const VendorInventoryScreen())),
                            style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact),
                            child: const Text("Fix Now",
                                style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: _buildStatCard(
                              "Products",
                              "${stats['totalProducts'] ?? 0}",
                              Icons.inventory,
                              Colors.blue)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildStatCard(
                              "Pending",
                              "${stats['pendingOrders'] ?? 0}",
                              Icons.pending_actions,
                              Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    leading: const Icon(Icons.inventory_2),
                    title: const Text("Manage Inventory"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const VendorInventoryScreen())),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.cloud_off_rounded,
                        size: 64, color: Colors.blueGrey.shade300),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Analytics are Offline",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "ZentroMart cannot connect to the server right now. You can still manage your storage inventory fields locally.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200)),
                    color: Colors.white,
                    child: ListTile(
                      leading: const Icon(Icons.inventory_2,
                          color: Colors.blueAccent),
                      title: const Text("Open Local Inventory",
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                      subtitle: const Text("Browse, update or delete products"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const VendorInventoryScreen())),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.refresh(vendorStatsProvider),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text("Retry Connection"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const VendorProductFormScreen())),
        label: const Text("Add Product"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
