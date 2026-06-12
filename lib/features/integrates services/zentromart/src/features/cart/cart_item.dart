class CartItem {
  final String id;
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      name: json['product']?['name'] ?? 'Unknown Item',
      imageUrl: json['product']?['imageUrl'] ?? '',
      price: (json['product']?['price'] as num? ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
    );
  }
}
