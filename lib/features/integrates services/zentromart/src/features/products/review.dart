class Review {
  final String id;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      userName: json['user']?['name'] ?? 'Anonymous',
      rating: json['rating'] as int? ?? 5,
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class ProductRatingSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // e.g., {5: 120, 4: 30, 3: 5...}

  ProductRatingSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory ProductRatingSummary.fromJson(Map<String, dynamic> json) {
    final dist = json['distribution'] as Map<String, dynamic>? ?? {};
    final parsedDistribution = {
      1: int.tryParse(dist['1']?.toString() ?? '0') ?? 0,
      2: int.tryParse(dist['2']?.toString() ?? '0') ?? 0,
      3: int.tryParse(dist['3']?.toString() ?? '0') ?? 0,
      4: int.tryParse(dist['4']?.toString() ?? '0') ?? 0,
      5: int.tryParse(dist['5']?.toString() ?? '0') ?? 0,
    };

    return ProductRatingSummary(
      averageRating:
          double.tryParse(json['averageRating']?.toString() ?? '0.0') ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      ratingDistribution: parsedDistribution,
    );
  }
}
