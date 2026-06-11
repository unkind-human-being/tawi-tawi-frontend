import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import 'star_rater.dart'; // Make sure this import points to your StarRater file
import '../screens/commuter_app_screen.dart';

class RatingModal extends StatefulWidget {
  final String driverId;
  final String driverName;
  final String franchiseNumber;

  const RatingModal({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.franchiseNumber,
  });

  @override
  State<RatingModal> createState() => _RatingModalState();
}

class _RatingModalState extends State<RatingModal> {
  int _currentRating = 0; // Tracks the stars
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitRide() async {
    if (_currentRating == 0) return;

    setState(() => _isSubmitting = true);

    try {
      // 1. Grab the saved token from the phone's storage
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('access_token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please log in again.')),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // 2. FORCE the ApiClient to use this token!
      ApiClient.instance.options.headers['Authorization'] = 'Bearer $token';

      // 3. Send the request
      final response = await ApiClient.instance.post(
        '/commuters/me/trips', 
        data: {
          'driver_id': widget.driverId,
          'franchise_number': widget.franchiseNumber,
          'rating_value': _currentRating,
          'review_text': _reviewController.text.trim(),
          'origin': 'Scanned QR', 
          'destination': 'Dropoff', 
          'fare': 0.0,              
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String commuterName = prefs.getString('full_name') ?? 'Commuter';
        final String initials = commuterName.isNotEmpty ? commuterName[0].toUpperCase() : 'C';
        final String email = prefs.getString('offline_id') ?? 'unknown@example.com';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ride logged and rated successfully!')),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => CommuterAppScreen(
                fullName: commuterName,
                initials: initials,
                discountStatus: 'Regular',
                email: email,
              ),
            ),
            (Route<dynamic> route) => false,
          );
        }
      }
    } on DioException catch (e) {
      print("🚨 API ERROR: ${e.response?.statusCode} - ${e.response?.data} 🚨");
      if (mounted) {
        // This will pop up the exact reason why it failed!
        final errorMessage = e.response?.data['detail'] ?? 'Network Error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $errorMessage'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unknown error occurred.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // 🔥 MAGIC FIX 2: SingleChildScrollView allows the keyboard to push the modal up safely!
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              Text(
                'Driver Scanned!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Name: ${widget.driverName}'),
              Text('Franchise: ${widget.franchiseNumber}'),
              
              const Divider(height: 32),
              
              const Text(
                'How was your ride?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              StarRater(
                rating: _currentRating,
                onRatingChanged: (rating) {
                  setState(() {
                    _currentRating = rating;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              TextField(
                controller: _reviewController,
                decoration: InputDecoration(
                  hintText: 'Add an optional review...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_currentRating > 0 && !_isSubmitting) ? _submitRide : () {
                        if (_currentRating == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a star rating first!')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Log Ride'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
