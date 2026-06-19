import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});
  final Future<void> Function() onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;
  var _loading = false;
  var _page = 0.0;
  var _currentPage = 0;

  static const _pages = [
    _IntroPage(
      icon: Icons.search_rounded,
      eyebrow: 'Chapter 1',
      title: 'Find trusted local help',
      body:
          'Browse approved workers and agencies in Tawi-Tawi for home services, errands, repairs, and more.',
      color: Color(0xFF7B2FF7),
      accent: Color(0xFFE9D8FF),
    ),
    _IntroPage(
      icon: Icons.calendar_month_rounded,
      eyebrow: 'Chapter 2',
      title: 'Book work without the back-and-forth',
      body:
          'Send requests, agree on schedules, and keep your booking details in one place.',
      color: Color(0xFF5F3DC4),
      accent: Color(0xFFDDE7FF),
    ),
    _IntroPage(
      icon: Icons.forum_rounded,
      eyebrow: 'Chapter 3',
      title: 'Share, chat, and stay updated',
      body:
          'Discover community posts, message providers, and follow stories from people around you.',
      color: Color(0xFF8A3FFC),
      accent: Color(0xFFFFE8CC),
    ),
    _IntroPage(
      icon: Icons.verified_rounded,
      eyebrow: 'Final Page',
      title: 'Build trust after every job',
      body:
          'Reviews, profiles, and booking history help the community choose reliable service providers.',
      color: Color(0xFF6D28D9),
      accent: Color(0xFFE7F8EF),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9)
      ..addListener(() {
        setState(() => _page = _controller.page ?? 0);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDone() async {
    if (_loading) return;
    final accepted = await _showTermsSheet();
    if (accepted != true || !mounted) return;
    setState(() => _loading = true);
    try {
      await widget.onDone();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool?> _showTermsSheet() {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TermsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0, 0.34, 0.72, 1],
            colors: [
              Color(0xFF170F20),
              Color(0xFF2B1740),
              appPrimary,
              appSecondary,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(24, compact ? 18 : 28, 24, 10),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/hanap_gawa/hanapgawa-shaped-white-background-logo.png',
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: appAccent,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.handshake_rounded,
                                color: appPrimary, size: 32),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Image.asset(
                        'assets/hanap_gawa/hanapgawa-wordmark.png',
                        height: 25,
                        errorBuilder: (_, __, ___) => const Text(
                          'HanapGawa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Open your local guide to trusted work and services.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xCFFFFFFF), height: 1.5),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            top: compact ? 18 : 34,
                            bottom: compact ? 18 : 30,
                            child: const _BookShadow(),
                          ),
                          PageView.builder(
                            controller: _controller,
                            itemCount: _pages.length,
                            onPageChanged: (index) =>
                                setState(() => _currentPage = index),
                            itemBuilder: (context, index) => _TurningBookPage(
                              page: _pages[index],
                              index: index,
                              currentPage: _page,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_pages.length, (index) {
                            final active = index == _currentPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              width: active ? 28 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: active
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.34),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            );
                          }),
                        ),
                        if (isLastPage) ...[
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: _loading ? null : _handleDone,
                            style: FilledButton.styleFrom(
                              backgroundColor: appAccent,
                              foregroundColor: appPrimary,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: appPrimary,
                                    ),
                                  )
                                : const Text('Get Started'),
                          ),
                        ] else
                          const SizedBox(height: 18 + 54),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _IntroPage {
  const _IntroPage({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.color,
    required this.accent,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final Color color;
  final Color accent;
}

class _BookShadow extends StatelessWidget {
  const _BookShadow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 46,
            spreadRadius: -12,
            offset: const Offset(0, 24),
          ),
        ],
      ),
    );
  }
}

class _TurningBookPage extends StatelessWidget {
  const _TurningBookPage({
    required this.page,
    required this.index,
    required this.currentPage,
  });

  final _IntroPage page;
  final int index;
  final double currentPage;

  @override
  Widget build(BuildContext context) {
    final distance = (index - currentPage).clamp(-1.0, 1.0);
    final isTurningAway = distance < 0;
    final turn = isTurningAway ? distance.abs() : (1 - distance).clamp(0, 1);
    final angle =
        isTurningAway ? -turn * math.pi / 2.7 : distance * math.pi / 3;
    final scale = 1 - distance.abs() * 0.05;
    final opacity = (1 - distance.abs() * 0.35).clamp(0.0, 1.0);

    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0016)
      ..rotateY(angle)
      ..scale(scale, scale);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 22),
      child: Opacity(
        opacity: opacity,
        child: Transform(
          alignment: Alignment.centerLeft,
          transform: transform,
          child: _BookPage(page: page, number: index + 1),
        ),
      ),
    );
  }
}

class _BookPage extends StatelessWidget {
  const _BookPage({required this.page, required this.number});
  final _IntroPage page;
  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _PaperPainter())),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 34,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: -54,
              top: -54,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: page.accent,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(38, 32, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: page.color,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: page.color.withOpacity(0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(page.icon, color: Colors.white, size: 32),
                      ),
                      const Spacer(),
                      Text(
                        number.toString().padLeft(2, '0'),
                        style: TextStyle(
                          color: page.color.withOpacity(0.18),
                          fontSize: 42,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    page.eyebrow.toUpperCase(),
                    style: TextStyle(
                      color: page.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    page.title,
                    style: const TextStyle(
                      color: Color(0xFF221729),
                      fontSize: 31,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    page.body,
                    style: const TextStyle(
                      color: appMuted,
                      fontSize: 15.5,
                      height: 1.65,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: page.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.swipe_rounded, color: page.color, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Swipe to turn the page',
                          style: TextStyle(
                            color: page.color,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsSheet extends StatefulWidget {
  const _TermsSheet();

  @override
  State<_TermsSheet> createState() => _TermsSheetState();
}

class _TermsSheetState extends State<_TermsSheet> {
  bool _accepted = false;
  bool _scrolledToBottom = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (!_scrolledToBottom) {
        final pos = _scrollController.position;
        if (pos.pixels >= pos.maxScrollExtent - 40) {
          setState(() => _scrolledToBottom = true);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.97,
      minChildSize: 0.6,
      builder: (ctx, outer) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFBF4),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: appPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.gavel_rounded, color: appPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terms & Conditions',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1C1917),
                          ),
                        ),
                        const Text(
                          'Please read before using Hanap Gawa',
                          style: TextStyle(fontSize: 12, color: appMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: const _TermsContent(),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 12, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_scrolledToBottom)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.keyboard_arrow_down_rounded,
                              color: appMuted, size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            'Scroll down to read all terms',
                            style: TextStyle(fontSize: 12, color: appMuted),
                          ),
                        ],
                      ),
                    ),
                  InkWell(
                    onTap: () => setState(() => _accepted = !_accepted),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _accepted,
                            onChanged: (v) =>
                                setState(() => _accepted = v ?? false),
                            activeColor: appPrimary,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                'I have read, understood, and agree to the Terms and Conditions of Hanap Gawa.',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _accepted
                        ? () => Navigator.pop(context, true)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: appPrimary,
                      disabledBackgroundColor: Colors.grey.shade300,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    child: const Text('I Agree — Get Started'),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: appMuted, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _TermsSection(
          title: '1. Acceptance of Terms',
          body:
              'By using Hanap Gawa, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use this application. These terms apply to all users, including clients, service providers, and agencies operating within the Tawi-Tawi region.',
        ),
        _TermsSection(
          title: '2. Eligibility',
          body:
              'You must be at least 18 years old to use Hanap Gawa. By registering, you confirm that the information you provide is accurate, complete, and current. Accounts found to contain false information may be suspended or permanently removed.',
        ),
        _TermsSection(
          title: '3. User Responsibilities',
          body:
              'You are solely responsible for all activity that occurs under your account. You agree not to misuse the platform, post false job listings, send fraudulent booking requests, or harass other users. Any content you post must not violate applicable Philippine laws.',
        ),
        _TermsSection(
          title: '4. Bookings and Transactions',
          body:
              'Hanap Gawa facilitates connections between clients and service providers but is not a party to any agreement, booking, or transaction between them. We do not guarantee the quality, safety, or legality of services offered. Users transact at their own risk and are encouraged to review provider ratings and history.',
        ),
        _TermsSection(
          title: '5. Payments',
          body:
              'Hanap Gawa does not process payments directly. Any financial arrangements are made between the client and the service provider. Disputes over payments must be resolved between the parties involved. Hanap Gawa is not liable for any financial loss arising from transactions conducted through the platform.',
        ),
        _TermsSection(
          title: '6. Privacy and Data',
          body:
              'We collect and process personal information in accordance with the Data Privacy Act of 2012 (Republic Act No. 10173). Your data is used solely to operate and improve the platform. We do not sell your personal information to third parties. By using this app, you consent to the collection and use of your data as described in our Privacy Policy.',
        ),
        _TermsSection(
          title: '7. Prohibited Conduct',
          body:
              'Users are prohibited from: posting illegal, offensive, or misleading content; impersonating another person or entity; attempting to gain unauthorized access to other accounts; using the platform for any unlawful purpose; and engaging in discriminatory behavior based on religion, ethnicity, gender, or disability.',
        ),
        _TermsSection(
          title: '8. Account Suspension and Termination',
          body:
              'Hanap Gawa reserves the right to suspend or permanently terminate any account that violates these terms, engages in fraudulent activity, or poses a risk to other users or the platform. Decisions on suspension are at the sole discretion of the platform administrators.',
        ),
        _TermsSection(
          title: '9. Limitation of Liability',
          body:
              'To the maximum extent permitted by law, Hanap Gawa and its operators are not liable for any indirect, incidental, or consequential damages arising from the use or inability to use the platform, including but not limited to loss of income, personal injury, or property damage resulting from services arranged through the app.',
        ),
        _TermsSection(
          title: '10. Modifications to Terms',
          body:
              'We may update these Terms and Conditions from time to time. Continued use of the application after changes are posted constitutes your acceptance of the revised terms. We encourage you to review these terms periodically.',
        ),
        _TermsSection(
          title: '11. Governing Law',
          body:
              'These Terms and Conditions are governed by the laws of the Republic of the Philippines. Any disputes arising from the use of this platform shall be subject to the jurisdiction of the courts in the Province of Tawi-Tawi.',
        ),
        _TermsSection(
          title: '12. Contact',
          body:
              'If you have questions about these Terms and Conditions, please contact the Hanap Gawa support team through the app\'s feedback or help section.',
        ),
        SizedBox(height: 8),
        Text(
          'Last updated: June 2026',
          style: TextStyle(fontSize: 12, color: appMuted),
        ),
        SizedBox(height: 4),
      ],
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF1C1917),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.65,
              color: Color(0xFF44403C),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF7B2FF7).withOpacity(0.04)
      ..strokeWidth = 1;
    for (var y = 92.0; y < size.height - 36; y += 26) {
      canvas.drawLine(Offset(38, y), Offset(size.width - 28, y), paint);
    }

    final fold = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.42),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(size.width - 44, 0, 44, size.height));
    canvas.drawRect(Rect.fromLTWH(size.width - 44, 0, 44, size.height), fold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
