import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../providers/lakbai_destinations_provider.dart';

class LakbaiAddDestinationScreen extends StatefulWidget {
  const LakbaiAddDestinationScreen({super.key});

  @override
  State<LakbaiAddDestinationScreen> createState() => _AddDestinationScreenState();
}

class _AddDestinationScreenState extends State<LakbaiAddDestinationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController(); 
  final _coordinatesController = TextEditingController();
  final _descriptionController = TextEditingController(); 
  
  String _selectedCategory = 'Nature';
  String _selectedRegion = 'Luzon';
  
  final List<String> _categories = ['Nature', 'Culture', 'Food', 'Adventure', 'Relaxation'];
  final List<String> _regions = ['Luzon', 'Visayas', 'Mindanao'];

  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  String? _base64Image;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final fileSizeInMB = bytes.lengthInBytes / (1024 * 1024);
        if (fileSizeInMB > 5) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image is too large. Max 5MB allowed.'), backgroundColor: Colors.red));
          return;
        }
        setState(() {
          _imageBytes = bytes;
          final extension = image.name.split('.').last;
          _base64Image = 'data:image/$extension;base64,${base64Encode(bytes)}';
        });
      }
    } catch (e) {
      print("Image picker error: $e");
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a destination image')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // ADAPTING FLUTTER TO THE ORIGINAL BACKEND:
      final newDest = {
        'name': _titleController.text.trim(),
        'region': _selectedRegion,
        'category': _selectedCategory,
        'address': _addressController.text.trim(),       // Matches original backend
        'coordinates': _coordinatesController.text.trim(), // Matches original backend
        'description': _descriptionController.text.trim(), 
        'image': _base64Image,                           // Matches original backend
        // We do NOT send 'status' here. Your Node.js routes.js handles it automatically!
      };

      await Provider.of<LakbaiDestinationsProvider>(context, listen: false).addDestination(newDest);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Destination published successfully!')));
        Navigator.pop(context); // FIXED: Used Navigator instead of go_router
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, 
        title: const Text('Add New Destination', style: TextStyle(color: Color(0xFF064E3B), fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.x, color: Color(0xFF059669)), 
            onPressed: () => Navigator.pop(context) // FIXED: Used Navigator instead of go_router
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 160, width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF6EE7B7), width: 2), 
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity))
                      : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(LucideIcons.upload, color: Color(0xFF059669), size: 32), SizedBox(height: 12),
                          Text('Click to upload an image', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value!),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedRegion,
                decoration: InputDecoration(labelText: 'Region', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (value) => setState(() => _selectedRegion = value!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Full Address', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _coordinatesController,
                decoration: InputDecoration(labelText: 'Map Coordinates (e.g. 11.19, 119.32)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(labelText: 'Full Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(LucideIcons.check, color: Colors.white),
                  label: Text(_isSubmitting ? 'SAVING...' : 'PUBLISH DESTINATION', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}