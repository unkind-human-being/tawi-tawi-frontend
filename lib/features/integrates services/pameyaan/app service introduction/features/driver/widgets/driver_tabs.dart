import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// --- 1. EARNINGS TAB ---
class EarningsTab extends StatelessWidget {
  final double todaysEarnings;
  final List<Map<String, dynamic>> recentTrips;

  const EarningsTab({
    super.key,
    this.todaysEarnings = 0.0, 
    this.recentTrips = const [], 
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 10),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.driverAccent.withValues(alpha: 0.1), 
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(color: AppColors.driverAccent.withValues(alpha: 0.3))
          ),
          child: Column(
            children: [
              Text('Today\'s Est. Earnings', style: TextStyle(color: context.dynamicMuted, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '₱${todaysEarnings.toStringAsFixed(2)}', 
                style: TextStyle(color: context.dynamicText, fontSize: 32, fontWeight: FontWeight.bold)
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        if (recentTrips.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Text('No trips logged today yet.', style: TextStyle(color: context.dynamicMuted)),
            ),
          )
        else
          ...recentTrips.take(3).map((trip) {
            return PremiumLogCard(
              title: trip['title'] ?? 'Unknown Route', 
              subtitle: '${trip['passengers']} Passengers', 
              amount: '+ ₱${trip['amount'].toStringAsFixed(2)}'
            );
          }),
      ],
    );
  }
}

// --- 2. HISTORY TAB ---
class HistoryTab extends StatelessWidget {
  final List<Map<String, dynamic>> allTrips;

  const HistoryTab({
    super.key,
    this.allTrips = const [], 
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 10),
      children: [
        if (allTrips.isEmpty)
          Center(child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text('No past trips logged yet.', style: TextStyle(color: context.dynamicMuted)),
          ))
        else
          ...allTrips.map((trip) {
            String dateText = "Recent";
            if (trip['timestamp'] != null) {
              try {
                final date = DateTime.parse(trip['timestamp'].toString());
                dateText = "${date.month}/${date.day}/${date.year}";
              } catch (_) {}
            }

            return PremiumLogCard(
              title: trip['title'] ?? 'Unknown Route', 
              subtitle: '${trip['passengers']} Passengers • $dateText', 
              amount: '₱${trip['amount'].toStringAsFixed(2)}'
            );
          }),
      ],
    );
  }
}

// --- REUSABLE COMPONENT FOR EARNINGS & HISTORY ---
class PremiumLogCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;

  const PremiumLogCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), 
      padding: const EdgeInsets.all(16), 
      // DYNAMIC: Card Background switches automatically!
      decoration: BoxDecoration(color: context.dynamicCard, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(
                  title, 
                  // DYNAMIC: Text switches from dark blue to white
                  style: TextStyle(fontWeight: FontWeight.bold, color: context.dynamicText, fontSize: 15),
                  overflow: TextOverflow.ellipsis, 
                  maxLines: 1,
                ), 
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: context.dynamicMuted, fontSize: 12))
              ]
            ),
          ),
          const SizedBox(width: 8),
          Text(amount, style: const TextStyle(color: AppColors.driverAccent, fontSize: 15, fontWeight: FontWeight.bold))
        ],
      ),
    );
  }
}

// --- 3. FARE MATRIX TAB (UPDATED WITH TOP BAR) ---
class FareMatrixTab extends StatelessWidget {
  const FareMatrixTab({super.key});

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
        title: const Text('Fare Matrix', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.dynamicCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.dynamicBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LGU Approved Rates', style: TextStyle(color: context.dynamicText, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Official LGU fare rates (cached for offline use)', style: TextStyle(color: context.dynamicMuted, fontSize: 13)),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(flex: 2, child: Text('Route', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.dynamicText))),
                    Expanded(child: Text('Regular', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.dynamicText))),
                    Expanded(child: Text('Discount', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: context.dynamicText))),
                  ],
                ),
                const Divider(height: 24),
                
                _buildMatrixRow(context, 'Bongao Port', 'to MSU-TCTO Campus', '₱25.00', '₱20.00'),
                const Divider(height: 16),
                _buildMatrixRow(context, 'Sanga-Sanga', 'to Bongao Town', '₱45.00', '₱36.00'),
                const Divider(height: 16),
                _buildMatrixRow(context, 'Provincial Cap.', 'to Datu Halun', '₱20.00', '₱16.00'),
                const Divider(height: 16),
                _buildMatrixRow(context, 'Brgy. Lamion', 'to Brgy. Pababag', '₱55.00', '₱44.00'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // DYNAMIC: Added 'context' parameter to access the theme helper
  Widget _buildMatrixRow(BuildContext context, String origin, String dest, String reg, String disc) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(origin, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.dynamicText), overflow: TextOverflow.ellipsis),
              Text(dest, style: TextStyle(color: context.dynamicMuted, fontSize: 12), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Expanded(child: Text(reg, style: TextStyle(fontSize: 14, color: context.dynamicText))),
        Expanded(child: Text(disc, textAlign: TextAlign.right, style: const TextStyle(color: AppColors.driverAccent, fontWeight: FontWeight.bold, fontSize: 14))),
      ],
    );
  }
}

// --- 4. ALERTS TAB ---
class DriverAlertsTab extends StatelessWidget {
  const DriverAlertsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 10),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.dynamicCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.dynamicBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transport Alerts', style: TextStyle(color: context.dynamicText, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Important announcements and updates', style: TextStyle(color: context.dynamicMuted, fontSize: 13)),
              const SizedBox(height: 24),

              _buildAlertCard(
                context: context,
                icon: Icons.check_circle_outline,
                iconColor: Colors.blueAccent,
                bgColor: Colors.blueAccent.withValues(alpha: 0.05),
                borderColor: Colors.blueAccent.withValues(alpha: 0.2),
                title: 'Fare Adjustment',
                subtitle: 'New fare rates effective starting Monday',
                badgeText: 'New',
              ),
              const SizedBox(height: 12),
              
              _buildAlertCard(
                context: context,
                icon: Icons.warning_amber_rounded,
                iconColor: Colors.orange,
                bgColor: Colors.orange.withValues(alpha: 0.05),
                borderColor: Colors.orange.withValues(alpha: 0.2),
                title: 'Road Construction',
                subtitle: 'Expect delays on Sanga-Sanga route due to ongoing road works',
                badgeText: 'New',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard({
    required BuildContext context, required IconData icon, required Color iconColor, required Color bgColor, required Color borderColor, required String title, required String subtitle, required String badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderColor)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: context.dynamicText, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: context.dynamicMuted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: context.dynamicCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.dynamicBorder)),
            child: Text(badgeText, style: TextStyle(color: context.dynamicText, fontSize: 11, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}

// --- 5. ACTIVE DRIVERS TAB ---
class ActiveDriversTab extends StatelessWidget {
  const ActiveDriversTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 10),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.dynamicCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.dynamicBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Active Drivers', style: TextStyle(color: context.dynamicText, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Nearby drivers on the same route', style: TextStyle(color: context.dynamicMuted, fontSize: 13)),
              const SizedBox(height: 24),

              _buildDriverCard(context, 'Ahmad Kasim', 'Bongao Loop - ABC 1234', 'active', AppColors.driverAccent),
              const SizedBox(height: 12),
              _buildDriverCard(context, 'Rashid Juhur', 'Sanga-Sanga - XYZ 5678', 'On Trip', Colors.blueAccent),
              const SizedBox(height: 12),
              _buildDriverCard(context, 'Benhur Usman', 'Provincial Capitol - DEF 9012', 'active', AppColors.driverAccent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDriverCard(BuildContext context, String name, String details, String status, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: context.dynamicCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.dynamicBorder)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20, 
            backgroundColor: context.isDarkMode ? Colors.grey[800] : Colors.grey[100], 
            child: Icon(Icons.person_outline, color: context.dynamicMuted)
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: context.dynamicText, fontSize: 14)),
                Text(details, style: TextStyle(color: context.dynamicMuted, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}