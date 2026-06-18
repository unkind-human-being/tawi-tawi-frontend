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
import 'widgets/app_logo.dart';
import 'widgets/aurora_background.dart';

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

  // Only initialize Supabase if the host app hasn't already done so. We must
  // probe `Supabase.instance.client` (the late field), NOT `Supabase.instance`:
  // the singleton object exists before initialize(), so checking `.instance`
  // alone wrongly reported "already initialized" and skipped setup — which left
  // `client` unset and threw "LateInitializationError: Field 'client'..." on
  // the first cloud call (e.g. sign-up).
  var alreadyInitialized = true;
  try {
    Supabase.instance.client; // throws until initialize() has run
  } catch (_) {
    alreadyInitialized = false;
  }
  if (!alreadyInitialized) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: AppConfig.supabaseAnonKey,
      );
    } catch (e) {
      // If a host app initialized it in parallel, ignore the double-init error.
      if (!e.toString().toLowerCase().contains('already initialized')) {
        rethrow;
      }
    }
  }

  _initialized = true;
}

/// Public entry widget. Open this from the host (e.g. a launcher tile):
///   Navigator.push(context,
///       MaterialPageRoute(builder: (_) => const TdlfEducApp()));
class TdlfEducApp extends StatefulWidget {
  /// `true` when launched inside a host super-app (e.g. Tawi-Tawi): shows a
  /// branded welcome and keeps the "return to host" controls. Defaults to
  /// `false` for the standalone app.
  final bool embedded;

  /// The host's logged-in user (Tawi-Tawi). When provided, the welcome's
  /// "Continue" signs them straight into a matching TDLF-Educ (Supabase)
  /// account derived from their email — no extra sign-up.
  final String? hostEmail;
  final String? hostName;

  const TdlfEducApp({
    super.key,
    this.embedded = false,
    this.hostEmail,
    this.hostName,
  });

  @override
  State<TdlfEducApp> createState() => _TdlfEducAppState();
}

class _TdlfEducAppState extends State<TdlfEducApp> {
  late final Future<void> _ready = ensureTdlfEducInitialized();
  bool _continued = false;

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
                create: (_) => AuthProvider(embedded: widget.embedded)),
            ChangeNotifierProvider(create: (_) => BookProvider()),
            ChangeNotifierProvider(create: (_) => QuizProvider()),
            ChangeNotifierProvider(create: (_) => CourseProvider()),
          ],
          child: _TdlfEducRoot(
            embedded: widget.embedded,
            hostEmail: widget.hostEmail,
            hostName: widget.hostName,
            // When opened from a host, show a branded welcome first.
            showWelcome: widget.embedded && !_continued,
            onProceed: () => setState(() => _continued = true),
          ),
        );
      },
    );
  }
}

/// The themed MaterialApp + auth gate (its own navigator, so it stays isolated
/// when embedded inside another app).
class _TdlfEducRoot extends StatelessWidget {
  final bool embedded;
  final String? hostEmail;
  final String? hostName;
  final bool showWelcome;
  final VoidCallback onProceed;
  const _TdlfEducRoot({
    required this.embedded,
    required this.hostEmail,
    required this.hostName,
    required this.showWelcome,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, _) {
        final Widget content;
        if (showWelcome && !authProvider.isLoggedIn) {
          content = _EmbeddedWelcome(
            hostEmail: hostEmail,
            hostName: hostName,
            onProceed: onProceed,
          );
        } else if (authProvider.isLoggedIn) {
          content = const HomeScreen();
        } else {
          // Embedded sign-in is pre-filled with the host email (their account).
          content = LoginScreen(prefillEmail: embedded ? hostEmail : null);
        }
        return MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          // Embedded: the Android back gesture returns to the host from any
          // screen.
          home: embedded ? _HostBackScope(child: content) : content,
          routes: {
            '/home': (context) => embedded
                ? const _HostBackScope(child: HomeScreen())
                : const HomeScreen(),
            '/login': (context) => const LoginScreen(),
          },
        );
      },
    );
  }
}

/// Wraps a screen so the Android back gesture/button returns to the host app
/// instead of doing nothing (used in embedded mode).
class _HostBackScope extends StatelessWidget {
  final Widget child;
  const _HostBackScope({required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context, rootNavigator: true).maybePop();
        }
      },
      child: child,
    );
  }
}

/// Branded welcome shown when the module is opened from a host app (Tawi-Tawi).
/// "Continue" signs the user into a TDLF-Educ account derived from their host
/// account; or they can use their own TDLF-Educ account instead.
class _EmbeddedWelcome extends StatefulWidget {
  final String? hostEmail;
  final String? hostName;
  final VoidCallback onProceed;
  const _EmbeddedWelcome({
    required this.hostEmail,
    required this.hostName,
    required this.onProceed,
  });

  @override
  State<_EmbeddedWelcome> createState() => _EmbeddedWelcomeState();
}

class _EmbeddedWelcomeState extends State<_EmbeddedWelcome> {
  bool _loading = false;
  String? _error;

  bool get _hasHostUser => (widget.hostEmail ?? '').trim().isNotEmpty;

  Future<void> _continueWithHost() async {
    if (!_hasHostUser) {
      widget.onProceed(); // no host user → go to sign-in/up
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<AuthProvider>().signInAsHostUser(
          widget.hostEmail!.trim(),
          (widget.hostName ?? '').trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    final lower = err?.toLowerCase() ?? '';
    if (err == null) {
      widget.onProceed(); // signed in → home
    } else if (lower.contains('already has a tdlf') ||
        lower.contains('sign in with your password')) {
      // Their email already has a TDLF-Educ account — go straight to a
      // pre-filled sign-in (this is also the cross-app sync path).
      widget.onProceed();
    } else {
      setState(() => _error = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final firstName = (widget.hostName ?? '').trim().split(' ').first;
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Column(
              children: [
                const Spacer(flex: 3),
                const AppLogo(size: 116, showWordmark: true),
                const SizedBox(height: 18),
                Text(
                  _hasHostUser && firstName.isNotEmpty
                      ? 'Welcome, $firstName!'
                      : 'Welcome!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  'Books and quizzes for every subject — built to work even '
                  'offline.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.5, height: 1.4, color: cs.onSurfaceVariant),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12.5, color: cs.onErrorContainer)),
                  ),
                ],
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _continueWithHost,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            _hasHostUser ? 'Continue' : 'Sign In / Sign Up',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                if (_hasHostUser) ...[
                  const SizedBox(height: 2),
                  TextButton(
                    onPressed: _loading ? null : widget.onProceed,
                    child: const Text('Use a TDLF-Educ account instead'),
                  ),
                ],
                TextButton(
                  onPressed: _loading
                      ? null
                      : () =>
                          Navigator.of(context, rootNavigator: true).maybePop(),
                  child: const Text('Back to Tawi-Tawi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
