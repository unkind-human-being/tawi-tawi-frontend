import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/network/dio_provider.dart';
import '../../core/network/sync_provider.dart';
import '../../core/database/models/cart_item_model.dart';
import '../../core/database/models/product_model.dart';
import 'cart_item.dart';
import 'cart_service.dart';

final cartServiceProvider = Provider<CartService>((ref) {
  final dio = ref.read(dioProvider);
  return CartService(dio);
});

// UPGRADED: Watch local Isar cart collection while quietly refreshing from backend if online
final cartProvider = StreamProvider<List<CartItem>>((ref) async* {
  final isar = ref.watch(isarProvider);

  // Quietly trigger network download sync behind the scenes
  _syncRemoteCart(ref);

  // Watch the local cart model table reactively
  final cartStream = isar.cartItemModels.where().watch(fireImmediately: true);

  await for (final localItems in cartStream) {
    List<CartItem> parsedList = [];

    for (var item in localItems) {
      // Load the explicit link relation model
      await item.product.load();
      final linkedProduct = item.product.value;

      parsedList.add(CartItem(
        id: item.backendId ?? item.id.toString(),
        productId: linkedProduct?.backendId ?? '',
        name: linkedProduct?.name ?? 'Unknown Item',
        imageUrl: linkedProduct?.imageUrl ?? '',
        price: linkedProduct?.price ?? 0.0,
        quantity: item.quantity,
      ));
    }
    yield parsedList;
  }
});

// Quietly hits NestJS endpoint and synchronizes local phone cache
Future<void> _syncRemoteCart(Ref ref) async {
  final connectivity = await Connectivity().checkConnectivity();
  if (connectivity.contains(ConnectivityResult.none)) return;

  final service = ref.read(cartServiceProvider);
  final isar = ref.read(isarProvider);

  try {
    final List<dynamic> remoteData = await service.getCart();

    await isar.writeTxn(() async {
      // Clear out older synced entries, keeping un-synced offline modifications safe
      await isar.cartItemModels.filter().isSyncedEqualTo(true).deleteAll();

      for (var json in remoteData) {
        final String remoteProdId = json['product']?['id']?.toString() ??
            json['productId']?.toString() ??
            '';

        // Find matching product model from local disk reference mappings
        final matchingProduct = await isar.productModels
            .filter()
            .backendIdEqualTo(remoteProdId)
            .findFirst();

        if (matchingProduct != null) {
          final cartModel = CartItemModel()
            ..backendId = json['id']?.toString() ?? ''
            ..quantity = json['quantity'] as int? ?? 1
            ..createdAt = DateTime.now()
            ..isSynced = true;

          await isar.cartItemModels.putByBackendId(cartModel);
          cartModel.product.value = matchingProduct;
          await cartModel.product.save(); // Locks down explicit database links
        }
      }
    });
  } catch (e) {
    print("Cart background download paused: $e. Running on Isar disk cache.");
  }
}

// Grand total tracking state generator
final cartTotalProvider = Provider<double>((ref) {
  final cartAsync = ref.watch(cartProvider);
  return cartAsync.maybeWhen(
    data: (items) =>
        items.fold(0.0, (sum, item) => sum + (item.price * item.quantity)),
    orElse: () => 0.0,
  );
});
