import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart'; // <-- FOR LIVE BACKEND DATA

final Color _neonTeal = AppColors.neonTeal;

// ==========================================
// 1. ROUTES TAB (Live FastAPI Connection)
// ==========================================
class RoutesTab extends StatefulWidget {
  const RoutesTab({super.key});

  @override
  State<RoutesTab> createState() => _RoutesTabState();
}

class _RoutesTabState extends State<RoutesTab> {
  bool _isLoading = true;
  List<dynamic> _routes = [];

  @override
  void initState() {
    super.initState();
    _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    try {
      // Fetching live data from your routes.py backend
      final response = await ApiClient.instance.get('/routes/');
      
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _routes = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.neonTeal),
      );
    }

    if (_routes.isEmpty) {
      return Center(
        child: Text(
          'No active routes available right now.',
          style: TextStyle(color: context.dynamicMuted, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      physics: const BouncingScrollPhysics(),
      itemCount: _routes.length,
      itemBuilder: (context, index) {
        final route = _routes[index];
        return _premiumRouteCard(
          context,
          route['title'] ?? 'Unknown Route',
          route['subtitle'] ?? '',
          route['status'] ?? 'Unknown',
          List<String>.from(route['stops'] ?? []),
        );
      },
    );
  }

  Widget _premiumRouteCard(BuildContext context, String title, String subtitle, String status, List<String> stops) {
    final isActive = status == 'Active';
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(color: context.dynamicCard, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: context.dynamicText, fontSize: 15)), 
                Text(subtitle, style: TextStyle(color: context.dynamicMuted, fontSize: 12))
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                decoration: BoxDecoration(color: isActive ? _neonTeal.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), 
                child: Text(status, style: TextStyle(color: isActive ? Colors.teal[800] : Colors.orange[800], fontSize: 11, fontWeight: FontWeight.bold))
              )
            ],
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: stops.map((stop) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
            decoration: BoxDecoration(color: context.isDarkMode ? AppColors.darkBg : AppColors.softBg, borderRadius: BorderRadius.circular(6), border: Border.all(color: context.dynamicBorder)), 
            child: Text(stop, style: TextStyle(fontSize: 10, color: context.dynamicText))
          )).toList())
        ],
      ),
    );
  }
}

// ==========================================
// 2. ALERTS TAB (Live FastAPI Connection)
// ==========================================
class AlertsTab extends StatefulWidget {
  const AlertsTab({super.key});

  @override
  State<AlertsTab> createState() => _AlertsTabState();
}

class _AlertsTabState extends State<AlertsTab> {
  bool _isLoading = true;
  List<dynamic> _alerts = [];

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  Future<void> _fetchAlerts() async {
    try {
      // Fetching live data from your alerts.py backend
      final response = await ApiClient.instance.get('/alerts/');
      
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _alerts = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If the network fails, stop loading and show an empty state
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.neonTeal),
      );
    }

    if (_alerts.isEmpty) {
      return Center(
        child: Text(
          'No active alerts at the moment.',
          style: TextStyle(color: context.dynamicMuted, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      physics: const BouncingScrollPhysics(),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        final alert = _alerts[index];
        
        // Use the 'is_critical' boolean from your backend to determine the color
        final bool isCritical = alert['is_critical'] ?? false;
        final Color accentColor = isCritical ? Colors.redAccent : _neonTeal;

        return _premiumAlertCard(
          context, 
          alert['title'] ?? 'Notice', 
          alert['message'] ?? '', 
          accentColor
        );
      },
    );
  }

  Widget _premiumAlertCard(BuildContext context, String title, String msg, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), 
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        color: context.dynamicCard, 
        borderRadius: BorderRadius.circular(16), 
        border: Border(left: BorderSide(color: accent, width: 4))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: context.dynamicText, fontSize: 14)), 
          const SizedBox(height: 4), 
          Text(msg, style: TextStyle(color: context.dynamicMuted, fontSize: 12))
        ]
      ),
    );
  }
}