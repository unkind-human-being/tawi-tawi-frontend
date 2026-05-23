import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_provider.dart';
import '../profile/profile_screen.dart';
import '../integrates services/social_health/app service introduction/shu_introduction.dart';

const Color _darkGreen = Color(0xFF064E3B);
const Color _mainGreen = Color(0xFF0F766E);
const Color _softGreen = Color(0xFFEFFAF5);
const Color _blueAccent = Color(0xFF0B5ED7);
const Color _pageBg = Color(0xFFF8FAF9);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  final List<_AppService> mainServices = const [
    _AppService(
      title: 'TawiMart',
      subtitle: 'Local ecommerce marketplace',
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFFDCFCE7),
      iconColor: Color(0xFF15803D),
    ),
    _AppService(
      title: 'eBooks',
      subtitle: 'Read local and school materials',
      icon: Icons.menu_book_rounded,
      color: Color(0xFFE0F2FE),
      iconColor: Color(0xFF0369A1),
    ),
    _AppService(
      title: 'Health Updates',
      subtitle: 'Social RHU health announcements',
      icon: Icons.health_and_safety_outlined,
      color: Color(0xFFF0FDF4),
      iconColor: Color(0xFF047857),
    ),
    _AppService(
      title: 'Local Link',
      subtitle: 'Local jobs and professional network',
      icon: Icons.work_outline,
      color: Color(0xFFFEF3C7),
      iconColor: Color(0xFFB45309),
    ),
    _AppService(
      title: 'TawiRide',
      subtitle: 'Local ride and delivery service',
      icon: Icons.delivery_dining_rounded,
      color: Color(0xFFFCE7F3),
      iconColor: Color(0xFFBE185D),
    ),
    _AppService(
      title: 'Tour Checker',
      subtitle: 'Tourism guide and trip checker',
      icon: Icons.travel_explore_rounded,
      color: Color(0xFFEDE9FE),
      iconColor: Color(0xFF6D28D9),
    ),
    _AppService(
      title: 'Community Watch',
      subtitle: 'Report suspicious activity safely',
      icon: Icons.report_gmailerrorred_rounded,
      color: Color(0xFFFEE2E2),
      iconColor: Color(0xFFB91C1C),
    ),
  ];

  final List<_QuickCategory> quickCategories = const [
    _QuickCategory('Shop', Icons.storefront_rounded),
    _QuickCategory('Read', Icons.book_rounded),
    _QuickCategory('Health', Icons.local_hospital_rounded),
    _QuickCategory('Jobs', Icons.badge_rounded),
    _QuickCategory('Ride', Icons.two_wheeler_rounded),
  ];

  void _openPlaceholder(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title module will be added next.'),
      ),
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

  void _openHealthModule() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ShuIntroductionScreen(),
      ),
    );
  }

  void _handleServiceTap(String title) {
    final String cleanTitle = title.trim().toLowerCase();

    if (cleanTitle == 'health' || cleanTitle == 'health updates') {
      _openHealthModule();
      return;
    }

    _openPlaceholder(title);
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
                          onTap: _handleServiceTap,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _PromoBanner(
                          onTap: () => _openPlaceholder('Tawi-Tawi Super App'),
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
                                  title: 'Community\nServices',
                                  subtitle: 'Powered by Tawi-Tawi',
                                  icon: Icons.location_city_rounded,
                                  backgroundColor: Color(0xFFEFF6FF),
                                  iconColor: _blueAccent,
                                  onTap: () =>
                                      _openPlaceholder('Community Services'),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _FeatureCard(
                                  title: 'Local App\nPortals',
                                  subtitle: 'All-in-one access',
                                  icon: Icons.apps_rounded,
                                  backgroundColor: Color(0xFFECFDF5),
                                  iconColor: _mainGreen,
                                  onTap: () => _openPlaceholder('Local Portals'),
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
                                      ? 'Most Used Services'
                                      : 'Community Apps',
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _openPlaceholder('All Services'),
                                child: const Text(
                                  'View All Services',
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
                                onTap: () => _handleServiceTap(service.title),
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
                    'Search apps like ecommerce, health, tourism',
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
  final ValueChanged<String> onTap;

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
            onTap: () => onTap(category.title),
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
                        'NEW PLATFORM',
                        style: TextStyle(
                          color: Color(0xFF15803D),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'One Tawi-Tawi\nDigital Hub',
                      style: TextStyle(
                        color: _darkGreen,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Shop, learn, travel, work, and connect locally.',
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
                  color: _mainGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.apps_rounded,
                  color: Colors.white,
                  size: 48,
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
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
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: service.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  service.icon,
                  color: service.iconColor,
                  size: 31,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      service.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
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
  final Color color;
  final Color iconColor;

  const _AppService({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.iconColor,
  });
}

class _QuickCategory {
  final String title;
  final IconData icon;

  const _QuickCategory(
    this.title,
    this.icon,
  );
}