import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

// Import Main App Auth
import '../../../../../../auth/auth_provider.dart'; 

// Import Pameyaan Core & Screens
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../commuter/screens/commuter_app_screen.dart';
import '../../driver/screens/driver_dashboard_screen.dart'; 

class PameyaanGatewayScreen extends StatefulWidget {
  final bool isDriver; 

  const PameyaanGatewayScreen({
    super.key, 
    this.isDriver = false, 
  });

  @override
  State<PameyaanGatewayScreen> createState() => _PameyaanGatewayScreenState();
}

class _PameyaanGatewayScreenState extends State<PameyaanGatewayScreen> {
  bool _isChecking = true;
  String _statusMessage = 'Connecting to Pameyaan Transport...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performHandshake();
    });
  }

  Future<void> _performHandshake() async {
    try {
      final mainAuth = context.read<AuthProvider>();
      final String? mainToken = mainAuth.token; 
      final mainUser = mainAuth.user;

      if (mainToken == null || mainUser == null) {
        setState(() {
          _isChecking = false;
          _statusMessage = 'Please log in to your Tawi-Tawi account first.';
        });
        return;
      }

      const String graphqlUrl = 'https://tawi-tawi-backend.onrender.com/graphql';

      final verifyResponse = await http.post(
        Uri.parse(graphqlUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $mainToken',
        },
        body: jsonEncode({
          'query': '''
            query VerifyServiceAccess(\$serviceName: String!) {
              verifyServiceAccess(serviceName: \$serviceName) {
                hasAccess
                requiresRegistration
              }
            }
          ''',
          'variables': {
            'serviceName': 'transportation',
          },
        }),
      );

      if (!mounted) return;

      final verifyData = jsonDecode(verifyResponse.body);
      
      if (verifyData['errors'] != null) {
         throw Exception(verifyData['errors'][0]['message']);
      }

      final accessData = verifyData['data']['verifyServiceAccess'];
      bool isLinked = accessData['hasAccess'] ?? false;
      bool requiresRegistration = accessData['requiresRegistration'] ?? false;

      // SCENARIO A: Account Exists
      if (isLinked) {
        ApiClient.instance.options.headers['Authorization'] = 'Bearer $mainToken';
        
        // FIXED: Removed redundant null check and passed email
        _routeUserToDashboard(mainUser.fullName, mainUser.id, mainUser.email);
        return;
      }

      // SCENARIO B: First-time User (Auto-Create Account)
      if (requiresRegistration) {
        setState(() => _statusMessage = 'Setting up your transport profile...');
        
        final Map<String, dynamic> registrationPayload = widget.isDriver 
            ? {"role": "driver", "franchise_number": mainUser.id} 
            : {"discount_status": "Regular"};

        final regResponse = await http.post(
          Uri.parse(graphqlUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $mainToken',
          },
          body: jsonEncode({
            'query': '''
              mutation RegisterForService(\$serviceName: String!, \$payload: String!) {
                registerForService(serviceName: \$serviceName, payload: \$payload) {
                  hasAccess
                }
              }
            ''',
            'variables': {
              'serviceName': 'transportation',
              'payload': jsonEncode(registrationPayload), 
            },
          }),
        );

        final regData = jsonDecode(regResponse.body);
        if (regData['errors'] != null) {
           throw Exception(regData['errors'][0]['message']);
        }

        final regAccessData = regData['data']['registerForService'];
        
        if (regAccessData['hasAccess'] == true && mounted) {
          ApiClient.instance.options.headers['Authorization'] = 'Bearer $mainToken';
          
          // FIXED: Removed redundant null check and passed email
          _routeUserToDashboard(mainUser.fullName, mainUser.id, mainUser.email);
        } else {
          throw Exception('Auto-provisioning failed.');
        }
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
        _statusMessage = 'Handshake failed.\nEnsure TRANSPORT_SERVICE_URL is set in Render.\n${e.toString()}';
      });
    }
  }

  // FIXED: Added email parameter
  void _routeUserToDashboard(String name, String userId, String email) {
    if (widget.isDriver) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverDashboardScreen(
            driverName: name,
            initials: name.isNotEmpty ? name[0].toUpperCase() : 'D',
            franchiseNumber: userId, 
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CommuterAppScreen(
            fullName: name,
            initials: name.isNotEmpty ? name[0].toUpperCase() : 'C',
            discountStatus: 'Regular', 
            email: email, // FIXED: Passed the required email argument
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepOcean, 
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isDriver ? Icons.local_taxi : Icons.directions_boat_filled, 
                  size: 64, 
                  color: AppColors.neonTeal
                ),
              ),
              const SizedBox(height: 32),
              
              if (_isChecking) ...[
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: AppColors.neonTeal,
                    strokeWidth: 3.5,
                  ),
                ),
              ] else ...[
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              ],
              
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              
              if (!_isChecking) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonTeal,
                    foregroundColor: AppColors.deepOcean,
                  ),
                  onPressed: () {
                    setState(() {
                      _isChecking = true;
                      _statusMessage = 'Retrying connection...';
                    });
                    _performHandshake();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('RETRY HANDSHAKE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back', style: TextStyle(color: Colors.white70)),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}