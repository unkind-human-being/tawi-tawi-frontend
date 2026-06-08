import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class DriverNotificationsScreen extends StatefulWidget {
  // NEW: Require the driver's unique franchise number so we can fetch their specific alerts
  final String franchiseNumber; 

  const DriverNotificationsScreen({super.key, required this.franchiseNumber});

  @override
  State<DriverNotificationsScreen> createState() => _DriverNotificationsScreenState();
}

class _DriverNotificationsScreenState extends State<DriverNotificationsScreen> {
  

  List<dynamic> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      // NEW: Pointing to the new CRUD router and passing the target_id
      final response = await ApiClient.instance.get('/notifications/${widget.franchiseNumber}');
      
      if (response.statusCode == 200) {
        setState(() {
          _notifications = response.data is List ? response.data : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not fetch live notifications. Showing offline alerts.';
        _isLoading = false;
        // Fallback static alerts
        _notifications = [
          {'title': 'Heavy Rain Warning', 'message': 'Proceed with caution on coastal roads.', 'type': 'warning'},
          {'title': 'System Sync Successful', 'message': 'All your offline trips have been uploaded.', 'type': 'success'},
          {'title': 'LGU Announcement', 'message': 'Terminal fees updated for Bongao Port. Please check the new matrix.', 'type': 'info'},
        ];
      });
    }
  }

  Color _getColorForType(String? type) {
    if (type == 'warning') return Colors.orange;
    if (type == 'success') return AppColors.neonTeal;
    return AppColors.deepOcean; // info or default
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.softBg,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        foregroundColor: context.dynamicText,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.neonTeal));
    }

    return Column(
      children: [
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.orange.withValues(alpha: 0.1),
            width: double.infinity,
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: _notifications.isEmpty
              ? Center(child: Text("No notifications available.", style: TextStyle(color: context.dynamicMuted)))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    return _premiumAlertCard(
                      notif['title'] ?? 'Alert',
                      notif['message'] ?? 'No message provided.',
                      _getColorForType(notif['type']),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _premiumAlertCard(String title, String msg, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.dynamicCard, 
        borderRadius: BorderRadius.circular(16), 
        border: Border(left: BorderSide(color: accent, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: context.dynamicText, fontSize: 14)),
          const SizedBox(height: 4),
          Text(msg, style: TextStyle(color: context.dynamicMuted, fontSize: 12)),
        ],
      ),
    );
  }
}