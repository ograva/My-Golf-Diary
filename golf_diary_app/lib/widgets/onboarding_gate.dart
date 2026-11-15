import 'package:flutter/material.dart';

import '../screens/home_shell.dart';
import '../models/golfer_profile.dart';
import '../screens/onboarding_starter_wizard.dart';
import '../services/local_database_service.dart';

/// Shows [OnboardingStarterWizard] until the golfer completes or defers.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key});

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool _loading = true;
  bool _showShell = false;
  GolferProfile _profile = const GolferProfile();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final profile = await LocalDatabaseService.instance.getGolferProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _showShell = profile.hasCompletedOnboarding;
      _loading = false;
    });
  }

  void _enterShell() {
    setState(() => _showShell = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_showShell) {
      return const HomeShell();
    }
    return OnboardingStarterWizard(
      initialProfile: _profile,
      onFinished: _enterShell,
    );
  }
}