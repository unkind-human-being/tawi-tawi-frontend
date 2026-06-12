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
  ConsumerState<VendorProductFormScreen> createState() =>
      _VendorProductFormScreenState();
}

class _VendorProductFormScreenState
    extends ConsumerState<VendorProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl,
      _descCtrl,
      _priceCtrl,
      _stockCtrl,
      _imageCtrl;

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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Select Image",
                    style:
                        TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold))),
            ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                }),
            ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                }),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.existingProduct == null &&
        _imageFile == null &&
        _imageCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please select an image"),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final bool isDeviceOnline =
          !connectivityResult.contains(ConnectivityResult.none);

      String finalImageUrl = _imageCtrl.text.trim();

      // --- FIXED: Direct bypass to force upload step if a physical image is present ---
      if (_imageFile != null) {
        if (kDebugMode) {
          print(
              "TEST LOG: Image file path matches: ${_imageFile!.path}. Forcing upload step directly.");
        }

        final uploadedUrl = await CloudinaryService().uploadImage(_imageFile!);

        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl;
          if (kDebugMode) {
            print(
                "TEST LOG: Final remote url written to map parameters: $finalImageUrl");
          }
        } else {
          if (kDebugMode) {
            print("TEST LOG: Asset transmission step returned null string.");
          }
        }
      } else {
        if (kDebugMode) {
          print(
              "TEST LOG: Processing save map payload sequence without new asset modifications.");
        }
      }

      final String sanitizedPriceText =
          _priceCtrl.text.replaceAll(',', '').trim();
      final double parsedPrice = double.tryParse(sanitizedPriceText) ?? 0.0;

      final String sanitizedStockText =
          _stockCtrl.text.replaceAll(',', '').trim();
      final int parsedStock = int.tryParse(sanitizedStockText) ?? 0;

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isDeviceOnline
                ? "Product Saved to Cloud!"
                : "Saved offline as product draft!"),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(iconTheme: const IconThemeData(color: Colors.black), 
          title: Text(
              widget.existingProduct == null ? "Add Product" : "Edit Product"),
          centerTitle: true,
          elevation: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildImagePreview(),
                    const SizedBox(height: 20),
                    _buildSectionCard("Basic Details", [
                      _buildTextField(_nameCtrl, "Product Name", Icons.label),
                      const SizedBox(height: 16),
                      _buildTextField(
                          _descCtrl, "Description", Icons.description,
                          maxLines: 3),
                    ]),
                    const SizedBox(height: 16),
                    _buildSectionCard("Pricing & Stock", [
                      Row(children: [
                        Expanded(
                            child: _buildTextField(
                                _priceCtrl, "Price (₱)", Icons.money,
                                isNumber: true)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: _buildTextField(
                                _stockCtrl, "Stock Qty", Icons.inventory,
                                isNumber: true)),
                      ]),
                    ]),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveProduct,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey.shade900,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: const Text("SAVE PRODUCT",
                            style: TextStyle(color: Colors.black87, 
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          ...children,
        ]),
      ),
    );
  }

  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300)),
        child: _imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(_imageFile!, fit: BoxFit.cover))
            : (_imageCtrl.text.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _imageCtrl.text.startsWith('/')
                        ? Image.file(File(_imageCtrl.text), fit: BoxFit.cover)
                        : Image.network(_imageCtrl.text, fit: BoxFit.cover))
                : const Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        Icon(Icons.add_a_photo, size: 40),
                        Text("Upload Image")
                      ]))),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController ctrl, String label, IconData icon,
      {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
      validator: (v) => v?.isEmpty ?? true ? "Required" : null,
    );
  }
}
