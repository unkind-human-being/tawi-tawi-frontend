import 'package:dio/dio.dart';

class ProductService {
  final Dio _dio;
  ProductService(this._dio);

  Future<dynamic> getProducts() async {
    try {
      final response = await _dio.get('/products');
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to load products from API: ${e.message}');
    }
  }
}
