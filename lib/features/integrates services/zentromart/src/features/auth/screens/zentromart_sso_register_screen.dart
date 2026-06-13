import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/auth/providers/auth_provider.dart' as zentro_auth;
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/auth/screens/home_screen.dart' as zentromart_home;
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/vendor/screens/vendor_dashboard_screen.dart';

class ZentromartSsoRegisterScreen extends ConsumerStatefulWidget {
  final String name;
  final String email;
  final String tawiToken;
  final Dio dio;
  final String targetUrl;

  const ZentromartSsoRegisterScreen({
    super.key,
    required this.name,
    required this.email,
    required this.tawiToken,
    required this.dio,
    required this.targetUrl,
  });

  @override
  ConsumerState<ZentromartSsoRegisterScreen> createState() => _ZentromartSsoRegisterScreenState();
}

class _ZentromartSsoRegisterScreenState extends ConsumerState<ZentromartSsoRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();

  String _selectedRole = 'USER';
  bool _isRegistering = false;

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopAddressController.dispose();
    super.dispose();
  }

  Future<void> _finalizeLink(String role) async {
    try {
      await ref.read(zentro_auth.authProvider.notifier).linkTawiTawiSession(
            widget.email,
            widget.name,
            role,
            widget.tawiToken,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created and linked successfully!'),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to link account locally: $e')),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    if (_selectedRole == 'VENDOR') {
      if (_shopNameController.text.trim().isEmpty ||
          _shopAddressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Shop Name and Address are required for Vendors"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRegistering = true);

    try {
      final payloadData = {
        "role": _selectedRole,
      };

      if (_selectedRole == 'VENDOR') {
        payloadData["shopName"] = _shopNameController.text.trim();
        payloadData["shopAddress"] = _shopAddressController.text.trim();
      }

      final payloadString = jsonEncode(payloadData).replaceAll('"', '\\"');

      final registerResponse = await widget.dio.post(
        widget.targetUrl,
        data: {
          'query': '''
            mutation RegisterService(\$serviceName: String!, \$payload: String!) {
              registerForService(serviceName: \$serviceName, payload: \$payload) {
                hasAccess
              }
            }
          ''',
          'variables': {
            'serviceName': 'ecommerce',
            'payload': jsonEncode(payloadData),
          }
        },
        options: Options(headers: {'Authorization': 'Bearer ${widget.tawiToken}'}),
      );

      final registerDataRaw = registerResponse.data;
      if (registerDataRaw['data'] == null) {
        throw Exception("GraphQL Error during register: ${registerDataRaw['errors'] ?? registerDataRaw}");
      }
      bool hasAccess = registerDataRaw['data']['registerForService']?['hasAccess'] ?? false;

      if (!mounted) return;

      if (hasAccess) {
        await _finalizeLink(_selectedRole);
      } else {
        throw Exception("Failed to register with ZentroMart backend.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: _selectedRole,
        decoration: InputDecoration(
          labelText: "I want to...",
          prefixIcon: const Icon(Icons.work_outline),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        items: const [
          DropdownMenuItem(value: 'USER', child: Text("Shop as a Customer")),
          DropdownMenuItem(value: 'VENDOR', child: Text("Open a Store (Vendor)")),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _selectedRole = value);
          }
        },
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (v) => v!.isEmpty ? "Required" : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(iconTheme: const IconThemeData(color: Colors.black), 
        title: const Text("Create ZentroMart Account"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    size: 80,
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Almost there!",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black87, 
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You are linking your Tawi-Tawi account:\n${widget.email}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  _buildDropdown(),
                  if (_selectedRole == 'VENDOR') ...[
                    _buildField(_shopNameController, "Shop Name", Icons.storefront),
                    _buildField(_shopAddressController, "Shop Address", Icons.location_on_outlined),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isRegistering ? null : _handleRegister,
                    child: _isRegistering
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "CREATE ACCOUNT",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
