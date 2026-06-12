import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../core/network/dio_provider.dart';
import '../../core/network/sync_provider.dart';
import '../../core/database/models/user_model.dart';
import 'profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  final dio = ref.read(dioProvider);
  return ProfileService(dio);
});

// Upgraded to AsyncNotifierProvider for better scalability
final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, Map<String, dynamic>>(() {
  return UserProfileNotifier();
});

class UserProfileNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  FutureOr<Map<String, dynamic>> build() async {
    return _fetchAndCacheProfile();
  }

  Future<Map<String, dynamic>> _fetchAndCacheProfile() async {
    final isar = ref.read(isarProvider);
    final service = ref.read(profileServiceProvider);

    var cachedUser = await isar.userModels.where().findFirst();

    try {
      final Map<String, dynamic> remoteProfile = await service.getMe();

      await isar.writeTxn(() async {
        // FIX: Create a new UserModel if one doesn't exist in the cache yet
        final userToSave = cachedUser ?? UserModel();

        userToSave.name = remoteProfile['name'] ?? userToSave.name;
        userToSave.role = remoteProfile['role'] ?? userToSave.role;
        userToSave.shopName = remoteProfile['shopName'] ?? userToSave.shopName;
        userToSave.shopAddress =
            remoteProfile['shopAddress'] ?? userToSave.shopAddress;
        userToSave.isSynced = true;

        // If it's a new cache entry, ensure required fields like email are mapped
        if (cachedUser == null) {
          userToSave.email = remoteProfile['email'];
          // Map your remote ID here if needed: userToSave.id = remoteProfile['id'];
        }

        await isar.userModels.put(userToSave);
      });

      return remoteProfile;
    } catch (e) {
      if (cachedUser != null) {
        return {
          'id': cachedUser.id.toString(),
          'email': cachedUser.email,
          'name': cachedUser.name,
          'role': cachedUser.role,
          'shopName': cachedUser.shopName ?? '',
          'shopAddress': cachedUser.shopAddress ?? '',
        };
      }
      throw Exception(
          "Authentication data profile properties not found cached inside internal device memory.");
    }
  }

  // ADDED: A helper to manually trigger a profile refresh from your UI
  Future<void> refreshProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAndCacheProfile());
  }
}
