import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/core/database/models/product_model.dart';
import 'package:dio/dio.dart';
import 'package:isar/isar.dart';

class ProductRepository {
  final Isar _isar;
  final Dio _dio;

  ProductRepository(this._isar, this._dio);

  // 1. WATCH LOCAL DATABASE (Reactive UI Stream)
  // Your UI screens can listen to this stream to auto-refresh whenever Isar changes!
  Stream<List<ProductModel>> watchLocalProducts() {
    return _isar.productModels.where().anyId().watch(fireImmediately: true);
  }

  // 2. FETCH FROM BACKEND & CACHE LOCALLY
  Future<void> refreshProducts() async {
    try {
      // Fetch latest updates from NestJS endpoint
      final response = await _dio.get('/products');
      final List<dynamic> remoteData = response.data as List<dynamic>;

      // Map incoming backend JSON into your local Isar structural models
      final List<ProductModel> products = remoteData.map((json) {
        return ProductModel()
          ..backendId = json['id']?.toString() ?? ''
          ..sku = json['sku']?.toString() ?? ''
          ..name = json['name']?.toString() ?? 'Unknown Item'
          ..description = json['description']?.toString() ?? ''
          ..price = double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0
          ..stock = int.tryParse(json['stock']?.toString() ?? '0') ?? 0
          ..imageUrl = json['imageUrl']?.toString()
          ..categoryId = json['categoryId']?.toString()
          ..updatedAt = json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'])
              : DateTime.now();
      }).toList();

      // Save into Isar using an Atomic Transaction block
      await _isar.writeTxn(() async {
        // Clear old cached versions or update existing entries via backendId index mapping
        await _isar.productModels.putAllByBackendId(products);
      });
    } on DioException catch (e) {
      // SILENT FALLBACK: If network is completely offline, catch error silently.
      // The app will simply continue displaying what is already stored inside Isar!
      print(
          "Offline Mode Active: Fetching products failed, falling back to local cache. Error: $e");
    }
  }

  // 3. GET SINGLE LOCAL PRODUCT DETAILS
  Future<ProductModel?> getLocalProductById(String backendId) async {
    return await _isar.productModels.getByBackendId(backendId);
  }
}
