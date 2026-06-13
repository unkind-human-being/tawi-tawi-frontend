import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../products/product.dart';

class VendorProductRow extends StatelessWidget {
  final Product product;
  final VoidCallback? onEditTap;

  const VendorProductRow({
    super.key,
    required this.product,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine exact warning states
    final bool isOutOfStock = product.stock == 0;
    final bool isLowStock = product.stock <= 3 && product.stock > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOutOfStock
              ? Colors.redAccent.withValues(alpha: 0.2)
              : isLowStock
                  ? Colors.orangeAccent.withValues(alpha: 0.2)
                  : Colors.grey.shade100,
        ),
      ),
      child: Row(
        children: [
          // Product Thumbnail Image Box
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 50,
              width: 50,
              color: Colors.grey.shade50,
              child: product.imageUrl != null &&
                      product.imageUrl!.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (c, u, e) =>
                          const Icon(Icons.image, color: Colors.grey),
                    )
                  : const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),

          // Details Block Layout Info Panel
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black87, 
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "₱${product.price.toStringAsFixed(2)}",
                      style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    const SizedBox(width: 12),

                    // --- REACTIVE STOCK STATUS INLINE ALARM COUNTERS ---
                    if (isOutOfStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text("SOLD OUT",
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w900)),
                      )
                    else if (isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          "LOW STOCK: ${product.stock} left",
                          style: TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.w900),
                        ),
                      )
                    else
                      Text(
                        "Stock: ${product.stock}",
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Quick Action Row Link
          IconButton(
            icon: const Icon(Icons.edit_note_outlined, color: Colors.blueGrey),
            onPressed: onEditTap,
          )
        ],
      ),
    );
  }
}
