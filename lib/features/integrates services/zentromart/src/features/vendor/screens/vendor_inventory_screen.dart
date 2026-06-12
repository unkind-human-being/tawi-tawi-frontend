import 'dart:io';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/products/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vendor_provider.dart';
import 'vendor_product_form_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'vendor_orders_screen.dart';

class VendorInventoryScreen extends ConsumerWidget {
  const VendorInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(vendorProductsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(iconTheme: const IconThemeData(color: Colors.black), 
        title: const Text("My Inventory",
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VendorOrdersScreen(),
                ),
              );
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add Product"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const VendorProductFormScreen(),
            ),
          );
        },
      ),
      body: productsAsync.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(
              child: Text(
                "No products yet. Click 'Add Product' to start selling!",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 10, bottom: 80),
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final Product p = products[index];

              final bool isOutOfStock = p.stock == 0;
              final bool isLowStock = p.stock <= 3 && p.stock > 0;

              // --- FIXED: Added deep sanitization check to catch blank server strings safely ---
              final bool hasValidImage = p.imageUrl != null &&
                  p.imageUrl!.trim().isNotEmpty &&
                  p.imageUrl != "";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isOutOfStock
                        ? Colors.redAccent.withValues(alpha: 0.4)
                        : isLowStock
                            ? Colors.orangeAccent.withValues(alpha: 0.4)
                            : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.hardEdge,
                      // --- FIXED: Safe Multi-mode rendering safeguard architecture ---
                      child: hasValidImage
                          ? (p.imageUrl!.startsWith('http')
                              ? CachedNetworkImage(
                                  imageUrl: p.imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                )
                              : Image.file(
                                  File(p.imageUrl!.replaceAll('file://', '')),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.broken_image,
                                    color: Colors.orangeAccent,
                                  ),
                                ))
                          : const Icon(Icons.image,
                              color: Colors
                                  .grey), // Clean fallback if image string is blank!
                    ),
                    title: Text(
                      p.name,
                      style: const TextStyle(color: Colors.black87, 
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Row(
                        children: [
                          Text(
                            "₱${p.price.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (isOutOfStock)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6)),
                              child: const Text("SOLD OUT",
                                  style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            )
                          else if (isLowStock)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text("ONLY ${p.stock} LEFT",
                                  style: const TextStyle(
                                      color: Colors.orangeAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            )
                          else
                            Text(
                              "Stock: ${p.stock}",
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VendorProductFormScreen(
                                    existingProduct: p.toJson()),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () =>
                              _confirmDelete(context, ref, p.id, p.name),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Product"),
        content: Text(
            "Are you sure you want to delete '$name'? This cannot be undone."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(vendorServiceProvider).deleteProduct(id);
                ref.invalidate(vendorProductsProvider);
                ref.invalidate(vendorStatsProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Product Deleted")));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
