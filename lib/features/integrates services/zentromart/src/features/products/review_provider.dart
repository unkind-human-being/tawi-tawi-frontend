import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/dio_provider.dart';
import 'review.dart';

class ReviewService {
  final Dio _dio;
  ReviewService(this._dio);

  // Get reviews for a specific product
  Future<List<Review>> getProductReviews(String productId) async {
    final res = await _dio.get('/reviews/product/$productId');
    final list = res.data as List? ?? [];
    return list.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Get the numerical summary breakdown
  Future<ProductRatingSummary> getRatingSummary(String productId) async {
    final res = await _dio.get('/reviews/product/$productId/summary');
    return ProductRatingSummary.fromJson(res.data as Map<String, dynamic>);
  }

  // Submit a new review
  Future<void> submitReview({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    // Cleaned: The global Dio Interceptor automatically handles token injection now!
    await _dio.post(
      '/reviews',
      data: {
        "productId": productId,
        "rating": rating,
        "comment": comment,
      },
    );
  }
}

// ==========================================================================
// PROVIDERS
// ==========================================================================
final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService(ref.read(dioProvider));
});

final productReviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, productId) async {
  return ref.read(reviewServiceProvider).getProductReviews(productId);
});

final ratingSummaryProvider =
    FutureProvider.family<ProductRatingSummary, String>((ref, productId) async {
  return ref.read(reviewServiceProvider).getRatingSummary(productId);
});
