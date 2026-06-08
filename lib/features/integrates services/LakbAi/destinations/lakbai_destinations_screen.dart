import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

// 1. Removed go_router
// 2. Import the provider and the newly fixed add destination screen
import '../providers/lakbai_destinations_provider.dart';
import 'lakbai_add_destination_screen.dart'; 

class LakbaiDestinationsScreen extends StatefulWidget {
  const LakbaiDestinationsScreen({super.key});

  @override
  State<LakbaiDestinationsScreen> createState() => _LakbaiDestinationsScreenState();
}

class _LakbaiDestinationsScreenState extends State<LakbaiDestinationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensures the widget is still on screen before fetching
      if (mounted) {
        Provider.of<LakbaiDestinationsProvider>(context, listen: false).fetchDestinations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECFDF5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Manage Destinations', style: TextStyle(color: Color(0xFF064E3B), fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Consumer<LakbaiDestinationsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.destinations.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
          }
          if (provider.error.isNotEmpty && provider.destinations.isEmpty) {
            return Center(child: Text(provider.error, style: const TextStyle(color: Colors.red)));
          }
          if (provider.destinations.isEmpty) {
            return const Center(child: Text('No destinations uploaded yet.', style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.destinations.length,
            itemBuilder: (context, index) {
              final dest = provider.destinations[index];
              final name = dest['name'] ?? dest['title'] ?? 'Unnamed';
              final status = dest['status'] ?? 'Active'; 
              final isActive = status.toString().toLowerCase() == 'active';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(LucideIcons.database, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text('Synced with DB', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toString().toUpperCase(),
                      style: TextStyle(
                        color: isActive ? const Color(0xFF059669) : const Color(0xFFD97706),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1);
            },
          );
        },
      ),
      // THE FIX IS HERE: Using Navigator.push instead of context.push
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LakbaiAddDestinationScreen()),
          );
        },
        backgroundColor: const Color(0xFF059669),
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Add New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 500.ms),
    );
  }
}