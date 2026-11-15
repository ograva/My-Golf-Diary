import 'package:flutter/material.dart';

import '../data/ph_golf_catalog.dart';
import '../models/caddy_session.dart';
import '../models/golf_models.dart';
import '../services/local_database_service.dart';

/// Read-only derived scorecard for the caddy shell (from stroke events).
class CaddyScorecardScreen extends StatefulWidget {
  const CaddyScorecardScreen({super.key, required this.session});

  final CaddySessionRecord session;

  @override
  State<CaddyScorecardScreen> createState() => _CaddyScorecardScreenState();
}

class _CaddyScorecardScreenState extends State<CaddyScorecardScreen> {
  List<RoundScore> _holes = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final rows =
        await LocalDatabaseService.instance.getScoresForRound(widget.session.roundId);
    if (!mounted) return;
    setState(() => _holes = rows);
  }

  @override
  Widget build(BuildContext context) {
    final holeCount = PhGolfCatalog.holeCount(widget.session.courseName);
    final byHole = {for (final h in _holes) h.holeNumber: h};

    return RefreshIndicator(
      key: const ValueKey('caddy-scorecard-refresh'),
      onRefresh: _reload,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: holeCount,
        itemBuilder: (context, index) {
          final n = index + 1;
          final row = byHole[n];
          final par = row?.par ?? PhGolfCatalog.parForHole(widget.session.courseName, n) ?? 4;
          final strokes = row?.strokes ?? 0;
          final gross = row != null && row.finalScore > 0
              ? row.finalScore
              : computeFinalScore(strokes: strokes, penalties: row?.penalties ?? 0);
          return ListTile(
            key: ValueKey('caddy-scorecard-hole-$n'),
            title: Text('Hole $n'),
            subtitle: Text('Par $par'),
            trailing: Text(
              strokes > 0 ? '$strokes ($gross)' : '—',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          );
        },
      ),
    );
  }
}