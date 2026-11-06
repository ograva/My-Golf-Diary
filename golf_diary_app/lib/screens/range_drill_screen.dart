import 'package:flutter/material.dart';

import '../models/golf_models.dart';
import '../services/local_database_service.dart';
import '../theme/app_theme.dart';

/// Resolves a drill block. Empty min or max copies [avg]. Returns null when
/// avg is missing or the three numbers are out of order.
DrillYardageInput? resolveDrillYardages({
  required String minText,
  required String avgText,
  required String maxText,
}) {
  final avg = double.tryParse(avgText.trim());
  if (avg == null || avg < 0) return null;

  double? optional(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  final minParsed = optional(minText);
  final maxParsed = optional(maxText);
  if (minText.trim().isNotEmpty && minParsed == null) return null;
  if (maxText.trim().isNotEmpty && maxParsed == null) return null;
  if (minParsed != null && minParsed < 0) return null;
  if (maxParsed != null && maxParsed < 0) return null;

  final min = minParsed ?? avg;
  final max = maxParsed ?? avg;
  if (min > avg || avg > max) return null;
  return DrillYardageInput(min: min, avg: avg, max: max);
}

class DrillYardageInput {
  const DrillYardageInput({required this.min, required this.avg, required this.max});

  final double min;
  final double avg;
  final double max;
}

class RangeDrillScreen extends StatefulWidget {
  const RangeDrillScreen({super.key});

  @override
  State<RangeDrillScreen> createState() => _RangeDrillScreenState();
}

class _RangeDrillScreenState extends State<RangeDrillScreen> {
  List<Club> _clubs = [];
  Club? _selectedClub;
  int _shotCounter = 0;
  bool _loading = true;
  bool _saving = false;

  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();
  final TextEditingController _avgController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final controller in [_minController, _avgController, _maxController]) {
      controller.addListener(_onFieldsChanged);
    }
    _loadClubs();
  }

  void _onFieldsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in [_minController, _avgController, _maxController]) {
      controller.removeListener(_onFieldsChanged);
      controller.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  DrillYardageInput? get _yardages => resolveDrillYardages(
        minText: _minController.text,
        avgText: _avgController.text,
        maxText: _maxController.text,
      );

  Future<void> _loadClubs() async {
    final clubs = await LocalDatabaseService.instance.getAllClubs();
    if (!mounted) return;
    setState(() {
      _clubs = clubs.where((c) => c.category != 'putter').toList();
      _loading = false;
      if (_clubs.isEmpty) {
        _selectedClub = null;
        return;
      }
      final currentId = _selectedClub?.id;
      final match = _clubs.where((c) => c.id == currentId);
      if (match.isNotEmpty) {
        _selectedClub = match.first;
      } else {
        _selectedClub = _clubs.first;
        _notesController.text = _selectedClub!.swingNotes;
      }
    });
  }

  Future<void> _saveDrillSet() async {
    final club = _selectedClub;
    final yards = _yardages;
    if (club == null || yards == null || _saving) return;

    setState(() => _saving = true);
    final log = RangeDrillLog(
      id: 'drill_${DateTime.now().millisecondsSinceEpoch}',
      clubId: club.id,
      shotCount: _shotCounter > 0 ? _shotCounter : 10,
      minYards: yards.min,
      maxYards: yards.max,
      avgYards: yards.avg,
      tempoNotes: _notesController.text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    try {
      await LocalDatabaseService.instance.saveRangeDrill(log);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved drill for ${club.name}. Bag avg updated.')),
      );
      setState(() {
        _shotCounter = 0;
        _saving = false;
      });
      _minController.clear();
      _maxController.clear();
      _avgController.clear();
      await _loadClubs();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t save this drill.')),
      );
    }
  }

  String _stat(double value) => value == 0 ? '—' : '${value.round()}';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final club = _selectedClub;
    final orderError = _yardages == null && _avgController.text.trim().isNotEmpty
        ? 'Min, average, and max must be numbers in order'
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Range')),
      body: club == null
          ? const Center(
              child: Text(
                'Add clubs to the bag before a drill.',
                key: ValueKey('range-empty-clubs'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('CLUB', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _clubs.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          key: ValueKey('range-club-chip-${item.id}'),
                          label: Text(item.name),
                          selected: club.id == item.id,
                          onSelected: (_) {
                            setState(() {
                              _selectedClub = item;
                              _notesController.text = item.swingNotes;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  key: const ValueKey('range-bag-baseline'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(club.name, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Bag now', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Text(
                          'MIN ${_stat(club.minDistance)}   AVG ${_stat(club.avgDistance)}   MAX ${_stat(club.maxDistance)}',
                          style: GolfTextStyles.yardage(context, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('range-tempo-field'),
                  controller: _notesController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Tempo for this drill',
                    helperText: 'A note here updates this club’s swing cue.',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '$_shotCounter / 10',
                  key: const ValueKey('range-shot-counter'),
                  textAlign: TextAlign.center,
                  style: GolfTextStyles.tabularNum(context, fontSize: 36),
                ),
                Text(
                  'Balls in this block. Leaving this at 0 saves the block as 10 balls.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                FilledButton.tonal(
                  key: const ValueKey('range-shot-counter-increment'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
                  onPressed: _shotCounter >= 10 ? null : () => setState(() => _shotCounter++),
                  child: const Text('Hit'),
                ),
                const SizedBox(height: 24),
                Text('This block (yds)', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('range-min-field'),
                  controller: _minController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Min',
                    suffixText: 'yds',
                    hintText: club.minDistance == 0 ? null : '${club.minDistance.round()}',
                    helperText: 'Empty min or max uses the average.',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('range-avg-field'),
                  controller: _avgController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Avg',
                    suffixText: 'yds',
                    hintText: club.avgDistance == 0 ? null : '${club.avgDistance.round()}',
                    errorText: orderError,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('range-max-field'),
                  controller: _maxController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Max',
                    suffixText: 'yds',
                    hintText: club.maxDistance == 0 ? null : '${club.maxDistance.round()}',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const ValueKey('range-save-drill-btn'),
                  onPressed: _yardages == null || _saving ? null : _saveDrillSet,
                  child: Text(_saving ? 'Saving…' : 'Save drill'),
                ),
              ],
            ),
    );
  }
}
