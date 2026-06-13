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
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          iconTheme: const IconThemeData(color: Colors.black), 
          title: const Text(
            "My Purchases",
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87, fontSize: 18),
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
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
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
              decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long, size: 60, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Text(
              "No orders yet",
              style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Looks like you haven't made your choice yet...",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Start Shopping", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
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

          final String displayId = o.id.toString().length > 8
              ? o.id.toString().substring(0, 8).toUpperCase()
              : o.id.toString().toUpperCase();

          final double totalAmount = (o.total as num? ?? 0.0).toDouble();

          // Items logic
          final items = o.items ?? [];
          final int totalItems = items.fold(0, (sum, item) => sum + (item.quantity as int));
          final firstItem = items.isNotEmpty ? items.first : null;

          Color statusColor = Colors.orange.shade800;
          String statusText = "TO SHIP";
          if (status == 'SHIPPED') {
            statusColor = Colors.blueAccent;
            statusText = "TO RECEIVE";
          } else if (status == 'DELIVERED') {
            statusColor = Colors.green;
            statusText = "COMPLETED";
          } else if (status == 'CANCELLED') {
            statusColor = Colors.redAccent;
            statusText = "CANCELLED";
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200), bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Store Name & Status)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.storefront, size: 18, color: Colors.blueGrey.shade700),
                          const SizedBox(width: 8),
                          const Text("ZentroMart Official", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                        ],
                      ),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                
                // Content (Items List)
                Container(
                  color: const Color(0xFFFAFAFA),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image Placeholder
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 30),
                      ),
                      const SizedBox(width: 12),
                      
                      // Product Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstItem != null ? firstItem.name : "Unknown Item",
                              style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  firstItem != null ? "₱${firstItem.price.toStringAsFixed(2)}" : "₱0.00",
                                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                                ),
                                Text(
                                  firstItem != null ? "x${firstItem.quantity}" : "x0",
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                            if (items.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "+ ${items.length - 1} more item(s)",
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                ),
                              )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                
                // Total Amount Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "$totalItems items",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      Row(
                        children: [
                          const Text("Order Total: ", style: TextStyle(fontSize: 13, color: Colors.black87)),
                          Text(
                            "₱${totalAmount.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueAccent, fontSize: 15),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // Footer (Action Buttons)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Order ID: #$displayId", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      Row(
                        children: [
                          if (status == 'DELIVERED') ...[
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text("Rate"),
                            ),
                            const SizedBox(width: 8),
                          ],
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: status == 'DELIVERED' ? Colors.blueAccent : Colors.orange.shade800,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(status == 'DELIVERED' ? "Buy Again" : "Track Order"),
                          ),
                        ],
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
}
