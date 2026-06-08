import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_messaging/firebase_messaging.dart'; 
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../commuter/screens/commuter_app_screen.dart';
import '../../driver/screens/driver_dashboard_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isDriver;
  const LoginScreen({super.key, required this.isDriver});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

 void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showToast('Please fill in all fields', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);
    
    final String inputId = _emailController.text.trim();
    final String inputPass = _passwordController.text;

    try {
      final endpoint = widget.isDriver ? '/drivers/login' : '/commuters/login';
      final payload = widget.isDriver 
          ? { "franchise_number": inputId, "password": inputPass }
          : { "email": inputId, "password": inputPass };
                
      final response = await ApiClient.instance.post(endpoint, data: payload);

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        final fetchedName = response.data['name']; // Grab the real name from backend!

        ApiClient.instance.options.headers['Authorization'] = 'Bearer $token';
        
        try {
          final fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            final tokenEndpoint = widget.isDriver ? '/drivers/me/fcm-token' : '/commuters/me/fcm-token';
            await ApiClient.instance.put(tokenEndpoint, data: {"fcm_token": fcmToken});
          }
        } catch (e) {
          print("Could not fetch or send FCM token: $e");
        }

        // Save Credentials + Real Name to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('offline_id', inputId);
        await prefs.setString('offline_pass', inputPass);
        await prefs.setBool('offline_isDriver', widget.isDriver);
        
        if (fetchedName != null) {
          await prefs.setString('offline_name', fetchedName); // <-- CACHE REAL NAME HERE
        }
        
        _proceedToDashboard(inputId, isOffline: false, fetchedName: fetchedName);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      if (e.response == null) {
        final prefs = await SharedPreferences.getInstance();
        final savedId = prefs.getString('offline_id');
        final savedPass = prefs.getString('offline_pass');
        final savedIsDriver = prefs.getBool('offline_isDriver');
        final savedName = prefs.getString('offline_name'); // <-- RETRIEVE CACHED NAME
        
        if (savedId == inputId && savedPass == inputPass && savedIsDriver == widget.isDriver) {
          _proceedToDashboard(inputId, isOffline: true, fetchedName: savedName); // <-- PASS TO UI
          return; 
        } else {
          _showToast('No internet. Offline login failed.', Colors.redAccent);
        }
      } else {
        String errorMsg = 'Login failed. Try again.';
        if (e.response?.statusCode == 401) {
          errorMsg = 'Invalid credentials';
        } else if (e.response?.statusCode == 422 && e.response?.data != null) {
          final detail = e.response!.data['detail'];
          errorMsg = detail is List && detail.isNotEmpty ? 'Error: ${detail[0]['msg']}' : 'Error: $detail';
        } else {
          errorMsg = e.response?.data['detail'] ?? 'Server error ${e.response?.statusCode}';
        }
        _showToast(errorMsg, Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  // NEW: Added fetchedName parameter
  void _proceedToDashboard(String rawInput, {bool isOffline = false, String? fetchedName}) {
    if (!mounted) return;
    if (isOffline) {
      _showToast('Offline Mode: Logged in securely', Colors.orange);
    }

    // 1. Prioritize the real name from the Database
    String extractedName = fetchedName ?? '';
    
    // 2. If no name exists (offline mode), fallback to formatting their raw login string
    if (extractedName.isEmpty) {
      extractedName = rawInput.contains('@') ? rawInput.split('@')[0] : rawInput;
      if (extractedName.isNotEmpty) {
        extractedName = extractedName[0].toUpperCase() + extractedName.substring(1).toLowerCase();
      } else {
        extractedName = widget.isDriver ? "Driver" : "Commuter";
      }
    }

    String userInitials = extractedName.isNotEmpty ? extractedName[0].toUpperCase() : (widget.isDriver ? 'D' : 'C');
    String formatId = widget.isDriver ? rawInput.toUpperCase() : 'UNKNOWN-ID';

    if (widget.isDriver) {
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => DriverDashboardScreen(
        driverName: extractedName, 
        initials: userInitials, 
        franchiseNumber: formatId)
      ));
    } else {
      Navigator.pushReplacement(
        context, MaterialPageRoute(
        builder: (_) => CommuterAppScreen(fullName: extractedName, 
        initials: userInitials, 
        discountStatus: 'Regular',
         email: rawInput)
      ));
    }
  }

  void _showToast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: color, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.isDarkMode ? AppColors.darkBg : AppColors.softBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.08),
              
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold) 
                    ?? const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in to your ${widget.isDriver ? 'Driver' : 'Commuter'} account',
                style: TextStyle(color: context.dynamicMuted, fontSize: 16),
              ),
              const SizedBox(height: 48),
              
              Text(
                widget.isDriver ? 'Franchise Number' : 'Email Address',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: widget.isDriver ? TextInputType.text : TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: widget.isDriver ? 'Enter franchise number' : 'Enter your email',
                  prefixIcon: Icon(widget.isDriver ? Icons.badge_outlined : Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: context.dynamicCard,
                ),
              ),
              const SizedBox(height: 24),
              
              const Text(
                'Password',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
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
              
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Forgot Password?'),
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ", style: TextStyle(color: context.dynamicMuted)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SignupScreen(isDriver: widget.isDriver))),
                    child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}