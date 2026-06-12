import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/auth/screens/home_screen.dart' as zentromart_home;
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/vendor/screens/vendor_dashboard_screen.dart';

class ZentromartRegisterScreen extends ConsumerStatefulWidget {
  final String initialEmail;
  final String initialName;

  const ZentromartRegisterScreen({
    super.key,
    required this.initialEmail,
    required this.initialName,
  });

  @override
  ConsumerState<ZentromartRegisterScreen> createState() => _ZentromartRegisterScreenState();
}

class _ZentromartRegisterScreenState extends ConsumerState<ZentromartRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();

  String _selectedRole = 'USER';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName;
    _emailController.text = widget.initialEmail;
  }

  Future<void> _handleRegister() async {
    if (_selectedRole == 'VENDOR') {
      if (_shopNameController.text.trim().isEmpty ||
          _shopAddressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Shop Name and Address are required for Vendors"),
              backgroundColor: Colors.red),
        );
        return;
      }
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Fixed: Switched from reading raw repository to executing via authProvider notifier
      await ref.read(authProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            role: _selectedRole,
            shopName: _selectedRole == 'VENDOR'
                ? _shopNameController.text.trim()
                : null,
            shopAddress: _selectedRole == 'VENDOR'
                ? _shopAddressController.text.trim()
                : null,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully! Welcome."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (_selectedRole == 'VENDOR') {
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
          SnackBar(
              content: Text("Registration failed: $e"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    super.dispose();
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue:
            _selectedRole, // Fixed: Changed from invalid initialValue to value parameter style
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
          DropdownMenuItem(
              value: 'VENDOR', child: Text("Open a Store (Vendor)")),
        ],
        onChanged: (value) => setState(() => _selectedRole = value!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(iconTheme: const IconThemeData(color: Colors.black), 
        title: const Text("Create Account"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          Material(
            // Wrap inside material context container to enforce structural text layouts
            color: Colors.transparent,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Join Zentromart",
                        style: TextStyle(color: Colors.black87, 
                            fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 20),
                    _buildDropdown(),
                    _buildField(
                        _nameController, "Full Name", Icons.person_outline),
                    _buildField(_emailController, "Email", Icons.email_outlined,
                        isEmail: true),
                    _buildField(
                        _passwordController, "Password", Icons.lock_outline,
                        isPassword: true),
                    if (_selectedRole == 'VENDOR') ...[
                      _buildField(
                          _shopNameController, "Shop Name", Icons.storefront),
                      _buildField(_shopAddressController, "Shop Address",
                          Icons.location_on_outlined),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      onPressed: _isLoading ? null : _handleRegister,
                      child: const Text("CREATE ACCOUNT",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller, String label, IconData icon,
      {bool isEmail = false, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
        validator: (v) => v!.isEmpty ? "Required" : null,
      ),
    );
  }
}
