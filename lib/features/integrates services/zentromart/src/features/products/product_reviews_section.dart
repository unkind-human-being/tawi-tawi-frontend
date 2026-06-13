import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'review.dart';
import 'review_provider.dart';
import 'review_modal.dart';

class ProductReviewsSection extends ConsumerWidget {
  final String productId;
  const ProductReviewsSection({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(ratingSummaryProvider(productId));
    final reviewsAsync = ref.watch(productReviewsProvider(productId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Customer Reviews",
                style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => LeaveReviewModal(productId: productId),
              ),
              icon: const Icon(Icons.rate_review, size: 18),
              label: const Text("Write Review"),
            )
          ],
        ),
        const SizedBox(height: 12),

        // 1. RATING METRICS SUMMARY BLOCK
        summaryAsync.when(
          data: (summary) => _buildSummaryBlock(summary),
          // 🛠️ FIX: Replaced SizedBox.shrink() with a constrained container placeholder to stop the infinite layout loop
          loading: () => const SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, __) => const SizedBox(
            height: 40,
            child: Text("Couldn't update ratings layout."),
          ),
        ),
        const SizedBox(height: 20),

        // 2. VIRTUALIZED USER REVIEWS LIST
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text("No reviews yet. Be the first to review!",
                      style: TextStyle(color: Colors.grey)),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, idx) {
                final rev = reviews[idx];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(rev.userName,
                            style:
                                const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        Row(
                          children: List.generate(
                              5,
                              (i) => Icon(
                                    Icons.star,
                                    size: 14,
                                    color: i < rev.rating
                                        ? Colors.amber
                                        : Colors.grey.shade300,
                                  )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(rev.comment,
                        style: TextStyle(
                            color: Colors.grey.shade800, height: 1.3)),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text("Error loading reviews: $err"),
        ),
      ],
    );
  }

  Widget _buildSummaryBlock(ProductRatingSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(summary.averageRating.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.black87, 
                      fontSize: 40, fontWeight: FontWeight.w900)),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          Icons.star,
                          size: 14,
                          color: i < summary.averageRating.round()
                              ? Colors.amber
                              : Colors.grey.shade300,
                        )),
              ),
              const SizedBox(height: 4),
              Text("${summary.totalReviews} reviews",
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: List.generate(5, (index) {
                final starLevel = 5 - index;
                final count = summary.ratingDistribution[starLevel] ?? 0;
                final percentage = summary.totalReviews == 0
                    ? 0.0
                    : count / summary.totalReviews;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Text("$starLevel",
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.amber,
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
