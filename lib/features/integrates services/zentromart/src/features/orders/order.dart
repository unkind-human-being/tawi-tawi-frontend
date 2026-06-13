class OrderItem {
  final String productId; // ---> ADDED: Required for the Review System!
  final String name;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId, // ---> ADDED
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Safely extract the name from the nested 'product' object NestJS sends back
    final productName =
        json['product'] != null ? json['product']['name'] : 'Unknown Item';

    // Safely extract the productId (checks root first, then checks inside the product object)
    final parsedProductId = json['productId']?.toString() ??
        (json['product'] != null ? json['product']['id']?.toString() : '') ??
        '';

    return OrderItem(
      productId: parsedProductId, // ---> ADDED
      name: productName ?? 'Unknown Item',
      quantity: json['quantity'] ?? 1,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class Order {
  final String id;
  final String status;
  final double total;
  final DateTime createdAt;
  final String paymentMethod; // ---> REQUIRED ARGUMENT DEFINED
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.paymentMethod, // ---> REQUIRED PARAMETER REQUIRED
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Safely parse the items list if it exists in your NestJS response
    var itemsList = json['items'] as List?;
    List<OrderItem> parsedItems = itemsList != null
        ? itemsList
            .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
            .toList()
        : [];

    // FIXED: Safely extract and format the nested payment method object key maps coming from Prisma
    final paymentMap = json['payment'] as Map<String, dynamic>?;
    final String rawMethod = paymentMap?['method']?.toString() ?? 'COD';
    final String formattedMethod =
        rawMethod.toUpperCase() == 'GCASH' ? 'GCash' : 'Cash on Delivery';

    return Order(
      id: json['id']?.toString() ?? '',
      status: json['status'] as String? ?? 'PENDING',
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      paymentMethod:
          formattedMethod, // ---> FIXED: Argument passed cleanly to resolve the constructor error
      items: parsedItems,
    );
  }
}
