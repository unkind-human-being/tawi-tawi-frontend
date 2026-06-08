import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  final bool isDriver;
  const SignupScreen({super.key, required this.isDriver});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _franchiseController = TextEditingController();
  final _passwordController = TextEditingController();

  String _discountStatus = 'Regular';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _franchiseController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    // NEW: Ensure email is required for both Driver and Commuter
    if (_nameController.text.isEmpty || 
        _passwordController.text.isEmpty || 
        _emailController.text.isEmpty ||
        (widget.isDriver && _franchiseController.text.isEmpty)) {
      _showToast('Please fill in all fields', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final endpoint = widget.isDriver ? '/drivers/signup' : '/commuters/register';
      
      final payload = widget.isDriver
          ? {
              "name": _nameController.text.trim(),
              "franchise_number": _franchiseController.text.trim(),
              "email": _emailController.text.trim(), // <-- NEW: Send email for Driver SSO Handshake
              "password": _passwordController.text
            }
          : {
              "name": _nameController.text.trim(),
              "email": _emailController.text.trim(),
              "password": _passwordController.text,
              "discount_status": _discountStatus
            };
            
      final response = await ApiClient.instance.post(endpoint, data: payload);
      
      if (response.statusCode == 201) {
        if (!mounted) return;
        _showToast('Account Created! Please log in.', Colors.teal);
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => LoginScreen(isDriver: widget.isDriver))
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      String msg = 'Registration failed.';
      if (e.response?.statusCode == 422 && e.response?.data != null) {
        final detail = e.response!.data['detail'];
        msg = detail is List && detail.isNotEmpty ? 'Error: ${detail[0]['msg']}' : 'Error: $detail';
      } else {
        msg = e.response?.data['detail'] ?? msg;
      }
      _showToast(msg, Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: color, behavior: SnackBarBehavior.floating)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDarkMode ? AppColors.darkBg : AppColors.softBg,
      appBar: AppBar(
        title: Text(widget.isDriver ? 'Register Operator' : 'Create Account'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join Pemeyaan Transport',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold) 
                    ?? const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your account to get started',
                style: TextStyle(color: context.dynamicMuted, fontSize: 16),
              ),
              const SizedBox(height: 32),
              
              const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: context.dynamicCard,
                ),
              ),
              const SizedBox(height: 24),

              // NEW: Dynamic UI for Franchise & Email Layout
              if (widget.isDriver) ...[
                const Text('Franchise Number', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _franchiseController,
                  decoration: InputDecoration(
                    hintText: 'Enter your franchise number',
                    prefixIcon: const Icon(Icons.numbers),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: context.dynamicCard,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: context.dynamicCard,
                ),
              ),
              const SizedBox(height: 24),

              const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Create a strong password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: context.dynamicCard,
                ),
              ),
              const SizedBox(height: 24),

              if (!widget.isDriver) ...[
                const Text('Discount Status', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _discountStatus,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.card_membership),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: context.dynamicCard,
                  ),
                  items: ['Regular', 'Student', 'Senior', 'PWD'].map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (val) => setState(() => _discountStatus = val!),
                ),
                const SizedBox(height: 24),
              ],

              Row(
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
                  ),
                  Expanded(
                    child: Text('I agree to the Terms of Service and Privacy Policy', style: TextStyle(color: context.dynamicMuted, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_agreeToTerms) ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}