import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../providers/vendor_provider.dart'; // Points to your consolidated providers file

class VendorOrdersScreen extends ConsumerWidget {
  const VendorOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watches our strongly-typed VendorOrder objects list pipeline
    final ordersAsync = ref.watch(vendorOrdersProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(iconTheme: const IconThemeData(color: Colors.black), 
        title: const Text("Manage Orders",
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("No orders found.",
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(vendorOrdersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                // FIXED: Treat order as a VendorOrder class model instanced object type
                final order = orders[index];
                final orderId = order.id;
                final currentStatus = order.status.toUpperCase();
                final total = order.price * order.quantity;

                final String dateString =
                    order.createdAt.toLocal().toString().split(' ')[0];

                // Status color coding mapping structures matching NestJS design architecture
                Color statusColor = Colors.orange;
                if (currentStatus == 'PAID') statusColor = Colors.blue;
                if (currentStatus == 'SHIPPED') statusColor = Colors.purple;
                if (currentStatus == 'DELIVERED') statusColor = Colors.green;
                if (currentStatus == 'CANCELLED') statusColor = Colors.red;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              orderId.length > 8
                                  ? "Order #${orderId.substring(0, 8).toUpperCase()}"
                                  : "Order #${orderId.toUpperCase()}",
                              style: const TextStyle(color: Colors.black87, 
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                currentStatus,
                                style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("Product: ${order.productName}",
                            style: const TextStyle(color: Colors.black87, 
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text("Customer: ${order.customerName}",
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 13)),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Placed on: $dateString",
                                style: const TextStyle(color: Colors.grey)),
                            Text("₱${total.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 16)),
                          ],
                        ),
                        const Divider(height: 24),

                        // Action Buttons mapped directly back to Prisma database OrderStatus structures
                        const Text("Update Status Pipeline:",
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _statusButton(
                                  "Ship",
                                  Colors.purple,
                                  currentStatus == 'PENDING',
                                  () => _updateStatus(
                                      context, ref, orderId, 'SHIPPED')),
                              const SizedBox(width: 8),
                              _statusButton(
                                  "Deliver",
                                  Colors.green,
                                  currentStatus == 'SHIPPED',
                                  () => _updateStatus(
                                      context, ref, orderId, 'DELIVERED')),
                              const SizedBox(width: 8),
                              _statusButton(
                                  "Cancel",
                                  Colors.red,
                                  currentStatus == 'PENDING',
                                  () => _updateStatus(
                                      context, ref, orderId, 'CANCELLED')),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _statusButton(
      String label, Color color, bool isEnabled, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: isEnabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? color : Colors.grey.shade300,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  // Helper method directly utilizing dioProvider to securely patch database fields
  Future<void> _updateStatus(BuildContext context, WidgetRef ref,
      String orderId, String newStatus) async {
    final dio = ref.read(dioProvider);
    try {
      // Direct REST API integration with your verified NestJS orders routing controller
      await dio.patch('/orders/$orderId/status', data: {'status': newStatus});

      // Refresh both the order list and the dashboard stats dynamically
      ref.invalidate(vendorOrdersProvider);
      ref.invalidate(vendorStatsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Order marked as $newStatus successfully!"),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Fulfillment execution failed: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}
