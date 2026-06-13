import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart' as tawi_provider;
import 'package:tawi_tawi_frontend/features/auth/auth_provider.dart' as tawi_auth;

import 'package:dio/dio.dart';
import 'package:tawi_tawi_frontend/core/constants/api_constants.dart';
// Import Zentromart's providers and screens
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/auth/providers/auth_provider.dart' as zentro_auth;
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/auth/screens/home_screen.dart' as zentromart_home;
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/auth/screens/zentromart_register_screen.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/auth/screens/zentromart_sso_register_screen.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/vendor/screens/vendor_dashboard_screen.dart';

class ZentromartLinkScreen extends ConsumerStatefulWidget {
  const ZentromartLinkScreen({super.key});

  @override
  ConsumerState<ZentromartLinkScreen> createState() => _ZentromartLinkScreenState();
}

class _ZentromartLinkScreenState extends ConsumerState<ZentromartLinkScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingSession();
    });
  }

  Future<void> _checkExistingSession() async {
    try {
      final tawiAuth = tawi_provider.Provider.of<tawi_auth.AuthProvider>(context, listen: false);
      final currentTawiEmail = tawiAuth.userEmail;

      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('saved_user');

      if (userJson != null) {
        final Map<String, dynamic> data = jsonDecode(userJson);
        final String savedEmail = data['user']?['email']?.toString() ?? '';
        final String role = data['user']?['role']?.toString().toUpperCase() ?? 'USER';
        
        // SECURITY CHECK: Ensure the saved Zentromart session belongs to the current Tawi-Tawi user!
        if (savedEmail.isNotEmpty && savedEmail != currentTawiEmail) {
          // Different user logged in! Clear the old Zentromart session.
          await prefs.remove('saved_user');
          return;
        }

        if (!mounted) return;
        if (role == 'VENDOR') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const VendorDashboardScreen()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const zentromart_home.HomeScreen()));
        }
      }
    } catch (e) {
      // ignore and let them link
    }
  }

  Future<void> _finalizeLink(String email, String name, String tawiToken, [String? assignedRole]) async {
    setState(() => _isLoading = true);
    try {
      final String role = assignedRole ?? await ref.read(zentro_auth.authProvider.notifier).checkAccount(email) ?? 'USER';
      
      await ref.read(zentro_auth.authProvider.notifier).linkTawiTawiSession(email, name, role, tawiToken);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully linked to ZentroMart!'),
          backgroundColor: Colors.green,
        ),
      );

      if (role.toUpperCase() == 'VENDOR') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VendorDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const zentromart_home.HomeScreen()),
        );
      }
    } catch (e, stackTrace) {
      print('Error finalizing link: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to link account locally: $e')),
        );
      }
    }
  }

  void _showRegistrationDialog(String name, String email, String tawiToken, Dio dio, String targetUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ZentromartSsoRegisterScreen(
          name: name,
          email: email,
          tawiToken: tawiToken,
          dio: dio,
          targetUrl: targetUrl,
        ),
      ),
    );
  }

  void _linkAccount() async {
    setState(() {
      _isLoading = true;
    });

    final tawiAuth = tawi_provider.Provider.of<tawi_auth.AuthProvider>(context, listen: false);
    final email = tawiAuth.userEmail;
    final name = tawiAuth.userName;

    try {
      final tawiToken = tawiAuth.token;
      if (tawiToken == null) throw Exception("Tawi-Tawi token is missing");

      final dio = Dio();
      final String targetUrl = ApiConstants.graphql;

      final verifyResponse = await dio.post(
        targetUrl,
        data: {
          'query': '''
            query VerifyAccess(\$serviceName: String!) {
              verifyServiceAccess(serviceName: \$serviceName) {
                hasAccess
                requiresRegistration
                role
              }
            }
          ''',
          'variables': {
            'serviceName': 'ecommerce',
          }
        },
        options: Options(headers: {'Authorization': 'Bearer $tawiToken'}),
      );

      final responseData = verifyResponse.data;
      if (responseData['data'] == null) {
        throw Exception("GraphQL Error during verify: ${responseData['errors'] ?? responseData}");
      }
      final verifyData = responseData['data']['verifyServiceAccess'];
      bool hasAccess = verifyData?['hasAccess'] ?? false;
      bool requiresRegistration = verifyData?['requiresRegistration'] ?? false;
      String? backendRole = verifyData?['role'];

      setState(() => _isLoading = false);

      if (!hasAccess && requiresRegistration) {
        _showRegistrationDialog(name, email, tawiToken, dio, targetUrl);
      } else if (hasAccess) {
        await _finalizeLink(email, name, tawiToken, backendRole);
      } else {
        throw Exception("Failed to authorize with ZentroMart backend.");
      }
    } catch (e, stackTrace) {
      print('Error linking Zentromart account: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Link Account', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.storefront_rounded,
                size: 100,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to ZentroMart!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Link your Tawi-Tawi account to ZentroMart to start shopping with exclusive deals and seamless experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _linkAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Link Account & Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
