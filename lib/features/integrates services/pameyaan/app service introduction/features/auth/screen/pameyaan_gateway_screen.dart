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
import 'role_selection_screen.dart'; 

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
      
      print("[PameyaanGateway] Starting Handshake...");
      print("[PameyaanGateway] URL: $graphqlUrl");
      print("[PameyaanGateway] Using Token: ${mainToken.substring(0, 10)}...");

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

      print("[PameyaanGateway] STATUS CODE: ${verifyResponse.statusCode}");
      print("[PameyaanGateway] RAW RESPONSE: ${verifyResponse.body}");

      final verifyData = jsonDecode(verifyResponse.body);
      
      if (verifyData['errors'] != null) {
         throw Exception(verifyData['errors'][0]['message']);
      }

      final accessData = verifyData['data']['verifyServiceAccess'];
      bool isLinked = accessData['hasAccess'] ?? false;
      bool requiresRegistration = accessData['requiresRegistration'] ?? false;
      
      // This will safely resolve to null since we are no longer querying it, 
      // allowing the widget.isDriver fallback to take over.
      String? userRole = accessData['role']; 

      // SCENARIO A: Account Exists (Check Commuter vs Driver)
      if (isLinked) {
        print("[PameyaanGateway] Access Granted. Routing as: ${userRole ?? (widget.isDriver ? 'driver' : 'commuter')}");
        ApiClient.instance.options.headers['Authorization'] = 'Bearer $mainToken';
        
        // DYNAMIC ROUTING: Route based on their actual database role
        if (userRole == 'driver' || (userRole == null && widget.isDriver)) {
          _routeToDriver(mainUser.fullName, mainUser.id);
        } else {
          // Defaults to Commuter if role is 'commuter' or null
          _routeToCommuter(mainUser.fullName, mainUser.id, mainUser.email);
        }
        return;
      }
 
      if (requiresRegistration) {
        setState(() => _statusMessage = 'Setting up your transport profile...');
        
        final Map<String, dynamic> registrationPayload = widget.isDriver 
            ? {"role": "driver", "franchise_number": mainUser.id} 
            : {"discount_status": "Regular"};

        print("[PameyaanGateway] Auto-Registering for Transport Service...");

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

        print("🚨 [PameyaanGateway] REGISTRATION RESPONSE: ${regResponse.body}");

        final regData = jsonDecode(regResponse.body);
        if (regData['errors'] != null) {
           throw Exception(regData['errors'][0]['message']);
        }

        final regAccessData = regData['data']['registerForService'];
        
        if (regAccessData['hasAccess'] == true && mounted) {
          ApiClient.instance.options.headers['Authorization'] = 'Bearer $mainToken';
          
          if (widget.isDriver) {
            _routeToDriver(mainUser.fullName, mainUser.id);
          } else {
            _routeToCommuter(mainUser.fullName, mainUser.id, mainUser.email);
          }
        } else {
          throw Exception('Auto-provisioning failed.');
        }
      }
    } catch (e) {
      print("❌ [PameyaanGateway] HANDSHAKE FATAL ERROR: $e");
      
      setState(() {
        _isChecking = false;
        _statusMessage = 'Handshake failed.\nEnsure TRANSPORT_SERVICE_URL is set in Render.\n${e.toString()}';
      });
    }
  }

  void _routeToDriver(String? name, String userId) {
    final safeName = name ?? 'Driver'; // Fallback if name is missing
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DriverDashboardScreen(
          driverName: safeName,
          initials: safeName.isNotEmpty ? safeName[0].toUpperCase() : 'D',
          franchiseNumber: userId, 
        ),
      ),
    );
  }

  void _routeToCommuter(String? name, String userId, String? email) {
    final safeName = name ?? 'Citizen'; // Fallback if name is missing
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CommuterAppScreen(
          fullName: safeName,
          initials: safeName.isNotEmpty ? safeName[0].toUpperCase() : 'C',
          discountStatus: 'Regular', 
          email: email ?? 'no-email@provided.com', // Safe Fallback!
        ),
      ),
    );
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