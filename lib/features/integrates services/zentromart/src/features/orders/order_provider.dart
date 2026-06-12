import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../core/network/dio_provider.dart';
import '../../core/network/sync_provider.dart';
import '../../core/database/models/order_model.dart';
import 'order.dart';
import 'order_service.dart';

final orderServiceProvider = Provider<OrderService>((ref) {
  final dio = ref.read(dioProvider);
  return OrderService(dio);
});

final orderProvider = AsyncNotifierProvider<OrderNotifier, List<Order>>(() {
  return OrderNotifier();
});

class OrderNotifier extends AsyncNotifier<List<Order>> {
  @override
  FutureOr<List<Order>> build() async {
    return _fetchAndCacheOrders();
  }

  Future<List<Order>> _fetchAndCacheOrders() async {
    final isar = ref.read(isarProvider);
    final service = ref.read(orderServiceProvider);

    final cachedModels = await isar.orderModels.where().findAll();

    try {
      final List<dynamic> rawData = await service.getOrders();

      final List<OrderModel> freshModels = rawData.map((e) {
        final json = e as Map<String, dynamic>;

        final paymentMap = json['payment'] as Map<String, dynamic>?;
        final String rawMethod = paymentMap?['method']?.toString() ?? 'COD';
        final String formattedMethod =
            rawMethod.toUpperCase() == 'GCASH' ? 'GCash' : 'Cash on Delivery';

        return OrderModel()
          ..backendId = json['id']?.toString() ?? ''
          ..total = double.tryParse(json['total']?.toString() ?? '0.0') ?? 0.0
          ..status = json['status']?.toString() ?? 'PENDING'
          ..paymentMethod = formattedMethod
          ..createdAt = json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now();
      }).toList();

      await isar.writeTxn(() async {
        await isar.orderModels.putAllByBackendId(freshModels);
      });

      return freshModels
          .map((m) => Order(
                id: m.backendId ?? '',
                total: m.total,
                status: m.status,
                createdAt: m.createdAt,
                paymentMethod: m.paymentMethod,
                items: const [],
              ))
          .toList();
    } catch (e) {
      if (cachedModels.isNotEmpty) {
        return cachedModels
            .map((m) => Order(
                  id: m.backendId ?? '',
                  total: m.total,
                  status: m.status,
                  createdAt: m.createdAt,
                  paymentMethod: m.paymentMethod,
                  items: const [],
                ))
            .toList();
      }
      return const [];
    }
  }

  Future<void> refreshOrders() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAndCacheOrders());
  }
}
