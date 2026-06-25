import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

    final lakbaiAuth = Provider.of<LakbaiAuthProvider>(context, listen: false);
    final tawiAuth = Provider.of<tawi_auth.AuthProvider>(context, listen: false);

    await lakbaiAuth.initAuth();
    if (!mounted) return;

    final tawiEmail = tawiAuth.user?.email;
    if (tawiEmail == null || tawiEmail.isEmpty) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LakbaiSignupScreen()));
      return;
    }

    // We use the email as the unique TawiTawi ID to guarantee matching
    final tawiId = tawiEmail; 

    // SCENARIO 1: Tawi-Tawi User exists but LakbAi memory is empty
    if (lakbaiAuth.user == null) {
      String result = await lakbaiAuth.verifyHandshake(tawiId, tawiEmail);
      
      if (result == "SUCCESS") {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LakbaiMainLayout()));
      } else if (result == "SIGNUP") {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LakbaiSignupScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LakbaiSignupScreen()));
      }
      return;
    }

    // SCENARIO 2: LakbAi memory is already active
    if (lakbaiAuth.user != null) {
      if (tawiEmail.trim().toLowerCase() == lakbaiAuth.user!['email'].toString().trim().toLowerCase()) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LakbaiMainLayout()));
        return;
      } else {
        await lakbaiAuth.logout();
        _checkAccountStatus();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/lakbai/hero-bg.jpg', fit: BoxFit.cover, color: Colors.black.withOpacity(0.65), colorBlendMode: BlendMode.darken)),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/lakbai/logo-white.png', height: 100).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.9, 0.9), end: const Offset(1.05, 1.05), duration: 1.5.seconds),
                const SizedBox(height: 32),
                const Text('Opening LakbAi', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1.5)).animate().fadeIn(duration: 500.ms).slideY(begin: 0.5),
                const SizedBox(height: 12),
                const Text('Syncing your Kawman account...', style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 16, fontWeight: FontWeight.w600)).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5),
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