import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';

// A simple map provider to quickly grab the user data without needing a full Model/Service class right away.
final userProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/users/me');
  return response.data as Map<String, dynamic>;
});
