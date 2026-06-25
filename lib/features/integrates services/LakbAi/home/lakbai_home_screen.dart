import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/lakbai_auth_provider.dart';

class LakbaiHomeScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const LakbaiHomeScreen({super.key, this.onNavigateTab});

  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                const SizedBox(height: 8),
                Text(description,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 15,
                        height: 1.5)),
              ],
            ),
          )
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.1);
  }

  // ✅ 1. THE MODERN FULL-SCREEN DEV CARD
  Widget _buildModernDevCard(String name, String role, String description, String imagePath, int delay) {
    return Container(
      height: 450, // Massive height to fill the screen on scroll
      margin: const EdgeInsets.only(bottom: 40),
      child: Stack(
        children: [
          // The Background Image
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Image.asset(
              imagePath,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF064E3B),
                child: const Icon(LucideIcons.user, size: 100, color: Colors.white24),
              ),
            ),
          ),
          // Cinematic Gradient Overlay (Black at bottom, transparent at top)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.95),
                  Colors.black.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // The Text Content at the Bottom
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D399).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF34D399).withOpacity(0.5))
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(color: Color(0xFF34D399), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                  ),
                ).animate(delay: Duration(milliseconds: delay + 200)).fadeIn().slideY(begin: 0.5),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1.1),
                ).animate(delay: Duration(milliseconds: delay + 300)).fadeIn().slideX(begin: 0.2),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                ).animate(delay: Duration(milliseconds: delay + 400)).fadeIn(),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: delay)).fadeIn(duration: 800.ms).scale(begin: const Offset(0.95, 0.95));
  }

  // ✅ 2. THE "ALL TOGETHER" SUMMARY TEAM ROW
  Widget _buildTeamSummary(String imagePath, String lastName, String shortRole) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF34D399), width: 3),
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(lastName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          shortRole,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<LakbaiAuthProvider>(context);
    final bool isLoggedIn = authProvider.user != null;
    final size = MediaQuery.of(context).size;

    final String userFirstName = isLoggedIn
        ? (authProvider.user!['name']?.split(' ')[0] ?? 'Explorer')
        : 'Explorer';
    final String userRole = isLoggedIn
        ? (authProvider.user!['role']?.toString().toUpperCase() ?? 'TOURIST')
        : 'TOURIST';
    final String userEmail =
        isLoggedIn ? (authProvider.user!['email'] ?? '') : '';

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
                  const ListTile(
                    leading: Icon(LucideIcons.info, color: Colors.white54),
                    title: Text('Managed by Kawman', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    subtitle: Text('To sign out, please return to the main Kawman app.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HERO SECTION
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
                          Builder(
                            builder: (ctx) => IconButton(
                              icon: const Icon(LucideIcons.menu, color: Colors.white, size: 32),
                              onPressed: () => Scaffold.of(ctx).openDrawer(),
                            ),
                          ),
                          const Text('LakbAi', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                          const SizedBox(width: 48),
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
                            'Welcome back,\n$userFirstName!',
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
                                    if (onNavigateTab != null) onNavigateTab!(1);
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
                                    if (onNavigateTab != null) onNavigateTab!(2);
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
            
            // WHY CHOOSE LAKBAI SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 80.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF064E3B), Color(0xFF022C22)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter),
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
                  _buildInfoRow(LucideIcons.checkCircle, 'Verified Local Spots', 'Discover hidden gems and destinations verified by local Tourism Offices.'),
                ],
              ),
            ),
            
            // ✅ THE MODERN DEVELOPER SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 80.0),
              decoration: const BoxDecoration(color: Color(0xFF022C22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white24, thickness: 1),
                  const SizedBox(height: 40),
                  const Text('Meet the Creators', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                  const SizedBox(height: 10),
                  const Text('The visionaries behind the LakbAi Integration.', style: TextStyle(color: Color(0xFF34D399), fontSize: 16)),
                  const SizedBox(height: 60),

                  // 1. Cinematic Card for Daing
                  _buildModernDevCard(
                    'Hazzraze Sadhan Daing',
                    'Lead Developer & AI',
                    'Architecting the AI offline models.',
                    'assets/lakbai/team/Daing.png',
                    100
                  ),
                  
                  // 2. Cinematic Card for Sanaani
                  _buildModernDevCard(
                    'Alnedzfar Sanaani',
                    'Frontend & UI/UX Design',
                    'Crafting modern visual experience and interfaces you interact with today.',
                    'assets/lakbai/team/Sanaani.png',
                    200
                  ),

                  // 3. Cinematic Card for Kohoyan
                  _buildModernDevCard(
                    'Jericho Kohoyan',
                    'Backend & Functionality',
                    'Managing the databases, and ensuring functionality.',
                    'assets/lakbai/team/Kohoyan.png',
                    300
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}