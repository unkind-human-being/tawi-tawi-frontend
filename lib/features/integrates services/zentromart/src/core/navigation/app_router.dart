import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/home_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/vendor/screens/vendor_dashboard_screen.dart';

// New reactive state to track onboarding progress
final onboardingCompletedProvider = StateProvider<bool>((ref) => true);

class AppRoutes {
  static const String home = '/home';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String vendor = '/vendor';
}

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Just return HomeScreen since we removed login
    return const HomeScreen();
  }

  static Map<String, WidgetBuilder> getNamedRoutes() {
    return {
      AppRoutes.home: (context) => const HomeScreen(),
      AppRoutes.cart: (context) => const CartScreen(),
      AppRoutes.orders: (context) => const OrdersScreen(),
      AppRoutes.vendor: (context) => const VendorDashboardScreen(),
    };
  }
}
