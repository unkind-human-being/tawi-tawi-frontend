import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/auth_provider.dart';
import 'core/api/marketplace_api.dart';
import 'core/local/local_db.dart';
import 'core/local/sync_service.dart';
import 'core/models/models.dart' show SessionUser;
import 'core/theme.dart';
import 'features/shell/shell_screen.dart';

/// Entry point that bridges Tawi-Tawi's auth into the full HanapGawa app.
/// Takes the Tawi-Tawi JWT token, initializes MarketplaceApi with it,
/// and launches ShellScreen directly — no HanapGawa login needed.
class HanapGawaEntryScreen extends StatefulWidget {
  const HanapGawaEntryScreen({super.key});

  @override
  State<HanapGawaEntryScreen> createState() => _HanapGawaEntryScreenState();
}

class _HanapGawaEntryScreenState extends State<HanapGawaEntryScreen> {
  static const Color _primary = Color(0xFFB45309);
  static const Color _bg = Color(0xFFFFFBEB);

  static const String _hanapGawaBaseUrl = String.fromEnvironment(
    'HANAPGAWA_API_URL',
    defaultValue: 'https://tawi-tawi-backend.onrender.com/api/hanapgawa',
  );

  MarketplaceApi? _api;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token ?? '';
      final tawiUser = authProvider.user;

      if (token.trim().isEmpty) {
        setState(() => _error = 'You must be logged into Tawi-Tawi to use Hanap Gawa.');
        return;
      }

      // In the Kawman flow the token is always injected fresh from Kawman auth,
      // so we never want a cached HanapGawa identity from a previous session.
      // Clear identity prefs every open; ssoInit will restore the correct user.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hanapgawa_user');
      await prefs.remove('hanapgawa_token');

      // Wipe SQLite cache when the Kawman user changes so account data doesn't bleed.
      const _lastUserKey = 'hanapgawa_last_kawman_user';
      final lastUserId = prefs.getString(_lastUserKey) ?? '';
      final currentUserId = tawiUser?.id ?? '';
      if (currentUserId.isNotEmpty && lastUserId != currentUserId) {
        await LocalDb.instance.clearUserData();
        await prefs.setString(_lastUserKey, currentUserId);
      }

      final api = MarketplaceApi(baseUrlOverride: _hanapGawaBaseUrl);

      // Build a minimal SessionUser from the Tawi-Tawi account
      SessionUser? sessionUser;
      if (tawiUser != null) {
        sessionUser = SessionUser(
          id: tawiUser.id,
          email: tawiUser.email,
          role: 'user',
          fullName: tawiUser.fullName,
          status: 'approved',
          emailVerified: true,
        );
      }

      await api.initWithToken(token, user: sessionUser);

      // Register/link the Tawi-Tawi user into HanapGawa's database.
      // Cached per-user (1 hour TTL) so it only fires once per session.
      if (tawiUser != null) {
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = 'hanapgawa_sso_init_${tawiUser.id}';
        final lastInit = prefs.getInt(cacheKey) ?? 0;
        final hourAgo = DateTime.now()
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch;
        if (lastInit < hourAgo) {
          await api.ssoInit(
            email: tawiUser.email,
            fullName: tawiUser.fullName,
          );
          await prefs.setInt(cacheKey, DateTime.now().millisecondsSinceEpoch);
        }
      }

      if (!kIsWeb) {
        await LocalDb.instance.db;
        await SyncService.instance.initialize(api);
      }

      if (!mounted) return;
      setState(() {
        _api = api;
        _ready = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _logout() async {
    await _api?.clearSession();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          title: const Text('Hanap Gawa',
              style: TextStyle(fontWeight: FontWeight.w900)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFB45309), size: 52),
                const SizedBox(height: 16),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFF44403C),
                        fontWeight: FontWeight.w700,
                        height: 1.45)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    setState(() => _error = null);
                    _init();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_ready || _api == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _primary),
              SizedBox(height: 18),
              Text('Loading Hanap Gawa...',
                  style: TextStyle(
                      color: Color(0xFF78716C), fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
    }

    // Wrap in a Theme so HanapGawa's own theme applies inside Tawi-Tawi
    return Theme(
      data: buildTheme(),
      child: ShellScreen(api: _api!, onLogout: _logout),
    );
  }
}
