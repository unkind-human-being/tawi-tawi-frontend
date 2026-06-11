import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../widgets/star_rater.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'commuter_app_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  final String driverId;
  final String driverName;
  final String franchiseNumber;
  final String initialTrustScore;
  final int initialTotalRatings;

  const DriverProfileScreen({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.franchiseNumber,
    required this.initialTrustScore,
    required this.initialTotalRatings,
  });

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final TextEditingController _reviewController = TextEditingController();
  
  int _currentRating = 0;
  bool _isSubmitting = false;

  late String _trustScore;
  late int _totalRatings;

  @override
  void initState() {
    super.initState();
    _trustScore = widget.initialTrustScore;
    _totalRatings = widget.initialTotalRatings;
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_currentRating == 0) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Look how clean this is! ApiClient automatically uses your IP address 
      // and automatically attaches the 'Bearer' token you saved during login.
      final prefs = await SharedPreferences.getInstance();
      final commuterId = prefs.getString('offline_id') ?? 'unknown_commuter';

      final response = await ApiClient.instance.post(
        '/v1/ratings', 
        data: {
          'driver_id': widget.driverId,
          'commuter_id': commuterId,
          'rating_value': _currentRating,
          'review_text': _reviewController.text.trim(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Ride logged perfectly!");
        
        // Update the UI instantly with the fresh data
        final data = response.data['data'] ?? {};
        setState(() {
          if (data['new_trust_score'] != null) {
            _trustScore = data['new_trust_score'].toString();
          }
          if (data['total_ratings'] != null) {
            _totalRatings = data['total_ratings'];
          }
          _currentRating = 0; // Reset stars after success
          _reviewController.clear(); // Clear text
        });
        
        final String commuterName = prefs.getString('full_name') ?? 'Commuter';
        final String initials = commuterName.isNotEmpty ? commuterName[0].toUpperCase() : 'C';
        final String email = prefs.getString('offline_id') ?? 'unknown@example.com';
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rating submitted successfully!')),
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
      // If it's a 401 now, it means the token is truly invalid or expired
      if (e.response?.statusCode == 401) {
         _showError("Session expired. Please log out and log back in.");
      } else {
         _showError("Failed to log ride: ${e.response?.data ?? e.message}");
      }
    } catch (e) {
      _showError('Network error. Please check your connection.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.errorRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. The Driver Profile View
            CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.driverAccent.withOpacity(0.2),
              child: const Icon(Icons.person, size: 50, color: AppColors.driverAccent),
            ),
            const SizedBox(height: 16),
            Text(
              widget.driverName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Franchise: ${widget.franchiseNumber}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.dynamicMuted,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: context.dynamicCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            _trustScore,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Trust Score',
                        style: TextStyle(color: context.dynamicMuted),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: context.dynamicBorder,
                  ),
                  Column(
                    children: [
                      Text(
                        '$_totalRatings',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Ratings',
                        style: TextStyle(color: context.dynamicMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // 2. The Rating Input Component
            const Divider(),
            const SizedBox(height: 24),
            Text(
              'Rate your ride',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            StarRater(
              rating: _currentRating,
              onRatingChanged: (rating) {
                setState(() {
                  _currentRating = rating;
                });
                print("Commuter selected $_currentRating stars!");
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reviewController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Optional: Leave a review...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: context.dynamicCard,
              ),
            ),
            const SizedBox(height: 24),
            
            // 3. The Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _currentRating > 0 && !_isSubmitting ? _submitRating : () {
                  if (_currentRating == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a star rating first!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Log this ride',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
