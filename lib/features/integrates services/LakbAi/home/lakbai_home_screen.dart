import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/lakbai_auth_provider.dart';
import '../auth/lakbai_login_screen.dart';

class LakbaiHomeScreen extends StatelessWidget {
  final Function(int)? onNavigateTab; // Receives the tab switcher function

  const LakbaiHomeScreen({super.key, this.onNavigateTab});

  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text(description, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15, height: 1.5)),
              ],
            ),
          )
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.1);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<LakbaiAuthProvider>(context);
    final bool isLoggedIn = authProvider.user != null;
    final size = MediaQuery.of(context).size;

    final String userFirstName = isLoggedIn ? (authProvider.user!['name']?.split(' ')[0] ?? 'Explorer') : '';
    final String userRole = isLoggedIn ? (authProvider.user!['role']?.toString().toUpperCase() ?? 'TOURIST') : '';
    final String userEmail = isLoggedIn ? (authProvider.user!['email'] ?? '') : '';

    return Scaffold(
      backgroundColor: const Color(0xFF022C22), 
      drawer: isLoggedIn
          ? Drawer(
              backgroundColor: const Color(0xFF022C22),
              child: Column(
                children: [
                  UserAccountsDrawerHeader(
                    decoration: const BoxDecoration(color: Color(0xFF064E3B)),
                    accountName: Text('Hi, $userFirstName!', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    accountEmail: Text(userEmail, style: const TextStyle(color: Colors.white70)),
                    currentAccountPicture: const CircleAvatar(
                      backgroundColor: Color(0xFFD1FAE5),
                      child: Icon(LucideIcons.user, color: Color(0xFF059669), size: 36),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: const Icon(LucideIcons.shieldCheck, color: Color(0xFF34D399)),
                    title: const Text('Account Privilege', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    subtitle: Text(userRole, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const Spacer(),
                  const Divider(color: Colors.white24),
                  ListTile(
                    leading: const Icon(LucideIcons.logOut, color: Colors.redAccent),
                    title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    onTap: () async {
                      await authProvider.logout();
                      if (context.mounted) {
                        Navigator.pop(context); 
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LakbaiLoginScreen()),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            )
          : null,

      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: size.height,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/lakbai/hero-bg.jpg', 
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.5), 
                      colorBlendMode: BlendMode.darken,
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          isLoggedIn
                              ? Builder(
                                  builder: (ctx) => IconButton(
                                    icon: const Icon(LucideIcons.menu, color: Colors.white, size: 32),
                                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                                  ),
                                )
                              : const Text('LakbAi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                          if (isLoggedIn)
                            const Text('LakbAi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                          isLoggedIn
                              ? const SizedBox(width: 48) 
                              : ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const LakbaiLoginScreen()),
                                    );
                                  },
                                  icon: const Icon(LucideIcons.user, color: Color(0xFF064E3B), size: 18),
                                  label: const Text('Sign In', style: TextStyle(color: Color(0xFF064E3B), fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, elevation: 0),
                                ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLoggedIn ? 'Welcome back,\n$userFirstName!' : 'Explore the Beauty\nof the Philippines',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1),
                          ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2),
                          const SizedBox(height: 20),
                          const Text(
                            'Plan customized itineraries seamlessly using production-grade AI offline models.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                          const SizedBox(height: 40),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (isLoggedIn && onNavigateTab != null) {
                                      onNavigateTab!(1); // Switches tab directly to Explore
                                    } else {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LakbaiLoginScreen()));
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF059669),
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('BROWSE NOW', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    if (isLoggedIn && onNavigateTab != null) {
                                      onNavigateTab!(2); // Switches tab directly to Planner
                                    } else {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const LakbaiLoginScreen()));
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.white, width: 2),
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: const Text('ITINERARY AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 600.ms).scale(),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('DISCOVER LAKBAI', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          const SizedBox(height: 8),
                          const Icon(LucideIcons.chevronDown, color: Colors.white, size: 32)
                              .animate(onPlay: (controller) => controller.repeat(reverse: true))
                              .moveY(begin: -5, end: 5, duration: 1.seconds, curve: Curves.easeInOut),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF022C22)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Why choose LakbAi?', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                  const SizedBox(height: 10),
                  const Text('Built for the modern traveler.', style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 18)),
                  const SizedBox(height: 50),
                  _buildInfoRow(LucideIcons.sparkles, 'AI-Powered Planning', 'Generate personalized, day-by-day travel itineraries instantly using Gemini AI. It learns your preferences and builds the perfect trip.'),
                  _buildInfoRow(LucideIcons.wifiOff, 'Offline-First Capability', 'Save destinations and queue up edits even when you lose internet connection. Perfect for remote island hopping.'),
                  _buildInfoRow(LucideIcons.checkCircle, 'Verified Local Spots', 'Discover hidden gems and destinations directly submitted and verified by local Tourism Offices.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}