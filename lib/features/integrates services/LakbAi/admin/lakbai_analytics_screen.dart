// frontend/lib/screens/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/lakbai_admin_provider.dart';

class LakbaiAnalyticsScreen extends StatefulWidget {
  const LakbaiAnalyticsScreen({super.key});

  @override
  State<LakbaiAnalyticsScreen> createState() => _LakbaiAnalyticsScreenState();
}

class _LakbaiAnalyticsScreenState extends State<LakbaiAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) {
        Provider.of<LakbaiAdminProvider>(context, listen: false).fetchAnalytics();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<LakbaiAdminProvider>(context);
    final stats = adminProvider.analyticsData['stats'] ?? {};

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Platform Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF064E3B),
        elevation: 0,
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : RefreshIndicator(
              onRefresh: () => adminProvider.fetchAnalytics(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Overview Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                    const SizedBox(height: 16),
                    
                    // Responsive Grid Layout matching metrics configurations
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard('Total Visitors', stats['totalVisitors'] ?? '0', LucideIcons.users, Colors.blue),
                        _buildStatCard('Active Spots', stats['activeDestinations'] ?? '0', LucideIcons.mapPin, Colors.teal),
                        _buildStatCard('Pending Approvals', stats['pendingRequests'] ?? '0', LucideIcons.clock, Colors.amber),
                        _buildStatCard('System Users', stats['totalUsers'] ?? '0', LucideIcons.shieldAlert, Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Active Peak Analytics Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF059669)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('System Peak Season Metric', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(stats['peakSeason'] ?? 'Analyzing...', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
              const SizedBox(height: 2),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )
        ],
      ),
    );
  }
}