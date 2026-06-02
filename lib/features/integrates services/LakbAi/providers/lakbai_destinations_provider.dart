import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../lakbai_config.dart'; 

class LakbaiDestinationsProvider extends ChangeNotifier {
  List<dynamic> _destinations = [];
  bool _isLoading = false;
  String _error = '';

  List<dynamic> get destinations => _destinations;
  bool get isLoading => _isLoading;
  String get error => _error;

  final _secureStorage = const FlutterSecureStorage();

  // SAFELY INITIALIZE HIVE ON DEMAND INSTEAD OF CRASHING ON APP START
  Future<Box> _getBox() async {
    await Hive.initFlutter();
    if (!Hive.isBoxOpen('destinationsBox')) {
      return await Hive.openBox('destinationsBox');
    }
    return Hive.box('destinationsBox');
  }

  Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'jwt_token'); 
  }

  Future<void> fetchDestinations() async {
    final box = await _getBox(); // Uses our safe box
    final cachedData = box.get('cached_destinations');
    
    if (cachedData != null) {
      _destinations = json.decode(cachedData);
      _error = '';
      notifyListeners();
    } else {
      _isLoading = true;
      _error = '';
      notifyListeners();
    }

    try {
      await _syncPendingDestinations();

      final response = await http.get(Uri.parse('${LakbaiAppConfig.baseUrl}/destinations'));
      
      if (response.statusCode == 200) {
        final freshData = json.decode(response.body);
        _destinations = freshData;
        _error = '';
        await box.put('cached_destinations', response.body); // Uses our safe box
      } else {
        if (_destinations.isEmpty) _error = 'Failed to load destinations';
      }
    } catch (e) {
      if (_destinations.isEmpty) _error = 'Network offline. Showing cached data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addDestination(Map<String, dynamic> destinationData) async {
    _isLoading = true;
    notifyListeners();

    final box = await _getBox(); // Uses our safe box

    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${LakbaiAppConfig.baseUrl}/destinations'), 
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(destinationData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _destinations.insert(0, destinationData); 
        await box.put('cached_destinations', json.encode(_destinations)); // 
        _error = '';
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to add destination');
      }
    } catch (e) {
      debugPrint('Add Destination Error: $e'); 
      final queuedDest = Map<String, dynamic>.from(destinationData);
      queuedDest['status'] = 'Pending Sync';
      
      _destinations.insert(0, queuedDest);
      await box.put('cached_destinations', json.encode(_destinations)); // 

      List<dynamic> pending = [];
      final storedPending = box.get('pending_additions');
      if (storedPending != null) {
        pending = json.decode(storedPending);
      }
      pending.add(destinationData);
      await box.put('pending_additions', json.encode(pending)); // 
      
      _error = 'Saved offline. Will sync when connected to Wi-Fi.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncPendingDestinations() async {
    final box = await _getBox(); //  Uses our safe box
    final storedPending = box.get('pending_additions');
    
    if (storedPending == null) return;
    
    List<dynamic> pending = json.decode(storedPending);
    if (pending.isEmpty) return;

    List<dynamic> stillPending = [];
    final token = await _getToken();

    for (var dest in pending) {
      try {
        final response = await http.post(
          Uri.parse('${LakbaiAppConfig.baseUrl}/destinations'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: json.encode(dest),
        );

        if (response.statusCode != 201 && response.statusCode != 200) {
          stillPending.add(dest);
        }
      } catch (e) {
        stillPending.add(dest);
      }
    }

    await box.put('pending_additions', json.encode(stillPending)); // 
  }
}