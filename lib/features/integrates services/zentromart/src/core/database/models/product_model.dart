import 'package:isar/isar.dart';

part 'product_model.g.dart';

@collection
class ProductModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String backendId;

  @Index()
  late String sku;

  @Index()
  late String name;

  late String description;
  late double price;
  late int stock;
  String? imageUrl;
  String? categoryId;
  late DateTime updatedAt;

  // --- NEW OFFLINE SYNC QUEUE FLAG ---
  @Index()
  bool isSynced = true; // Defaults to true for remote-fetched items
}
