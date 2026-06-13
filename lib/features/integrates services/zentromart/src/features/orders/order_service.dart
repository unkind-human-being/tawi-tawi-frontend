import 'package:dio/dio.dart';
import '../../core/storage/secure_storage.dart';

class OrderService {
  final Dio _dio;

  OrderService(this._dio);

  // --- FETCH USER ORDERS ---
  Future<List<dynamic>> getOrders() async {
    try {
      final token = await SecureStorage.getToken();
      final response = await _dio.get(
        '/orders/my-orders',
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );

      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _handleError(e, 'fetch orders');
    }
  }

  // --- CHECKOUT ---
  Future<void> checkout(Map<String, dynamic> orderData) async {
    try {
      final token = await SecureStorage.getToken();
      await _dio.post(
        '/orders/checkout',
        data: orderData,
        options: Options(headers: {"Authorization": "Bearer $token"}),
      );
    } on DioException catch (e) {
      throw _handleError(e, 'process checkout');
    }
  }

  // Helper for cleaner error messages
  Exception _handleError(DioException e, String action) {
    String errorMessage = e.message ?? 'Unknown error occurred';
    if (e.response?.data is Map<String, dynamic>) {
      errorMessage = e.response?.data['message'] ?? errorMessage;
    }
    return Exception('Failed to $action: $errorMessage');
  }
}
