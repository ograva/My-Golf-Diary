import 'package:flutter/material.dart';

import '../models/caddy_session.dart';
import '../services/caddy_pairing_service.dart';
import 'caddy_on_course_screen.dart';
import 'caddy_scorecard_screen.dart';

/// Web PWA shell: On Course + Scorecard tabs only (MGDV-5).
class CaddyShell extends StatefulWidget {
  const CaddyShell({
    super.key,
    required this.session,
    this.pairing,
  });

  final CaddySessionRecord session;
  final CaddyPairingService? pairing;

  @override
  State<CaddyShell> createState() => _CaddyShellState();
}

class _CaddyShellState extends State<CaddyShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Caddy scoring'),
            Text(
              widget.session.courseName,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: [
          CaddyOnCourseScreen(
            session: widget.session,
            pairing: widget.pairing,
          ),
          CaddyScorecardScreen(session: widget.session),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        key: const ValueKey('caddy-shell-nav'),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            key: ValueKey('caddy-tab-oncourse'),
            icon: Icon(Icons.my_location),
            label: 'On Course',
          ),
          NavigationDestination(
            key: ValueKey('caddy-tab-scorecard'),
            icon: Icon(Icons.scoreboard),
            label: 'Scorecard',
          ),
        ],
      ),
    );
  }
}