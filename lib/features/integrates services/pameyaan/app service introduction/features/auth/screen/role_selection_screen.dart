import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart'; // <-- Added Theme Import
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  // Premium Palette to match the rest of the app (Kept the accents!)
  final Color _driverAccent = const Color(0xFF10B981); // Emerald Green
  final Color _commuterAccent = const Color(0xFF3B82F6); // Royal Blue

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // DYNAMIC: Background switches based on system theme
      backgroundColor: context.isDarkMode ? AppColors.darkBg : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // FIXED: Wrapped the logo in a Center widget so it doesn't stretch!
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.dynamicCard, // DYNAMIC: Logo background
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.isDarkMode ? Colors.black26 : const Color(0xFF0F172A).withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50), 
                    child: Image.asset(
                      'lib/assets/logo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain, // FIXED: Changed to contain so the whole logo is visible
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Premium Typography
              Text(
                'Welcome to Pemeyaan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: context.dynamicText, // DYNAMIC: Text Color
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your role to get started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.dynamicMuted, // DYNAMIC: Subtitle Color
                ),
              ),
              const SizedBox(height: 48),
              
              // Driver Option
              _buildRoleCard(
                context: context,
                title: 'I am a Driver',
                subtitle: 'Manage trips and view earnings',
                icon: Icons.local_taxi,
                accentColor: _driverAccent,
                isDriver: true, 
              ),
              
              const SizedBox(height: 16),
              
              // Commuter Option
              _buildRoleCard(
                context: context,
                title: 'I am a Commuter',
                subtitle: 'Calculate fares and report incidents',
                icon: Icons.people_alt_outlined,
                accentColor: _commuterAccent,
                isDriver: false, 
              ),
              
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isDriver, 
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(isDriver: isDriver), 
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.dynamicCard, // DYNAMIC: Card Background
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.dynamicBorder), // DYNAMIC: Border
          boxShadow: [
            BoxShadow(
              color: context.isDarkMode ? Colors.black12 : const Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 28, color: accentColor),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.dynamicText, // DYNAMIC: Title Text
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.dynamicMuted, // DYNAMIC: Subtitle Text
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: context.dynamicMuted), // DYNAMIC: Arrow Icon
          ],
        ),
      ),
    );
  }
}