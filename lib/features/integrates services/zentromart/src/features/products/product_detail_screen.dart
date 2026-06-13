import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/auth/providers/favorites_provider.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/cart/cart_item.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/cart/cart_provider.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/cart/cart_service.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/chat/chat_detail_screen.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/products/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/network/dio_provider.dart';
import '../cart/checkout_screen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool isActionLoading = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final String rawUrl = product.imageUrl ?? '';

    // --- FIXED: Multi-stage sanitization to completely intercept blank server fields ---
    final bool isUrlValid =
        rawUrl.trim().isNotEmpty && rawUrl != "" && rawUrl.startsWith('http');

    final isSoldOut = product.stock <= 0;
    final favoriteProducts = ref.watch(favoritesProvider);
    final isFavorite = favoriteProducts.any((p) => p.id == product.id);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.black54),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  productId: product.id,
                  vendorId: product.vendorId,
                  productName: product.name,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.black54,
            ),
            onPressed: () =>
                ref.read(favoritesProvider.notifier).toggleFavorite(product),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              // OPTION 1: ADD TO CART BUTTON
              Expanded(
                child: OutlinedButton(
                  onPressed: (isSoldOut || isActionLoading)
                      ? null
                      : () async {
                          setState(() => isActionLoading = true);
                          final dio = ref.read(dioProvider);
                          final cartService = CartService(dio);
                          try {
                            await cartService.addToCart(product.id, 1);
                            ref.invalidate(cartProvider);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text("${product.name} added to cart!"),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Failed to add to cart: $e"),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => isActionLoading = false);
                            }
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.blueAccent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Add to Cart",
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),

              // OPTION 2: BUY NOW BUTTON
              Expanded(
                child: ElevatedButton(
                  onPressed: (isSoldOut || isActionLoading)
                      ? null
                      : () {
                          // FIXED: Instantiating a clean local CartItem data footprint without hitting backend database endpoints beforehand
                          final directItem = CartItem(
                            id: "DIRECT_${DateTime.now().millisecondsSinceEpoch}", // Safe local tracking token string
                            productId: product
                                .id, // Exact backend database parameter link
                            name: product.name,
                            imageUrl: product.imageUrl ?? '',
                            price: product.price.toDouble(),
                            quantity: 1,
                          );

                          // Instantly push to Checkout passing our custom directItem in an array wrapper
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CheckoutScreen(
                                items: [directItem],
                                totalAmount: product.price.toDouble(),
                              ),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey.shade900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Buy Now",
                      style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 400,
              color: Colors.grey.shade100,
              child: isUrlValid
                  ? CachedNetworkImage(
                      imageUrl: rawUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image,
                            color: Colors.red, size: 50),
                      ),
                    )
                  : const Icon(Icons.image_not_supported,
                      size: 80, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(color: Colors.black87, 
                        fontSize: 28, fontWeight: FontWeight.w800, height: 1.2),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    product.description,
                    style: TextStyle(
                        fontSize: 15, color: Colors.grey.shade700, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
