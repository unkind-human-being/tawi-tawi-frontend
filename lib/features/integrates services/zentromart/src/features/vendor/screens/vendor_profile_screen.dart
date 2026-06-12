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
      // Connects directly to the real vendor service layer
      final vendorService = ref.read(vendorServiceProvider);

      // Matches the precise argument names expected by NestJS
      await vendorService.updateVendorProfile(
        shopName: _shopNameController.text.trim(),
        shopAddress: _addressController.text.trim(),
        shopDescription: _descriptionController.text.trim(),
        imageFile: _pickedImage,
      );

      // Refresh the dashboard stats provider so the new profile values display instantly
      ref.invalidate(vendorStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Shop profile updated successfully!"),
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
            content: Text("Update failed: $e"),
            backgroundColor: Colors.red,
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
      appBar: AppBar(iconTheme: const IconThemeData(color: Colors.black), 
        title: const Text("Shop Settings", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12)
                            ],
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
                                    : const Icon(Icons.storefront, size: 50, color: Colors.grey),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blueGrey.shade900,
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'VENDOR',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(
                    label: "Official Shop Name",
                    controller: _shopNameController,
                    icon: Icons.store,
                    validator: (v) => v!.trim().isEmpty ? "Shop name is required" : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: "Business Description",
                    controller: _descriptionController,
                    icon: Icons.description_outlined,
                    maxLines: 3,
                    validator: (v) => v!.trim().isEmpty ? "Please provide a short summary" : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    label: "Store Address / Pickup Location",
                    controller: _addressController,
                    icon: Icons.location_on_outlined,
                    validator: (v) => v!.trim().isEmpty ? "Pickup location is required" : null,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade900,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("Save Business Profile",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
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
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
