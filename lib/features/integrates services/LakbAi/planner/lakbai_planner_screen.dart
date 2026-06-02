import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // <-- 1. IMPORTED MARKDOWN
import '../providers/lakbai_itinerary_provider.dart';
import '../providers/lakbai_destinations_provider.dart';

class LakbaiPlannerScreen extends StatefulWidget {
  const LakbaiPlannerScreen({super.key});

  @override
  State<LakbaiPlannerScreen> createState() => _LakbaiPlannerScreenState();
}

class _LakbaiPlannerScreenState extends State<LakbaiPlannerScreen> {
  String? _selectedDestination;
  double _days = 4;
  String _selectedBudget = 'Moderate';
  
  final List<String> _availableInterests = ['Nature', 'Food', 'Culture', 'Adventure', 'Relaxation', 'Shopping'];
  final List<String> _selectedInterests = [];
  final List<String> _budgets = ['Budget', 'Moderate', 'Luxury'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LakbaiDestinationsProvider>(context, listen: false).fetchDestinations();
      Provider.of<LakbaiItineraryProvider>(context, listen: false).fetchSavedItineraries();
    });
  }

  Future<void> _generate() async {
    if (_selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a destination')));
      return;
    }
    
    final provider = Provider.of<LakbaiItineraryProvider>(context, listen: false);
    await provider.generateItinerary(
      _selectedDestination!, _days, _selectedBudget, _selectedInterests
    );

    if (provider.currentAiResult.toLowerCase().contains('error') || provider.currentAiResult.toLowerCase().contains('failed')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.currentAiResult), backgroundColor: Colors.red, duration: const Duration(seconds: 4))
        );
      }
    }
  }

  void _editPlan(BuildContext context, Map<String, dynamic> item) {
    final TextEditingController editController = TextEditingController(text: item['content']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Plan for ${item['destination']}'),
        content: TextField(
          controller: editController,
          maxLines: 10,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'You can use markdown here (e.g. **bold**, ## header)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final updated = {...item, 'content': editController.text};
              Provider.of<LakbaiItineraryProvider>(context, listen: false).updateItinerary(item['_id'], updated);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F4EA), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('AI Itinerary Planner', style: TextStyle(color: Color(0xFF064E3B), fontWeight: FontWeight.bold, fontSize: 24)),
        centerTitle: false,
      ),
      body: Consumer2<LakbaiItineraryProvider, LakbaiDestinationsProvider>(
        builder: (context, itineraryProvider, destinationsProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plan your next adventure using registered spots.', style: TextStyle(color: Color(0xFF059669), fontSize: 16)),
                const SizedBox(height: 20),

                // --- INPUT FORM ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(LucideIcons.mapPin, color: Color(0xFF064E3B), size: 18),
                          SizedBox(width: 8),
                          Text('Select Destination', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        hint: const Text('Choose a registered place...'),
                        initialValue: _selectedDestination,
                        items: destinationsProvider.destinations.map((dest) {
                          final name = dest['name'] ?? dest['title'] ?? 'Unknown';
                          return DropdownMenuItem<String>(value: name, child: Text(name));
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedDestination = value),
                      ),
                      const SizedBox(height: 20),
                      
                      Text('Duration: ${_days.toInt()} Days', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                      Slider(
                        value: _days, min: 1, max: 14, divisions: 13,
                        activeColor: const Color(0xFF059669), inactiveColor: const Color(0xFFD1FAE5),
                        onChanged: (value) => setState(() => _days = value),
                      ),
                      const SizedBox(height: 12),
                      
                      const Text('Budget', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF059669))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        initialValue: _selectedBudget,
                        items: _budgets.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                        onChanged: (value) => setState(() => _selectedBudget = value!),
                      ),
                      const SizedBox(height: 20),

                      const Text('Interests', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _availableInterests.map((interest) {
                          final isSelected = _selectedInterests.contains(interest);
                          return FilterChip(
                            label: Text(interest),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                selected ? _selectedInterests.add(interest) : _selectedInterests.remove(interest);
                              });
                            },
                            selectedColor: const Color(0xFFD1FAE5), checkmarkColor: const Color(0xFF059669),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.transparent)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: itineraryProvider.isLoading ? null : _generate,
                          icon: itineraryProvider.isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(LucideIcons.sparkles, color: Colors.white),
                          label: Text(itineraryProvider.isLoading ? 'Consulting AI Guides...' : 'Generate Itinerary', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF064E3B), 
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 32),

                // --- SAVED ITINERARIES (NOW WITH MARKDOWN) ---
                if (itineraryProvider.itineraries.isNotEmpty && !itineraryProvider.isLoading) ...[
                  const Text('My Saved Plans', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))).animate().fadeIn(),
                  const SizedBox(height: 16),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: itineraryProvider.itineraries.length,
                    itemBuilder: (context, index) {
                      final item = itineraryProvider.itineraries[index];
                      final dest = item['destination'] ?? 'Unknown Destination';
                      final content = item['content'] ?? 'No details available.';
                      final id = item['_id'] ?? '';
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFD1FAE5)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
                        ),
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(LucideIcons.map, color: Color(0xFF059669)),
                          ),
                          title: Text(dest, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF064E3B), fontSize: 18)),
                          subtitle: Text('${item['days'] ?? 1} Days • ${item['budget'] ?? 'Flexible'}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              // <-- 2. MAGIC HAPPENS HERE: Markdown Rendering -->
                              child: MarkdownBody(
                                data: content,
                                selectable: true, // Lets the user copy text if they want!
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(color: Colors.grey[800], fontSize: 15, height: 1.6),
                                  h1: const TextStyle(color: Color(0xFF064E3B), fontSize: 24, fontWeight: FontWeight.bold),
                                  h2: const TextStyle(color: Color(0xFF059669), fontSize: 20, fontWeight: FontWeight.bold),
                                  h3: const TextStyle(color: Color(0xFF047857), fontSize: 18, fontWeight: FontWeight.bold),
                                  strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                  listBullet: const TextStyle(color: Color(0xFF059669), fontSize: 16),
                                ),
                              ),
                            ),
                            const Divider(color: Color(0xFFD1FAE5)),
                            OverflowBar(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _editPlan(context, item), 
                                  icon: const Icon(LucideIcons.edit2, color: Colors.blue, size: 16), 
                                  label: const Text('Edit')
                                ),
                                TextButton.icon(
                                  onPressed: () => Provider.of<LakbaiItineraryProvider>(context, listen: false).deleteItinerary(id), 
                                  icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 16), 
                                  label: const Text('Delete', style: TextStyle(color: Colors.red))
                                ),
                              ],
                            )
                          ],
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 150 * index)).slideX(begin: -0.1);
                    },
                  ),
                  const SizedBox(height: 80),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}