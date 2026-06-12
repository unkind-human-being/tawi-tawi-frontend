// product.dart

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final int stock;

  // --- ADDED VENDOR FIELD ---
  final String vendorId;
  final String? shopName;

  // E-commerce feature fields
  final double averageRating;
  final List<Review> reviews;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.stock,
    required this.vendorId,
    this.shopName,
    required this.averageRating,
    required this.reviews,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Item',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num? ?? 0).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      stock: json['stock'] as int? ?? 0,
      vendorId:
          json['vendorId'] as String? ?? 'Unknown Vendor', // Safely extracted
      averageRating: (json['averageRating'] as num? ?? 0.0).toDouble(),
      reviews: (json['reviews'] as List? ?? [])
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'stock': stock,
      'vendorId': vendorId, // Added to JSON output
      'averageRating': averageRating,
      'reviews': reviews.map((e) => e.toJson()).toList(),
    };
  }
}

class Review {
  final String id;
  final String username;
  final int rating; // 1 to 5 stars
  final String comment;
  final DateTime date;

  Review({
    required this.id,
    required this.username,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      username: json['username'] ?? 'Anonymous User',
      rating: json['rating'] as int? ?? 5,
      comment: json['comment'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'rating': rating,
      'comment': comment,
      'date': date.toIso8601String(),
    };
  }
}
