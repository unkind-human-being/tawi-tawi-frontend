import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/onboarding/onboarding_screen.dart';
import '../hanap_gawa_entry_screen.dart';

const _kOnboardingKey = 'hanapgawa_onboarding_seen';

class HanapGawaIntroductionScreen extends StatefulWidget {
  const HanapGawaIntroductionScreen({super.key});

  @override
  State<HanapGawaIntroductionScreen> createState() =>
      _HanapGawaIntroductionScreenState();
}

class _HanapGawaIntroductionScreenState
    extends State<HanapGawaIntroductionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSeen());
  }

  Future<void> _checkSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_kOnboardingKey) ?? false;
    if (seen && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HanapGawaEntryScreen()),
      );
    }
  }

  Future<void> _onDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingKey, true);
    if (mounted) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HanapGawaEntryScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScreen(onDone: _onDone);
  }
}
