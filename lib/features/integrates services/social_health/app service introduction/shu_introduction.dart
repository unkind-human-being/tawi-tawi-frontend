import 'package:flutter/material.dart';


import '../home/social_health_gateway_screen.dart';

class ShuIntroductionScreen extends StatefulWidget {
  const ShuIntroductionScreen({super.key});

  static const String routeName = '/shu-introduction';

  @override
  State<ShuIntroductionScreen> createState() => _ShuIntroductionScreenState();
}

class _ShuIntroductionScreenState extends State<ShuIntroductionScreen> {
  static const Color _darkGreen = Color(0xFF064E3B);
  static const Color _mainGreen = Color(0xFF0EA5E9);
  static const Color _softGreen = Color(0xFF0EA5E9);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);

  bool _agreedToTerms = false;

  void _goToLogin() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms before continuing.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );

      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SocialHealthGatewayScreen(),
      ),
    );
  }

  void _showTermsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.90,
          builder: (
            BuildContext context,
            ScrollController scrollController,
          ) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Terms and Privacy Notice',
                    style: TextStyle(
                      color: _textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'By continuing, you agree to use the RHU Social Health Update module responsibly. This module is intended for public health updates, RHU announcements, surveys, events, appointment requests, and health service communication.',
                    style: TextStyle(
                      color: _textMuted,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const _TermsItem(
                    title: 'Public Health Updates',
                    body:
                        'Posts, events, and surveys may be published by authorized RHU staff for public awareness and participation.',
                  ),
                  const _TermsItem(
                    title: 'Appointments',
                    body:
                        'Appointment requests must contain truthful and accurate information. Online consultations may require supporting documents when needed.',
                  ),
                  const _TermsItem(
                    title: 'Account Responsibility',
                    body:
                        'Keep your login information private. Do not use another person’s account or submit false information.',
                  ),
                  const _TermsItem(
                    title: 'Emergency Reminder',
                    body:
                        'This app is not a replacement for emergency medical care. For urgent health concerns, contact your RHU directly or go to the nearest health facility.',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _mainGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'I Understand',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool canContinue = _agreedToTerms;

    return Scaffold(
      backgroundColor: _softGreen,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            const _BackgroundDecor(),
            Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const _TopBadge(),
                        const SizedBox(height: 24),
                        Center(
                          child: Container(
                            width: 116,
                            height: 116,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  _darkGreen,
                                  _mainGreen,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(36),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: _mainGreen.withValues(alpha: 0.28),
                                  blurRadius: 28,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.health_and_safety_rounded,
                              color: Colors.white,
                              size: 64,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'RHU Social Health Updates',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: _textDark,
                            fontSize: 32,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Stay connected with your Rural Health Unit through public health posts, surveys, events, and appointment services.',
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 15.5,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 26),
                        const _FeatureCard(
                          icon: Icons.campaign_rounded,
                          title: 'Health Posts',
                          description:
                              'Read official RHU announcements, health reminders, and public advisories.',
                          color: Color(0xFF0F766E),
                          bgColor: Color(0xFFEFFAF5),
                        ),
                        const SizedBox(height: 12),
                        const _FeatureCard(
                          icon: Icons.event_available_rounded,
                          title: 'Events',
                          description:
                              'View upcoming RHU activities, health campaigns, and community programs.',
                          color: Color(0xFF2563EB),
                          bgColor: Color(0xFFEFF6FF),
                        ),
                        const SizedBox(height: 12),
                        const _FeatureCard(
                          icon: Icons.fact_check_rounded,
                          title: 'Surveys',
                          description:
                              'Answer RHU surveys that help improve public health services.',
                          color: Color(0xFF7C3AED),
                          bgColor: Color(0xFFF5F3FF),
                        ),
                        const SizedBox(height: 12),
                        const _FeatureCard(
                          icon: Icons.calendar_month_rounded,
                          title: 'Apply Appointment',
                          description:
                              'Request walk-in or online appointments with your assigned RHU.',
                          color: Color(0xFFEA580C),
                          bgColor: Color(0xFFFFF7ED),
                        ),
                        const SizedBox(height: 20),
                        _InfoNotice(
                          onTermsTap: _showTermsSheet,
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
                _BottomActionPanel(
                  agreedToTerms: _agreedToTerms,
                  canContinue: canContinue,
                  onChanged: (bool? value) {
                    setState(() {
                      _agreedToTerms = value ?? false;
                    });
                  },
                  onTermsTap: _showTermsSheet,
                  onGetStarted: _goToLogin,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned(
          top: -90,
          right: -90,
          child: Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 140,
          left: -90,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -70,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBadge extends StatelessWidget {
  const _TopBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFFD1FAE5),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.verified_rounded,
                color: Color(0xFF0F766E),
                size: 17,
              ),
              SizedBox(width: 6),
              Text(
                'Official RHU Module',
                style: TextStyle(
                  color: Color(0xFF064E3B),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: color,
              size: 29,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNotice extends StatelessWidget {
  const _InfoNotice({
    required this.onTermsTap,
  });

  final VoidCallback onTermsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF2563EB),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Color(0xFF1E3A8A),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
                children: <InlineSpan>[
                  const TextSpan(
                    text:
                        'This module is for public health information and appointment requests. For emergency cases, please contact your RHU or nearest health facility directly. ',
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: onTermsTap,
                      child: const Text(
                        'Read terms',
                        style: TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionPanel extends StatelessWidget {
  const _BottomActionPanel({
    required this.agreedToTerms,
    required this.canContinue,
    required this.onChanged,
    required this.onTermsTap,
    required this.onGetStarted,
  });

  final bool agreedToTerms;
  final bool canContinue;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onTermsTap;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              color: agreedToTerms
                  ? const Color(0xFFEFFAF5)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: agreedToTerms
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: CheckboxListTile(
              value: agreedToTerms,
              onChanged: onChanged,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFF0F766E),
              title: const Text(
                'I agree with the terms and privacy notice.',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              subtitle: GestureDetector(
                onTap: onTermsTap,
                child: const Text(
                  'Tap to read the terms',
                  style: TextStyle(
                    color: Color(0xFF0F766E),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: canContinue
                    ? const Color(0xFF0F766E)
                    : const Color(0xFF94A3B8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              onPressed: canContinue ? onGetStarted : null,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsItem extends StatelessWidget {
  const _TermsItem({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF0F766E),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}