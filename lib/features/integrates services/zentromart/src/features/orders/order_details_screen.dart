import 'package:flutter/material.dart';
import 'order.dart';
import 'order_tracker_widget.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(iconTheme: const IconThemeData(color: Colors.black), 
        title: Text("Order #${order.id.substring(0, 8)}"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Order Header Details (Tracking Status)
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  "Tracking Status",
                  style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                OrderTrackerWidget(status: order.status),
                const Divider(height: 40),
                const Text(
                  "Items Ordered",
                  style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (order.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      "No item details found for this order.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
              ]),
            ),
          ),

          // Core Virtualized List of Items Ordered
          if (order.items.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final item = order.items[idx];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.name,
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text("Qty: ${item.quantity}"),
                      trailing: Text(
                        "₱${(item.price * item.quantity).toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.black87, 
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    );
                  },
                  childCount: order.items.length,
                ),
              ),
            ),

          // Checkout Totals Summary Section
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Amount",
                      style:
                          TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "₱${order.total.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
