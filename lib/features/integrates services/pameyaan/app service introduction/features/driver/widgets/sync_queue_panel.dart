import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:provider/provider.dart'; // <-- Added for Network detection

import '../../../core/database/local_db.dart';
import '../../sync_engine/services/sync_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/network_provider.dart'; // <-- Added for Network Status

class SyncQueuePanel extends StatefulWidget {
  const SyncQueuePanel({super.key});

  @override
  State<SyncQueuePanel> createState() => _SyncQueuePanelState();
}

class _SyncQueuePanelState extends State<SyncQueuePanel> {
  bool _isLoading = true;
  bool _isSyncing = false;
  List<Map<String, dynamic>> _pendingItems = [];

  @override
  void initState() {
    super.initState();
    _loadPendingData();
  }

  Future<void> _loadPendingData() async {
    final items = await LocalDatabase.instance.getPendingSyncs();
    if (!mounted) return;
    setState(() {
      _pendingItems = items;
      _isLoading = false;
    });
  }

  // NEW: Delete a specific trip from the queue
  Future<void> _deleteTrip(int id) async {
    await LocalDatabase.instance.deleteQueuedItem(id);
    await _loadPendingData(); // Refresh the list after deleting
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Trip deleted from queue.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )
    );
  }

  Future<void> _performSync() async {
    setState(() => _isSyncing = true);
    
    await SyncService.syncOfflineData();
    await Future.delayed(const Duration(milliseconds: 500));
    
    final remainingItems = await LocalDatabase.instance.getPendingSyncs();
    if (!mounted) return;
    
    setState(() {
      _pendingItems = remainingItems; 
      _isSyncing = false;
    });
    
    if (remainingItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All offline trips uploaded successfully!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppColors.driverAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${remainingItems.length} trips waiting for internet connection.', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // NEW: Listen to the network provider instantly
    final bool isOffline = Provider.of<NetworkProvider>(context).isOffline;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75, 
      padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: context.dynamicCard, 
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.dynamicBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Offline Sync Hub', style: TextStyle(color: context.dynamicText, fontSize: 20, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _pendingItems.isEmpty ? AppColors.driverAccent.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  _pendingItems.isEmpty ? 'UP TO DATE' : '${_pendingItems.length} PENDING', 
                  style: TextStyle(color: _pendingItems.isEmpty ? AppColors.driverAccent : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)
                ),
              )
            ],
          ),
          const SizedBox(height: 16),

          // NEW: Dynamic Network Status Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOffline ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isOffline ? Colors.orange.withOpacity(0.3) : Colors.green.withOpacity(0.3))
            ),
            child: Row(
              children: [
                Icon(isOffline ? Icons.wifi_off : Icons.wifi, color: isOffline ? Colors.orange : Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isOffline 
                      ? 'You are OFFLINE. Trips are safely stored.' 
                      : 'You are ONLINE. Ready to sync!',
                    style: TextStyle(
                      color: isOffline ? Colors.orange[800] : Colors.green[800], 
                      fontWeight: FontWeight.bold, 
                      fontSize: 13
                    )
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.driverAccent))
                : _pendingItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_done_outlined, size: 64, color: AppColors.driverAccent.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text('All data is backed up to the cloud.', style: TextStyle(color: context.dynamicMuted, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _pendingItems.length,
                        itemBuilder: (context, index) {
                          final item = _pendingItems[index];
                          
                          final payload = jsonDecode(item['payload'] as String);
                          
                          final String origin = payload['origin'] ?? 'Unknown Origin';
                          final String destination = payload['destination'] ?? 'Unknown Destination';
                          final int passengers = payload['passengers_logged'] ?? payload['passengers'] ?? 1;
                          
                          final rawEarnings = payload['estimated_earnings'] ?? payload['fare'] ?? payload['amount'] ?? 0.0;
                          final double earnings = (rawEarnings is num) ? rawEarnings.toDouble() : 0.0;

                          String timeText = 'Just now';
                          if (payload['timestamp'] != null) {
                            try {
                              final dt = DateTime.parse(payload['timestamp']).toLocal();
                              final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
                              final minute = dt.minute.toString().padLeft(2, '0');
                              final amPm = dt.hour >= 12 ? 'PM' : 'AM';
                              timeText = '$hour:$minute $amPm';
                            } catch (_) {}
                          }
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.isDarkMode ? AppColors.darkBg : AppColors.softBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: context.dynamicBorder)
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(timeText, style: TextStyle(color: context.dynamicMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                                    
                                    // NEW: Added the Delete Trash Can icon next to the earnings
                                    Row(
                                      children: [
                                        Text('+ ₱${earnings.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.driverAccent, fontSize: 16)),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => _deleteTrip(item['id'] as int),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                            child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.trip_origin, color: AppColors.driverAccent, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(origin, style: TextStyle(fontWeight: FontWeight.w600, color: context.dynamicText))),
                                  ],
                                ),
                                Container(margin: const EdgeInsets.only(left: 7), height: 10, width: 2, color: context.dynamicBorder),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(destination, style: TextStyle(fontWeight: FontWeight.w600, color: context.dynamicText))),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.people_alt_outlined, size: 14, color: context.dynamicMuted),
                                    const SizedBox(width: 6),
                                    Text('$passengers Passenger(s)', style: TextStyle(color: context.dynamicMuted, fontSize: 12)),
                                    const Spacer(),
                                    
                                    // NEW: Updates dynamically based on live Wi-Fi status
                                    Icon(isOffline ? Icons.wifi_off : Icons.wifi, size: 14, color: isOffline ? Colors.orange : Colors.green),
                                    const SizedBox(width: 4),
                                    Text(isOffline ? 'Waiting to sync' : 'Ready to sync', style: TextStyle(color: isOffline ? Colors.orange : Colors.green, fontSize: 11)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          
          const SizedBox(height: 16),
          if (_pendingItems.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSyncing ? null : _performSync,
                icon: _isSyncing 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.sync),
                label: Text(_isSyncing ? 'SYNCING TO DATABASE...' : 'SYNC DATA NOW', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.driverAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            )
        ],
      ),
    );
  }
}