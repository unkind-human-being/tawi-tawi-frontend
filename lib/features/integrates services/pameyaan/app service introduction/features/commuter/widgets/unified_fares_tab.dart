import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/distance_calculator.dart';
import '../../../core/theme/app_theme.dart';

class UnifiedFaresTab extends StatefulWidget {
  final String discountStatus;
  const UnifiedFaresTab({super.key, required this.discountStatus});

  @override
  State<UnifiedFaresTab> createState() => _UnifiedFaresTabState();
}

class _UnifiedFaresTabState extends State<UnifiedFaresTab> {
  // --- Estimator State ---
  String? _selectedOrigin;
  String? _selectedDestination;
  double _distance = 0.0;
  double _estimatedFare = 0.0;
  bool _isCalculating = false; // <-- NEW: Loading State Tracker
  final List<String> _locations = DistanceCalculator.bongaoLocations.keys.toList()..sort();

  // --- Matrix State ---
  bool _isLoading = true;
  List<dynamic> _fares = [];
  final Color _neonTeal = AppColors.neonTeal;

  @override
  void initState() {
    super.initState();
    _fetchFareMatrix();
  }

  // FIXED: Converted to async to support the loading effect
  Future<void> _calculateFare() async {
    if (_selectedOrigin != null && _selectedDestination != null) {
      if (_selectedOrigin == _selectedDestination) {
        setState(() {
          _distance = 0.0;
          _estimatedFare = 0.0;
          _isCalculating = false;
        });
        return;
      }
      
      // 1. Trigger the Loading Spinner
      setState(() {
        _isCalculating = true;
      });

      // 2. Add an intentional delay for the premium loading effect
      await Future.delayed(const Duration(milliseconds: 800));
      
      // 3. Perform the actual calculation
      double dist = DistanceCalculator.getDistanceInKm(_selectedOrigin!, _selectedDestination!);
      double baseFare = 20.0;
      double additionalFare = dist > 1.0 ? (dist - 1.0) * 5.0 : 0.0;
      double totalFare = baseFare + additionalFare;
      
      if (widget.discountStatus != 'Regular') {
        totalFare = totalFare * 0.80; // 20% LGU Discount
      }
      
      // 4. Stop Loading and Reveal Result!
      if (mounted) {
        setState(() {
          _distance = dist;
          _estimatedFare = totalFare;
          _isCalculating = false;
        });
      }
    }
  }

  Future<void> _fetchFareMatrix() async {
    final prefs = await SharedPreferences.getInstance();
    const cacheKey = 'fare_matrix_cache';
    
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      setState(() {
        _fares = jsonDecode(cachedData);
        _isLoading = false;
      });
    }
    
    try {
      final response = await ApiClient.instance.get('/fares/');
      if (response.statusCode == 200) {
        await prefs.setString(cacheKey, jsonEncode(response.data));
        if (!mounted) return;
        setState(() {
          _fares = response.data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLocationPicker(String title, bool isOrigin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPickerSheet(
        title: title,
        locations: _locations,
        onSelected: (val) {
          setState(() {
            if (isOrigin) _selectedOrigin = val;
            else _selectedDestination = val;
          });
          _calculateFare(); // Automatically triggers the calculation and loading spinner!
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final Color bgColor = isDark ? AppColors.darkBg : AppColors.softBg;
    final Color cardColor = isDark ? AppColors.darkCard : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        title: const Text('Fares & Routes', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fare Estimator', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text('Select your route to calculate the official LGU fare.', style: TextStyle(color: context.dynamicMuted)),
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        _buildDropdown(
                          label: 'Pick-up Location', icon: Icons.my_location, iconColor: AppColors.neonTeal,
                          value: _selectedOrigin, isOrigin: true,
                        ),
                        const Padding(padding: EdgeInsets.only(left: 18, top: 8, bottom: 8), child: Align(alignment: Alignment.centerLeft, child: Icon(Icons.more_vert, color: Colors.grey))),
                        _buildDropdown(
                          label: 'Drop-off Destination', icon: Icons.location_on, iconColor: Colors.redAccent,
                          value: _selectedDestination, isOrigin: false,
                        ),
                      ],
                    ),
                  ),
                  
                  // NEW: THE LOADING OR RESULTS CARD
                  if (_isCalculating) ...[
                    const SizedBox(height: 24),
                    Container(
                      height: 140, // Keeps the card height consistent
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.deepOcean, Color(0xFF1A365D)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppColors.deepOcean.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppColors.neonTeal),
                            SizedBox(height: 16),
                            Text('Calculating optimal route...', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0))
                          ],
                        ),
                      ),
                    ),
                  ] 
                  else if (_selectedOrigin != null && _selectedDestination != null && _selectedOrigin != _selectedDestination) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.deepOcean, Color(0xFF1A365D)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppColors.deepOcean.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Estimated Fare', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.neonTeal.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                child: Text(widget.discountStatus.toUpperCase(), style: const TextStyle(color: AppColors.neonTeal, fontSize: 10, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('₱ ', style: TextStyle(color: AppColors.neonTeal, fontSize: 24, fontWeight: FontWeight.bold)),
                              Text(_estimatedFare.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, height: 1.0)),
                            ],
                          ),
                          const Divider(color: Colors.white24, height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Trip Distance:', style: TextStyle(color: Colors.white70)),
                              Text('${_distance.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                  
                  if (_selectedOrigin == _selectedDestination && _selectedOrigin != null)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(child: Text("Pick-up and Drop-off cannot be the same.", style: TextStyle(color: Colors.redAccent))),
                    ),
                    
                  const SizedBox(height: 48),
                  
                  Text('Official Fare Matrix', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 8),
                  Text('Standard LGU approved tricycle rates for Bongao.', style: TextStyle(color: context.dynamicMuted)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          if (_isLoading && _fares.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.neonTeal)))
          else if (_fares.isEmpty)
            SliverFillRemaining(child: Center(child: Text('Route list currently unavailable.', style: TextStyle(color: context.dynamicMuted))))
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final fare = _fares[index];
                    return _buildFareCard(fare, cardColor, textColor, context);
                  },
                  childCount: _fares.length > 20 ? 20 : _fares.length,
                ),
              ),
            ),
            
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildDropdown({required String label, required IconData icon, required Color iconColor, required String? value, required bool isOrigin}) {
    return InkWell(
      onTap: () => _showLocationPicker(label, isOrigin),
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: iconColor),
          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: context.isDarkMode ? Colors.black12 : Colors.white,
        ),
        child: Text(
          value ?? '',
          style: TextStyle(
            color: context.dynamicText,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildFareCard(dynamic fare, Color cardColor, Color textColor, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.dynamicBorder)),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.directions_transit, color: context.dynamicMuted, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(fare['origin'] ?? 'Unknown', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13))),
              const Icon(Icons.arrow_forward, color: Colors.grey, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(fare['destination'] ?? 'Unknown', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.right)),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Regular: ₱ ${fare['regular_fare']?.toStringAsFixed(2) ?? '0.00'}', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _neonTeal.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text('Discounted: ₱ ${fare['student_fare']?.toStringAsFixed(2) ?? '0.00'}', style: TextStyle(color: _neonTeal, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LocationPickerSheet extends StatefulWidget {
  final String title;
  final List<String> locations;
  final Function(String) onSelected;

  const LocationPickerSheet({
    super.key,
    required this.title,
    required this.locations,
    required this.onSelected,
  });

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredLocations = widget.locations
        .where((loc) => loc.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24
      ),
      decoration: BoxDecoration(
        color: context.dynamicCard,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: context.dynamicBorder, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 24),
          Text(widget.title, style: TextStyle(color: context.dynamicText, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          TextField(
            autofocus: true,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: TextStyle(color: context.dynamicText), 
            decoration: InputDecoration(
              hintText: 'Search barangay or school...',
              hintStyle: TextStyle(color: context.dynamicMuted, fontSize: 14), 
              prefixIcon: Icon(Icons.search, color: context.dynamicMuted), 
              filled: true,
              fillColor: context.isDarkMode ? AppColors.darkBg : const Color(0xFFF4F7F9), 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: filteredLocations.isEmpty
              ? Center(child: Text('No locations found.', style: TextStyle(color: context.dynamicMuted))) 
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredLocations.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on, color: AppColors.neonTeal),
                      title: Text(
                        filteredLocations[index],
                        style: TextStyle(color: context.dynamicText, fontWeight: FontWeight.w600, fontSize: 14), 
                      ),
                      onTap: () {
                        widget.onSelected(filteredLocations[index]);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}