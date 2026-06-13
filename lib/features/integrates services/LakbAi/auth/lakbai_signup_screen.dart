import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/lakbai_auth_provider.dart';

import '../../../auth/auth_provider.dart' as tawi_auth;
import 'lakbai_login_screen.dart';

class LakbaiSignupScreen extends StatefulWidget {
  const LakbaiSignupScreen({super.key});

  @override
  State<LakbaiSignupScreen> createState() => _LakbaiSignupScreenState();
}

class _LakbaiSignupScreenState extends State<LakbaiSignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _contactController = TextEditingController();

  String _selectedRole = 'tourist';
  String _selectedRegion = 'Luzon';
  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<String> _regions = ['Luzon', 'Visayas', 'Mindanao'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tawiUser = Provider.of<tawi_auth.AuthProvider>(context, listen: false).user;
      if (tawiUser != null) {
        setState(() {
          if (tawiUser.fullName.isNotEmpty) _nameController.text = tawiUser.fullName;
          if (tawiUser.email.isNotEmpty) _emailController.text = tawiUser.email;
        });
      }
    });
  }

  Future<void> _handleSignup() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Provider.of<LakbaiAuthProvider>(context, listen: false).register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _selectedRole,
        _selectedRegion,
        _contactController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account Created! Please Log In.'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LakbaiLoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // ✅ UPGRADE: Lets background image flow behind the AppBar
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white), // ✅ White arrow for dark background
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // ✅ UPGRADE: Replaced solid color with Stack and Background Image
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/lakbai/hero-bg.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.55),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 100.0, left: 24.0, right: 24.0, bottom: 24.0),
              child: Container(
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(
                  color: Colors.white, // Floating white card
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 15)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ UPGRADE: Used your actual Green Logo
                    Image.asset(
                      'assets/lakbai/logo-green.png', 
                      height: 50,
                      errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.userPlus, size: 48, color: Color(0xFF059669)),
                    ),
                    const SizedBox(height: 16),
                    const Text('Create Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                    const SizedBox(height: 8),
                    const Text('Join LakbAi and explore the Philippines', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
                    const SizedBox(height: 32),

                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(LucideIcons.user, color: Color(0xFF059669)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(LucideIcons.mail, color: Color(0xFF059669)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(LucideIcons.lock, color: Color(0xFF059669)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, color: Colors.grey),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _contactController,
                      decoration: InputDecoration(
                        labelText: 'Contact Number (Optional)',
                        prefixIcon: const Icon(LucideIcons.phone, color: Color(0xFF059669)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedRegion,
                      decoration: InputDecoration(
                        labelText: 'Region',
                        prefixIcon: const Icon(LucideIcons.mapPin, color: Color(0xFF059669)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                      onChanged: (val) => setState(() => _selectedRegion = val!),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Account Type',
                        prefixIcon: const Icon(LucideIcons.briefcase, color: Color(0xFF059669)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'tourist', child: Text('Tourist')),
                        DropdownMenuItem(value: 'tourism_office', child: Text('Tourism Office')),
                      ],
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('SIGN UP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LakbaiLoginScreen()),
                        );
                      },
                      child: const Text("Already have an account? Sign in", style: TextStyle(color: Color(0xFF059669))),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}