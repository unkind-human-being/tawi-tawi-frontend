import 'package:isar/isar.dart';
import 'product_model.dart';

part 'order_model.g.dart';

@collection
class OrderModel {
  // Generates a stable, predictable 64-bit int from the global backendId string
  Id get id => _fastHash(backendId ?? '');

  @Index(unique: true, replace: true)
  String? backendId;

  @Index()
  late String status;

  late double total;
  late DateTime createdAt;

  // FIXED: Native high-performance field mapping string to track payment details
  late String paymentMethod;

  @Index()
  bool isSynced = true;

  final items = IsarLinks<OrderItemModel>();

  /// High-performance string-to-integer hashing engine
  int _fastHash(String string) {
    if (string.isEmpty) return Isar.autoIncrement;
    var hash = 0xcbf29ce484222325;
    var i = 0;
    while (i < string.length) {
      final codeUnit = string.codeUnitAt(i++);
      hash ^= codeUnit >> 8;
      hash *= 0x100000001b3;
      hash ^= codeUnit & 0xFF;
      hash *= 0x100000001b3;
    }
    return hash;
  }
}

@collection
class OrderItemModel {
  // Uses a compound fast-hash string to ensure child IDs never collide inside Isar tables
  Id get id =>
      _fastHash('${backendId ?? ''}_${product.value?.backendId ?? ''}');

  String? backendId;
  late int quantity;
  late double price;

  final product = IsarLink<ProductModel>();

  @Backlink(to: 'items')
  final order = IsarLink<OrderModel>();

  /// High-performance string-to-integer hashing engine
  int _fastHash(String string) {
    if (string.isEmpty) return Isar.autoIncrement;
    var hash = 0xcbf29ce484222325;
    var i = 0;
    while (i < string.length) {
      final codeUnit = string.codeUnitAt(i++);
      hash ^= codeUnit >> 8;
      hash *= 0x100000001b3;
      hash ^= codeUnit & 0xFF;
      hash *= 0x100000001b3;
    }
    return hash;
  }
}
