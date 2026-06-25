import 'package:flutter/material.dart';

import 'kawman_detail_screen.dart';
import 'service_detail_screen.dart';
import 'developers_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _goToService(BuildContext context, String serviceName) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ServiceDetailScreen(serviceName: serviceName)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Kawman'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('About Kawman'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KawmanDetailScreen()),
              );
            },
          ),
          
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Services',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          
          ListTile(
            title: const Text('LakbAi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _goToService(context, 'LakbAi'),
          ),
          ListTile(
            title: const Text('Reach'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _goToService(context, 'Reach'),
          ),
          ListTile(
            title: const Text('ZentroMart'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _goToService(context, 'ZentroMart'),
          ),
          ListTile(
            title: const Text('PAMEYAAN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _goToService(context, 'PAMEYAAN'),
          ),
          ListTile(
            title: const Text('TDLF-Educ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _goToService(context, 'TDLF-Educ'),
          ),
          ListTile(
            title: const Text('SOCIAL HEALTH UPDATE'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _goToService(context, 'SOCIAL HEALTH UPDATE'),
          ),
          ListTile(
            title: const Text('HanapGawa'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _goToService(context, 'HanapGawa'),
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Developers',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          
          ListTile(
            title: const Text('The Developers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DevelopersScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
