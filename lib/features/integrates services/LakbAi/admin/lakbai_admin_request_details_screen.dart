import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../providers/lakbai_admin_provider.dart';

class LakbaiAdminRequestDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> request;

  const LakbaiAdminRequestDetailsScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<LakbaiAdminProvider>(context, listen: false);

    // FIXED: Now checks for 'image' (since we reverted the backend) and falls back to 'photo' just in case.
    final String photoStr = request['image'] ?? request['photo'] ?? '';
    final bool isBase64 = photoStr.startsWith('data:image');
    Uint8List? imageBytes;

    // THE FIX: Clean the base64 string before decoding to prevent the Red Screen of Death
    if (isBase64) {
      try {
        final cleanBase64 = photoStr.split(',').last.replaceAll(RegExp(r'\s+'), '');
        imageBytes = base64Decode(cleanBase64);
      } catch (e) {
        debugPrint('Base64 decode error: $e');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(request['name'] ?? request['title'] ?? 'Review Request', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF064E3B),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image Rendering
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                image: !isBase64 && photoStr.isNotEmpty
                    ? DecorationImage(image: NetworkImage(photoStr), fit: BoxFit.cover)
                    : null,
              ),
              child: isBase64 && imageBytes != null
                  ? Image.memory(
                      imageBytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : (photoStr.isEmpty
                      ? const Center(child: Icon(LucideIcons.image, size: 50, color: Colors.grey))
                      : null),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Section
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, color: Color(0xFF059669), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        request['region'] ?? 'Unspecified Region',
                        style: const TextStyle(fontSize: 16, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    request['name'] ?? request['title'] ?? 'Untitled Destination',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF064E3B)),
                  ),
                  const SizedBox(height: 8),
                  
                  // --- FULL ADDRESS CONTAINER ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Full Address', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(request['address'] ?? request['fullAddress'] ?? 'No address provided', style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // --- MAP COORDINATES CONTAINER ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Map Coordinates', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(request['coordinates'] ?? request['mapCoordinates'] ?? '0.0000, 0.0000', style: const TextStyle(fontSize: 15, fontFamily: 'Courier')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- AGENCY SUBMITTER PROFILE CARD ---
                  if (request['submittedBy'] != null) ...[
                    const Text('Submitted By Agency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.briefcase, color: Color(0xFF059669)),
                              const SizedBox(width: 12),
                              Text(request['submittedBy']['name'] ?? 'Unknown Agency', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const Divider(height: 20, color: Color(0xFFA7F3D0)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('✉  ${request['submittedBy']['email'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[700])),
                              Text('📞  ${request['submittedBy']['phone'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[700])),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Description
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                  const SizedBox(height: 8),
                  Text(request['description'] ?? 'No description text supplied.', style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5)),
                  const SizedBox(height: 40),

                  // Approve and Reject Execution Triggers
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await adminProvider.rejectDestination(request['_id']);
                            if (context.mounted) context.pop();
                          },
                          icon: const Icon(LucideIcons.xCircle, color: Colors.red),
                          label: const Text('REJECT', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await adminProvider.approveDestination(request['_id']);
                            if (context.mounted) context.pop();
                          },
                          icon: const Icon(LucideIcons.checkCircle, color: Colors.white),
                          label: const Text('APPROVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}