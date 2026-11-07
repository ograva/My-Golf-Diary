import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/golf_models.dart';
import '../services/cloud_sync_service.dart';
import '../services/local_database_service.dart';
import '../theme/app_theme.dart';

class FairwayTrackerScreen extends StatefulWidget {
  const FairwayTrackerScreen({super.key});

  @override
  State<FairwayTrackerScreen> createState() => FairwayTrackerScreenState();
}

class FairwayTrackerScreenState extends State<FairwayTrackerScreen> {
  static const _lies = ['tee', 'fairway', 'rough', 'bunker', 'green', 'penalty'];

  final _courseController = TextEditingController(text: 'Local Course');
  final _courseFocus = FocusNode();

  List<Club> _clubs = [];
  String? _roundId;
  int _holeNumber = 1;
  int _par = 4;
  Club? _selectedClub;
  String _lieType = 'tee';
  RoundScore? _holeScore;
  List<ShotRecord> _shots = [];
  int _roundTotal = 0;
  bool _busy = false;
  bool _courseReady = false;

  @override
  void initState() {
    super.initState();
    _courseFocus.addListener(_onCourseFocus);
    _bootstrap();
  }

  @override
  void dispose() {
    _courseFocus.removeListener(_onCourseFocus);
    _persistCourseName();
    _courseFocus.dispose();
    _courseController.dispose();
    super.dispose();
  }

  void _onCourseFocus() {
    if (!_courseFocus.hasFocus) {
      _persistCourseName();
    }
  }

  Future<void> _bootstrap() async {
    _clubs = await LocalDatabaseService.instance.getAllClubs();
    _roundId = await LocalDatabaseService.instance.ensureActiveRound(
      courseName: _courseController.text.trim().isEmpty ? 'Local Course' : _courseController.text.trim(),
    );
    await _loadCourseName();
    _courseReady = true;
    await _refreshHoleState();
  }

  Future<void> _loadCourseName() async {
    if (_roundId == null) return;
    final name = await LocalDatabaseService.instance.getCourseNameForRound(_roundId!);
    if (!mounted || name.isEmpty) return;
    _courseController.text = name;
  }

  Future<void> _persistCourseName() async {
    if (!_courseReady) return;
    final roundId = _roundId;
    final name = _courseController.text.trim();
    if (roundId == null || name.isEmpty) return;
    await LocalDatabaseService.instance.updateCourseName(roundId, name);
  }

  /// Follows the latest in-progress round, including one started from the scorecard.
  Future<void> reloadActiveRound() async {
    final active = await LocalDatabaseService.instance.getActiveRoundId();
    if (!mounted || active == null) return;
    final changed = active != _roundId;
    _roundId = active;
    if (changed) {
      _holeNumber = 1;
      _lieType = 'tee';
      _par = 4;
    }
    _clubs = await LocalDatabaseService.instance.getAllClubs();
    await _loadCourseName();
    _courseReady = true;
    await _refreshHoleState();
  }

  Future<void> _refreshHoleState() async {
    if (_roundId == null) return;
    final hole = await LocalDatabaseService.instance.getHoleScore(_roundId!, _holeNumber);
    final shots = await LocalDatabaseService.instance.getShotsForHole(_roundId!, _holeNumber);
    final total = await LocalDatabaseService.instance.getRoundTotal(_roundId!);
    if (!mounted) return;
    setState(() {
      _holeScore = hole;
      _shots = shots;
      _roundTotal = total;
      if (_selectedClub == null && _clubs.isNotEmpty) {
        _selectedClub = _clubs.first;
      }
      if (hole != null) {
        _par = hole.par;
      }
    });
  }

  Future<Position?> _readGps() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required for shot tracking')),
        );
      }
      return null;
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _recordShot() async {
    if (_roundId == null || _selectedClub == null || _busy) return;
    setState(() => _busy = true);
    try {
      final position = await _readGps();
      if (position == null) return;

      await LocalDatabaseService.instance.recordFairwayHit(
        roundId: _roundId!,
        holeNumber: _holeNumber,
        clubId: _selectedClub!.id,
        lieType: _lieType,
        currentLat: position.latitude,
        currentLon: position.longitude,
      );
      await _refreshHoleState();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishHole() async {
    if (_roundId == null) return;
    await LocalDatabaseService.instance.finishHole(
      roundId: _roundId!,
      holeNumber: _holeNumber,
      nextPar: 4,
    );
    if (_holeNumber < 18) {
      setState(() {
        _holeNumber += 1;
        _lieType = 'tee';
      });
    }
    await _refreshHoleState();
  }

  Future<void> _sync() async {
    const userId = 'local_user';
    final sync = CloudSyncService(userId: userId);
    if (!sync.isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Firebase not configured — local data is saved on device')),
        );
      }
      return;
    }
    final count = await sync.syncAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Synced $count records to cloud')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strokes = _holeScore?.strokes ?? _shots.length;
    final penalties = _holeScore?.penalties ?? 0;
    final holeScore = computeFinalScore(strokes: strokes, penalties: penalties);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fairway HUD'),
        actions: [
          IconButton(onPressed: _sync, icon: const Icon(Icons.cloud_upload_outlined), tooltip: 'Sync'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _courseController,
              focusNode: _courseFocus,
              decoration: const InputDecoration(
                labelText: 'Course name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _persistCourseName(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hole $_holeNumber', style: Theme.of(context).textTheme.headlineSmall),
                Text('Round total: $_roundTotal', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Par $_par · Strokes $strokes · Penalties $penalties · Score $holeScore'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [3, 4, 5].map((p) {
                return ChoiceChip(
                  label: Text('Par $p'),
                  selected: _par == p,
                  onSelected: (_) async {
                    setState(() => _par = p);
                    if (_roundId != null && _holeScore != null) {
                      await LocalDatabaseService.instance.upsertHoleScore(
                        _holeScore!.copyWith(par: p, isSynced: 0),
                      );
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Club', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      onSelected: (_) => setState(() => _selectedClub = club),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Lie', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _lies.map((lie) {
                  final label = lie[0].toUpperCase() + lie.substring(1);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _lieType == lie,
                      onSelected: (_) => setState(() => _lieType = lie),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 80,
              child: ElevatedButton(
                onPressed: _busy ? null : _recordShot,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                child: _busy
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Record Shot at Ball', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _roundId == null
                        ? null
                        : () => LocalDatabaseService.instance.incrementPenalties(_roundId!, _holeNumber, 1).then((_) => _refreshHoleState()),
                    child: const Text('Penalty +1'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _roundId == null
                        ? null
                        : () => LocalDatabaseService.instance.incrementPenalties(_roundId!, _holeNumber, 2).then((_) => _refreshHoleState()),
                    child: const Text('Penalty +2'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _roundId == null
                        ? null
                        : () => LocalDatabaseService.instance.incrementMulligans(_roundId!, _holeNumber).then((_) => _refreshHoleState()),
                    child: Text('Mulligans ${_holeScore?.mulligans ?? 0}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _roundId == null
                        ? null
                        : () => LocalDatabaseService.instance.concedeHole(_roundId!, _holeNumber).then((_) => _refreshHoleState()),
                    child: const Text('Concede / Gimme'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 72,
              child: ElevatedButton(
                onPressed: _finishHole,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: Colors.black87),
                child: Text(
                  _holeNumber >= 18 ? 'Finish Round' : 'Finish Hole',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (_shots.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Shots this hole', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._shots.map(
                (s) => ListTile(
                  dense: true,
                  title: Text('Stroke ${s.strokeNumber} · ${s.lieType} · ${s.clubId}'),
                  subtitle: Text(
                    s.distanceYards > 0 ? '${s.distanceYards.round()} yds' : 'Distance pending',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
