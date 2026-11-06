import 'package:flutter/material.dart';

import '../models/golf_models.dart';
import '../models/round_summary.dart';
import '../services/local_database_service.dart';
import '../theme/app_theme.dart';
import 'scorecard_hole_editor.dart';

class ScorecardScreen extends StatefulWidget {
  const ScorecardScreen({super.key});

  @override
  State<ScorecardScreen> createState() => ScorecardScreenState();
}

/// Public state type so [HomeShell] can refresh when the tab is selected.
class ScorecardScreenState extends State<ScorecardScreen> {
  List<RoundSummary> _recentRounds = [];
  String? _selectedRoundId;
  List<RoundScore> _holes = [];
  RoundTotals? _totals;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadScorecard();
  }

  Future<void> loadScorecard() async {
    setState(() => _loading = true);
    final db = LocalDatabaseService.instance;
    final recent = await db.listRecentRounds(limit: 12);
    final active = await db.getActiveRoundId();
    var roundId = _selectedRoundId;
    if (roundId == null || !recent.any((r) => r.roundId == roundId)) {
      roundId = active ?? (recent.isNotEmpty ? recent.first.roundId : null);
    }
    List<RoundScore> holes = [];
    RoundTotals? totals;
    if (roundId != null) {
      holes = await db.getScoresForRound(roundId);
      totals = await db.computeRoundTotals(roundId);
    }
    if (!mounted) return;
    setState(() {
      _recentRounds = recent;
      _selectedRoundId = roundId;
      _holes = holes;
      _totals = totals;
      _loading = false;
    });
  }

  Future<void> _startNewRound() async {
    await LocalDatabaseService.instance.ensureActiveRound(courseName: 'Local Course');
    setState(() => _selectedRoundId = null);
    await loadScorecard();
  }

  RoundScore? _holeRow(int holeNumber) {
    for (final h in _holes) {
      if (h.holeNumber == holeNumber) return h;
    }
    return null;
  }

  String get _courseName =>
      _totals?.courseName ?? (_holes.isNotEmpty ? _holes.first.courseName : 'Local Course');

  Future<void> _editHole(int holeNumber) async {
    final roundId = _selectedRoundId;
    if (roundId == null) return;
    await showScorecardHoleEditor(
      context: context,
      roundId: roundId,
      courseName: _courseName,
      holeNumber: holeNumber,
      existing: _holeRow(holeNumber),
    );
    await loadScorecard();
  }

  @override
  Widget build(BuildContext context) {
    final courseName = _totals?.courseName ?? 'No round selected';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scorecard'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadScorecard),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadScorecard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_recentRounds.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('No rounds yet. Track shots on the On Course tab or start a round here.'),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _startNewRound, child: const Text('Start new round')),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Text(courseName, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    if (_recentRounds.length > 1)
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _recentRounds.map((summary) {
                            final label = summary.label;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(label, overflow: TextOverflow.ellipsis),
                                selected: _selectedRoundId == summary.roundId,
                                onSelected: (_) {
                                  setState(() => _selectedRoundId = summary.roundId);
                                  loadScorecard();
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _SummaryBanner(totals: _totals),
                    const SizedBox(height: 8),
                    Text(
                      'Tap any hole to enter or edit scores manually.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    _ScorecardTable(holeRow: _holeRow, onHoleTap: _editHole),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _startNewRound,
                      icon: const Icon(Icons.add),
                      label: const Text('Start new round'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.totals});

  final RoundTotals? totals;

  @override
  Widget build(BuildContext context) {
    if (totals == null) {
      return const SizedBox.shrink();
    }
    final t = totals!;
    return Card(
      color: AppColors.amber.withOpacity(0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryCell(label: 'Out', value: '${t.frontNineScore}', sub: _toParLabel(t.frontNineToPar)),
                _SummaryCell(label: 'In', value: '${t.backNineScore}', sub: _toParLabel(t.backNineToPar)),
                _SummaryCell(label: 'Total', value: '${t.totalScore}', sub: _toParLabel(t.totalToPar)),
              ],
            ),
            if (t.penaltiesTotal > 0 || t.mulligansTotal > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Penalties ${t.penaltiesTotal} · Mulligans ${t.mulligansTotal} (practice)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _toParLabel(int toPar) {
    if (toPar == 0) return 'E';
    if (toPar > 0) return '+$toPar';
    return '$toPar';
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.label, required this.value, required this.sub});

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        Text(sub, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ScorecardTable extends StatelessWidget {
  const _ScorecardTable({required this.holeRow, required this.onHoleTap});

  final RoundScore? Function(int holeNumber) holeRow;
  final Future<void> Function(int holeNumber) onHoleTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const _ScorecardHeaderRow(),
          const Divider(height: 1),
          for (var hole = 1; hole <= 18; hole++) ...[
            _ScorecardDataRow(hole: hole, row: holeRow(hole), onTap: () => onHoleTap(hole)),
            if (hole == 9) const Divider(height: 1, thickness: 2),
          ],
        ],
      ),
    );
  }
}

class _ScorecardHeaderRow extends StatelessWidget {
  const _ScorecardHeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 13);
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('Hole', style: style)),
          Expanded(child: Text('Par', style: style, textAlign: TextAlign.center)),
          Expanded(child: Text('Str', style: style, textAlign: TextAlign.center)),
          Expanded(child: Text('Pen', style: style, textAlign: TextAlign.center)),
          Expanded(child: Text('Tot', style: style, textAlign: TextAlign.center)),
          Expanded(child: Text('+/-', style: style, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class _ScorecardDataRow extends StatelessWidget {
  const _ScorecardDataRow({required this.hole, required this.row, required this.onTap});

  final int hole;
  final RoundScore? row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final played = row != null && isHolePlayed(row!);
    final par = row?.par ?? 4;
    final strokes = row?.strokes ?? 0;
    final penalties = row?.penalties ?? 0;
    final total = row != null ? effectiveHoleScore(row!) : 0;
    final toPar = played ? total - par : null;
    final conceded = row?.conceded == 1;

    Color? rowColor;
    if (conceded) {
      rowColor = Colors.grey.shade200;
    } else if (played && toPar != null) {
      if (toPar <= -1) rowColor = Colors.blue.shade50;
      if (toPar >= 1) rowColor = Colors.orange.shade50;
    }

    String toParText = '—';
    if (toPar != null) {
      if (toPar == 0) {
        toParText = 'E';
      } else if (toPar > 0) {
        toParText = '+$toPar';
      } else {
        toParText = '$toPar';
      }
    }

    return Material(
      color: rowColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Text('$hole${conceded ? ' *' : ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade600),
                  ],
                ),
              ),
          Expanded(child: Text(played || row != null ? '$par' : '—', textAlign: TextAlign.center)),
          Expanded(child: Text(played ? '$strokes' : '—', textAlign: TextAlign.center)),
          Expanded(child: Text(penalties > 0 ? '$penalties' : '—', textAlign: TextAlign.center)),
          Expanded(
            child: Text(
              played ? '$total' : '—',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              toParText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: toPar != null && toPar > 0 ? Colors.deepOrange : AppColors.green,
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
