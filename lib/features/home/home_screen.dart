// lib/features/home/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';

// Integrated Services Imports
import '../integrates services/LakbAi/widgets/lakbai_main_layout.dart';
import '../integrates services/social_health/app service introduction/shu_introduction.dart';
import '../integrates services/team ubbama/team ubbama_login_screen.dart' as team_ubbama_intro;

<<<<<<< HEAD
import '../integrates services/TDLF-Educ/app service introduction/introduction_screen.dart'
    as tdlf_intro;
import '../integrates services/team lodo/app service introduction/introduction_screen.dart'
    as team_lodo_intro;
import '../integrates services/team ubbama/app service introduction/introduction_screen.dart'
    as team_ubbama_intro;

// --- PAMEYAAN SUBSYSTEM CORE IMPORTS ---
import '../integrates services/pameyaan/app service introduction/core/network/network_provider.dart';
import '../integrates services/pameyaan/app service introduction/features/auth/screen/pameyaan_gateway_screen.dart';

const Color _darkGreen = Color(0xFF064E3B);
const Color _mainGreen = Color(0xFF0F766E);
const Color _softGreen = Color(0xFFEFFAF5);
const Color _blueAccent = Color(0xFF0B5ED7);
const Color _pageBg = Color(0xFFF8FAF9);

enum _ServiceRoute {
  socialHealth,
  hanapGawa,
  lakbAi,
  tdlfEduc,
  teamLodo,
  pameyaan, // Upgraded path definition
  teamUbbama,
}
=======
// New Services Imports
import '../integrates services/hanap_gawa/app service introduction/introduction_screen.dart' as hanap_gawa_intro;
import '../integrates services/pameyaan/app service introduction/introduction_screen.dart' as pameyaan_intro;
import '../integrates services/TDLF-Educ/app service introduction/introduction_screen.dart' as educ_intro;
import '../integrates services/mesh_messaging/app service introduction/inbox_screen.dart';
>>>>>>> c71801b64dd7ab66351b0b62210cd3c7b08f354c

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;

  const HomeScreen({super.key, this.onSwitchTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isListView = false;
  late final PageController _pageController;
  Timer? _carouselTimer;
  int _currentCarouselIndex = 0;

<<<<<<< HEAD
  final List<_AppService> mainServices = const [
    _AppService(
      title: 'Health Updates',
      subtitle: 'Social RHU health announcements, posts, surveys, events, and appointments',
      icon: Icons.health_and_safety_outlined,
      imageAsset: 'assets/logo/shu/logo.png',
      color: Color(0xFFF0FDF4),
      iconColor: Color(0xFF047857),
      statusLabel: 'Live',
      route: _ServiceRoute.socialHealth,
    ),
    _AppService(title: 'Pameyaan Transit',
      subtitle: 'Calculate automated local fares, map active routes, and sync transit records logs',
      icon: Icons.directions_boat_filled_rounded,
      color: Color(0xFFE0F2FE),
      iconColor: Color(0xFF0EA5E9),
      statusLabel: 'Live',
      route: _ServiceRoute.pameyaan,
    ),
    _AppService(
      title: 'Hanap Gawa',
      subtitle: 'Find local jobs, skilled workers, and service providers',
      icon: Icons.work_outline_rounded,
      color: Color(0xFFFEF3C7),
      iconColor: Color(0xFFB45309),
      statusLabel: 'Coming Soon',
      route: _ServiceRoute.hanapGawa,
    ),
    _AppService(
      title: 'LakbAi',
      subtitle: 'Tourism, local travel guide, and smart trip assistance',
      icon: Icons.travel_explore_rounded,
      color: Color(0xFFEDE9FE),
      iconColor: Color(0xFF6D28D9),
      // 2. --- CHANGED: Status is now Live ---
      statusLabel: 'Live',
      route: _ServiceRoute.lakbAi,
    ),
    _AppService(
      title: 'TDLF-Educ',
      subtitle: 'Education tools, school materials, and learning resources',
      icon: Icons.school_rounded,
      color: Color(0xFFE0F2FE),
      iconColor: Color(0xFF0369A1),
      statusLabel: 'Coming Soon',
      route: _ServiceRoute.tdlfEduc,
    ),
    _AppService(
      title: 'Team Lodo',
      subtitle: 'Community service module prepared for future integration',
      icon: Icons.groups_2_rounded,
      color: Color(0xFFDCFCE7),
      iconColor: Color(0xFF15803D),
      statusLabel: 'Coming Soon',
      route: _ServiceRoute.teamLodo,
    ),
    _AppService(
      title: 'Team Ubbama',
      subtitle: 'Upcoming digital service for the Tawi-Tawi platform',
      icon: Icons.public_rounded,
      color: Color(0xFFFEE2E2),
      iconColor: Color(0xFFB91C1C),
      statusLabel: 'Coming Soon',
      route: _ServiceRoute.teamUbbama,
    ),
  ];

  final List<_QuickCategory> quickCategories = const [
    _QuickCategory(
      title: 'Health',
      icon: Icons.local_hospital_rounded,
      route: _ServiceRoute.socialHealth,
    ),
    _QuickCategory(
      title: 'Transit',
      icon: Icons.directions_boat_filled_rounded,
      route: _ServiceRoute.pameyaan,
    ),
    _QuickCategory(
      title: 'Jobs',
      icon: Icons.badge_rounded,
      route: _ServiceRoute.hanapGawa,
    ),
    _QuickCategory(
      title: 'Travel',
      icon: Icons.travel_explore_rounded,
      route: _ServiceRoute.lakbAi,
    ),
    _QuickCategory(
      title: 'Educ',
      icon: Icons.school_rounded,
      route: _ServiceRoute.tdlfEduc,
    ),
  ];

  void _openPlaceholder(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title module will be added next.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openService(_ServiceRoute route) {
    Widget screen;

    switch (route) {
      case _ServiceRoute.socialHealth:
        screen = const ShuIntroductionScreen();
        break;

      case _ServiceRoute.pameyaan:
        // Automatically encapsulate the required state layer on launch initialization
        screen = MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => NetworkProvider()),
          ],
          child: const PameyaanGatewayScreen(),
        );
        break;

      case _ServiceRoute.hanapGawa:
        screen = const hanap_gawa_intro.HanapGawaIntroductionScreen();
        break;

      //CHANGED THIS: Replaced LakbaiHomeScreen with LakbaiMainLayout so the bottom tab bar is active
      case _ServiceRoute.lakbAi:
        screen = const LakbaiMainLayout(); 
        break;

      case _ServiceRoute.tdlfEduc:
        screen = const tdlf_intro.TDLFEducIntroductionScreen();
        break;

      case _ServiceRoute.teamLodo:
        screen = const team_lodo_intro.TeamLodoIntroductionScreen();
        break;

      case _ServiceRoute.teamUbbama:
        screen = const team_ubbama_intro.TeamUbbamaIntroductionScreen();
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
=======
  final List<Map<String, String>> _carouselItems = [
    {
      'title': 'LakbAi',
      'subtitle': 'AI Travel Assistant',
      'image': 'assets/images/lakbai.webp',
    },
    {
      'title': 'Social Health',
      'subtitle': 'RHU Updates & QR',
      'image': 'assets/images/rhu.webp',
    },
    {
      'title': 'Hanap Gawa',
      'subtitle': 'Local Job Portal',
      'image': 'assets/images/at-carpenter-workshop.webp',
    },
    {
      'title': 'Pameyaan',
      'subtitle': 'Transport Services',
      'image': 'assets/images/pameyaan.webp',
    },
    {
      'title': 'Education',
      'subtitle': 'Learning Platform',
      'image': 'assets/images/educ.webp',
    },
    {
      'title': 'Team Ubbama',
      'subtitle': 'eCommerce',
      'image': 'assets/images/e store.webp',
    },
    {
      'title': 'Mesh Messaging',
      'subtitle': 'Offline Communication',
      'image': 'assets/images/mesh.webp',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 6000, viewportFraction: 0.93);
    _startCarousel();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
>>>>>>> c71801b64dd7ab66351b0b62210cd3c7b08f354c
  }

  void _navigateToService(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LakbaiMainLayout()));
        break;
      case 1:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShuIntroductionScreen()));
        break;
      case 2:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const hanap_gawa_intro.HanapGawaIntroductionScreen()));
        break;
      case 3:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const pameyaan_intro.TeamRasmanIntroductionScreen()));
        break;
      case 4:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const educ_intro.TDLFEducIntroductionScreen()));
        break;
      case 5:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const team_ubbama_intro.TeamUbbamaLoginScreen()));
        break;
      case 6:
        if (widget.onSwitchTab != null) {
          widget.onSwitchTab!(1);
        } else {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InboxScreen()));
        }
        break;
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String _getFormattedDate() {
    final DateTime now = DateTime.now();
    final List<String> weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final List<String> months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  // Helper function to extract initials from the full name
  String _getInitials(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'U';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Core theme colors adapted for light and dark modes
    final Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color textDark = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    
    // Top bar is now ALWAYS the primary green, even in dark mode
    const Color topBarColor = Color(0xFF0F766E);

    final user = context.watch<AuthProvider>().user;
    final userName = user?.fullName ?? 'Citizen';
    final firstName = userName.trim().isEmpty ? 'Citizen' : userName.trim().split(' ').first;
    final String initials = _getInitials(userName);

<<<<<<< HEAD
    return Scaffold(
      backgroundColor: _pageBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 700;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 620 : double.infinity,
              ),
              child: Stack(
                children: [
                  CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _HeaderSection(
                          userName: user?.fullName ?? 'Public User',
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                          child: _SearchBox(
                            onTap: () => _openPlaceholder('Search'),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _QuickCategoriesRow(
                          categories: quickCategories,
                          onTap: _openService,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _PromoBanner(
                          onTap: () => _openService(_ServiceRoute.socialHealth),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Featured Tawi-Tawi Services',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _openPlaceholder('All Services'),
                                child: const Text(
                                  'View All',
                                  style: TextStyle(
                                    color: _blueAccent,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: _FeatureCard(
                                  title: 'Health\nPortal',
                                  subtitle: 'RHU updates and services',
                                  icon: Icons.health_and_safety_rounded,
                                  backgroundColor: const Color(0xFFECFDF5),
                                  iconColor: _mainGreen,
                                  onTap: () =>
                                      _openService(_ServiceRoute.socialHealth),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _FeatureCard(
                                  title: 'Transit\nPortal',
                                  subtitle: 'Local Pameyaan platform services',
                                  icon: Icons.directions_boat_filled_rounded,
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  iconColor: _blueAccent,
                                  onTap: () =>
                                      _openService(_ServiceRoute.pameyaan),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                          child: _ServiceTabs(
                            selectedTab: _selectedTab,
                            onChanged: (value) {
                              setState(() => _selectedTab = value);
                            },
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedTab == 0
                                      ? 'Available and Coming Services'
                                      : 'Community App Modules',
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final service = mainServices[index];

                            return Padding(
                              padding: EdgeInsets.fromLTRB(
                                20,
                                index == 0 ? 4 : 8,
                                20,
                                8,
                              ),
                              child: _ServiceTile(
                                service: service,
                                onTap: () => _openService(service.route),
                              ),
                            );
                          },
                          childCount: mainServices.length,
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 110),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: _BottomNavBar(
                      selectedIndex: 0,
                      onTap: _onBottomTap,
                    ),
                  ),
                ],
              ),
            ),
=======
    // The updated list of services with corrected categories and icons
    final List<Widget> serviceItems = [
      _buildServiceItem(
        title: 'LakbAi',
        subtitle: 'AI Travel Assistant',
        icon: Icons.travel_explore_rounded,
        color: const Color(0xFFF59E0B),
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LakbaiMainLayout()),
>>>>>>> c71801b64dd7ab66351b0b62210cd3c7b08f354c
          );
        },
      ),
      _buildServiceItem(
        title: 'Social Health',
        subtitle: 'RHU Updates & QR',
        icon: Icons.health_and_safety_rounded,
        color: const Color(0xFF0EA5E9),
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ShuIntroductionScreen()),
          );
        },
      ),
      _buildServiceItem(
        title: 'Hanap Gawa',
        subtitle: 'Local Job Portal',
        icon: Icons.work_rounded,
        color: const Color(0xFF8B5CF6), // Purple
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const hanap_gawa_intro.HanapGawaIntroductionScreen()),
          );
        },
      ),
      _buildServiceItem(
        title: 'Pameyaan',
        subtitle: 'Transport Services',
        icon: Icons.directions_car_rounded, // Transportation Icon
        color: const Color(0xFFF97316), // Orange
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const pameyaan_intro.TeamRasmanIntroductionScreen()),
          );
        },
      ),
      _buildServiceItem(
        title: 'Education',
        subtitle: 'Learning Platform',
        icon: Icons.school_rounded,
        color: const Color(0xFF3B82F6), // Blue
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const educ_intro.TDLFEducIntroductionScreen()),
          );
        },
      ),
      _buildServiceItem(
        title: 'Team Ubbama',
        subtitle: 'Local Stores',
        icon: Icons.storefront_rounded, // Store Icon
        color: const Color(0xFFEF4444), // Red
        isDark: isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const team_ubbama_intro.TeamUbbamaLoginScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        centerTitle: false, // Forces the title content to align to the left
        backgroundColor: topBarColor,
        toolbarHeight: 90, 
        elevation: 8,
        shadowColor: isDark 
            ? Colors.black.withValues(alpha: 0.5) 
            : const Color(0xFF0F766E).withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
        ),
        titleSpacing: 24, 
        title: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getFormattedDate(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Hi, $firstName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 24, top: 12),
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              child: _buildHeroBanner(isDark),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Integrated Services',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isListView ? Icons.grid_view_rounded : Icons.view_list_rounded,
                            color: textMuted,
                            size: 22,
                          ),
                          tooltip: _isListView ? 'Switch to Grid View' : 'Switch to List View',
                          onPressed: () {
                            setState(() {
                              _isListView = !_isListView;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: _isListView
                ? SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: serviceItems[index],
                      ),
                      childCount: serviceItems.length,
                    ),
                  )
                : SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.95,
                    ),
                    delegate: SliverChildListDelegate(serviceItems),
                  ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(bool isDark) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentCarouselIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final int actualIndex = index % _carouselItems.length;
          final item = _carouselItems[actualIndex];
          return GestureDetector(
            onTap: () => _navigateToService(context, actualIndex),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
              image: DecorationImage(
                image: AssetImage(item['image']!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.5),
                  BlendMode.darken,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'PUBLIC PORTAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  item['title']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['subtitle']!,
                  style: const TextStyle(
                    color: Color(0xFFCCFBF1),
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ));
        },
      ),
    );
  }

  Widget _buildServiceItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    if (_isListView) {
      return _ServiceListCard(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        isDark: isDark,
        onTap: onTap,
      );
    } else {
      return _ServiceGridCard(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        isDark: isDark,
        onTap: onTap,
      );
    }
  }
}

class _ServiceGridCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ServiceGridCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 12,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ServiceListCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}