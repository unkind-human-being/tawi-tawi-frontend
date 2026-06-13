import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Import Tawi-Tawi auth to check for SSO
import '../../../auth/auth_provider.dart' as tawi_auth;

import '../providers/lakbai_auth_provider.dart';
import '../widgets/lakbai_main_layout.dart';
import '../auth/lakbai_signup_screen.dart'; 

class LakbaiGatewayScreen extends StatefulWidget {
  const LakbaiGatewayScreen({super.key});

  @override
  State<LakbaiGatewayScreen> createState() => _LakbaiGatewayScreenState();
}

class _LakbaiGatewayScreenState extends State<LakbaiGatewayScreen> {
  @override
  void initState() {
    super.initState();
    _checkAccountStatus();
  }

  Future<void> _checkAccountStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = Provider.of<LakbaiAuthProvider>(context, listen: false);
    await authProvider.initAuth();

    if (!mounted) return;

    if (authProvider.user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LakbaiMainLayout()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LakbaiSignupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ UPGRADE: Replaced solid color with a Stack containing your hero background
      body: Stack(
        children: [
          // Beautiful Background Image with Dark Overlay
          Positioned.fill(
            child: Image.asset(
              'assets/lakbai/hero-bg.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.65), 
              colorBlendMode: BlendMode.darken,
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ UPGRADE: Used your actual white logo instead of a basic icon
                Image.asset(
                  'assets/lakbai/logo-white.png', 
                  height: 100,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.travel_explore, color: Colors.white, size: 80),
                )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.05, 1.05), duration: 1.5.seconds),
                
                const SizedBox(height: 32),
                
                const Text(
                  'Opening LakbAi',
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.5),
                
                const SizedBox(height: 12),
                
                const Text(
                  'Preparing your travel experience...',
                  style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 16, fontWeight: FontWeight.w600),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5),

                const SizedBox(height: 48),
                
                const CircularProgressIndicator(color: Colors.white).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}