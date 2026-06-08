import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/lakbai_auth_provider.dart';

// Import all screens
import '../home/lakbai_home_screen.dart';
import '../destinations/lakbai_explore_screen.dart';
import '../planner/lakbai_planner_screen.dart';
import '../destinations/lakbai_destinations_screen.dart';
import '../admin/lakbai_requests_screen.dart';
import '../admin/lakbai_analytics_screen.dart';

class LakbaiMainLayout extends StatefulWidget {
  final int initialIndex;
  const LakbaiMainLayout({super.key, this.initialIndex = 0});

  @override
  State<LakbaiMainLayout> createState() => _LakbaiMainLayoutState();
}

class _LakbaiMainLayoutState extends State<LakbaiMainLayout> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  // This function allows screens to change the bottom tabs dynamically
  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<LakbaiAuthProvider>(context);
    final user = authProvider.user;
    
    // Dynamically build the tabs exactly like your React/Fullstack logic
    final List<Map<String, dynamic>> tabs = [
      {
        'name': 'Home', 
        'icon': LucideIcons.home, 
        'screen': LakbaiHomeScreen(onNavigateTab: _switchTab) // Pass the function to Home!
      },
    ];

    if (user != null) {
      if (authProvider.isAdmin) {
        tabs.add({'name': 'Requests', 'icon': LucideIcons.inbox, 'screen': const LakbaiRequestsScreen()});
        tabs.add({'name': 'Analytics', 'icon': LucideIcons.barChart3, 'screen': const LakbaiAnalyticsScreen()});
      } else if (authProvider.isTourismOffice) {
        tabs.add({'name': 'Destinations', 'icon': LucideIcons.mapPin, 'screen': const LakbaiDestinationsScreen()});
        tabs.add({'name': 'Analytics', 'icon': LucideIcons.barChart3, 'screen': const LakbaiAnalyticsScreen()});
      } else {
        tabs.add({'name': 'Explore', 'icon': LucideIcons.map, 'screen': const LakbaiExploreScreen()});
        tabs.add({'name': 'Planner', 'icon': LucideIcons.calendar, 'screen': const LakbaiPlannerScreen()});
      }
    }

    if (_currentIndex >= tabs.length) _currentIndex = 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: tabs[_currentIndex]['screen'], 
      
      bottomNavigationBar: tabs.length > 1 ? Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (index) {
                final isActive = _currentIndex == index;
                final item = tabs[index];
                return InkWell(
                  onTap: () => _switchTab(index),
                  borderRadius: BorderRadius.circular(30),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF059669) : Colors.transparent, 
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item['icon'],
                          color: isActive ? Colors.white : const Color(0xFF059669),
                          size: 20,
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Text(
                            item['name'].toString().toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ) : null,
    );
  }
}