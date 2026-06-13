import 'package:flutter/material.dart';


class OrderTimelineCard extends StatelessWidget {
  final dynamic order; // Using dynamic or your OrderModel

  const OrderTimelineCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    // 1. Safely extract values from your model or map
    final String orderId = order['id']?.toString().substring(0, 8).toUpperCase() ?? 'UNKNOWN';
    final String status = (order['status'] ?? 'PENDING').toString().toUpperCase();
    final double total = double.tryParse(order['totalAmount']?.toString() ?? '0') ?? 0.0;
    final List items = order['items'] ?? [];

    // 2. Map status strings to step indices
    int currentStep = 0;
    if (status == 'PREPARING') currentStep = 1;
    if (status == 'SHIPPED') currentStep = 2;
    if (status == 'DELIVERED') currentStep = 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Order #$orderId", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                Text(
                  "₱${total.toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueAccent, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text("${items.length} items ordered", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const Divider(height: 24),

            // Visual Status Timeline Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimelineStep(Icons.receipt_long, "Placed", currentStep >= 0),
                _buildLine(currentStep >= 1),
                _buildTimelineStep(Icons.inventory_2_outlined, "Preparing", currentStep >= 1),
                _buildLine(currentStep >= 2),
                _buildTimelineStep(Icons.local_shipping_outlined, "Shipped", currentStep >= 2),
                _buildLine(currentStep >= 3),
                _buildTimelineStep(Icons.check_circle_outline, "Delivered", currentStep >= 3),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(IconData icon, String label, bool isAchieved) {
    final Color color = isAchieved ? Colors.blueAccent : Colors.grey.shade300;
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: isAchieved ? Colors.blue.shade50 : Colors.grey.shade100,
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isAchieved ? FontWeight.bold : FontWeight.normal,
            color: isAchieved ? Colors.blueGrey.shade900 : Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(bool isAchieved) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4), // Aligns line center to icons
        color: isAchieved ? Colors.blueAccent : Colors.grey.shade300,
      ),
    );
  }
}
