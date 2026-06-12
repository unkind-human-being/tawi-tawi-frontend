import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

// --- ZENTROMART ISAR MODELS ---
import 'features/integrates services/zentromart/src/core/database/models/cart_item_model.dart';
import 'features/integrates services/zentromart/src/core/database/models/order_model.dart';
import 'features/integrates services/zentromart/src/core/database/models/product_model.dart';
import 'features/integrates services/zentromart/src/core/database/models/user_model.dart';
import 'features/integrates services/zentromart/src/core/network/sync_provider.dart';
// --- FIREBASE IMPORTS ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// Note: Ensure this path correctly points to your generated firebase_options.dart
import 'features/integrates services/pameyaan/app service introduction/firebase_options.dart';

// --- LAKBAI PROVIDERS ---
import 'features/integrates services/LakbAi/providers/lakbai_admin_provider.dart';
import 'features/integrates services/LakbAi/providers/lakbai_auth_provider.dart';
import 'features/integrates services/LakbAi/providers/lakbai_destinations_provider.dart';
import 'features/integrates services/LakbAi/providers/lakbai_itinerary_provider.dart';

// --- MAIN APP AUTH & SERVICES ---
import 'features/integrates services/social_health/auth/social_health_auth_provider.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

import 'core/constants/api_constants.dart';
import 'core/services/api_service.dart';
import 'core/services/google_auth_service.dart';
import 'core/services/meta_auth_service.dart';
import 'core/services/secure_storage_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/auth_api_service.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/main/main_screen.dart';

// --- PAMEYAAN PROVIDERS ---
import 'features/integrates services/pameyaan/app service introduction/core/network/network_provider.dart';

// --- FIREBASE BACKGROUND HANDLER ---
// This must remain outside of any class
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- ADDED ZENTROMART ISAR INITIALIZATION ---
  Isar? isarInstance;
  try {
    final dir = await getApplicationDocumentsDirectory();
    if (Isar.getInstance() != null) {
      isarInstance = Isar.getInstance()!;
    } else {
      isarInstance = await Isar.open(
        [CartItemModelSchema, OrderModelSchema, OrderItemModelSchema, ProductModelSchema, UserModelSchema],
        directory: dir.path,
      );
    }
  } catch (e) {
    debugPrint('Isar Initialization Error: $e');
  }

  // --- ADDED PAMEYAAN FIREBASE INITIALIZATION ---
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }

  // --- EXISTING META / FACEBOOK INIT ---
  if (kIsWeb) {
    if (ApiConstants.metaAppId.isEmpty) {
      debugPrint('META_APP_ID is missing. Meta login will not work.');
    } else {
      await FacebookAuth.i.webAndDesktopInitialize(
        appId: ApiConstants.metaAppId,
        cookie: true,
        xfbml: true,
        version: 'v19.0',
      );

      final initialized = FacebookAuth.i.isWebSdkInitialized;
      debugPrint('Facebook Web SDK initialized: $initialized');
    }
  }

  // --- APP SERVICES INIT ---
  final apiService = ApiService();
  final secureStorageService = SecureStorageService();
  final googleAuthService = GoogleAuthService();
  final metaAuthService = MetaAuthService();
  final authApiService = AuthApiService(apiService);

  final authRepository = AuthRepository(
    authApiService: authApiService,
    secureStorageService: secureStorageService,
    googleAuthService: googleAuthService,
    metaAuthService: metaAuthService,
  );

  final authProvider = AuthProvider(authRepository);
  await authProvider.initialize();
  runApp(
    ProviderScope(
      overrides: [
        if (isarInstance != null) isarProvider.overrideWithValue(isarInstance),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => SocialHealthAuthProvider()),
          ChangeNotifierProvider.value(value: authProvider),
          
          // LakbAi Providers
          ChangeNotifierProvider(create: (_) => LakbaiAuthProvider()),
          ChangeNotifierProvider(create: (_) => LakbaiDestinationsProvider()),
          ChangeNotifierProvider(create: (_) => LakbaiItineraryProvider()),
          ChangeNotifierProvider(create: (_) => LakbaiAdminProvider()),
          
          // Pameyaan Network Provider
          ChangeNotifierProvider(create: (_) => NetworkProvider()),
        ],
        child: const TawiTawiApp(),
      ),
    ),
  );
}

class TawiTawiApp extends StatelessWidget {
  const TawiTawiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();

    return MaterialApp(
      title: 'Kawman',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const NoScrollbarScrollBehavior(),
      themeMode: themeProvider.themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: authProvider.isAuthenticated ? const MainScreen() : const LoginScreen(),
    );
  }
}

class NoScrollbarScrollBehavior extends MaterialScrollBehavior {
  const NoScrollbarScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}