import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:convert';
import '../providers/lakbai_destinations_provider.dart';
import '../providers/lakbai_itinerary_provider.dart';

class LakbaiExploreScreen extends StatefulWidget {
  const LakbaiExploreScreen({super.key});

  @override
  State<LakbaiExploreScreen> createState() => _LakbaiExploreScreenState();
}

class _LakbaiExploreScreenState extends State<LakbaiExploreScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Luzon', 'Visayas', 'Mindanao'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LakbaiDestinationsProvider>(context, listen: false).fetchDestinations();
    });
  }

  Widget _buildImage(String rawImageUrl) {
    if (rawImageUrl.isEmpty) {
      return Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity);
    }
    
    if (rawImageUrl.startsWith('data:image')) {
      try {
        final base64String = rawImageUrl.split(',').last.replaceAll(RegExp(r'\s+'), '');
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity, height: double.infinity));
      } catch (e) {
        return Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity, height: double.infinity);
      }
    } else if (rawImageUrl.startsWith('http')) {
      return Image.network(rawImageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity, height: double.infinity));
    } else {
      return Image.network('http://localhost:3000/$rawImageUrl', fit: BoxFit.cover, width: double.infinity, height: double.infinity, errorBuilder: (c, e, s) => Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity, height: double.infinity));
    }
  }

  void _showDetailsModal(BuildContext context, Map<String, dynamic> dest) {
    showDialog(
      context: context,
      barrierColor: const Color(0xFF022C22).withOpacity(0.7), 
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: _DestinationDetailsModal(dest: dest, imageBuilder: _buildImage),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F4EA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Explore Destinations', style: TextStyle(color: Color(0xFF064E3B), fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(LucideIcons.bell, color: Color(0xFF064E3B)), onPressed: () {}),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search spots, beaches, mountains...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(LucideIcons.search, color: Color(0xFF059669)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),
          
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: ChoiceChip(
                    label: Text(category, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = category);
                    },
                    selectedColor: const Color(0xFF059669),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF059669)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: Consumer<LakbaiDestinationsProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
                }
                
                final filteredDestinations = provider.destinations.where((dest) {
                  if (_selectedCategory == 'All') return true;
                  final location = (dest['location'] ?? dest['region'] ?? '').toString().toLowerCase();
                  return location.contains(_selectedCategory.toLowerCase());
                }).toList();

                if (filteredDestinations.isEmpty) {
                  return const Center(child: Text('No destinations match this category.', style: TextStyle(color: Colors.grey, fontSize: 16)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  itemCount: filteredDestinations.length,
                  itemBuilder: (context, index) {
                    final dest = filteredDestinations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: _buildRegionCard(context, dest).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionCard(BuildContext context, Map<String, dynamic> dest) {
    final title = dest['name'] ?? dest['title'] ?? 'Unknown Place';
    final location = dest['location'] ?? dest['region'] ?? 'PHILIPPINES';
    final description = dest['description'] ?? 'Explore this beautiful tourist destination.';
    final rawImageUrl = dest['image'] ?? dest['photo'] ?? dest['imageUrl'] ?? ''; 

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: _buildImage(rawImageUrl),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF059669)),
                    const SizedBox(width: 4),
                    Text(location.toString().toUpperCase(), style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF064E3B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 20),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showDetailsModal(context, dest),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF059669),
                      side: const BorderSide(color: Color(0xFFD1FAE5), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.white,
                    ),
                    child: const Text('Explore Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationDetailsModal extends StatefulWidget {
  final Map<String, dynamic> dest;
  final Widget Function(String) imageBuilder;

  const _DestinationDetailsModal({required this.dest, required this.imageBuilder});

  @override
  State<_DestinationDetailsModal> createState() => _DestinationDetailsModalState();
}

class _DestinationDetailsModalState extends State<_DestinationDetailsModal> {
  bool _isFavorite = false;
  int _hoveredStar = 0;

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    
    if (_isFavorite) {
      final destName = widget.dest['name'] ?? widget.dest['title'] ?? 'Unknown Destination';
      Provider.of<LakbaiItineraryProvider>(context, listen: false).addManualDestination(destName);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to your Planner!'), backgroundColor: Color(0xFF059669)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from Favorites'), backgroundColor: Colors.red),
      );
    }
  }

  void _submitRating(int star) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Thank you for rating this $star stars!'), backgroundColor: const Color(0xFF059669)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dest = widget.dest;
    final rawImageUrl = dest['image'] ?? dest['photo'] ?? dest['imageUrl'] ?? '';
    
    List<dynamic> ratings = dest['ratings'] ?? [];
    String avgRating = 'New';
    if (ratings.isNotEmpty) {
      double total = 0;
      for (var r in ratings) total += (r['value'] ?? 0);
      avgRating = (total / ratings.length).toStringAsFixed(1);
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 800),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 800;
              
              // FIXED: Removed the map, image now takes full available height and width of this section
              Widget mediaSection = SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: widget.imageBuilder(rawImageUrl),
              );

              Widget infoSection = Container(
                color: const Color(0xFFFAFAF9),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(LucideIcons.mapPin, color: Color(0xFF059669), size: 16),
                          const SizedBox(width: 6),
                          Text(dest['region'] ?? 'Unknown Region', style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                          const SizedBox(width: 12),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(20)), child: Text(dest['category'] ?? 'Nature', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF064E3B)))),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFECFDF5)), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
                            child: Row(children: [Icon(LucideIcons.star, size: 14, color: ratings.isNotEmpty ? Colors.amber : Colors.grey[300]), const SizedBox(width: 4), Text(avgRating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF064E3B)))]),
                          )
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      Text(dest['name'] ?? dest['title'] ?? 'Untitled', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF064E3B), height: 1.1)),
                      const SizedBox(height: 8),
                      if (dest['address'] != null || dest['fullAddress'] != null)
                        Text('📍 ${dest['address'] ?? dest['fullAddress']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF047857))),
                      const SizedBox(height: 24),
                      Text(dest['description'] ?? 'No description available.', style: const TextStyle(fontSize: 16, color: Color(0xFF065F46), height: 1.6)),
                      const SizedBox(height: 32),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: const Color(0xFF064E3B), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rate this destination', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                                Text('Share your experience!', style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 13)),
                              ],
                            ),
                            Row(
                              children: List.generate(5, (index) {
                                int starValue = index + 1;
                                return GestureDetector(
                                  onTap: () => _submitRating(starValue),
                                  onTapDown: (_) => setState(() => _hoveredStar = starValue),
                                  onTapUp: (_) => setState(() => _hoveredStar = 0),
                                  onTapCancel: () => setState(() => _hoveredStar = 0),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                    child: AnimatedScale(
                                      scale: _hoveredStar == starValue ? 1.2 : 1.0,
                                      duration: const Duration(milliseconds: 150),
                                      child: Icon(LucideIcons.star, size: 28, color: starValue <= _hoveredStar ? Colors.amber : Colors.white.withOpacity(0.2)),
                                    ),
                                  ),
                                );
                              }),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFD1FAE5))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TOURISM OFFICE CONTACT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF34D399), letterSpacing: 1.5)),
                            const SizedBox(height: 16),
                            Row(children: [
                              Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle), child: const Icon(LucideIcons.building, size: 18, color: Color(0xFF059669))), 
                              const SizedBox(width: 12), 
                              Expanded(child: Text(dest['submittedBy']?['name'] ?? 'Local Tourism Office', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF064E3B)), overflow: TextOverflow.ellipsis))
                            ]),
                            const SizedBox(height: 16),
                            Row(children: [
                              Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle), child: const Icon(LucideIcons.mail, size: 18, color: Color(0xFF059669))), 
                              const SizedBox(width: 12), 
                              Expanded(child: Text(dest['submittedBy']?['email'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF064E3B)), overflow: TextOverflow.ellipsis))
                            ]),
                            const SizedBox(height: 16),
                            Row(children: [
                              Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle), child: const Icon(LucideIcons.phone, size: 18, color: Color(0xFF059669))), 
                              const SizedBox(width: 12), 
                              Expanded(child: Text(dest['submittedBy']?['phone'] ?? 'No contact number', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF064E3B)), overflow: TextOverflow.ellipsis))
                            ]),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _toggleFavorite,
                          icon: Icon(LucideIcons.bookmarkPlus, color: _isFavorite ? Colors.red : Colors.white),
                          label: Text(_isFavorite ? 'Saved to Planner' : 'Save to Planner', style: TextStyle(color: _isFavorite ? Colors.red : Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFavorite ? Colors.red[50] : const Color(0xFF064E3B),
                            side: _isFavorite ? const BorderSide(color: Colors.red) : BorderSide.none,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: _isFavorite ? 0 : 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              if (isDesktop) {
                return Row(children: [Expanded(flex: 4, child: mediaSection), Expanded(flex: 6, child: infoSection)]);
              } else {
                return Column(children: [
                  SizedBox(height: 250, child: mediaSection), 
                  Expanded(child: infoSection)
                ]);
              }
            },
          ),
          
          Positioned(
            top: 24, right: 24,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
                child: const Icon(LucideIcons.x, color: Color(0xFF064E3B), size: 24),
              ),
            ),
          )
        ],
      ),
    );
  }
}