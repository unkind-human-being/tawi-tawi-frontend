import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/lakbai_auth_provider.dart';
import '../widgets/lakbai_main_layout.dart';
import 'lakbai_signup_screen.dart'; 
import '../../../auth/auth_provider.dart' as tawi_auth; 

class LakbaiLoginScreen extends StatefulWidget {
  const LakbaiLoginScreen({super.key});

  @override
  State<LakbaiLoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LakbaiLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true; 
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tawiUser = Provider.of<tawi_auth.AuthProvider>(context, listen: false).user;
      if (tawiUser != null && tawiUser.email.isNotEmpty) {
        setState(() {
          _emailController.text = tawiUser.email;
        });
      }
    });
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<LakbaiAuthProvider>(context, listen: false).login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LakbaiMainLayout()),
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
              padding: const EdgeInsets.all(24.0),
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
                      height: 60,
                      errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.map, size: 48, color: Color(0xFF059669)),
                    ),
                    const SizedBox(height: 20),
                    const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                    const SizedBox(height: 8),
                    const Text('Log in to continue your journey', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 32),
                    
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
                          icon: Icon(
                            _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('SIGN IN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LakbaiSignupScreen()),
                        );
                      },
                      child: const Text("Don't have an account? Sign up", style: TextStyle(color: Color(0xFF059669))),
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