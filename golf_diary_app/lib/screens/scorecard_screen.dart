import 'package:flutter/material.dart';

import '../models/golf_models.dart';
import '../models/round_summary.dart';
import '../services/local_database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/save_round_before_new_dialog.dart';
import '../widgets/sync_cloud_button.dart';
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
    final db = LocalDatabaseService.instance;
    final activeId = await db.getActiveRoundId();
    if (activeId != null && await db.roundHasMeaningfulPlay(activeId)) {
      final course = await db.getCourseNameForRound(activeId);
      if (!mounted) return;
      final choice = await showSaveRoundBeforeNewDialog(context: context, courseName: course);
      if (choice == null || choice == SaveRoundBeforeNewChoice.cancel) return;
      if (choice == SaveRoundBeforeNewChoice.saveAndStartNew) {
        await db.completeRound(activeId);
      } else {
        await db.discardRound(activeId);
      }
    }

    final courseName = await showDialog<String>(
      context: context,
      builder: (context) => const _NewRoundDialog(),
    );
    if (courseName == null || !mounted) return;
    final roundId = await db.startNewRound(courseName: courseName);
    if (!mounted) return;
    setState(() => _selectedRoundId = roundId);
    await loadScorecard();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Started round at $courseName'), backgroundColor: AppColors.green),
    );
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
      appBar: AppBar(title: const Text('Scorecard'), actions: const [SyncCloudButton()]),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(key: ValueKey('scorecard-loading')),
            )
          : RefreshIndicator(
              onRefresh: loadScorecard,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (_recentRounds.isEmpty)
                    Card(
                      key: const ValueKey('scorecard-empty-state'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'No rounds yet. Track shots on On Course or start a round here.',
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              key: const ValueKey('scorecard-new-round-btn'),
                              onPressed: _startNewRound,
                              child: const Text('Start new round'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Text(courseName, style: Theme.of(context).textTheme.headlineSmall),
                    if (_selectedRoundId != null &&
                        _recentRounds.any((r) => r.roundId == _selectedRoundId && !r.isCompleted))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'In progress — finish holes on On Course or save via Start new round',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (_recentRounds.length > 1)
                      SizedBox(
                        height: 48,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _recentRounds.map((summary) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                key: ValueKey('scorecard-round-chip-${summary.roundId}'),
                                label: Text(summary.label, overflow: TextOverflow.ellipsis),
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
                    const SizedBox(height: 16),
                    _NineGrid(title: 'FRONT 9', startHole: 1, holeRow: _holeRow, onHoleTap: _editHole),
                    const SizedBox(height: 16),
                    _NineGrid(title: 'BACK 9', startHole: 10, holeRow: _holeRow, onHoleTap: _editHole),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      key: const ValueKey('scorecard-new-round-btn'),
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

class _NewRoundDialog extends StatefulWidget {
  const _NewRoundDialog();

  @override
  State<_NewRoundDialog> createState() => _NewRoundDialogState();
}

class _NewRoundDialogState extends State<_NewRoundDialog> {
  final _controller = TextEditingController(text: 'Local Course');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    Navigator.pop(context, name.isEmpty ? 'Local Course' : name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start new round'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Course name'),
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _submit, child: const Text('Start')),
      ],
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.totals});

  final RoundTotals? totals;

  @override
  Widget build(BuildContext context) {
    if (totals == null) return const SizedBox.shrink();
    final t = totals!;
    return Card(
      key: const ValueKey('scorecard-summary-banner'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryCell(label: 'OUT', value: '${t.frontNineScore}', toPar: t.frontNineToPar),
                _SummaryCell(label: 'IN', value: '${t.backNineScore}', toPar: t.backNineToPar),
                _SummaryCell(label: 'TOT', value: '${t.totalScore}', toPar: t.totalToPar),
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
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.label, required this.value, required this.toPar});

  final String label;
  final String value;
  final int toPar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(value, style: GolfTextStyles.tabularNum(context, fontSize: 28)),
        Text(_toParLabel(toPar), style: _deltaStyle(context, toPar)),
      ],
    );
  }
}

class _NineGrid extends StatelessWidget {
  const _NineGrid({
    required this.title,
    required this.startHole,
    required this.holeRow,
    required this.onHoleTap,
  });

  final String title;
  final int startHole;
  final RoundScore? Function(int holeNumber) holeRow;
  final Future<void> Function(int holeNumber) onHoleTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        for (var row = 0; row < 3; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (col > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _HoleTile(
                      hole: startHole + row * 3 + col,
                      row: holeRow(startHole + row * 3 + col),
                      onTap: () => onHoleTap(startHole + row * 3 + col),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _HoleTile extends StatelessWidget {
  const _HoleTile({required this.hole, required this.row, required this.onTap});

  final int hole;
  final RoundScore? row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final played = row != null && isHolePlayed(row!);
    final conceded = row?.conceded == 1;
    final par = row?.par ?? 4;
    final total = row != null ? effectiveHoleScore(row!) : 0;
    final toPar = played ? total - par : null;

    Color? fill;
    if (conceded) {
      fill = scheme.surfaceContainerHigh;
    } else if (played && toPar != null && toPar < 0) {
      fill = scheme.primaryContainer;
    } else if (played && toPar != null && toPar > 0) {
      fill = scheme.errorContainer;
    }

    final bottom = conceded
        ? 'Gimme'
        : toPar == null
            ? '—'
            : _toParLabel(toPar);

    return Material(
      color: fill ?? scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: ValueKey('scorecard-hole-tile-$hole'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$hole', style: Theme.of(context).textTheme.titleSmall),
              Text(
                played ? '$total' : '—',
                style: GolfTextStyles.tabularNum(context, fontSize: 20),
              ),
              Text(
                bottom,
                style: conceded
                    ? Theme.of(context).textTheme.labelSmall
                    : (toPar == null ? Theme.of(context).textTheme.labelSmall : _deltaStyle(context, toPar)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _toParLabel(int toPar) {
  if (toPar == 0) return 'E';
  if (toPar > 0) return '+$toPar';
  return '$toPar';
}

TextStyle _deltaStyle(BuildContext context, int toPar) {
  if (toPar < 0) return GolfTextStyles.scorePositive(context, fontSize: 12);
  if (toPar > 0) return GolfTextStyles.scoreNegative(context, fontSize: 12);
  return GolfTextStyles.tabularNum(context, fontSize: 12, fontWeight: FontWeight.w600);
}
