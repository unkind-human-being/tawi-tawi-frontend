import 'package:flutter/material.dart';

class VendorHomeScreen extends StatelessWidget {
  const VendorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(iconTheme: const IconThemeData(color: Colors.black), 
        title: const Text('Vendor Dashboard'),
        backgroundColor: const Color(0xFF2C5364),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Welcome, Vendor!', style: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
