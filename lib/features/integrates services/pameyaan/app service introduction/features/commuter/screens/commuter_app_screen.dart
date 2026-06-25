import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../core/theme/app_theme.dart';
import '../widgets/commuter_header.dart';
import '../widgets/commuter_tabs.dart';
import 'commuter_settings_screen.dart';
import '../widgets/trip_history_tab.dart';
import '../widgets/unified_fares_tab.dart';
import 'commuter_notifications_screen.dart';

// <-- REQUIRED IMPORT FOR THE SYNC BUTTON -->
import '../../sync_engine/services/sync_service.dart'; 

// <-- FIXED: EXACT IMPORT PATH TO YOUR TAWI-TAWI MAIN HUB SCREEN -->
import '../../../../../../main/main_screen.dart';

class CommuterAppScreen extends StatefulWidget {
  final String fullName;
  final String initials;
  final String discountStatus;
  final String email; 

  const CommuterAppScreen({
    super.key,
    required this.fullName,
    required this.initials,
    required this.discountStatus,
    required this.email, 
  });

  @override
  State<CommuterAppScreen> createState() => _CommuterAppScreenState();
}

class _CommuterAppScreenState extends State<CommuterAppScreen> with SingleTickerProviderStateMixin {
  late TabController _dashboardTabController;
  int _selectedIndex = 0;

  late String _fullName;
  late String _initials;
  late String _discountStatus;

  @override
  void initState() {
    super.initState();
    _fullName = widget.fullName;
    _initials = widget.initials;
    _discountStatus = widget.discountStatus;
    
    _dashboardTabController = TabController(length: 2, vsync: this);
    _setupPushNotifications();
  }

  @override
  void dispose() {
    _dashboardTabController.dispose();
    super.dispose();
  }

  void _setupPushNotifications() async {
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('Notification permission status: ${settings.authorizationStatus}');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null && mounted) {
        final bool isCritical = message.notification!.title?.contains('CRITICAL') ?? false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.notification!.title ?? 'Transport Alert', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)
                ),
                const SizedBox(height: 4),
                Text(
                  message.notification!.body ?? '', 
                  style: const TextStyle(color: Colors.white, fontSize: 14)
                ),
              ],
            ),
            backgroundColor: isCritical ? Colors.redAccent : AppColors.neonTeal,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 150, 
              left: 16, 
              right: 16
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            duration: const Duration(seconds: 6),
            elevation: 10,
          ),
        );
      }
    });
  }

  void _updateProfileData(String newName) {
    setState(() {
      _fullName = newName;
      _initials = newName.isNotEmpty ? newName[0].toUpperCase() : 'C';
    });
  }

  Widget _buildDashboardUI() {
    final bool isDark = context.isDarkMode;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('Pemeyaan Transport', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: textColor)),
        actions: [
          // <-- SYNC HUB ICON -->
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.neonTeal),
            tooltip: 'Sync Data',
            onPressed: () {
              SyncService.syncOfflineData();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Syncing offline data...', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
                  backgroundColor: AppColors.neonTeal, 
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                )
              );
            },
          ),
          
          // <-- NOTIFICATION BELL -->
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: textColor), 
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommuterNotificationsScreen(
                    email: widget.email, 
                  ),
                ),
              );
            }
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            CommuterHeader(
              fullName: _fullName,
              initials: _initials,
              discountStatus: _discountStatus,
              onProfileUpdated: _updateProfileData,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 24),
                            _buildCustomSquareTabs(context),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _dashboardTabController,
                    physics: const BouncingScrollPhysics(),
                    children: const [
                      RoutesTab(),
                      AlertsTab(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSquareTabs(BuildContext context) {
    return Container(
      height: 45,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: context.isDarkMode ? AppColors.darkBg : Colors.grey[300], borderRadius: BorderRadius.circular(8)),
      child: TabBar(
        controller: _dashboardTabController,
        indicator: BoxDecoration(
          color: context.dynamicCard, 
          borderRadius: BorderRadius.circular(6), 
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
        ),
        labelColor: context.dynamicText,
        unselectedLabelColor: context.dynamicMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Active Routes'),
          Tab(text: 'Transport Alerts'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return PopScope(
      canPop: false, 
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
        } else {

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.softBg,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildDashboardUI(), 
            UnifiedFaresTab(discountStatus: _discountStatus), 
            const TripHistoryTab(), 
            CommuterSettingsScreen(
              fullName: _fullName,
              initials: _initials,
              discountStatus: _discountStatus
            ),
          ],
        ),
        
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed, 
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          selectedItemColor: AppColors.neonTeal,
          unselectedItemColor: Colors.grey,
          elevation: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), label: 'Fares'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}