import 'package:isar/isar.dart';
import 'product_model.dart';

part 'cart_item_model.g.dart';

@collection
class CartItemModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String? backendId;

  late int quantity;
  late DateTime createdAt;

  @Index()
  bool isSynced = true;

  final product = IsarLink<ProductModel>();
}
