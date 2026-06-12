import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../product.dart';
import '../product_detail_screen.dart';
import 'flash_sale_countdown.dart';
import '../../cart/cart_provider.dart'; // 🛠️ Added for cart invalidation
import '../../cart/cart_service.dart'; // 🛠️ Added for direct background API injection
import '../../../core/network/dio_provider.dart';

class FlashSaleShelf extends ConsumerStatefulWidget {
  final List<Product> products;

  const FlashSaleShelf({super.key, required this.products});

  @override
  ConsumerState<FlashSaleShelf> createState() => _FlashSaleShelfState();
}

class _FlashSaleShelfState extends ConsumerState<FlashSaleShelf> {
  late final ScrollController _scrollController;
  Timer? _autoScrollTimer;
  int _currentIndex = 0;
  bool _isUserInteracting =
      false; // Tracks if the user is holding/dragging the list
  String?
      _loadingProductId; // Tracks which product button is hitting the network

  static const double _cardWidth = 153.0;
  static const Duration _scrollInterval = Duration(seconds: 3);
  static const Duration _animationDuration = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startAutoScrollLoop();
  }

  void _startAutoScrollLoop() {
    if (widget.products.isEmpty || widget.products.length <= 1) return;

    final int maxItems =
        widget.products.length > 5 ? 5 : widget.products.length;

    _autoScrollTimer = Timer.periodic(_scrollInterval, (timer) {
      // 🛠️ IMPROVEMENT: Skip automatic scrolling instantly if the user is touching the shelf
      if (!_scrollController.hasClients || _isUserInteracting) return;

      _currentIndex++;

      if (_currentIndex >= maxItems) {
        _currentIndex = 0;
        _scrollController.animateTo(
          0.0,
          duration: _animationDuration,
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.animateTo(
          _currentIndex * _cardWidth,
          duration: _animationDuration,
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  // 🛠️ QUICK ADD-TO-CART ENGINE
  Future<void> _quickAddToCart(Product product) async {
    setState(() => _loadingProductId = product.id);

    final dio = ref.read(dioProvider);
    final cartService = CartService(dio);

    try {
      await cartService.addToCart(product.id, 1);
      ref.invalidate(cartProvider); // Instantly updates badge counts globally

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${product.name} added to cart! 🛒"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add item: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingProductId = null);
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) return const SizedBox.shrink();

    final mockTargetTime =
        DateTime.now().add(const Duration(hours: 4, minutes: 30));

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flash_on, color: Colors.amber, size: 26),
                    SizedBox(width: 6),
                    Text(
                      "Flash Sale",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                FlashSaleCountdown(closingTime: mockTargetTime),
              ],
            ),
          ),
          SizedBox(
            height: 235,
            // 🛠️ IMPROVEMENT: Wrap in a Listener to detect touch down/up gestures and pause the carousel
            child: Listener(
              onPointerDown: (_) => setState(() => _isUserInteracting = true),
              onPointerUp: (_) => setState(() => _isUserInteracting = false),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount:
                    widget.products.length > 5 ? 5 : widget.products.length,
                itemBuilder: (context, index) {
                  final product = widget.products[index];
                  const double discountPercent = 0.20;
                  final double promoPrice =
                      product.price * (1 - discountPercent);

                  final String rawUrl = product.imageUrl ?? '';
                  final bool isUrlValid = rawUrl.trim().isNotEmpty &&
                      rawUrl != "" &&
                      rawUrl.startsWith('http');

                  final bool isItemLoading = _loadingProductId == product.id;

                  return Container(
                    width: 145,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Card(
                      elevation: 0,
                      color: const Color(0xFFF8F9FB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade100),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  height: 115,
                                  width: double.infinity,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                  ),
                                  child: isUrlValid
                                      ? ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(12)),
                                          child: CachedNetworkImage(
                                            imageUrl: rawUrl,
                                            fit: BoxFit.cover,
                                            errorWidget: (c, u, e) => Icon(
                                                Icons.broken_image,
                                                color: Colors.grey.shade400),
                                          ),
                                        )
                                      : Icon(Icons.image,
                                          color: Colors.grey.shade400),
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      "-20%",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Stack(
                                children: [
                                  // Product Text Layout Column
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width:
                                            95, // Leaves space so title never overlaps our floating button
                                        child: Text(
                                          product.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "₱${promoPrice.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        "₱${product.price.toStringAsFixed(2)}",
                                        style: TextStyle(
                                            color: Colors.grey.shade400,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),

                                  // 🛠️ IMPROVEMENT: FLOATING + QUICK CART ACTION BUTTON
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        style: IconButton.styleFrom(
                                          backgroundColor:
                                              Colors.blueGrey.shade900,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                        icon: isItemLoading
                                            ? const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child:
                                                    CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 1.5))
                                            : const Icon(Icons.add,
                                                color: Colors.white, size: 16),
                                        onPressed: isItemLoading
                                            ? null
                                            : () => _quickAddToCart(product),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
