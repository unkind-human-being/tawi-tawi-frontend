import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../features/sync_engine/services/sync_service.dart';

class NetworkProvider extends ChangeNotifier {
  bool _isOffline = false;
  bool get isOffline => _isOffline;

  NetworkProvider() {
    // Check initial status on startup
    _checkInitialConnection();
    
    // Listen for connection changes (e.g., losing signal at sea, regaining at port)
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }

  Future<void> _checkInitialConnection() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // If the list only contains 'none', we are completely offline
    bool isCurrentlyOffline = results.contains(ConnectivityResult.none) && results.length == 1;

    // Only update if the status actually changed
    if (_isOffline != isCurrentlyOffline) {
      _isOffline = isCurrentlyOffline;
      
      // Tells the UI to show or hide the orange Offline Banner
      notifyListeners(); 

      // If we just got our signal back, fire the Auto-Sync Engine!
      if (!_isOffline) {
        print("Signal restored! Waking up Auto-Sync Engine...");
        SyncService.syncOfflineData();
      }
    }
  }
}