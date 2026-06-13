import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/core/database/models/product_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../core/network/dio_provider.dart';
import '../../core/network/sync_provider.dart';
import '../auth/providers/auth_provider.dart';
import 'product.dart';
import 'product_service.dart';

// ==========================================================================
// 1. NETWORK SERVICE PROVIDER
// ==========================================================================
final productServiceProvider = Provider<ProductService>((ref) {
  final dio = ref.read(dioProvider);
  return ProductService(dio);
});

// ==========================================================================
// 2. COMBINED OFFLINE-FIRST STREAM PROVIDER
// ==========================================================================
final productProvider = StreamProvider<List<Product>>((ref) async* {
  ref.watch(authProvider);

  final isar = ref.read(isarProvider);
  final service = ref.read(productServiceProvider);

  Future<void> syncRemoteProducts() async {
    try {
      final dynamic responseData = await service.getProducts();
      List<dynamic> remoteItems = [];

      if (responseData is Map<String, dynamic>) {
        remoteItems = responseData['items'] as List? ?? [];
      } else if (responseData is List) {
        remoteItems = responseData;
      }

      if (remoteItems.isNotEmpty) {
        final List<ProductModel> modelsToCache = remoteItems.map((e) {
          return ProductModel()
            ..backendId = e['id']?.toString() ?? ''
            ..sku = e['sku']?.toString() ?? ''
            ..name = e['name']?.toString() ?? 'Unknown Item'
            ..description = e['description']?.toString() ?? ''
            ..price = double.tryParse(e['price']?.toString() ?? '0.0') ?? 0.0
            ..stock = int.tryParse(e['stock']?.toString() ?? '0') ?? 0
            ..imageUrl = e['imageUrl']?.toString()
            ..categoryId = e['categoryId']?.toString()
            ..updatedAt = e['updatedAt'] != null
                ? DateTime.parse(e['updatedAt'])
                : DateTime.now();
        }).toList();

        await isar.writeTxn(() async {
          await isar.productModels.putAllByBackendId(modelsToCache);
        });
      }
    } catch (e) {
      print("Offline Cache Mode Active. Remote sync deferred: $e");
    }
  }

  syncRemoteProducts();

  yield* isar.productModels
      .where()
      .anyId()
      .watch(fireImmediately: true)
      .map((modelsList) {
    return modelsList.map((m) {
      // --- FIXED: Sanitize cache images to bypass empty string network code leaks ---
      final String? rawUrl = m.imageUrl?.trim();
      final String? sanitizedUrl =
          (rawUrl != null && rawUrl.isNotEmpty && rawUrl != "") ? rawUrl : null;

      return Product(
        id: m.backendId,
        name: m.name,
        description: m.description,
        price: m.price,
        stock: m.stock,
        imageUrl:
            sanitizedUrl, // <-- Passes a safe clean null option instead of a broken '' string!
        vendorId: '',
        averageRating: 0.0,
        reviews: const [],
      );
    }).toList();
  });
});

// ==========================================================================
// 3. FILTER STATE PROVIDERS
// ==========================================================================
final searchQueryProvider = StateProvider<String>((ref) => '');
final minPriceProvider = StateProvider<double>((ref) => 0.0);
final maxPriceProvider = StateProvider<double>((ref) => 100000.0);
final sortByProvider = StateProvider<String>((ref) => 'Newest');

// ==========================================================================
// 4. COMBINED FILTERED DATA PROVIDER
// ==========================================================================
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final productsAsync = ref.watch(productProvider);
  final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
  final minPrice = ref.watch(minPriceProvider);
  final maxPrice = ref.watch(maxPriceProvider);
  final sortBy = ref.watch(sortByProvider);

  final products = productsAsync.value ?? [];

  final filtered = products.where((p) {
    final matchesSearch = p.name.toLowerCase().contains(searchQuery);
    final matchesPrice = p.price >= minPrice && p.price <= maxPrice;
    return matchesSearch && matchesPrice;
  }).toList();

  if (sortBy == 'Price: Low-High') {
    filtered.sort((a, b) => a.price.compareTo(b.price));
  } else if (sortBy == 'Price: High-Low') {
    filtered.sort((a, b) => b.price.compareTo(a.price));
  }

  return filtered;
});
