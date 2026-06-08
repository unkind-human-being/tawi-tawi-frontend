import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class CommuterEditProfileScreen extends StatefulWidget {
  final String currentName;

  const CommuterEditProfileScreen({
    super.key,
    required this.currentName,
  });

  @override
  State<CommuterEditProfileScreen> createState() => _CommuterEditProfileScreenState();
}

class _CommuterEditProfileScreenState extends State<CommuterEditProfileScreen> {
  late TextEditingController _nameController;
  bool _isLoading = false;

  final Color _deepOcean = const Color(0xFF0B192C);
  final Color _neonTeal = const Color(0xFF00FFCA);
  final Color _softBg = const Color(0xFFF4F7F9);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateProfile() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // ACTUAL API CALL: Hitting the secure Python route
      await ApiClient.instance.put(
        '/commuters/me/profile', 
        data: {
          "name": _nameController.text.trim(),
        }
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile Updated Successfully!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
          backgroundColor: _neonTeal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Return the newly typed name back to the Settings Screen
      Navigator.pop(context, _nameController.text.trim()); 
      
    } on DioException catch (e) {
      if (!mounted) return;
      String errorMsg = 'Failed to update';
      if (e.response?.data != null) {
        errorMsg = e.response!.data['detail'] ?? errorMsg;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unexpected error occurred.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBg,
      appBar: AppBar(
        backgroundColor: _deepOcean,
        foregroundColor: Colors.white,
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Display Name', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: TextStyle(color: _deepOcean, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.person, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: _deepOcean,
                foregroundColor: _neonTeal,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: _neonTeal, strokeWidth: 2))
                : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            )
          ],
        ),
      ),
    );
  }
}