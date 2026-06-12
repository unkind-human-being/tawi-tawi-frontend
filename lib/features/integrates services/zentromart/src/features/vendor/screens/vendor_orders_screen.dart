import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../providers/vendor_provider.dart';

class VendorOrdersScreen extends ConsumerWidget {
  const VendorOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(vendorOrdersProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text("Manage Orders", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "All"),
              Tab(text: "Pending"),
              Tab(text: "Shipped"),
              Tab(text: "Completed"),
            ],
          ),
        ),
        body: ordersAsync.when(
          data: (orders) {
            // Filter logic
            List filterOrders(int tabIndex) {
              if (tabIndex == 1) return orders.where((o) => o.status.toUpperCase() == 'PENDING').toList();
              if (tabIndex == 2) return orders.where((o) => o.status.toUpperCase() == 'SHIPPED').toList();
              if (tabIndex == 3) return orders.where((o) => o.status.toUpperCase() == 'DELIVERED').toList();
              return orders;
            }

            return TabBarView(
              children: [
                _buildOrderList(filterOrders(0), ref),
                _buildOrderList(filterOrders(1), ref),
                _buildOrderList(filterOrders(2), ref),
                _buildOrderList(filterOrders(3), ref),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
          error: (err, _) => Center(child: Text("Error: $err")),
        ),
      ),
    );
  }

  Widget _buildOrderList(List orders, WidgetRef ref) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_outlined, size: 60, color: Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            const Text("No orders found", style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("You're all caught up for now!", style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(vendorOrdersProvider),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          final String orderId = order.id;
          final String currentStatus = order.status.toUpperCase();
          final double total = order.price * order.quantity;
          final String dateString = order.createdAt.toLocal().toString().split(' ')[0];

          Color statusColor = Colors.orange;
          if (currentStatus == 'PAID') statusColor = Colors.blue;
          if (currentStatus == 'SHIPPED') statusColor = Colors.purple;
          if (currentStatus == 'DELIVERED') statusColor = Colors.green;
          if (currentStatus == 'CANCELLED') statusColor = Colors.red;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200), bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Order ID & Status)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.blue.shade50,
                            child: const Icon(Icons.person, size: 16, color: Colors.blueAccent),
                          ),
                          const SizedBox(width: 8),
                          Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                        ],
                      ),
                      Text(
                        currentStatus,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // Order Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.productName,
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text("Order #${orderId.substring(0, 8).toUpperCase()}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("x${order.quantity}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                Text("₱${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // Footer (Action Buttons)
                if (currentStatus == 'PENDING' || currentStatus == 'SHIPPED')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (currentStatus == 'PENDING') ...[
                          _actionButton("Cancel Order", Colors.redAccent, false, () => _updateStatus(context, ref, orderId, 'CANCELLED')),
                          const SizedBox(width: 12),
                          _actionButton("Arrange Shipment", Colors.blueAccent, true, () => _updateStatus(context, ref, orderId, 'SHIPPED')),
                        ],
                        if (currentStatus == 'SHIPPED') ...[
                          _actionButton("Mark as Delivered", Colors.green, true, () => _updateStatus(context, ref, orderId, 'DELIVERED')),
                        ]
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Placed on $dateString", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          currentStatus == 'DELIVERED' ? "Fulfillment Complete" : "Order Cancelled",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _actionButton(String label, Color color, bool isPrimary, VoidCallback onTap) {
    return isPrimary
        ? ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          )
        : OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String orderId, String newStatus) async {
    final dio = ref.read(dioProvider);
    try {
      await dio.patch('/orders/$orderId/status', data: {'status': newStatus});
      ref.invalidate(vendorOrdersProvider);
      ref.invalidate(vendorStatsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Order marked as $newStatus!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Update failed: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
