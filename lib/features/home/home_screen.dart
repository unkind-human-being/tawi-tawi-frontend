import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../profile/profile_screen.dart';
import '../integrates services/social_health/app service introduction/shu_introduction.dart';

import '../integrates services/hanap_gawa/app service introduction/introduction_screen.dart'
    as hanap_gawa_intro;
import '../integrates services/LakbAi/app service introduction/introduction_screen.dart'
    as lakbai_intro;
import '../integrates services/TDLF-Educ/app service introduction/introduction_screen.dart'
    as tdlf_intro;
import '../integrates services/team lodo/app service introduction/introduction_screen.dart'
    as team_lodo_intro;
import '../integrates services/team rasman/app service introduction/introduction_screen.dart'
    as team_rasman_intro;
import '../integrates services/team ubbama/app service introduction/introduction_screen.dart'
    as team_ubbama_intro;

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
  teamRasman,
  teamUbbama,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  /*
    DEVELOPER NOTE:
    To integrate a real app later:
    1. Add the app screen import above.
    2. Add the service here in mainServices.
    3. Add a case inside _openService().
    4. Replace the coming soon screen with the real app screen.
  */
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
      statusLabel: 'Coming Soon',
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
      title: 'Team Rasman',
      subtitle: 'Local app module prepared for future integration',
      icon: Icons.apps_rounded,
      color: Color(0xFFFCE7F3),
      iconColor: Color(0xFFBE185D),
      statusLabel: 'Coming Soon',
      route: _ServiceRoute.teamRasman,
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
    _QuickCategory(
      title: 'Apps',
      icon: Icons.apps_rounded,
      route: _ServiceRoute.teamLodo,
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

      case _ServiceRoute.hanapGawa:
        screen = const hanap_gawa_intro.HanapGawaIntroductionScreen();
        break;

      case _ServiceRoute.lakbAi:
        screen = const lakbai_intro.LakbAiIntroductionScreen();
        break;

      case _ServiceRoute.tdlfEduc:
        screen = const tdlf_intro.TDLFEducIntroductionScreen();
        break;

      case _ServiceRoute.teamLodo:
        screen = const team_lodo_intro.TeamLodoIntroductionScreen();
        break;

      case _ServiceRoute.teamRasman:
        screen = const team_rasman_intro.TeamRasmanIntroductionScreen();
        break;

      case _ServiceRoute.teamUbbama:
        screen = const team_ubbama_intro.TeamUbbamaIntroductionScreen();
        break;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _onBottomTap(int index) {
    if (index == 0) {
      setState(() => _selectedTab = 0);
      return;
    }

    if (index == 4) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }

    final labels = ['Home', 'Scan', 'Digital ID', 'History', 'Account'];
    _openPlaceholder(labels[index]);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

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
                                  title: 'Coming\nApps',
                                  subtitle: 'More services soon',
                                  icon: Icons.apps_rounded,
                                  backgroundColor: const Color(0xFFEFF6FF),
                                  iconColor: _blueAccent,
                                  onTap: () =>
                                      _openService(_ServiceRoute.teamLodo),
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
          );
        },
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String userName;

  const _HeaderSection({
    required this.userName,
  });

  String _firstName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'User';
    return clean.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _firstName(userName);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_darkGreen, _mainGreen],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: const Icon(
                  Icons.waves_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mabuhay, $firstName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Welcome to Tawi-Tawi App',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Text(
                  firstName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: _darkGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(
                Icons.nightlight_round,
                color: Colors.white.withValues(alpha: 0.92),
              ),
              const Spacer(),
              Text(
                _formattedDate(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    const days = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];

    return '${days[now.weekday - 1]} · ${months[now.month - 1]} ${now.day}, ${now.year}';
  }
}

class _SearchBox extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchBox({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Search apps like health, jobs, travel, education',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _softGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: _mainGreen,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickCategoriesRow extends StatelessWidget {
  final List<_QuickCategory> categories;
  final ValueChanged<_ServiceRoute> onTap;

  const _QuickCategoriesRow({
    required this.categories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, index) {
          final category = categories[index];

          return InkWell(
            onTap: () => onTap(category.route),
            borderRadius: BorderRadius.circular(50),
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFDCEAFE),
                      ),
                    ),
                    child: Icon(
                      category.icon,
                      color: _blueAccent,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    category.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _PromoBanner({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          height: 165,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFDCFCE7),
                Color(0xFFECFDF5),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFBBF7D0),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        'ONE DIGITAL HUB',
                        style: TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Tawi-Tawi\nService Portal',
                      style: TextStyle(
                        color: _darkGreen,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Access health updates and future local services.',
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: Image.asset(
                  'assets/logo/shu/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.health_and_safety_rounded,
                      color: _mainGreen,
                      size: 48,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 136,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                bottom: 0,
                child: Icon(
                  icon,
                  color: iconColor.withValues(alpha: 0.8),
                  size: 46,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
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

class _ServiceTabs extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onChanged;

  const _ServiceTabs({
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TabButton(
                title: 'Local Apps',
                isSelected: selectedTab == 0,
                onTap: () => onChanged(0),
              ),
            ),
            Expanded(
              child: _TabButton(
                title: 'Community',
                isSelected: selectedTab == 1,
                onTap: () => onChanged(1),
              ),
            ),
          ],
        ),
        Container(
          height: 3,
          color: const Color(0xFFE5E7EB),
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  color: selectedTab == 0 ? _blueAccent : Colors.transparent,
                ),
              ),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  color: selectedTab == 1 ? _blueAccent : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? _blueAccent : const Color(0xFF6B7280),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final _AppService service;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLive = service.statusLabel.toLowerCase() == 'live';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 104),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                padding: EdgeInsets.all(service.imageAsset == null ? 0 : 8),
                decoration: BoxDecoration(
                  color: service.imageAsset == null ? service.color : Colors.white,
                  shape: BoxShape.circle,
                  border: service.imageAsset == null
                      ? null
                      : Border.all(
                          color: const Color(0xFFE5E7EB),
                        ),
                ),
                child: service.imageAsset == null
                    ? Icon(
                        service.icon,
                        color: service.iconColor,
                        size: 31,
                      )
                    : Image.asset(
                        service.imageAsset!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            service.icon,
                            color: service.iconColor,
                            size: 31,
                          );
                        },
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            service.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1F2937),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isLive
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            service.statusLabel,
                            style: TextStyle(
                              color: isLive
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFF6B7280),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      service.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavItem(
            label: 'Home',
            icon: Icons.home_rounded,
            active: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            label: 'Scan',
            icon: Icons.qr_code_scanner_rounded,
            active: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Column(
                children: [
                  Transform.translate(
                    offset: const Offset(0, -24),
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: _blueAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _blueAccent.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.badge_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: const Text(
                      'Digital ID',
                      style: TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _NavItem(
            label: 'History',
            icon: Icons.receipt_long_rounded,
            active: selectedIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavItem(
            label: 'Account',
            icon: Icons.grid_view_rounded,
            active: selectedIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? _blueAccent : const Color(0xFF2F2F2F);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 27,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppService {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? imageAsset;
  final Color color;
  final Color iconColor;
  final String statusLabel;
  final _ServiceRoute route;

  const _AppService({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.imageAsset,
    required this.color,
    required this.iconColor,
    required this.statusLabel,
    required this.route,
  });
}

class _QuickCategory {
  final String title;
  final IconData icon;
  final _ServiceRoute route;

  const _QuickCategory({
    required this.title,
    required this.icon,
    required this.route,
  });
}