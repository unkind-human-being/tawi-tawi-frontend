import 'package:flutter/material.dart';

class KawmanDetailScreen extends StatelessWidget {
  const KawmanDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Kawman'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'What is Kawman?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Kawman is a comprehensive digital ecosystem designed specifically for the local community. It bridges the gap between individuals, skilled workers, businesses, and essential services. By bringing multiple specialized platforms into one unified portal, Kawman aims to foster local economic growth, build trust, and simplify daily life within the community.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 24),
            Text(
              'Integrated Services Ecosystem',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Kawman serves as a central hub, connecting you to a variety of specialized modules effortlessly:',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 16),
            _ServiceItem(
              title: 'LakbAi',
              description: 'An intelligent travel and navigation companion for navigating the local area and discovering new places.',
            ),
            _ServiceItem(
              title: 'Reach',
              description: 'A platform dedicated to community communication, announcements, and keeping everyone connected.',
            ),
            _ServiceItem(
              title: 'ZentroMart',
              description: 'A local digital marketplace where you can easily find, buy, and sell everyday goods and groceries.',
            ),
            _ServiceItem(
              title: 'PAMEYAAN',
              description: 'A specialized platform supporting local commerce and livelihood programs.',
            ),
            _ServiceItem(
              title: 'TDLF-Educ',
              description: 'An educational resource hub providing learning materials and opportunities for the community.',
            ),
            _ServiceItem(
              title: 'SOCIAL HEALTH UPDATE',
              description: 'Your go-to source for local health advisories, medical updates, and wellness information.',
            ),
            _ServiceItem(
              title: 'HanapGawa',
              description: 'A centralized job portal that bridges the gap between skilled workers and people looking for services, helping locals find employment and hire talent.',
            ),
            SizedBox(height: 16),
            Text(
              'Through these integrated services, Kawman provides a unified experience where finding a job, shopping locally, staying informed, and traveling become seamless parts of community life.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final String title;
  final String description;

  const _ServiceItem({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: description),
          ],
        ),
        style: const TextStyle(fontSize: 16, height: 1.5),
      ),
    );
  }
}
