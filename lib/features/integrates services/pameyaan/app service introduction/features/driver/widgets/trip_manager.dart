import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- NEW: For checking internet
import '../../../core/database/local_db.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../sync_engine/services/sync_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/network_provider.dart'; // <-- NEW: Network state
import 'sync_queue_panel.dart'; // <-- NEW: To open the bottom sheet automatically

class TripManagerCard extends StatefulWidget {
  final String driverName;
  final String franchiseNumber;
  final Function(Map<String, dynamic>)? onTripCompleted;

  const TripManagerCard({
    super.key, 
    required this.driverName,
    required this.franchiseNumber,
    this.onTripCompleted,
  });

  @override
  State<TripManagerCard> createState() => _TripManagerCardState();
}

class _TripManagerCardState extends State<TripManagerCard> {
  final Color _driverAccent = AppColors.driverAccent;
  bool _isActive = false;
  int _passengerCount = 1;
  bool _isSyncing = false;

  String? _origin;
  String? _destination;

  final List<String> _locations = [
    'Bongao Port', 'Sanga-Sanga Airport', 'Tawi-Tawi Provincial Capitol', 'Bongao Municipal Hall',
    'MSU-TCTO Campus', 'Mahardika Institute of Technology', 'Tawi-Tawi Regional Agricultural College', 'Abubakar Computer Learning Center', 'Bongao Central Elementary School', 'Datu Halun Pilot School',
    'Brgy. Bongao Poblacion', 'Brgy. Ipil', 'Brgy. Kamagong', 'Brgy. Karungdong', 'Brgy. Lagasan', 'Brgy. Lakit Lakit', 'Brgy. Lamion', 'Brgy. Lapid Lapid', 'Brgy. Lato Lato', 'Brgy. Luuk Pandan', 'Brgy. Luuk Tulay', 'Brgy. Malassa', 'Brgy. Mandulan', 'Brgy. Masantong', 'Brgy. Montay Montay', 'Brgy. Nalil', 'Brgy. Pababag', 'Brgy. Pag-asa', 'Brgy. Pagasinan', 'Brgy. Pagatpat', 'Brgy. Pahut', 'Brgy. Pakias', 'Brgy. Paniongan', 'Brgy. Pasiagan', 'Brgy. Sanga-Sanga', 'Brgy. Silubog', 'Brgy. Simandagit', 'Brgy. Sumangat', 'Brgy. Tarawakan', 'Brgy. Tongsinah', 'Brgy. Tubig Basag', 'Brgy. Tubig Tanah', 'Brgy. Tubig-Boh', 'Brgy. Tubig-Mampallam', 'Brgy. Ungus-ungus'
  ];

  double _getCalculatedEarnings() {
    if (_origin == null || _destination == null || _origin == _destination) {
      return _passengerCount * 20.0; 
    }
    double distanceKm = DistanceCalculator.getDistanceInKm(_origin!, _destination!);
    double baseFare = 20.00;
    if (distanceKm > 1.0) baseFare += ((distanceKm - 1.0) * 5.00);
    return baseFare * _passengerCount;
  }

  void _showLocationPicker(String title, bool isOrigin) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => DriverLocationPickerSheet(
        title: 'Select $title', locations: _locations, driverAccent: _driverAccent,
        onSelected: (val) {
          setState(() {
            if (isOrigin) _origin = val;
            else _destination = val;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double currentEarnings = _getCalculatedEarnings();
    double currentDistance = (_origin != null && _destination != null) ? DistanceCalculator.getDistanceInKm(_origin!, _destination!) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: context.dynamicCard, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppColors.deepOcean.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [Icon(Icons.local_taxi, color: _driverAccent, size: 20), const SizedBox(width: 8), Text('Current Trip', style: TextStyle(color: context.dynamicText, fontSize: 18, fontWeight: FontWeight.bold))]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _isActive ? _driverAccent.withOpacity(0.2) : context.isDarkMode ? Colors.grey[800] : Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                child: Text(_isActive ? 'ON ROUTE' : 'WAITING', style: TextStyle(color: _isActive ? Colors.green[800] : context.dynamicMuted, fontSize: 11, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 24),
          
          if (_isActive) ...[
            Row(
              children: [
                Expanded(child: _buildCustomDropdown('From', _origin, true)),
                const SizedBox(width: 16),
                Expanded(child: _buildCustomDropdown('To', _destination, false)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: context.isDarkMode ? AppColors.darkBg : AppColors.softBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.dynamicBorder)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Passengers', style: TextStyle(color: context.dynamicMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('$_passengerCount', style: TextStyle(color: context.dynamicText, fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(onPressed: () => setState(() { if (_passengerCount > 1) _passengerCount--; }), icon: const Icon(Icons.remove_circle_outline), color: Colors.redAccent),
                          IconButton(onPressed: () => setState(() => _passengerCount++), icon: const Icon(Icons.add_circle), color: _driverAccent, iconSize: 32),
                        ],
                      )
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Est. Route Earnings:', style: TextStyle(color: context.dynamicMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('₱${currentEarnings.toStringAsFixed(2)}', style: TextStyle(color: _driverAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSyncing ? null : () async {
                if (_isActive) {
                  if (_origin == null || _destination == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select From and To locations', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating));
                    return;
                  }
                  setState(() => _isSyncing = true);
                  
                  final tripPayload = {
                    "driver_name": widget.driverName,
                    "franchise_number": widget.franchiseNumber,
                    "origin": _origin,
                    "destination": _destination,
                    "distance_km": currentDistance,
                    "passengers_logged": _passengerCount,
                    "estimated_earnings": currentEarnings,
                    "timestamp": DateTime.now().toIso8601String(),
                  };
                  
                  // 1. Queue it in SQLite
                  await LocalDatabase.instance.queueOfflineAction('/drivers/trips/log', tripPayload);
                  
                  // 2. Update UI instantly
                  if (widget.onTripCompleted != null) {
                    widget.onTripCompleted!({
                      'title': 'Trip to $_destination',
                      'passengers': _passengerCount,
                      'amount': currentEarnings,
                      'timestamp': tripPayload['timestamp'],
                    });
                  }
                  
                  // 3. CHECK THE NETWORK STATE!
                  bool isOffline = Provider.of<NetworkProvider>(context, listen: false).isOffline;
                  
                  if (!context.mounted) return;

                  if (isOffline) {
                    // IF OFFLINE: Show orange snackbar and slide up the Sync Hub Panel automatically
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Offline: Trip securely saved to Sync Hub!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))
                    );
                    
                    setState(() { _passengerCount = 1; _origin = null; _destination = null; _isActive = false; _isSyncing = false; });
                    
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const SyncQueuePanel(), // Pops the panel up!
                    );
                  } else {
                    // IF ONLINE: Run the background sync as normal
                    SyncService.syncOfflineData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Trip logged & syncing securely!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), backgroundColor: _driverAccent, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))
                    );
                    
                    setState(() { _passengerCount = 1; _origin = null; _destination = null; _isActive = false; _isSyncing = false; });
                  }
                  
                } else {
                  setState(() => _isActive = true); 
                }
              },
              icon: _isSyncing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(_isActive ? Icons.check_circle : Icons.play_circle_fill, size: 20), 
              label: Text(_isActive ? (_isSyncing ? 'SAVING...' : 'COMPLETE TRIP') : 'START NEW TRIP', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              style: ElevatedButton.styleFrom(backgroundColor: _isActive ? _driverAccent : AppColors.deepOcean, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCustomDropdown(String label, String? value, bool isOrigin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.dynamicMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showLocationPicker(label, isOrigin),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(color: context.isDarkMode ? AppColors.darkBg : AppColors.softBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.dynamicBorder)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(value ?? 'Select', style: TextStyle(fontSize: 13, color: value == null ? context.dynamicMuted : context.dynamicText, fontWeight: value == null ? FontWeight.normal : FontWeight.w600), overflow: TextOverflow.ellipsis)),
                Icon(Icons.search, color: _driverAccent, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class DriverLocationPickerSheet extends StatefulWidget {
  final String title;
  final List<String> locations;
  final Function(String) onSelected;
  final Color driverAccent;

  const DriverLocationPickerSheet({
    super.key, required this.title, required this.locations, required this.onSelected, required this.driverAccent,
  });

  @override
  State<DriverLocationPickerSheet> createState() => _DriverLocationPickerSheetState();
}

class _DriverLocationPickerSheetState extends State<DriverLocationPickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredLocations = widget.locations.where((loc) => loc.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.75, 
      padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(color: context.dynamicCard, borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.dynamicBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Text(widget.title, style: TextStyle(color: context.dynamicText, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            autofocus: true, onChanged: (val) => setState(() => _searchQuery = val),
            style: TextStyle(color: context.dynamicText),
            decoration: InputDecoration(hintText: 'Search barangay or school...', hintStyle: TextStyle(color: context.dynamicMuted, fontSize: 14), prefixIcon: Icon(Icons.search, color: context.dynamicMuted), filled: true, fillColor: context.isDarkMode ? AppColors.darkBg : const Color(0xFFF4F7F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredLocations.isEmpty
              ? Center(child: Text('No locations found.', style: TextStyle(color: context.dynamicMuted)))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(), itemCount: filteredLocations.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero, leading: Icon(Icons.location_on, color: widget.driverAccent),
                      title: Text(filteredLocations[index], style: TextStyle(color: context.dynamicText, fontWeight: FontWeight.w600, fontSize: 14)),
                      onTap: () { widget.onSelected(filteredLocations[index]); Navigator.pop(context); },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}