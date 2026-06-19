import 'package:flutter/material.dart';

/// ADD YOUR SERVICE DETAILS HERE
/// Developers: Simply add your service name as the key and its description as the value.
const Map<String, String> serviceDescriptions = {
  'LakbAi': 'LakbAi is an intelligent travel and mapping assistant that helps you navigate and explore local destinations effortlessly.',
  
  'Reach': 'Reach is a highly resilient, offline-first mesh messaging platform designed for absolute privacy and off-grid reliability. It operates by utilizing a dual-network approach: Google Nearby Connections for Bluetooth/WiFi-Direct peer-to-peer links, and mDNS for Local Area Network (LAN) routing.\n\n'
      'All communications—including texts, images, and documents—are strictly End-to-End Encrypted using AES-256-GCM and RSA-2048, authenticated via Ed25519 digital signatures, and secured locally by a 6-digit PIN. Its advanced routing engine utilizes Dijkstra\'s algorithm for shortest-path delivery and controlled epidemic flooding with Time-To-Live (TTL) limits to ensure your data securely hops through the community to its destination.\n\n'
      'When internet connectivity is restored, Reach seamlessly transitions to its WebSocket cloud-fallback to sync offline history and deliver pending out-of-range messages.',
  
  'ZentroMart': 'ZentroMart is our local e-commerce and marketplace solution, making it simple to buy and sell goods directly within the community.',
  
  'PAMEYAAN': 'PAMEYAAN serves as a centralized community forum and municipal announcements board, bringing local governance closer to the people.',
  
  'TDLF-Educ': 'TDLF-Educ provides educational resources, e-learning modules, and school-related updates tailored for local students and educators.',
  
  'SOCIAL HEALTH UPDATE': 'Stay up to date with vital health updates, clinic schedules, and integrated public health modules directly from the RHU.',
  
  'HanapGawa': 'HanapGawa is a local job marketplace and community platform built for the people of Bongao. It connects workers and clients directly—making it easier for residents to find skilled professionals nearby and for job seekers to discover opportunities in their own community.\n\n'
      'The platform supports multiple types of posts: job listings let employers advertise vacancies with full details and requirements, while service offerings allow workers and freelancers to promote their skills and set their own rates. A social community feed keeps professionals and clients connected, sharing updates and news within the local workforce.\n\n'
      'Workers can build detailed profiles showcasing their skills, experience, and availability. Clients can browse and filter talent by skill or rating, apply directly, or send booking requests. A built-in rating and review system ensures trust and transparency on both sides—so every hiring decision is informed and every worker\'s reputation is earned.\n\n'
      'HanapGawa includes real-time direct messaging and instant notifications so job offers, booking confirmations, and responses are never delayed. Listings and users are monitored through platform admin tools to keep the environment safe and fair for everyone.\n\n'
      'Integrated into the Kawman ecosystem, HanapGawa automatically links your Kawman account—no separate sign-up needed. Your identity and profile are securely managed across sessions, so accessing local work opportunities in Bongao is always just one tap away.',
};

class ServiceDetailScreen extends StatelessWidget {
  final String serviceName;

  const ServiceDetailScreen({super.key, required this.serviceName});

  @override
  Widget build(BuildContext context) {
    // Look up the description from the map, or provide a default fallback
    final String description = serviceDescriptions[serviceName] ?? 
        'Learn more about $serviceName and how it integrates into the Kawman ecosystem to provide seamless services.';

    return Scaffold(
      appBar: AppBar(
        title: Text('About $serviceName'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              serviceName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}