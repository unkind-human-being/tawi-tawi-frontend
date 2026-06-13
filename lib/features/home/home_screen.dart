// lib/features/home/home_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/auth_provider.dart';

// Integrated Services Imports
import '../integrates services/LakbAi/widgets/lakbai_main_layout.dart';
import '../integrates services/social_health/app service introduction/shu_introduction.dart';
import '../integrates services/hanap_gawa/app service introduction/introduction_screen.dart' as hanap_gawa_intro;
import '../integrates services/TDLF-Educ/tdlf_educ_app.dart';
import '../integrates services/zentromart/zentromart_link_screen.dart' as zentromart;
import '../integrates services/mesh_messaging/app service introduction/inbox_screen.dart';



// Pameyaan Subsystem Core Imports
import '../integrates services/pameyaan/app service introduction/core/network/network_provider.dart';
// ADDED: Missing Gateway Screen Import
import '../integrates services/pameyaan/app service introduction/features/auth/screen/pameyaan_gateway_screen.dart';

const Color _darkGreen = Color(0xFF064E3B);
const Color _mainGreen = Color(0xFF0F766E);
const Color _softGreen = Color(0xFFEFFAF5);
const Color _blueAccent = Color(0xFF0B5ED7);
const Color _pageBg = Color(0xFFF8FAF9);


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
      'title': 'ZentroMart',
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => NetworkProvider()),
              ],
              child: const PameyaanGatewayScreen(),
            ),
          ),
        );
        break;
      case 4:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TdlfEducApp(guestMode: true)));
        break;
      case 5:
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const zentromart.ZentromartLinkScreen()));
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
    final List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final List<String> months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  String _getInitials(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final Color textDark = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const Color topBarColor = Color(0xFF0F766E);

    final user = context.watch<AuthProvider>().user;
    final userName = user?.fullName ?? 'Citizen';
    final firstName = userName.trim().isEmpty ? 'Citizen' : userName.trim().split(' ').first;
    final String initials = _getInitials(userName);


    final List<Widget> serviceItems = [
     _buildServiceItem(
        title: 'LakbAi',
        subtitle: 'AI Travel Assistant',
        icon: Icons.travel_explore_rounded,
        color: const Color(0xFFF59E0B),
        isDark: isDark,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LakbaiMainLayout())), 
      ),
      _buildServiceItem(
        title: 'Social Health',
        subtitle: 'RHU Updates & QR',
        icon: Icons.health_and_safety_rounded,
        color: const Color(0xFF0EA5E9),
        isDark: isDark,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShuIntroductionScreen())),
      ),
      _buildServiceItem(
        title: 'Hanap Gawa',
        subtitle: 'Local Job Portal',
        icon: Icons.work_rounded,
        color: const Color(0xFF8B5CF6),
        isDark: isDark,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const hanap_gawa_intro.HanapGawaIntroductionScreen())),
      ),
      _buildServiceItem(
        title: 'Pameyaan',
        subtitle: 'Transport Services',
        icon: Icons.electric_rickshaw_rounded, // Changed to a tricycle/tuk-tuk style
        color: const Color(0xFFF97316),
        isDark: isDark,
        onTap: () => Navigator.of(context).push(
          // FIXED: Wrap Gateway with NetworkProvider directly inline to launch handshake
          MaterialPageRoute(
            builder: (_) => MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => NetworkProvider()),
              ],
              child: const PameyaanGatewayScreen(),
            ),
          ),
        ),
      ),
      _buildServiceItem(
        title: 'Education',
        subtitle: 'Learning Platform',
        icon: Icons.school_rounded,
        color: const Color(0xFF3B82F6),
        isDark: isDark,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TdlfEducApp(guestMode: true))),
      ),
      _buildServiceItem(
        title: 'ZentroMart',
        subtitle: 'Local Stores',
        icon: Icons.storefront_rounded,
        color: const Color(0xFFEF4444),
        isDark: isDark,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const zentromart.ZentromartLinkScreen())),
      ),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: topBarColor,
        toolbarHeight: 90,
        elevation: 8,
        shadowColor: isDark
            ? Colors.black.withValues(alpha: 0.5)
            : const Color(0xFF0F766E).withValues(alpha: 0.4),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
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
            ),
          );
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