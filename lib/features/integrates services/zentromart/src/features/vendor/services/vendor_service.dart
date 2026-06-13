import 'dart:io';
import 'package:dio/dio.dart';

class VendorService {
  final Dio _dio;

  VendorService(this._dio);

  // --- READ STATS ---
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _dio.get('/vendor/stats');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'load stats');
    }
  }

  // --- READ PRODUCTS ---
  Future<List<dynamic>> getMyProducts() async {
    try {
      final response = await _dio.get('/vendor/products');
      return List<dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'load products');
    }
  }

  // --- CREATE PRODUCT ---
  Future<void> createProduct(Map<String, dynamic> data) async {
    try {
      // Your NestJS backend expects price/stock as numbers
      data['price'] = double.parse(data['price'].toString());
      data['stock'] = int.parse(data['stock'].toString());
      await _dio.post('/products', data: data);
    } on DioException catch (e) {
      throw _handleError(e, 'create product');
    }
  }

  // --- UPDATE PRODUCT ---
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      if (data.containsKey('price')) {
        data['price'] = double.parse(data['price'].toString());
      }
      if (data.containsKey('stock')) {
        data['stock'] = int.parse(data['stock'].toString());
      }
      await _dio.patch('/products/$id', data: data);
    } on DioException catch (e) {
      throw _handleError(e, 'update product');
    }
  }

  // --- DELETE PRODUCT ---
  Future<void> deleteProduct(String id) async {
    try {
      await _dio.delete('/products/$id');
    } on DioException catch (e) {
      throw _handleError(e, 'delete product');
    }
  }

  // --- FETCH ALL ORDERS (VENDOR/ADMIN) ---
  Future<List<dynamic>> getVendorOrders() async {
    try {
      final response = await _dio.get('/orders/admin/all');
      return List<dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e, 'load vendor orders');
    }
  }

  // --- UPDATE ORDER STATUS ---
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _dio.patch(
        '/orders/$orderId/status',
        data: {'status': newStatus},
      );
    } on DioException catch (e) {
      throw _handleError(e, 'update order status');
    }
  }

  // --- UPDATE VENDOR PROFILE STORE SETTINGS ---
  Future<void> updateVendorProfile({
    required String shopName,
    required String shopAddress,
    required String shopDescription,
    File? imageFile,
  }) async {
    try {
      final Map<String, dynamic> formMap = {
        "shopName": shopName,
        "shopAddress": shopAddress,
        "shopDescription": shopDescription,
      };

      if (imageFile != null) {
        formMap["file"] = await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        );
      }

      final formData = FormData.fromMap(formMap);

      await _dio.patch(
        '/vendor/profile/update',
        data: formData,
        options: Options(
          headers: {
            "Content-Type": "multipart/form-data",
          },
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e, 'update vendor profile');
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
