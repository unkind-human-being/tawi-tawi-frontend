import 'package:flutter/material.dart';

// =======================================================
// THE VISUAL TRACKER WIDGET
// Automatically handles logic for coloring the timeline
// =======================================================
class OrderTrackerWidget extends StatelessWidget {
  final String status;

  const OrderTrackerWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == 'CANCELLED') {
      return const Row(
        children: [
          Icon(Icons.cancel, color: Colors.red),
          SizedBox(width: 8),
          Text("Order Cancelled",
              style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ],
      );
    }

    // Determine how many steps are completed based on the string
    int currentStep = 0;
    if (status == 'PROCESSING' || status == 'PAID') currentStep = 1;
    if (status == 'SHIPPED') currentStep = 2;
    if (status == 'DELIVERED') currentStep = 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStep("Placed", Icons.receipt_long, currentStep >= 0),
        _buildLine(currentStep >= 1),
        _buildStep("Processed", Icons.inventory_2, currentStep >= 1),
        _buildLine(currentStep >= 2),
        _buildStep("Shipped", Icons.local_shipping, currentStep >= 2),
        _buildLine(currentStep >= 3),
        _buildStep("Delivered", Icons.check_circle, currentStep >= 3),
      ],
    );
  }

  Widget _buildStep(String label, IconData icon, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor:
              isActive ? Colors.blueGrey.shade900 : Colors.grey.shade200,
          child: Icon(icon,
              color: isActive ? Colors.white : Colors.grey, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 20, left: 4, right: 4),
        color: isActive ? Colors.blueGrey.shade900 : Colors.grey.shade200,
      ),
    );
  }
}
