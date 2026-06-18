import 'package:flutter/material.dart';

import '../../core/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About HanapGawa')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Image.asset(
              'assets/hanap_gawa/hanapgawa-shaped-white-background-logo.png',
              width: 100,
              height: 100,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: appAccent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.work_outline, size: 48, color: appPrimary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Image.asset(
              'assets/hanap_gawa/hanapgawa-wordmark.png',
              height: 32,
              errorBuilder: (_, __, ___) => const Text(
                'HanapGawa',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: appPrimary),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Local Services & Job Marketplace',
              style: TextStyle(color: appMuted, fontSize: 14),
            ),
          ),
          const SizedBox(height: 32),
          _InfoCard(
            icon: Icons.info_outline,
            title: 'About the App',
            body:
                'HanapGawa connects local service providers with clients across Tawi-Tawi. '
                'Find skilled workers, post job listings, and book services — all in one place.',
          ),
          const SizedBox(height: 16),
          _InfoCard(
            icon: Icons.group_outlined,
            title: 'Developed By',
            child: const _DeveloperList(),
          ),
          const SizedBox(height: 16),
          _InfoCard(
            icon: Icons.code_outlined,
            title: 'Version',
            body: '1.0.0',
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '© ${DateTime.now().year} HanapGawa. All rights reserved.',
              style: const TextStyle(color: appMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DeveloperList extends StatelessWidget {
  const _DeveloperList();

  @override
  Widget build(BuildContext context) {
    const developers = [
      (name: 'Asaad, Fatima Reedzqha', role: 'Developer'),
      (name: 'Ajul, Raizha', role: 'Developer'),
      (name: 'Tadus, Sandara', role: 'Developer'),
    ];

    return Column(
      children: developers.map((dev) {
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: appAccent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  dev.name[0].toUpperCase(),
                  style: const TextStyle(
                      color: appPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dev.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              Text(dev.role,
                  style: const TextStyle(color: appMuted, fontSize: 12)),
            ]),
          ]),
        );
      }).toList(),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, this.body, this.child});
  final IconData icon;
  final String title;
  final String? body;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: appPrimary),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15)),
        ]),
        if (body != null) ...[
          const SizedBox(height: 8),
          Text(body!, style: const TextStyle(color: appMuted, height: 1.5)),
        ],
        if (child != null) child!,
      ]),
    );
  }
}
