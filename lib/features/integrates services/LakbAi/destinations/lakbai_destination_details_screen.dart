import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert'; 
import 'package:provider/provider.dart'; 
import '../providers/lakbai_itinerary_provider.dart'; 

class LakbaiDestinationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> destination;

  const LakbaiDestinationDetailsScreen({super.key, required this.destination});

  // ✅ SMART IMAGE BUILDER
  Widget _buildImage(String rawImageUrl) {
    if (rawImageUrl.isEmpty) {
      return Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity);
    }
    
    if (rawImageUrl.startsWith('data:image')) {
      try {
        final base64String = rawImageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c, e, s) => Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity));
      } catch (e) {
        return Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity);
      }
    } 
    else if (rawImageUrl.startsWith('http')) {
      return Image.network(rawImageUrl, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c, e, s) => Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity));
    } 
    else {
      // ✅ FIXED: Look in the assets folder instead of localhost!
      return Image.asset('assets/images/$rawImageUrl', fit: BoxFit.cover, width: double.infinity, errorBuilder: (c, e, s) => Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = destination['name'] ?? destination['title'] ?? 'Unknown Place';
    final location = destination['location'] ?? destination['region'] ?? 'PHILIPPINES';
    final description = destination['description'] ?? 'Explore this beautiful tourist destination. The exact details for this location are currently being updated by the tourism office.';
    
    final submittedBy = destination['submittedBy'] ?? {};
    final postedByName = submittedBy['name'] ?? 'Tourism Office';
    final postedByEmail = submittedBy['email'] ?? 'office@lakbai.ph';
    final postedByPhone = submittedBy['phone'] ?? '+63 912 345 6789';

    final rawImageUrl = destination['image'] ?? destination['imageUrl'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF064E3B)),
            // ✅ FIXED: Standard Navigator pop instead of go_router
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      extendBodyBehindAppBar: true, 
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 300,
              width: double.infinity,
              child: _buildImage(rawImageUrl),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))).animate().fadeIn().slideX(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 16, color: Color(0xFF059669)),
                      const SizedBox(width: 4),
                      Text(location.toString().toUpperCase(), style: const TextStyle(fontSize: 14, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                    ],
                  ).animate().fadeIn().slideX(),
                  
                  const SizedBox(height: 24),
                  
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5), 
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('POSTED BY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857), letterSpacing: 1.2)),
                        const SizedBox(height: 16),
                        _buildContactRow(LucideIcons.user, postedByName),
                        const SizedBox(height: 12),
                        _buildContactRow(LucideIcons.mail, postedByEmail),
                        const SizedBox(height: 12),
                        _buildContactRow(LucideIcons.phone, postedByPhone),
                      ],
                    ),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 200)).slideY(begin: 0.1),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.6),
                  ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
                  
                  const SizedBox(height: 40),
                  
                  // Bottom Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adding to your Planner...')));
                            // Calling the Itinerary Provider
                            await Provider.of<LakbaiItineraryProvider>(context, listen: false).addManualDestination(title);
                            if (context.mounted) {
                               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully added to Planner!')));
                            }
                          },
                          icon: const Icon(LucideIcons.calendar, color: Colors.white, size: 18),
                          label: const Text('Add to Planner', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF064E3B), 
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(LucideIcons.info, color: Color(0xFF064E3B), size: 18),
                          label: const Text('More Info', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF064E3B), fontSize: 14)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFFD1FAE5), width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: const Duration(milliseconds: 400)).slideY(begin: 0.2),
                  
                  const SizedBox(height: 40), 
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF059669)),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF047857), fontWeight: FontWeight.w500))),
      ],
    );
  }
}