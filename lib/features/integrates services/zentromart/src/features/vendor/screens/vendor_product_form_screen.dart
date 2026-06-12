import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tawi_tawi_frontend/features/integrates services/zentromart/src/features/auth/services/cloudinary_service.dart';
import '../providers/vendor_provider.dart';

class VendorProductFormScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existingProduct;

  const VendorProductFormScreen({super.key, this.existingProduct});

  @override
  ConsumerState<VendorProductFormScreen> createState() => _VendorProductFormScreenState();
}

class _VendorProductFormScreenState extends ConsumerState<VendorProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _descCtrl, _priceCtrl, _stockCtrl, _imageCtrl;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    _nameCtrl = TextEditingController(text: p?['name'] ?? '');
    _descCtrl = TextEditingController(text: p?['description'] ?? '');
    _priceCtrl = TextEditingController(text: p?['price']?.toString() ?? '');
    _stockCtrl = TextEditingController(text: p?['stock']?.toString() ?? '');
    _imageCtrl = TextEditingController(text: p?['imageUrl'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Upload Product Image",
                    style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.blue.shade50, child: const Icon(Icons.camera_alt, color: Colors.blueAccent)),
                title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.purple.shade50, child: const Icon(Icons.photo_library, color: Colors.purpleAccent)),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.existingProduct == null && _imageFile == null && _imageCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("A product image is required"), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final bool isDeviceOnline = !connectivityResult.contains(ConnectivityResult.none);

      String finalImageUrl = _imageCtrl.text.trim();

      if (_imageFile != null) {
        final uploadedUrl = await CloudinaryService().uploadImage(_imageFile!);
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
        }
      }

      final double parsedPrice = double.tryParse(_priceCtrl.text.replaceAll(',', '').trim()) ?? 0.0;
      final int parsedStock = int.tryParse(_stockCtrl.text.replaceAll(',', '').trim()) ?? 0;

      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': parsedPrice,
        'stock': parsedStock,
        'imageUrl': finalImageUrl,
      };

      await ref.read(vendorProductControllerProvider).saveProduct(
            existingId: widget.existingProduct?['id'],
            data: data,
            isOnline: isDeviceOnline,
          );

      ref.invalidate(vendorProductsProvider);
      ref.invalidate(vendorStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDeviceOnline ? "Product saved successfully! 🎉" : "Saved offline as draft"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(widget.existingProduct == null ? "Add New Product" : "Edit Product", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Image Upload Section
                    _buildImagePreview(),
                    const SizedBox(height: 24),
                    
                    // Basic Details
                    _buildSectionCard("Product Information", [
                      _buildTextField(_nameCtrl, "Product Name", Icons.shopping_bag_outlined, "e.g. Wireless Headphones"),
                      const SizedBox(height: 16),
                      _buildTextField(_descCtrl, "Description", Icons.description_outlined, "Describe the key features and benefits...", maxLines: 4),
                    ]),
                    const SizedBox(height: 16),

                    // Pricing and Inventory
                    _buildSectionCard("Pricing & Inventory", [
                      Row(
                        children: [
                          Expanded(child: _buildTextField(_priceCtrl, "Price (₱)", Icons.sell_outlined, "0.00", isNumber: true)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField(_stockCtrl, "Stock Qty", Icons.inventory_2_outlined, "0", isNumber: true)),
                        ],
                      ),
                    ]),
                    
                    const SizedBox(height: 32),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Save Product", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 2),
        ),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.file(_imageFile!, fit: BoxFit.cover),
              )
            : (_imageCtrl.text.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _imageCtrl.text.startsWith('/')
                        ? Image.file(File(_imageCtrl.text), fit: BoxFit.cover)
                        : Image.network(_imageCtrl.text, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                        child: const Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 16),
                      const Text("Tap to upload product image", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text("High-quality images sell better", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  )),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, String hint, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.grey.shade50,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
      ),
      validator: (v) => v == null || v.trim().isEmpty ? "Required field" : null,
    );
  }
}
