import 'package:flutter/material.dart';

import '../models/golf_models.dart';
import '../services/local_database_service.dart';
import '../theme/app_theme.dart';

class RangeDrillScreen extends StatefulWidget {
  const RangeDrillScreen({super.key});

  @override
  State<RangeDrillScreen> createState() => RangeDrillScreenState();
}

class RangeDrillScreenState extends State<RangeDrillScreen> {
  List<Club> _clubs = [];
  List<RangeDrillSummary> _log = [];
  Club? _selectedClub;
  int _shotCounter = 0;

  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();
  final TextEditingController _avgController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _avgController.dispose();
    _notesController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> reload() async {
    final clubs = await LocalDatabaseService.instance.getAllClubs();
    final log = await LocalDatabaseService.instance.listRangeDrills();
    if (!mounted) return;
    setState(() {
      _clubs = clubs.where((c) => c.category != 'putter').toList();
      _log = log;
      if (_selectedClub == null && _clubs.isNotEmpty) {
        _selectedClub = _clubs.first;
        _notesController.text = _selectedClub!.swingNotes;
      } else if (_selectedClub != null && !_clubs.any((c) => c.id == _selectedClub!.id)) {
        _selectedClub = _clubs.isNotEmpty ? _clubs.first : null;
      }
    });
  }

  Future<void> _saveDrillSet() async {
    if (_selectedClub == null) return;

    final log = RangeDrillLog(
      id: 'drill_${DateTime.now().millisecondsSinceEpoch}',
      clubId: _selectedClub!.id,
      shotCount: _shotCounter > 0 ? _shotCounter : 10,
      minYards: double.tryParse(_minController.text) ?? 0.0,
      maxYards: double.tryParse(_maxController.text) ?? 0.0,
      avgYards: double.tryParse(_avgController.text) ?? 0.0,
      tempoNotes: _notesController.text,
      venueName: _venueController.text.trim(),
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await LocalDatabaseService.instance.saveRangeDrill(log);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved drill for ${_selectedClub!.name}!'),
          backgroundColor: AppColors.green,
        ),
      );
      setState(() => _shotCounter = 0);
      _minController.clear();
      _maxController.clear();
      _avgController.clear();
      await reload();
    }
  }

  String _formatWhen(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.month}/${date.day}/${date.year} $hour:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Range Drill Instructor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _venueController,
              decoration: const InputDecoration(
                labelText: 'Driving range or simulator',
                hintText: 'Topgolf, local range, sim bay…',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Text('Select club', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _clubs.map((club) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(club.name),
                      selected: _selectedClub?.id == club.id,
                      onSelected: (_) {
                        setState(() {
                          _selectedClub = club;
                          _notesController.text = club.swingNotes;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: AppColors.amber.withOpacity(0.15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppColors.amber),
                        SizedBox(width: 8),
                        Text('Swing Cue & Mechanics Note', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText: 'e.g., 3:1 tempo, pause at top, smooth transition',
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shots: $_shotCounter / 10',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _shotCounter >= 10
                      ? null
                      : () => setState(() => _shotCounter++),
                  icon: const Icon(Icons.sports_golf),
                  label: const Text('Hit Shot'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(140, 56)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Min (Yds)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _avgController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Avg (Yds)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Max (Yds)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 72,
              child: ElevatedButton(
                onPressed: _saveDrillSet,
                child: const Text('Save Drill Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Session log', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_log.isEmpty)
              const Text('Saved drills show up here, newest first.')
            else
              ..._log.map((entry) {
                final drill = entry.drill;
                final venue = drill.venueName.isEmpty ? 'Unnamed venue' : drill.venueName;
                final notes = drill.tempoNotes.trim();
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text('${entry.clubName} · $venue'),
                    subtitle: Text(
                      '${_formatWhen(drill.timestamp)}\n'
                      '${drill.shotCount} shots · min ${drill.minYards.round()} · '
                      'avg ${drill.avgYards.round()} · max ${drill.maxYards.round()}'
                      '${notes.isEmpty ? '' : '\n$notes'}',
                    ),
                    isThreeLine: true,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
