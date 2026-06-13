import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/vendor_provider.dart';

class VendorProfileScreen extends ConsumerStatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  ConsumerState<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends ConsumerState<VendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _shopNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;

  File? _pickedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _shopNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final vendorService = ref.read(vendorServiceProvider);
      await vendorService.updateVendorProfile(
        shopName: _shopNameController.text.trim(),
        shopAddress: _addressController.text.trim(),
        shopDescription: _descriptionController.text.trim(),
        imageFile: _pickedImage,
      );

      ref.invalidate(vendorStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Store identity updated successfully! 🎉", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Update failed: $e", style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(vendorStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Store Identity", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: statsAsync.when(
        data: (stats) {
          final Map<String, dynamic> profile = stats['profile'] as Map<String, dynamic>? ?? {};

          if (_shopNameController.text.isEmpty) {
            _shopNameController.text = profile['shopName']?.toString() ?? stats['name']?.toString() ?? '';
            _descriptionController.text = profile['shopDescription']?.toString() ?? '';
            _addressController.text = profile['shopAddress']?.toString() ?? '';
          }

          final String rawAvatarPath = profile['avatarUrl']?.toString() ?? '';
          final String completeImageUrl = "http://10.0.26.26:10000$rawAvatarPath";

          return SingleChildScrollView(
            child: Column(
              children: [
                // Top Header block with overlapping avatar
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 60),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade800, Colors.blueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -20,
                            top: -20,
                            child: Icon(Icons.storefront, size: 150, color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          const Positioned(
                            left: 24,
                            top: 40,
                            child: Text(
                              "Build Your Brand",
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Positioned(
                            left: 24,
                            top: 70,
                            child: Text(
                              "Make your store stand out to customers.",
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Avatar Box
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
                            ),
                            child: ClipOval(
                              child: _pickedImage != null
                                  ? Image.file(_pickedImage!, fit: BoxFit.cover)
                                  : rawAvatarPath.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: completeImageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => const CircularProgressIndicator(),
                                          errorWidget: (_, __, ___) => const Icon(Icons.storefront, size: 50, color: Colors.grey),
                                        )
                                      : Container(color: Colors.blue.shade50, child: const Icon(Icons.storefront, size: 50, color: Colors.blueAccent)),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Text("Store Logo", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                // Form Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Business Information", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 24),
                          
                          _buildTextField(
                            label: "Official Shop Name",
                            hint: "e.g. ZentroGadgets Official",
                            controller: _shopNameController,
                            icon: Icons.store,
                            validator: (v) => v!.trim().isEmpty ? "Shop name is required" : null,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            label: "Store Address / Pickup Location",
                            hint: "Full operational address...",
                            controller: _addressController,
                            icon: Icons.location_on_outlined,
                            validator: (v) => v!.trim().isEmpty ? "Pickup location is required" : null,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            label: "Business Description",
                            hint: "Tell customers what you sell...",
                            controller: _descriptionController,
                            icon: Icons.description_outlined,
                            maxLines: 4,
                            validator: (v) => v!.trim().isEmpty ? "Please provide a short summary" : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                
                // Save Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Save Store Identity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
        error: (err, _) => Center(child: Text("Error launching profiles: $err")),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
          ),
        ),
      ],
    );
  }
}
