import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/lakbai_auth_provider.dart';
import '../../../auth/auth_provider.dart' as tawi_auth;
import '../widgets/lakbai_main_layout.dart';

class LakbaiSignupScreen extends StatefulWidget {
  const LakbaiSignupScreen({super.key});

  @override
  State<LakbaiSignupScreen> createState() => _LakbaiSignupScreenState();
}

class _LakbaiSignupScreenState extends State<LakbaiSignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();

  String _selectedRegion = 'Luzon';
  bool _isLoading = false;
  final List<String> _regions = ['Luzon', 'Visayas', 'Mindanao'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tawiUser = Provider.of<tawi_auth.AuthProvider>(context, listen: false).user;
      if (tawiUser != null) {
        setState(() {
          // Pre-fill from Kawman
          if (tawiUser.fullName.isNotEmpty) _nameController.text = tawiUser.fullName;
          if (tawiUser.email.isNotEmpty) _emailController.text = tawiUser.email;
        });
      }
    });
  }

  Future<void> _handleSignup() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final tawiId = _emailController.text.trim().toLowerCase(); 
      
      // ✅ Using internal Handshake registration!
      // Notice 'tourist' is hardcoded here for security.
      await Provider.of<LakbaiAuthProvider>(context, listen: false).registerHandshake(
        tawiId,
        _nameController.text.trim(),
        _emailController.text.trim(),
        'tourist', // Hardcoded security lock
        _selectedRegion,
        _contactController.text.trim(),
      );
      
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LakbaiMainLayout()));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: Colors.white), onPressed: () => Navigator.pop(context))),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/lakbai/hero-bg.jpg', fit: BoxFit.cover, color: Colors.black.withOpacity(0.55), colorBlendMode: BlendMode.darken)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(32.0),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/lakbai/logo-green.png', height: 50),
                    const SizedBox(height: 16),
                    const Text('Complete LakbAi Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF064E3B))),
                    const SizedBox(height: 32),
                    
                    // ✅ LOCKED FIELD: Full Name (readOnly: true)
                    TextField(
                      controller: _nameController, 
                      readOnly: true, 
                      style: const TextStyle(color: Colors.grey), 
                      decoration: InputDecoration(
                        labelText: 'Kawman Full Name', 
                        prefixIcon: const Icon(LucideIcons.user, color: Colors.grey), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                      )
                    ),
                    const SizedBox(height: 16),

                    // ✅ LOCKED FIELD: Email (readOnly: true)
                    TextField(
                      controller: _emailController, 
                      readOnly: true, 
                      style: const TextStyle(color: Colors.grey), 
                      decoration: InputDecoration(
                        labelText: 'Kawman Email Address', 
                        prefixIcon: const Icon(LucideIcons.mailCheck, color: Colors.grey), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                      )
                    ),
                    const SizedBox(height: 16),
                    
                    // EDITABLE: Contact Number
                    TextField(
                      controller: _contactController, 
                      decoration: InputDecoration(
                        labelText: 'Contact Number (Optional)', 
                        prefixIcon: const Icon(LucideIcons.phone, color: Color(0xFF059669)), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                      )
                    ),
                    const SizedBox(height: 16),
                    
                    // EDITABLE: Region
                    DropdownButtonFormField<String>(
                      value: _selectedRegion, 
                      decoration: InputDecoration(
                        labelText: 'Region', 
                        prefixIcon: const Icon(LucideIcons.mapPin, color: Color(0xFF059669)), 
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                      ), 
                      items: _regions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(), 
                      onChanged: (val) => setState(() => _selectedRegion = val!)
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity, 
                      height: 50, 
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup, 
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
                        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('ENTER LAKBAI', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                      )
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}