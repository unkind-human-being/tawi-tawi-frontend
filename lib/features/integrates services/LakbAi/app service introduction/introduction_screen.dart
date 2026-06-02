import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../lakbai_config.dart';

class LakbaiDestinationsProvider extends ChangeNotifier {
  List<dynamic> _destinations = [];
  bool _isLoading = false;

  List<dynamic> get destinations => _destinations;
  bool get isLoading => _isLoading;

  // Fetch all destinations
  Future<void> fetchDestinations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('${LakbaiAppConfig.baseUrl}/destinations'));
      if (response.statusCode == 200) {
        _destinations = json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching destinations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ADD NEW DESTINATION
  Future<bool> addDestination(Map<String, dynamic> destinationData, String token) async {
    try {
      final response = await http.post(
        Uri.parse('${LakbaiAppConfig.baseUrl}/destinations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Send token to verify they are an agency
        },
        body: json.encode(destinationData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchDestinations(); // Refresh the list so the new item shows up
        return true;
      }
    } catch (e) {
      debugPrint('Error adding destination: $e');
    }
    return false;
  }
}