import 'package:flutter/material.dart';

import '../models/golfer_profile.dart';
import '../screens/caddy_pairing_gate.dart';
import '../screens/flight_join_screen.dart';
import '../screens/home_shell.dart';
import '../screens/onboarding_starter_wizard.dart';
import '../services/caddy_launch_config.dart';
import '../services/flight_launch_config.dart';
import '../services/golfer_profile_store.dart';
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
  String? _caddyRequestToken;
  String? _flightToken;
  GolferProfile _profile = const GolferProfile();
  final GolferProfileStore _profileStore = GolferProfileStore();

  @override
  void initState() {
    super.initState();
    _flightToken = FlightLaunchConfig.currentPlatformLaunch()?.token;
    _caddyRequestToken = CaddyLaunchConfig.currentPlatformLaunch()?.requestToken;
    if (_flightToken != null || _caddyRequestToken != null) {
      setState(() => _loading = false);
      return;
    }
    _refresh();
  }

  Future<void> _refresh() async {
    final profile = await LocalDatabaseService.instance.getGolferProfile();
    if (profile.hasCompletedOnboarding) {
      await _profileStore.load();
    }
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _showShell = profile.hasCompletedOnboarding;
      _loading = false;
    });
  }

  void _enterShell() {
    _profileStore.load();
    setState(() => _showShell = true);
  }

  @override
  Widget build(BuildContext context) {
    final flightToken = _flightToken;
    if (flightToken != null) {
      return FlightJoinScreen(
        token: flightToken,
        onContinue: () {
          setState(() {
            _flightToken = null;
            _loading = true;
          });
          _refresh();
        },
      );
    }
    final caddyToken = _caddyRequestToken;
    if (caddyToken != null) {
      return CaddyPairingGate(requestToken: caddyToken);
    }
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_showShell) {
      return GolferProfileScope(
        store: _profileStore,
        child: const HomeShell(),
      );
    }
    return OnboardingStarterWizard(
      initialProfile: _profile,
      onFinished: _enterShell,
    );
  }
}