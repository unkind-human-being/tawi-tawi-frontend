import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/orders/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../auth/providers/auth_provider.dart';
import '../cart/cart_provider.dart';
import '../cart/cart_item.dart';
import '../auth/screens/home_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final List<CartItem> items;
  final double totalAmount;

  const CheckoutScreen({
    super.key,
    required this.items,
    required this.totalAmount,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String selectedPaymentMethod = "Cash on Delivery";
  bool _isProcessing = false;

  Future<void> _placeOrder() async {
    setState(() => _isProcessing = true);
    try {
      String apiPaymentMethod = selectedPaymentMethod == "GCash" ? "GCASH" : "COD";

      await ref.read(orderServiceProvider).checkout({
        "paymentMethod": apiPaymentMethod,
        "totalAmount": widget.totalAmount,
        "items": widget.items
            .map((i) => {"productId": i.productId, "quantity": i.quantity})
            .toList(),
      });

      ref.invalidate(cartProvider);
      ref.invalidate(orderProvider);

      if (mounted) {
        // Show success modal instead of snackbar for premium feel
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Order Placed!",
                  style: TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your order has been successfully placed and is being processed.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Navigate back to Zentromart Home Screen
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => route.isFirst,
                      );
                    },
                    child: const Text(
                      "Continue Shopping",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Checkout Failed: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(authProvider);
    final deliveryAddress = userState?.user.shopAddress ?? "No address set. Please update in profile.";
    final userName = userState?.user.name ?? "Customer";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("Checkout", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Delivery Address Strip
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Colors.redAccent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Delivery Address", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(
                          "$userName | +63 9XX XXX XXXX",
                          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deliveryAddress,
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            
            const SizedBox(height: 12),

            // Order Items
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront, color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 8),
                      const Text("ZentroMart Store", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      final isUrlValid = item.imageUrl.isNotEmpty && item.imageUrl.startsWith('http');
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              image: isUrlValid
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(item.imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: !isUrlValid
                                ? const Icon(Icons.image, color: Colors.grey, size: 24)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "₱${item.price.toStringAsFixed(2)}",
                                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      "x${item.quantity}",
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Payment Method
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.payment, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text("Payment Method", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: const Text("Cash on Delivery"),
                          subtitle: const Text("Pay when you receive the item", style: TextStyle(color: Colors.black87, fontSize: 12)),
                          value: "Cash on Delivery",
                          groupValue: selectedPaymentMethod,
                          activeColor: Colors.blueAccent,
                          onChanged: (v) => setState(() => selectedPaymentMethod = v!),
                          secondary: const Icon(Icons.local_shipping_outlined, color: Colors.blueGrey),
                        ),
                        const Divider(height: 1),
                        RadioListTile<String>(
                          title: const Text("GCash"),
                          subtitle: const Text("E-wallet payment", style: TextStyle(color: Colors.black87, fontSize: 12)),
                          value: "GCash",
                          groupValue: selectedPaymentMethod,
                          activeColor: Colors.blueAccent,
                          onChanged: (v) => setState(() => selectedPaymentMethod = v!),
                          secondary: const Icon(Icons.account_balance_wallet_outlined, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Order Summary
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Payment Details", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Merchandise Subtotal", style: TextStyle(color: Colors.grey)),
                      Text("₱${widget.totalAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Shipping Subtotal", style: TextStyle(color: Colors.grey)),
                      Text("₱0.00", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Payment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        "₱${widget.totalAmount.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // padding for bottom bar
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Total Payment", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    "₱${widget.totalAmount.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.blueAccent),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              SizedBox(
                height: 50,
                width: 140,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Place Order",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
