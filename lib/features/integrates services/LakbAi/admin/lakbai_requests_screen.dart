import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../providers/lakbai_admin_provider.dart';

class LakbaiRequestsScreen extends StatefulWidget {
  const LakbaiRequestsScreen({super.key});

  @override
  State<LakbaiRequestsScreen> createState() => _LakbaiRequestsScreenState();
}

class _LakbaiRequestsScreenState extends State<LakbaiRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LakbaiAdminProvider>(context, listen: false).fetchPendingRequests();
    });
  }

  Widget _buildImage(String rawImageUrl) {
    if (rawImageUrl.isEmpty) return Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity);
    if (rawImageUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(rawImageUrl.split(',').last);
        return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, errorBuilder: (c,e,s) => Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity));
      } catch (e) {
        return Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity);
      }
    } 
    return Image.network(rawImageUrl.startsWith('http') ? rawImageUrl : 'http://localhost:3000/$rawImageUrl', fit: BoxFit.cover, width: double.infinity, errorBuilder: (c,e,s) => Image.asset('assets/images/hero-bg.jpg', fit: BoxFit.cover, width: double.infinity));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F4EA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Pending Requests', style: TextStyle(color: Color(0xFF064E3B), fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: Consumer<LakbaiAdminProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.pendingRequests.isEmpty) return const Center(child: CircularProgressIndicator(color: Color(0xFF059669)));
          if (provider.pendingRequests.isEmpty) {
            return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(LucideIcons.checkCircle, size: 64, color: Color(0xFFD1FAE5)), SizedBox(height: 16), Text('All Caught Up!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF059669)))]));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.pendingRequests.length,
            itemBuilder: (context, index) {
              final dest = provider.pendingRequests[index];
              final title = dest['name'] ?? dest['title'] ?? 'Unnamed';
              final region = dest['region'] ?? dest['location'] ?? 'Unknown Region';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 180, width: double.infinity, child: _buildImage(dest['image'] ?? dest['imageUrl'] ?? '')),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [const Icon(LucideIcons.mapPin, size: 14, color: Color(0xFF059669)), const SizedBox(width: 4), Text(region.toString().toUpperCase(), style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.bold))]),
                          const SizedBox(height: 8),
                          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => context.push('/admin-request-details', extra: dest),
                              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF059669), side: const BorderSide(color: Color(0xFFD1FAE5), width: 2), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1);
            },
          );
        },
      ),
    );
  }
}