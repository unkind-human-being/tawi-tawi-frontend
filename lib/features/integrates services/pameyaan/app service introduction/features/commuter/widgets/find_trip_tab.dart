// import 'package:flutter/material.dart';
// import '../../../core/utils/distance_calculator.dart';
// import '../../../core/theme/app_theme.dart';
// import '../../../core/network/api_client.dart';
// import '../../../core/database/local_db.dart';
// import '../../sync_engine/services/sync_service.dart';

// class FindTripTab extends StatefulWidget {
//   final String discountStatus;

//   const FindTripTab({super.key, required this.discountStatus});

//   @override
//   State<FindTripTab> createState() => _FindTripTabState();
// }

// class _FindTripTabState extends State<FindTripTab> {
//   String? _selectedOrigin;
//   String? _selectedDestination;
//   double _distance = 0.0;
//   double _estimatedFare = 0.0;
//   bool _isLogging = false;

//   final TextEditingController _franchiseController = TextEditingController();
//   final List<String> _locations = DistanceCalculator.bongaoLocations.keys.toList()..sort();

//   @override
//   void dispose() {
//     _franchiseController.dispose();
//     super.dispose();
//   }

//   void _calculateFare() {
//     if (_selectedOrigin != null && _selectedDestination != null) {
//       if (_selectedOrigin == _selectedDestination) {
//         setState(() {
//           _distance = 0.0;
//           _estimatedFare = 0.0;
//         });
//         return;
//       }

//       double dist = DistanceCalculator.getDistanceInKm(_selectedOrigin!, _selectedDestination!);
//       double baseFare = 20.0;
//       double additionalFare = dist > 1.0 ? (dist - 1.0) * 5.0 : 0.0;
//       double totalFare = baseFare + additionalFare;

//       if (widget.discountStatus != 'Regular') {
//         totalFare = totalFare * 0.80; // 20% Discount
//       }

//       setState(() {
//         _distance = dist;
//         _estimatedFare = totalFare;
//       });
//     }
//   }

//   Future<void> _logConnectedTrip() async {
//     final franchiseNumber = _franchiseController.text.trim();
//     if (franchiseNumber.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please enter the tricycle Franchise Number.'), backgroundColor: Colors.orange)
//       );
//       return;
//     }

//     setState(() => _isLogging = true);

//     try {
//       final tripPayload = {
//         "driver_id": franchiseNumber,
//         "driver_name": "Tricycle #$franchiseNumber",
//         "origin": _selectedOrigin,
//         "destination": _selectedDestination,
//         "fare": _estimatedFare,
//         "timestamp": DateTime.now().toIso8601String(),
//       };

//       // 1. Try sending directly to backend
//       try {
//         await ApiClient.instance.post('/me/trips/log', data: tripPayload);
//       } catch (e) {
//         // 2. If offline, save to local queue and sync later
//         await LocalDatabase.instance.queueOfflineAction('/me/trips/log', tripPayload);
//         SyncService.syncOfflineData();
//       }

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Ride logged! Linked to Driver #$franchiseNumber.'), 
//           backgroundColor: AppColors.neonTeal,
//           behavior: SnackBarBehavior.floating,
//         )
//       );

//       // Reset form
//       setState(() {
//         _selectedOrigin = null;
//         _selectedDestination = null;
//         _franchiseController.clear();
//         _distance = 0.0;
//         _estimatedFare = 0.0;
//       });

//     } finally {
//       if (mounted) setState(() => _isLogging = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isDark = context.isDarkMode;
//     final Color bgColor = isDark ? AppColors.darkBg : AppColors.softBg;
//     final Color cardColor = isDark ? AppColors.darkCard : Colors.white;
//     final Color textColor = isDark ? Colors.white : Colors.black87;

//     return Scaffold(
//       backgroundColor: bgColor,
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Log Your Ride', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
//             const SizedBox(height: 8),
//             Text('Enter your route and the tricycle number to log this trip to your history.', style: TextStyle(color: Colors.grey[600])),
//             const SizedBox(height: 24),

//             // ROUTE SELECTOR CARD
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: cardColor,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
//               ),
//               child: Column(
//                 children: [
//                   _buildDropdown(
//                     label: 'Pick-up Location', icon: Icons.trip_origin, iconColor: AppColors.neonTeal,
//                     value: _selectedOrigin, onChanged: (val) { setState(() => _selectedOrigin = val); _calculateFare(); },
//                   ),
//                   const Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 18), child: Align(alignment: Alignment.centerLeft, child: Icon(Icons.more_vert, color: Colors.grey))),
//                   _buildDropdown(
//                     label: 'Drop-off Destination', icon: Icons.location_on, iconColor: Colors.redAccent,
//                     value: _selectedDestination, onChanged: (val) { setState(() => _selectedDestination = val); _calculateFare(); },
//                   ),
//                   const SizedBox(height: 16),
                  
//                   // NEW: Franchise Number Input
//                   TextField(
//                     controller: _franchiseController,
//                     keyboardType: TextInputType.number,
//                     decoration: InputDecoration(
//                       labelText: 'Tricycle Franchise Number',
//                       prefixIcon: const Icon(Icons.numbers, color: AppColors.deepOcean),
//                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                       filled: true,
//                       fillColor: context.isDarkMode ? Colors.black12 : Colors.grey[50],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 32),

//             // RESULTS & LOG BUTTON
//             if (_selectedOrigin != null && _selectedDestination != null && _selectedOrigin != _selectedDestination)
//               Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(colors: [AppColors.deepOcean, Color(0xFF1A365D)]),
//                   borderRadius: BorderRadius.circular(16),
//                   boxShadow: [BoxShadow(color: AppColors.deepOcean.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
//                 ),
//                 child: Column(
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text('Official Fare', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16)),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(color: AppColors.neonTeal.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
//                           child: Text(widget.discountStatus.toUpperCase(), style: const TextStyle(color: AppColors.neonTeal, fontSize: 10, fontWeight: FontWeight.bold)),
//                         )
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         const Text('₱', style: TextStyle(color: AppColors.neonTeal, fontSize: 24, fontWeight: FontWeight.bold)),
//                         Text(_estimatedFare.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, height: 1.0)),
//                       ],
//                     ),
//                     const Divider(color: Colors.white24, height: 24),
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: _isLogging ? null : _logConnectedTrip,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.neonTeal,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
//                         ),
//                         child: _isLogging 
//                           ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                           : const Text('LOG THIS RIDE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
//                       ),
//                     )
//                   ],
//                 ),
//               ),
              
//               if (_selectedOrigin == _selectedDestination && _selectedOrigin != null)
//                 const Center(child: Text("Pick-up and Drop-off cannot be the same.", style: TextStyle(color: Colors.redAccent))),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDropdown({required String label, required IconData icon, required Color iconColor, required String? value, required Function(String?) onChanged}) {
//     return DropdownButtonFormField<String>(
//       value: value, isExpanded: true,
//       decoration: InputDecoration(
//         labelText: label, prefixIcon: Icon(icon, color: iconColor),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         filled: true, fillColor: context.isDarkMode ? Colors.black12 : Colors.grey[50],
//       ),
//       items: _locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc, overflow: TextOverflow.ellipsis))).toList(),
//       onChanged: onChanged,
//     );
//   }
// }