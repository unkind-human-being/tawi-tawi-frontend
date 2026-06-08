import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class DriverMyTripsTab extends StatefulWidget {
  final String franchiseNumber;
  
  const DriverMyTripsTab({super.key, required this.franchiseNumber});

  @override
  State<DriverMyTripsTab> createState() => _DriverMyTripsTabState();
}

class _DriverMyTripsTabState extends State<DriverMyTripsTab> {
  bool _isLoading = true;
  List<dynamic> _trips = [];
  final Color _driverAccent = AppColors.driverAccent;

  @override
  void initState() {
    super.initState();
    _fetchMyTrips();
  }

  Future<void> _fetchMyTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'driver_full_history_${widget.franchiseNumber}';

    // 1. Load offline cache instantly
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      try {
        final parsed = jsonDecode(cachedData);
        setState(() {
          _trips = parsed['recent_trips'] ?? [];
          _isLoading = false;
        });
      } catch (_) {}
    }

    // 2. Fetch fresh data from the FastAPI backend
    try {
      final response = await ApiClient.instance.get('/drivers/${widget.franchiseNumber}/trips');
      if (response.statusCode == 200) {
        await prefs.setString(cacheKey, jsonEncode(response.data)); 
        if (!mounted) return;
        setState(() {
          _trips = response.data['recent_trips'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color bgColor = isDark ? AppColors.darkBg : AppColors.softBg;
    final Color cardColor = isDark ? AppColors.darkCard : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        title: const Text('My Trips', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading && _trips.isEmpty
          ? Center(child: CircularProgressIndicator(color: _driverAccent))
          : _trips.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_taxi_outlined, size: 64, color: context.dynamicMuted.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'No trips logged yet.',
                        style: TextStyle(color: context.dynamicMuted, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _trips.length,
                  itemBuilder: (context, index) {
                    final trip = _trips[index];
                    return _buildDriverTripCard(trip, cardColor, textColor, context);
                  },
                ),
    );
  }

  Widget _buildDriverTripCard(dynamic trip, Color cardColor, Color textColor, BuildContext context) {
    // Safely Parse Date
    String dateText = "Recent";
    if (trip['timestamp'] != null) {
      try {
        DateTime parsedDate = DateTime.parse(trip['timestamp']).toLocal();
        dateText = DateFormat('MMM d, yyyy • h:mm a').format(parsedDate);
      } catch (_) {}
    }

    // Parse Amount & Passengers
    double amount = (trip['amount'] ?? 0.0).toDouble();
    int passengers = trip['passengers'] ?? 0;
    String title = trip['title'] ?? 'Unknown Route';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.dynamicBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateText, style: TextStyle(color: context.dynamicMuted, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(
                '+ ₱${amount.toStringAsFixed(2)}',
                style: TextStyle(color: _driverAccent, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, color: _driverAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.people_alt_outlined, size: 16, color: context.dynamicMuted),
                  const SizedBox(width: 8),
                  Text('$passengers Passengers', style: TextStyle(color: context.dynamicMuted, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _driverAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Completed',
                  style: TextStyle(color: _driverAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}