import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/products/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';

// A simple service to hit the public products endpoint
final customerProductsProvider = FutureProvider<List<Product>>((ref) async {
  final dio = ref.read(dioProvider);

  // Hit the root '/products' endpoint to get everyone's inventory
  final response = await dio.get('/products');

  final List<dynamic> rawData = response.data['items'];
  return rawData
      .map((json) => Product.fromJson(json as Map<String, dynamic>))
      .toList();
});
