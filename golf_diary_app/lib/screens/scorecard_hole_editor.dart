import 'package:flutter/material.dart';

import '../models/golf_models.dart';
import '../services/local_database_service.dart';
import '../theme/app_theme.dart';

Future<void> showScorecardHoleEditor({
  required BuildContext context,
  required String roundId,
  required String courseName,
  required int holeNumber,
  RoundScore? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _HoleEditorSheet(
        roundId: roundId,
        courseName: courseName,
        holeNumber: holeNumber,
        existing: existing,
      ),
    ),
  );
}

class _HoleEditorSheet extends StatefulWidget {
  const _HoleEditorSheet({
    required this.roundId,
    required this.courseName,
    required this.holeNumber,
    required this.existing,
  });

  final String roundId;
  final String courseName;
  final int holeNumber;
  final RoundScore? existing;

  @override
  State<_HoleEditorSheet> createState() => _HoleEditorSheetState();
}

class _HoleEditorSheetState extends State<_HoleEditorSheet> {
  late int _par;
  late int _strokes;
  late int _penalties;
  late int _mulligans;
  late bool _holeComplete;
  late bool _conceded;

  @override
  void initState() {
    super.initState();
    final row = widget.existing;
    _par = row?.par ?? 4;
    _strokes = row?.strokes ?? 0;
    if (row != null && row.conceded == 1) {
      _strokes = row.par * 2;
    }
    _penalties = row?.penalties ?? 0;
    _mulligans = row?.mulligans ?? 0;
    _conceded = row?.conceded == 1;
    _holeComplete = row != null && (row.finalScore > 0 || _conceded);
  }

  int get _previewTotal => computeFinalScore(strokes: _strokes, penalties: _penalties);

  Future<void> _save() async {
    await LocalDatabaseService.instance.saveManualHoleScore(
      roundId: widget.roundId,
      courseName: widget.courseName,
      holeNumber: widget.holeNumber,
      par: _par,
      strokes: _strokes,
      penalties: _penalties,
      holeComplete: _holeComplete,
      conceded: _conceded,
      mulligans: _mulligans,
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _adjustStrokes(int delta) {
    setState(() {
      _conceded = false;
      _strokes = (_strokes + delta).clamp(0, 20);
    });
  }

  void _adjustPenalties(int delta) {
    setState(() => _penalties = (_penalties + delta).clamp(0, 10));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hole ${widget.holeNumber}',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            Text(
              'Manual score entry',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            const Text('Par', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [3, 4, 5].map((p) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text('$p'),
                      selected: _par == p,
                      onSelected: (_) => setState(() => _par = p),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            _CounterRow(
              label: 'Strokes',
              value: _strokes,
              onDecrement: () => _adjustStrokes(-1),
              onIncrement: () => _adjustStrokes(1),
            ),
            const SizedBox(height: 12),
            _CounterRow(
              label: 'Penalties',
              value: _penalties,
              onDecrement: () => _adjustPenalties(-1),
              onIncrement: () => _adjustPenalties(1),
            ),
            const SizedBox(height: 12),
            _CounterRow(
              label: 'Mulligans (practice)',
              value: _mulligans,
              onDecrement: () => setState(() => _mulligans = (_mulligans - 1).clamp(0, 20)),
              onIncrement: () => setState(() => _mulligans = (_mulligans + 1).clamp(0, 20)),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Concede / gimme (2× par)'),
              value: _conceded,
              onChanged: (v) {
                setState(() {
                  _conceded = v;
                  if (v) {
                    _strokes = _par * 2;
                    _holeComplete = true;
                  }
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mark hole complete'),
              subtitle: Text('Locks score on card ($_previewTotal gross)'),
              value: _holeComplete,
              onChanged: _conceded
                  ? null
                  : (v) => setState(() => _holeComplete = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 64,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(
                  'Save hole ${widget.holeNumber}',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
        IconButton.filled(
          onPressed: value > 0 ? onDecrement : null,
          icon: const Icon(Icons.remove),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(56, 56),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton.filled(
          onPressed: onIncrement,
          icon: const Icon(Icons.add),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(56, 56),
          ),
        ),
      ],
    );
  }
}
