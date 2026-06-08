import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/driver_header.dart';
import '../widgets/trip_manager.dart';
import '../widgets/driver_tabs.dart';
import '../widgets/driver_my_trips_tab.dart'; 
import '../widgets/sync_queue_panel.dart'; // <-- ADDED SYNC PANEL IMPORT
import 'driver_settings_screen.dart';
import 'driver_notifications_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  final String driverName;
  final String initials;
  final String franchiseNumber;

  const DriverDashboardScreen({
    super.key,
    required this.driverName,
    required this.initials,
    required this.franchiseNumber,
  });

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _dashboardTabController;
  int _selectedIndex = 0;

  double _todaysEarnings = 0.0;
  List<Map<String, dynamic>> _recentTrips = [];
  bool _isLoadingTrips = true;

  late String _currentDriverName;
  late String _currentInitials;

  @override
  void initState() {
    super.initState();
    _currentDriverName = widget.driverName;
    _currentInitials = widget.initials;

    _dashboardTabController = TabController(length: 3, vsync: this);
    _fetchDriverHistory();
  }

  void _updateProfileData(String newName) {
    setState(() {
      _currentDriverName = newName;
      _currentInitials = newName.isNotEmpty ? newName[0].toUpperCase() : 'D';
    });
  }

  Future<void> _fetchDriverHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'driver_history_${widget.franchiseNumber}';

    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      final parsed = jsonDecode(cachedData);
      setState(() {
        _todaysEarnings = (parsed['todays_earnings'] ?? 0.0).toDouble();
        _recentTrips = List<Map<String, dynamic>>.from(
          parsed['recent_trips'] ?? [],
        );
        if (parsed['driver_name'] != null) {
          _currentDriverName = parsed['driver_name'];
          _currentInitials = _currentDriverName.isNotEmpty ? _currentDriverName[0].toUpperCase() : 'D';
        }
        _isLoadingTrips = false;
      });
    }

    try {
      final response = await ApiClient.instance.get(
        '/drivers/${widget.franchiseNumber}/trips',
      );

      if (response.statusCode == 200) {
        await prefs.setString(cacheKey, jsonEncode(response.data));
        if (!mounted) return;
        setState(() {
          _todaysEarnings = (response.data['todays_earnings'] ?? 0.0).toDouble();
          _recentTrips = List<Map<String, dynamic>>.from(
            response.data['recent_trips'] ?? [],
          );
          if (response.data['driver_name'] != null) {
            _currentDriverName = response.data['driver_name'];
            _currentInitials = _currentDriverName.isNotEmpty ? _currentDriverName[0].toUpperCase() : 'D';
          }
          _isLoadingTrips = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTrips = false);
    }
  }

  void _addNewTripLocally(Map<String, dynamic> newTrip) {
    setState(() {
      _todaysEarnings += (newTrip['amount'] as double);
      _recentTrips.insert(0, newTrip);
    });
  }

  Future<void> _showExitConfirmationDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDark = context.isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.exit_to_app, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text('Exit App', style: TextStyle(color: context.dynamicText, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text('Are you sure you want to exit Pemeyaan Transport?', style: TextStyle(color: context.dynamicMuted)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('EXIT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }

  @override
  void dispose() {
    _dashboardTabController.dispose();
    super.dispose();
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
        title: Text(
          'Pemeyaan Operator',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: textColor,
          ),
        ),
      actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: AppColors.neonTeal),
            tooltip: 'Sync Hub',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const SyncQueuePanel(),
              );
            },
          ),
          
        // <-- UPDATED THIS BUTTON -->
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: textColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DriverNotificationsScreen(
                    franchiseNumber: widget.franchiseNumber, // <-- ADD THIS LINE!
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8), 
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            DriverHeader(
              driverName: _currentDriverName,
              initials: _currentInitials,
              franchiseNumber: widget.franchiseNumber,
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
                            const SizedBox(height: 10),
                            TripManagerCard(
                              driverName: _currentDriverName,
                              franchiseNumber: widget.franchiseNumber,
                              onTripCompleted: _addNewTripLocally,
                            ),
                            const SizedBox(height: 32),
                            _buildCustomSquareTabs(context),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ];
                  },
                  body: Stack(
                    children: [
                      TabBarView(
                        controller: _dashboardTabController,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          EarningsTab(
                            todaysEarnings: _todaysEarnings,
                            recentTrips: _recentTrips,
                          ),
                          const DriverAlertsTab(),
                          const ActiveDriversTab(),
                        ],
                      ),
                      if (_isLoadingTrips)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(
                            color: AppColors.neonTeal,
                            backgroundColor: Colors.transparent,
                            minHeight: 2,
                          ),
                        ),
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
      decoration: BoxDecoration(
        color: context.isDarkMode ? AppColors.darkBg : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TabBar(
        controller: _dashboardTabController,
        indicator: BoxDecoration(
          color: context.dynamicCard,
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: context.dynamicText,
        unselectedLabelColor: context.dynamicMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Today\'s Earnings'),
          Tab(text: 'Alerts'),
          Tab(text: 'Active Drivers'),
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
          _showExitConfirmationDialog(); 
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.softBg,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildDashboardUI(), 
            const FareMatrixTab(), 
            DriverMyTripsTab(
              franchiseNumber: widget.franchiseNumber,
            ), 
            DriverSettingsScreen(
              driverName: _currentDriverName,
              initials: _currentInitials,
              franchiseNumber: widget.franchiseNumber,
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
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              label: 'Matrix',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_taxi_outlined),
              label: 'My Trips',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}