import 'package:dio/dio.dart';
import 'package:isar/isar.dart';
import '../database/models/product_model.dart';
import '../database/models/order_model.dart';

class SyncService {
  final Dio _dio;
  final Isar _isar;

  SyncService(this._dio, this._isar);

  // ==========================================
  // 1. DOWNSTREAM: Fetch from Backend -> Isar
  // ==========================================
  Future<void> syncProductsDownstream() async {
    try {
      final response = await _dio.get('/products');
      final List<dynamic> backendProducts = response.data;

      await _isar.writeTxn(() async {
        for (var json in backendProducts) {
          var localProduct = await _isar.productModels
              .where()
              .backendIdEqualTo(json['id'])
              .findFirst();

          localProduct ??= ProductModel();

          localProduct
            ..backendId = json['id']
            ..sku = json['sku']
            ..name = json['name']
            ..description = json['description']
            ..price = (json['price'] as num).toDouble()
            ..stock = json['stock']
            ..imageUrl = json['imageUrl']
            ..categoryId = json['categoryId']
            ..updatedAt = DateTime.parse(
              json['updatedAt'] ?? DateTime.now().toIso8601String(),
            );

          await _isar.productModels.put(localProduct);
        }
      });
      print("Products synced successfully!");
    } catch (e) {
      print("Failed to sync products downstream: $e");
    }
  }

  // ==========================================
  // 2. UPSTREAM: Push from Isar -> Backend
  // ==========================================
  Future<void> pushOfflineOrdersUpstream() async {
    try {
      final offlineOrders =
          await _isar.orderModels.filter().isSyncedEqualTo(false).findAll();

      if (offlineOrders.isEmpty) {
        print("No offline orders to sync.");
        return;
      }

      for (var localOrder in offlineOrders) {
        try {
          final response = await _dio.post(
            '/orders',
            data: {
              'total': localOrder.total,
              'status': localOrder.status,
              // Map your items here when ready
            },
          );

          if (response.statusCode == 201 || response.statusCode == 200) {
            await _isar.writeTxn(() async {
              localOrder.backendId = response.data['id'];
              localOrder.isSynced = true;
              await _isar.orderModels.put(localOrder);
            });
          }
        } catch (e) {
          // Inner catch prevents one failed order (e.g. 500 error)
          // from stopping the rest of the offline queue from syncing.
          print("Failed to sync individual order ${localOrder.id}: $e");
        }
      }
      print("Offline orders sync cycle complete!");
    } catch (e) {
      print("Failed to access database for upstream sync: $e");
    }
  }
}
