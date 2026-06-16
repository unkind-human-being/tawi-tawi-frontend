import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'dart:convert'; // Added for base64 image decoding
import '../providers/lakbai_destinations_provider.dart';
import 'lakbai_destination_details_screen.dart'; // ✅ Added to make the click work!

class LakbaiExploreScreen extends StatefulWidget {
  const LakbaiExploreScreen({super.key});

  @override
  State<LakbaiExploreScreen> createState() => _LakbaiExploreScreenState();
}

class _LakbaiExploreScreenState extends State<LakbaiExploreScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<LakbaiDestinationsProvider>(context, listen: false).fetchDestinations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), 
      appBar: AppBar(
        backgroundColor: const Color(0xFF064E3B), 
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Explore Philippines', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Consumer<LakbaiDestinationsProvider>(
        builder: (context, provider, child) {
          
          if (provider.isLoading && provider.destinations.isEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4,
              itemBuilder: (context, index) => const _SkeletonCard(),
            );
          }

          if (provider.error.isNotEmpty && provider.destinations.isEmpty) {
            return Center(
              child: Text(provider.error, style: const TextStyle(color: Colors.red, fontSize: 16)),
            );
          }

          if (provider.destinations.isEmpty) {
            return const Center(
              child: Text('No destinations found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.destinations.length,
            itemBuilder: (context, index) {
              final dest = provider.destinations[index];
              return _DestinationCard(destination: dest);
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// WIDGET: THE NEAT DESTINATION CARD
// ==========================================
class _DestinationCard extends StatelessWidget {
  final dynamic destination;
  const _DestinationCard({required this.destination});

  // ✅ SMART IMAGE BUILDER
  Widget _buildSmartImage(String rawImageUrl) {
    if (rawImageUrl.isEmpty) {
      return Container(color: Colors.grey[300], child: const Icon(LucideIcons.image, size: 50, color: Colors.grey));
    }
    
    if (rawImageUrl.startsWith('data:image')) {
      try {
        final base64String = rawImageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity);
      } catch (e) {
        return Container(color: Colors.grey[300], child: const Icon(LucideIcons.image, size: 50, color: Colors.grey));
      }
    } else if (rawImageUrl.startsWith('http')) {
      return Image.network(rawImageUrl, fit: BoxFit.cover, width: double.infinity,
          errorBuilder: (c, e, s) => Container(color: Colors.grey[300], child: const Icon(LucideIcons.image, size: 50, color: Colors.grey)));
    } else {
      // It's a local React image like 'luzon.jpg'! Look in the assets folder safely.
      return Image.asset('assets/images/$rawImageUrl', fit: BoxFit.cover, width: double.infinity,
          errorBuilder: (c, e, s) => Container(color: Colors.grey[300], child: const Icon(LucideIcons.image, size: 50, color: Colors.grey)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = destination['name'] ?? destination['title'] ?? 'Unknown';
    final location = destination['location'] ?? destination['address'] ?? 'Philippines';
    final description = destination['description'] ?? 'A beautiful place to visit.';
    final category = destination['category'] ?? 'Nature';
    final imageUrl = destination['image'] ?? '';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // ✅ FIXED: Now it successfully opens the popup detail screen!
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LakbaiDestinationDetailsScreen(destination: destination),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SECTION USING SMART BUILDER
            SizedBox(
              height: 180,
              width: double.infinity,
              child: _buildSmartImage(imageUrl),
            ),
            // DETAILS SECTION
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(12)),
                        child: Text(category, style: const TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(location, style: const TextStyle(color: Colors.grey, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(description, style: TextStyle(color: Colors.grey[800], fontSize: 14, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET: THE LOADING SKELETON MANAGER
// ==========================================
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0, margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 180, width: double.infinity, color: Colors.grey[200]),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 20, width: 200, color: Colors.grey[200]),
                const SizedBox(height: 12),
                Container(height: 16, width: 120, color: Colors.grey[200]),
                const SizedBox(height: 16),
                Container(height: 14, width: double.infinity, color: Colors.grey[200]),
                const SizedBox(height: 6),
                Container(height: 14, width: 250, color: Colors.grey[200]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}