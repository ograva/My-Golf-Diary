import 'dart:async';

import 'package:flutter/material.dart';

import 'pwa/pwa_update_client.dart';
import 'services/account_auth_controller.dart';
import 'services/cloud_sync_service.dart';
import 'services/desktop_database.dart';
import 'theme/app_theme.dart';
import 'widgets/onboarding_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await preparePwaSession();
  await initDesktopDatabase();
  // Local SQLite is enough to paint. Firebase, App Check, and anonymous
  // sign-in need the network and must not hold the first frame.
  runApp(const GolfDiaryApp());
  unawaited(_startOptionalCloud());
}

Future<void> _startOptionalCloud() async {
  await initializeFirebase();
  AccountAuthController.instance.startListening();
}

class GolfDiaryApp extends StatelessWidget {
  const GolfDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Golf Diary',
      theme: buildGolfTheme(),
      darkTheme: buildGolfTheme(brightness: Brightness.dark),
      home: const OnboardingGate(),
    );
  }
}