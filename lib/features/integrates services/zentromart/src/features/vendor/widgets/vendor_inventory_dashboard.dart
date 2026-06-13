import 'package:flutter/material.dart';
import '../../products/product.dart'; // Adjust based on your product model location

class VendorInventoryDashboard extends StatelessWidget {
  final List<Product> vendorProducts;

  const VendorInventoryDashboard({super.key, required this.vendorProducts});

  @override
  Widget build(BuildContext context) {
    // 1. Calculate statistics reactively from the state array
    final int totalItems = vendorProducts.length;
    final int lowStockCount =
        vendorProducts.where((p) => p.stock <= 3 && p.stock > 0).length;
    final int outOfStockCount =
        vendorProducts.where((p) => p.stock == 0).length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Inventory Health Overview",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Total Catalog Count Card
              Expanded(
                child: _buildStatCard(
                  title: "Active Products",
                  value: totalItems.toString(),
                  color: Colors.blueAccent,
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 12),
              // Low Stock Reactive Alarm Card
              Expanded(
                child: _buildStatCard(
                  title: "Low Stock Alert",
                  value: lowStockCount.toString(),
                  color: lowStockCount > 0 ? Colors.orangeAccent : Colors.green,
                  icon: Icons.running_with_errors_outlined,
                ),
              ),
              const SizedBox(width: 12),
              // Out of Stock Alarm Card
              Expanded(
                child: _buildStatCard(
                  title: "Out of Stock",
                  value: outOfStockCount.toString(),
                  color: outOfStockCount > 0
                      ? Colors.redAccent
                      : Colors.grey.shade400,
                  icon: Icons.gpp_bad_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
