import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/products/product_provider.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/wishlist/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/core/navigation/app_router.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/chat/inbox_screen.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/products/product_detail_screen.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/orders/orders_screen.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/profile/profile_screen.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/products/product.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/products/widgets/flash_sale_shelf.dart'; // 🛠️ ADDED: Explicit import linking your sale shelf component
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/cart/cart_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _ShopTab(),
    const WishlistScreen(),
    const OrdersScreen(),
    const InboxScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text("ZentroMart",
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            ),
          )
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.shop), label: 'Shop'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border), label: 'Wishlist'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined), label: 'Orders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Inbox'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _ShopTab extends ConsumerWidget {
  const _ShopTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredProducts = ref.watch(filteredProductsProvider);
    final productsAsync = ref.watch(productProvider);

    return productsAsync.when(
      data: (allProducts) => RefreshIndicator(
        onRefresh: () async => ref.refresh(productProvider),
        child: Column(
          children: [
            _buildSearchBar(ref),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    FlashSaleShelf(products: allProducts),

                    // Main Catalog Section Header Title Label
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "All Products",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey),
                        ),
                      ),
                    ),

                    // Grid layout container converted into a nested non-scrollable widget so it streams cleanly within SingleChildScrollView
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: filteredProducts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.65),
                      itemBuilder: (context, index) => _buildPremiumProductCard(
                          context, filteredProducts[index]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text("Error: $err")),
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        style: const TextStyle(color: Colors.black),
        onChanged: (value) =>
            ref.read(searchQueryProvider.notifier).state = value,
        decoration: InputDecoration(
            hintText: "Search products in ZentroMart...",
            prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none)),
      ),
    );
  }

  Widget _buildPremiumProductCard(BuildContext context, Product product) {
    final String rawUrl = product.imageUrl ?? '';
    final bool isUrlValid =
        rawUrl.trim().isNotEmpty && rawUrl != "" && rawUrl.startsWith('http');

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  color: Colors.grey.shade100,
                  image: isUrlValid
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(rawUrl),
                          fit: BoxFit.cover)
                      : null,
                ),
                child: isUrlValid
                    ? null
                    : const Center(
                        child: Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black87, 
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text("₱${product.price.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
