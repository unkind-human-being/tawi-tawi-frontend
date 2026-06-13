import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/core/database/models/product_model.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/products/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:isar/isar.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/sync_provider.dart';
import '../services/vendor_service.dart';

class VendorOrder {
  final String id;
  final String customerName;
  final String productName;
  final double price;
  final int quantity;
  final String status;
  final DateTime createdAt;

  VendorOrder({
    required this.id,
    required this.customerName,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.status,
    required this.createdAt,
  });

  factory VendorOrder.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    final firstItem = itemsList.isNotEmpty ? itemsList[0] : null;

    return VendorOrder(
      id: json['id'] ?? '',
      customerName: json['user']?['name'] ?? 'Anonymous Buyer',
      productName: firstItem?['product']?['name'] ?? 'Unknown Item',
      price: (firstItem?['price'] as num? ?? 0.0).toDouble(),
      quantity: firstItem?['quantity'] as int? ?? 1,
      status: json['status'] ?? 'PENDING',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

final vendorServiceProvider = Provider<VendorService>((ref) {
  final dio = ref.read(dioProvider);
  return VendorService(dio);
});

final vendorStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(vendorServiceProvider);
  try {
    return await service.getStats();
  } catch (e) {
    return {
      'profile': {
        'shopName': 'Offline Store',
        'shopAddress': 'No Connection',
        'shopDescription': '',
        'avatarUrl': ''
      },
      'totalRevenue': 0.0,
      'lowStockCount': 0,
      'totalProducts': 0,
      'pendingOrders': 0
    };
  }
});

final vendorProductsProvider = StreamProvider<List<Product>>((ref) async* {
  final isar = ref.watch(isarProvider);

  _fetchRemoteVendorProducts(ref);

  final localStream = isar.productModels.where().watch(fireImmediately: true);

  await for (final cachedItems in localStream) {
    yield cachedItems
        .map((dbRow) => Product(
              id: dbRow.backendId,
              name: dbRow.name,
              description: dbRow.description,
              price: dbRow.price,
              stock: dbRow.stock,
              imageUrl: dbRow.imageUrl,
              vendorId: dbRow.categoryId ?? '',
              averageRating: 0.0,
              reviews: const [],
            ))
        .toList();
  }
});

Future<void> _fetchRemoteVendorProducts(Ref ref) async {
  final connectivity = await Connectivity().checkConnectivity();
  if (connectivity.contains(ConnectivityResult.none)) {
    return;
  }

  final service = ref.read(vendorServiceProvider);
  final isar = ref.read(isarProvider);

  try {
    final rawList = await service.getMyProducts();
    final serverProducts = rawList.map((json) {
      final map = json as Map<String, dynamic>;
      return ProductModel()
        ..backendId = map['id']?.toString() ?? ''
        ..sku = map['sku']?.toString() ?? map['id']?.toString() ?? ''
        ..name = map['name']?.toString() ?? ''
        ..description = map['description']?.toString() ?? ''
        ..price = double.tryParse(map['price']?.toString() ?? '0') ?? 0.0
        ..stock = int.tryParse(map['stock']?.toString() ?? '0') ?? 0
        ..imageUrl = map['imageUrl']?.toString()
        ..updatedAt = DateTime.now();
    }).toList();

    await isar.writeTxn(() async {
      await isar.productModels.clear();
      await isar.productModels.putAll(serverProducts);
    });
  } catch (e) {
    print("Background catalog sync paused: $e. Running smoothly on Isar.");
  }
}

final vendorOrdersProvider = FutureProvider<List<VendorOrder>>((ref) async {
  final service = ref.read(vendorServiceProvider);
  try {
    final rawList = await service.getVendorOrders();
    return rawList
        .map((json) => VendorOrder.fromJson(json as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

final vendorProductControllerProvider =
    Provider((ref) => VendorProductController(ref));

class VendorProductController {
  final Ref _ref;
  VendorProductController(this._ref);

  Future<void> saveProduct({
    required String? existingId,
    required Map<String, dynamic> data,
    required bool isOnline,
  }) async {
    final isar = _ref.read(isarProvider);
    final service = _ref.read(vendorServiceProvider);

    if (isOnline) {
      if (existingId == null || existingId.startsWith('offline_draft_')) {
        await service.createProduct(data);
      } else {
        await service.updateProduct(existingId, data);
      }

      // Force an immediate remote database fetch to update Isar cache fields
      await _fetchRemoteVendorProducts(_ref);
    } else {
      final localDraft = ProductModel()
        ..backendId = existingId ??
            'offline_draft_${DateTime.now().millisecondsSinceEpoch}'
        ..sku = 'DRAFT_${DateTime.now().microsecondsSinceEpoch}'
        ..name = data['name']
        ..description = data['description']
        ..price = double.tryParse(data['price'].toString()) ?? 0.0
        ..stock = int.tryParse(data['stock'].toString()) ?? 0
        ..imageUrl = data['imageUrl']
        ..updatedAt = DateTime.now();

      await isar.writeTxn(() async {
        await isar.productModels.putByBackendId(localDraft);
      });
    }
  }
}
