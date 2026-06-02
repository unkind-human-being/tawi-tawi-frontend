import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../lakbai_config.dart'; // <-- Import centralized config

class LakbaiAdminProvider extends ChangeNotifier {
  List<dynamic> _pendingRequests = [];
  Map<String, dynamic> _analyticsData = {};
  bool _isLoading = false;

  List<dynamic> get pendingRequests => _pendingRequests;
  Map<String, dynamic> get analyticsData => _analyticsData;
  bool get isLoading => _isLoading;

  final _secureStorage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> fetchPendingRequests() async {
    _isLoading = true;
    notifyListeners();
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${LakbaiAppConfig.baseUrl}/destinations/pending'), // Centralized Base URL
        headers: headers,
      );
      if (response.statusCode == 200) {
        _pendingRequests = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Admin requests loading exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAnalytics() async {
    _isLoading = true;
    notifyListeners();
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${LakbaiAppConfig.baseUrl}/analytics'), // Centralized Base URL
        headers: headers,
      );
      if (response.statusCode == 200) {
        _analyticsData = jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Admin analytics loading exception: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> approveDestination(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('${LakbaiAppConfig.baseUrl}/destinations/$id/approve'), // Centralized Base URL
        headers: headers,
      );
      if (response.statusCode == 200) {
        _pendingRequests.removeWhere((req) => req['_id'] == id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Approval routing connection error: $e');
    }
  }

  Future<void> rejectDestination(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${LakbaiAppConfig.baseUrl}/destinations/$id/reject'), // Centralized Base URL
        headers: headers,
      );
      if (response.statusCode == 200) {
        _pendingRequests.removeWhere((req) => req['_id'] == id);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Rejection routing connection error: $e');
    }
  }
}