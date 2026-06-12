import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'order_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(iconTheme: const IconThemeData(color: Colors.black), 
          title: const Text(
            "My Orders",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3,
            labelStyle: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "All"),
              Tab(text: "To Ship"),
              Tab(text: "To Receive"),
              Tab(text: "Completed"),
            ],
          ),
        ),
        body: ordersAsync.when(
          data: (orders) {
            // Helper to filter orders based on tab logic
            List filterOrders(int tabIndex) {
              if (tabIndex == 1) return orders.where((o) => o.status.toString().toUpperCase() == 'PENDING').toList();
              if (tabIndex == 2) return orders.where((o) => o.status.toString().toUpperCase() == 'SHIPPED').toList();
              if (tabIndex == 3) return orders.where((o) => o.status.toString().toUpperCase() == 'DELIVERED').toList();
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
          error: (e, _) => Center(
            child: Text(
              "Error loading orders: $e",
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
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
              child: const Icon(Icons.receipt_long, size: 60, color: Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            const Text(
              "No orders yet",
              style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Looks like you haven't made your choice yet...",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(orderProvider),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final o = orders[index];
          final String status = o.status.toString().toUpperCase();

          int currentStep = 0;
          if (status == 'SHIPPED') currentStep = 1;
          if (status == 'DELIVERED') currentStep = 2;

          final String displayId = o.id.toString().length > 8
              ? o.id.toString().substring(0, 8).toUpperCase()
              : o.id.toString().toUpperCase();

          final double totalAmount = (o.total as num? ?? 0.0).toDouble();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Store Name & Status)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.storefront, size: 18, color: Colors.blueGrey),
                          SizedBox(width: 8),
                          Text("ZentroMart Store", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      Text(
                        status == 'PENDING' ? 'TO SHIP' : status == 'SHIPPED' ? 'TO RECEIVE' : 'COMPLETED',
                        style: TextStyle(
                          color: status == 'DELIVERED' ? Colors.green : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                
                // Content (Order ID and Timeline)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Order ID: #$displayId", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: o.paymentMethod == 'GCash' ? Colors.blue.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              o.paymentMethod,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: o.paymentMethod == 'GCash' ? Colors.blueAccent : Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimelineStep(Icons.receipt_long, "Placed", currentStep >= 0),
                          _buildLine(currentStep >= 1),
                          _buildTimelineStep(Icons.local_shipping_outlined, "Shipped", currentStep >= 1),
                          _buildLine(currentStep >= 2),
                          _buildTimelineStep(Icons.check_circle_outline, "Delivered", currentStep >= 2),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // Footer (Total Price & CTA)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Order Total", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(
                            "₱${totalAmount.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueAccent, fontSize: 16),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: status == 'DELIVERED' ? Colors.white : Colors.blueAccent,
                          foregroundColor: status == 'DELIVERED' ? Colors.blueAccent : Colors.white,
                          elevation: 0,
                          side: status == 'DELIVERED' ? const BorderSide(color: Colors.blueAccent) : null,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: Text(status == 'DELIVERED' ? "Buy Again" : "Track Order"),
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

  Widget _buildTimelineStep(IconData icon, String label, bool isAchieved) {
    final Color color = isAchieved ? Colors.blueAccent : Colors.grey.shade300;
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isAchieved ? Colors.blue.shade50 : Colors.grey.shade100,
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
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
        margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
        color: isAchieved ? Colors.blueAccent : Colors.grey.shade200,
      ),
    );
  }
}
