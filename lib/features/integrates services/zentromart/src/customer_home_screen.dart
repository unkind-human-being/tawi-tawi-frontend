import 'package:flutter/material.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(iconTheme: const IconThemeData(color: Colors.black), 
        title: const Text('Customer Dashboard'),
        backgroundColor: const Color(0xFF203A43),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Welcome, Customer!', style: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
