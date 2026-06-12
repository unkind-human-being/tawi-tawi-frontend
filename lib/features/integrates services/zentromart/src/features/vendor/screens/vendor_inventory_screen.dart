import 'dart:io';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/products/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vendor_provider.dart';
import 'vendor_product_form_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VendorInventoryScreen extends ConsumerWidget {
  const VendorInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(vendorProductsProvider);

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.black),
          title: const Text("Inventory Management",
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
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
              Tab(text: "All Products"),
              Tab(text: "Live"),
              Tab(text: "Low Stock"),
              Tab(text: "Sold Out"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text("Add Product", style: TextStyle(fontWeight: FontWeight.bold)),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const VendorProductFormScreen()));
          },
        ),
        body: productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.inventory_2_outlined, size: 60, color: Colors.blueAccent),
                    ),
                    const SizedBox(height: 20),
                    const Text("Your shop is empty!", style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Add your first product to start selling.", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              );
            }

            // Tab Filters
            List<Product> filterProducts(int tabIndex) {
              if (tabIndex == 1) return products.where((p) => p.stock > 3).toList();
              if (tabIndex == 2) return products.where((p) => p.stock > 0 && p.stock <= 3).toList();
              if (tabIndex == 3) return products.where((p) => p.stock == 0).toList();
              return products;
            }

            return TabBarView(
              children: [
                _buildProductList(filterProducts(0), ref),
                _buildProductList(filterProducts(1), ref),
                _buildProductList(filterProducts(2), ref),
                _buildProductList(filterProducts(3), ref),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
          error: (err, stack) => Center(child: Text("Error: $err")),
        ),
      ),
    );
  }

  Widget _buildProductList(List<Product> products, WidgetRef ref) {
    if (products.isEmpty) {
      return const Center(child: Text("No products match this category.", style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(vendorProductsProvider),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 12, bottom: 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final Product p = products[index];

          final bool isOutOfStock = p.stock == 0;
          final bool isLowStock = p.stock <= 3 && p.stock > 0;
          final bool hasValidImage = p.imageUrl != null && p.imageUrl!.trim().isNotEmpty && p.imageUrl != "";

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isOutOfStock ? Colors.red.shade100 : (isLowStock ? Colors.orange.shade200 : Colors.grey.shade200)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                // Header (Status Strip)
                if (isOutOfStock || isLowStock)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: isOutOfStock ? Colors.red.shade50 : Colors.orange.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: Row(
                      children: [
                        Icon(isOutOfStock ? Icons.error_outline : Icons.warning_amber_rounded,
                            size: 14, color: isOutOfStock ? Colors.redAccent : Colors.orange.shade800),
                        const SizedBox(width: 6),
                        Text(
                          isOutOfStock ? "SOLD OUT" : "LOW STOCK (${p.stock} LEFT)",
                          style: TextStyle(
                            color: isOutOfStock ? Colors.redAccent : Colors.orange.shade900,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Product Content
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                        clipBehavior: Clip.hardEdge,
                        child: hasValidImage
                            ? (p.imageUrl!.startsWith('http')
                                ? CachedNetworkImage(
                                    imageUrl: p.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                                  )
                                : Image.file(
                                    File(p.imageUrl!.replaceAll('file://', '')),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.orangeAccent),
                                  ))
                            : const Icon(Icons.image, color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "₱${p.price.toStringAsFixed(2)}",
                              style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text("Current Stock: ${p.stock}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFEEEEEE)),

                // Action Footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Delete
                      TextButton.icon(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                        label: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                        onPressed: () => _confirmDelete(context, ref, p.id, p.name),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      ),
                      // Edit
                      ElevatedButton.icon(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text("Edit Details"),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => VendorProductFormScreen(existingProduct: p.toJson())));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blueAccent,
                          elevation: 0,
                          side: const BorderSide(color: Colors.blueAccent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          visualDensity: VisualDensity.compact,
                        ),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Product", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete '$name'? This action cannot be undone."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(vendorServiceProvider).deleteProduct(id);
                ref.invalidate(vendorProductsProvider);
                ref.invalidate(vendorStatsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product successfully deleted"), backgroundColor: Colors.green));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                }
              }
            },
            child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
