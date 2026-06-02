import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:provider/provider.dart';
import 'features/integrates services/LakbAi/providers/lakbai_admin_provider.dart';
import 'features/integrates services/LakbAi/providers/lakbai_auth_provider.dart';
import 'features/integrates services/LakbAi/providers/lakbai_destinations_provider.dart';
import 'features/integrates services/LakbAi/providers/lakbai_itinerary_provider.dart';
import 'features/integrates services/social_health/auth/social_health_auth_provider.dart';



import 'core/constants/api_constants.dart';
import 'core/services/api_service.dart';
import 'core/services/google_auth_service.dart';
import 'core/services/meta_auth_service.dart';
import 'core/services/secure_storage_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/services/auth_api_service.dart';
import 'features/auth/auth_provider.dart';
import 'features/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

      final initialized = await FacebookAuth.i.isWebSdkInitialized;
      debugPrint('Facebook Web SDK initialized: $initialized');
    }
  }

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

  runApp(
    MultiProvider(
      
      providers: [
        ChangeNotifierProvider(
          create: (_) => SocialHealthAuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authRepository),
        ),

          // ADD THESE LINES inside your MultiProvider's list:
      ChangeNotifierProvider(create: (_) => LakbaiAuthProvider()),
      ChangeNotifierProvider(create: (_) => LakbaiDestinationsProvider()),
      ChangeNotifierProvider(create: (_) => LakbaiItineraryProvider()),
      ChangeNotifierProvider(create: (_) => LakbaiAdminProvider()),
      ],
      child: const TawiTawiApp(),
      
    ),
    
  );
}

class TawiTawiApp extends StatelessWidget {
  const TawiTawiApp({super.key});

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color(0xFF064E3B);
    const mainGreen = Color(0xFF0F766E);
    const softGreen = Color(0xFFEFFAF5);

    return MaterialApp(
      title: 'Tawi-Tawi App',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const NoScrollbarScrollBehavior(),
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: softGreen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: mainGreen,
          primary: mainGreen,
          secondary: darkGreen,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkGreen,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
              color: Colors.green.shade100,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: mainGreen,
              width: 2,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: darkGreen,
            side: const BorderSide(color: darkGreen),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
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