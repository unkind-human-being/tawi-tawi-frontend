import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../screens/commuter_settings_screen.dart';
import '../../../core/theme/app_theme.dart';

class CommuterHeader extends StatelessWidget {
  final String fullName;
  final String initials;
  final String discountStatus;
  final Function(String) onProfileUpdated;

  const CommuterHeader({
    super.key,
    required this.fullName,
    required this.initials,
    required this.discountStatus,
    required this.onProfileUpdated,
  });

  final Color _deepOcean = AppColors.deepOcean;
  final Color _neonTeal = AppColors.neonTeal;
  final Color _softBg = AppColors.softBg;

  void _showBoardingPassQR(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: _deepOcean.withOpacity(0.1),
                child: Text(initials, style: TextStyle(color: _deepOcean, fontWeight: FontWeight.bold, fontSize: 24)),
              ),
              const SizedBox(height: 16),
              Text(fullName, style: TextStyle(color: _deepOcean, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _neonTeal.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text(discountStatus, style: TextStyle(color: Colors.teal[800], fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
              QrImageView(data: 'COMMUTER:$fullName|$discountStatus', version: QrVersions.auto, size: 200.0, foregroundColor: _deepOcean),
              const SizedBox(height: 12),
              const Text('Show this to the driver for scanning', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 24),
              TextButton(onPressed: () => Navigator.pop(context), child: Text('CLOSE', style: TextStyle(color: _neonTeal, fontWeight: FontWeight.bold, letterSpacing: 1))),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                final updatedName = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CommuterSettingsScreen(fullName: fullName, initials: initials, discountStatus: discountStatus)),
                );
                if (updatedName != null && updatedName is String) {
                  onProfileUpdated(updatedName);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: context.isDarkMode ? Colors.white : AppColors.deepOcean,
                      child: Text(initials, style: TextStyle(color: context.isDarkMode ? AppColors.deepOcean : Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Where to today,', style: TextStyle(color: context.dynamicMuted, fontSize: 12)),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  fullName, // <-- REMOVED THE QUESTION MARK HERE
                                  style: TextStyle(color: context.dynamicText, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              // <-- REMOVED THE EDIT PENCIL ICON FROM HERE
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: _neonTeal.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: _neonTeal.withOpacity(0.5))),
                            child: Text(discountStatus, style: TextStyle(color: context.isDarkMode ? _neonTeal : Colors.teal[800], fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: context.dynamicText, size: 28), 
            onPressed: () => _showBoardingPassQR(context)
          ),
        ],
      ),
    );
  }
}