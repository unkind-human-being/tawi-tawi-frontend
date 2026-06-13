import 'package:dio/dio.dart';
import '../../core/storage/secure_storage.dart';

class CartService {
  final Dio dio;
  CartService(this.dio);

  Future<List<dynamic>> getCart() async {
    try {
      final token = await SecureStorage.getToken();
      final res = await dio.get(
        '/cart',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
      return res.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e, 'fetch cart');
    }
  }

  Future<void> addToCart(String productId, int quantity) async {
    try {
      final token = await SecureStorage.getToken();
      await dio.post(
        '/cart/add',
        data: {"productId": productId, "quantity": quantity},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      throw _handleError(e, 'add item to cart');
    }
  }

  Future<void> updateQty(String id, int quantity) async {
    try {
      final token = await SecureStorage.getToken();
      await dio.patch(
        '/cart/$id',
        data: {"quantity": quantity},
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      throw _handleError(e, 'update quantity');
    }
  }

  Future<void> removeItem(String id) async {
    try {
      final token = await SecureStorage.getToken();
      await dio.delete(
        '/cart/$id',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      throw _handleError(e, 'remove item');
    }
  }

  // ---> UNIFIED PROCESS CHECKOUT <---
  Future<void> checkout() async {
    try {
      final token = await SecureStorage.getToken();
      await dio.post(
        '/orders/checkout',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      throw _handleError(e, 'process checkout');
    }
  }

  Exception _handleError(DioException e, String action) {
    String errorMessage = e.message ?? 'Unknown error occurred';
    if (e.response?.data is Map<String, dynamic>) {
      errorMessage = e.response?.data['message'] ?? errorMessage;
    }
    return Exception('Failed to $action: $errorMessage');
  }
}
