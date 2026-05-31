import 'package:flutter/material.dart';

const Color _primaryColor = Color(0xFFB91C1C);
const Color _darkColor = Color(0xFF7F1D1D);
const Color _softBg = Color(0xFFFEF2F2);

class TeamUbbamaIntroductionScreen extends StatelessWidget {
  const TeamUbbamaIntroductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ComingSoonIntroductionScreen(
      serviceName: 'Team Ubbama',
      shortDescription: 'Upcoming digital service for the Tawi-Tawi platform.',
      icon: Icons.public_rounded,
    );
  }
}

class _ComingSoonIntroductionScreen extends StatelessWidget {
  final String serviceName;
  final String shortDescription;
  final IconData icon;

  const _ComingSoonIntroductionScreen({
    required this.serviceName,
    required this.shortDescription,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBg,
      appBar: AppBar(
        backgroundColor: _softBg,
        elevation: 0,
        foregroundColor: _darkColor,
        title: Text(
          serviceName,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Icon(icon, color: _primaryColor, size: 58),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  'COMING SOON',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                serviceName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _darkColor,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                shortDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Column(
                  children: [
                    _InfoRow(
                      icon: Icons.build_circle_outlined,
                      text: 'This service is still under development.',
                    ),
                    SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.phone_android_rounded,
                      text: 'It will be available inside this app soon.',
                    ),
                    SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.verified_rounded,
                      text: 'Please check again after the official launch.',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: null,
                  style: FilledButton.styleFrom(
                    disabledBackgroundColor: _primaryColor.withValues(alpha: 0.45),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Coming Soon',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _primaryColor, size: 23),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}