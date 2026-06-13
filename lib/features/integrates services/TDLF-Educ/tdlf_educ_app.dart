import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'providers/course_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';

/// ════════════════════════════════════════════════════════════════════════
///  TDLF-Educ — drop-in module entry point.
///
///  This file lets the app run either standalone OR embedded inside a host
///  super-app (e.g. the Tawi-Tawi frontend). The host only needs to:
///    1. copy this project's `lib/` into its modules folder,
///    2. add this project's dependencies to its pubspec.yaml,
///    3. open `const TdlfEducApp()` from a button/route.
///
///  `TdlfEducApp` initializes everything it needs itself (Supabase + desktop
///  SQLite), brings its own providers, and renders its own themed MaterialApp,
///  so it behaves exactly the same whether standalone or embedded.
/// ════════════════════════════════════════════════════════════════════════

bool _initialized = false;

/// Idempotent one-time setup. Safe to call repeatedly and safe to call from a
/// host app that may have already initialized Flutter/Supabase.
Future<void> ensureTdlfEducInitialized() async {
  if (_initialized) return;
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop (Windows/Linux) needs the FFI sqlite implementation.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Only initialize Supabase if the host app hasn't already done so.
  var alreadyInitialized = true;
  try {
    Supabase.instance; // throws if not yet initialized
  } catch (_) {
    alreadyInitialized = false;
  }
  if (!alreadyInitialized) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  _initialized = true;
}

/// Public entry widget. Open this from the host (e.g. a launcher tile):
///   Navigator.push(context,
///       MaterialPageRoute(builder: (_) => const TdlfEducApp()));
class TdlfEducApp extends StatefulWidget {
  /// When `true`, the module skips its own sign-in/sign-up and opens straight
  /// into the content as a read-only guest. Use this when launching from a host
  /// super-app (e.g. Tawi-Tawi) that has already authenticated the user.
  /// Defaults to `false` so the standalone app keeps its own login.
  final bool guestMode;

  const TdlfEducApp({super.key, this.guestMode = false});

  @override
  State<TdlfEducApp> createState() => _TdlfEducAppState();
}

class _TdlfEducAppState extends State<TdlfEducApp> {
  late final Future<void> _ready = ensureTdlfEducInitialized();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Works with or without a MaterialApp ancestor.
          return const Directionality(
            textDirection: TextDirection.ltr,
            child: ColoredBox(
              color: Color(0xFF0D0B1C),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          );
        }
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(
                create: (_) => AuthProvider(guest: widget.guestMode)),
            ChangeNotifierProvider(create: (_) => BookProvider()),
            ChangeNotifierProvider(create: (_) => QuizProvider()),
            ChangeNotifierProvider(create: (_) => CourseProvider()),
          ],
          child: const _TdlfEducRoot(),
        );
      },
    );
  }
}

/// The themed MaterialApp + auth gate (its own navigator, so it stays isolated
/// when embedded inside another app).
class _TdlfEducRoot extends StatelessWidget {
  const _TdlfEducRoot();

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, _) {
        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: authProvider.isLoggedIn
              ? const HomeScreen()
              : const LoginScreen(),
          routes: {
            '/home': (context) => const HomeScreen(),
            '/login': (context) => const LoginScreen(),
          },
        );
      },
    );
  }
}
