import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'sync_service.dart';
import 'dio_provider.dart';

// Create a provider to hold your active Isar instance safely
// You will override this in your main.dart during app startup
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider must be overridden in main.dart');
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final dio = ref.read(dioProvider);
  final isar = ref.read(isarProvider);
  return SyncService(dio, isar);
});
