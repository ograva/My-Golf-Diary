import 'package:flutter/material.dart';

import '../services/flight_launch_config.dart';

/// Landing page for `?mode=flight&token=`. The golfer continues into the diary
/// and joins the flight from the scorecard with this code.
class FlightJoinScreen extends StatelessWidget {
  const FlightJoinScreen({
    super.key,
    required this.token,
    this.onContinue,
  });

  final String token;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join flight')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'This code links your diary to the same game. Your shots and notes stay on this device.',
            ),
            const SizedBox(height: 16),
            Text(
              token,
              key: const ValueKey('flight-join-token'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(FlightLaunchConfig.buildInviteUrl(token)),
            const Spacer(),
            FilledButton(
              key: const ValueKey('flight-join-continue'),
              onPressed: onContinue,
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
