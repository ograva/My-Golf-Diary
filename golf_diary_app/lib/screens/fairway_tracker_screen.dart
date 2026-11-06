import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/golf_models.dart';
import '../services/cloud_sync_service.dart';
import '../services/local_database_service.dart';
import '../theme/app_theme.dart';

class FairwayTrackerScreen extends StatefulWidget {
  const FairwayTrackerScreen({super.key});

  @override
  State<FairwayTrackerScreen> createState() => _FairwayTrackerScreenState();
}

class _FairwayTrackerScreenState extends State<FairwayTrackerScreen> {
  static const _lies = ['tee', 'fairway', 'rough', 'bunker', 'green', 'penalty'];

  final _courseController = TextEditingController(text: 'Local Course');

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
  bool _editingCourse = false;
  bool _locationDenied = false;
  bool _bootstrapFailed = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      _clubs = await LocalDatabaseService.instance.getAllClubs();
      _roundId = await LocalDatabaseService.instance.ensureActiveRound(
        courseName: _courseController.text.trim(),
      );
      final stored = await LocalDatabaseService.instance.getCourseNameForRound(_roundId!);
      _courseController.text = stored;
      if (mounted) setState(() => _bootstrapFailed = false);
      await _refreshHoleState();
    } catch (_) {
      if (mounted) setState(() => _bootstrapFailed = true);
    }
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

  Future<void> _commitCourseName() async {
    final name = _courseController.text.trim().isEmpty ? 'Local Course' : _courseController.text.trim();
    _courseController.text = name;
    setState(() => _editingCourse = false);
    if (_roundId != null) {
      await LocalDatabaseService.instance.updateRoundCourseName(_roundId!, name);
    }
  }

  String _clubName(String id) {
    for (final club in _clubs) {
      if (club.id == id) return club.name;
    }
    return id;
  }

  String _label(String value) => value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  Future<Position?> _readGps() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    final denied = permission == LocationPermission.denied || permission == LocationPermission.deniedForever;
    if (mounted) setState(() => _locationDenied = denied);
    if (denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required for shot tracking')),
        );
      }
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn’t read location. Shot not saved.')),
        );
      }
      return null;
    }
  }

  Future<void> _openLocationSettings() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    } else {
      await Geolocator.requestPermission();
    }
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
    final finishedRound = _holeNumber >= 18;
    if (!finishedRound) {
      setState(() {
        _holeNumber += 1;
        _lieType = 'tee';
      });
    }
    await _refreshHoleState();
    if (finishedRound && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Round saved on this device')),
      );
    }
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
    final conceded = _holeScore?.conceded == 1;
    final scheme = Theme.of(context).colorScheme;
    final selected = _selectedClub;
    final clubHeader = selected == null
        ? 'CLUB'
        : selected.avgDistance > 0
            ? '${selected.name} · ${selected.avgDistance.round()} yds'
            : selected.name;

    return Scaffold(
      appBar: AppBar(
        title: const Text('On Course'),
        actions: [
          IconButton(
            key: const ValueKey('oncourse-sync-btn'),
            onPressed: _sync,
            icon: const Icon(Icons.cloud_upload_outlined),
            tooltip: 'Sync',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _bootstrapFailed ? _bootstrap : _refreshHoleState,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  if (_bootstrapFailed)
                    Card(
                      child: ListTile(
                        title: const Text('Couldn’t start the round. Pull to retry.'),
                        trailing: TextButton(onPressed: _bootstrap, child: const Text('Retry')),
                      ),
                    ),
                  if (_locationDenied)
                    Card(
                      key: const ValueKey('oncourse-location-banner'),
                      color: scheme.errorContainer,
                      child: ListTile(
                        title: Text(
                          'Location is off for shot tracking.',
                          style: TextStyle(color: scheme.onErrorContainer),
                        ),
                        trailing: TextButton(
                          onPressed: _openLocationSettings,
                          child: const Text('Open settings'),
                        ),
                      ),
                    ),
                  if (_editingCourse)
                    TextField(
                      key: const ValueKey('oncourse-course-name-field'),
                      controller: _courseController,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Course name'),
                      onSubmitted: (_) => _commitCourseName(),
                      onEditingComplete: _commitCourseName,
                    )
                  else
                    InkWell(
                      key: const ValueKey('oncourse-course-name-field'),
                      onTap: () => setState(() => _editingCourse = true),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _courseController.text,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Icon(Icons.edit_outlined, color: scheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Hole $_holeNumber', style: Theme.of(context).textTheme.headlineSmall),
                              Text('Par $_par', style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          if (conceded)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text('Gimme', style: Theme.of(context).textTheme.labelLarge),
                            ),
                          const SizedBox(height: 8),
                          Text('Strokes $strokes · Penalties $penalties'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Hole $holeScore', style: GolfTextStyles.tabularNum(context, fontSize: 18)),
                              Text('Round $_roundTotal', style: GolfTextStyles.tabularNum(context, fontSize: 18)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('PAR', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [3, 4, 5].map((p) {
                      return ChoiceChip(
                        key: ValueKey('oncourse-par-chip-$p'),
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
                  Text(clubHeader, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _clubs.map((club) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            key: ValueKey('oncourse-club-chip-${club.id}'),
                            label: Text(club.name),
                            selected: _selectedClub?.id == club.id,
                            onSelected: (_) => setState(() => _selectedClub = club),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('LIE', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _lies.map((lie) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            key: ValueKey('oncourse-lie-chip-$lie'),
                            label: Text(_label(lie)),
                            selected: _lieType == lie,
                            onSelected: (_) => setState(() => _lieType = lie),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (_shots.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Shots this hole', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ..._shots.map(
                      (s) => ListTile(
                        key: ValueKey('oncourse-shot-row-${s.strokeNumber}'),
                        title: Text('Stroke ${s.strokeNumber} · ${_label(s.lieType)} · ${_clubName(s.clubId)}'),
                        subtitle: Text(
                          s.distanceYards > 0 ? '${s.distanceYards.round()} yds' : 'Distance pending',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey('oncourse-penalty-1-btn'),
                          onPressed: _roundId == null
                              ? null
                              : () => LocalDatabaseService.instance
                                  .incrementPenalties(_roundId!, _holeNumber, 1)
                                  .then((_) => _refreshHoleState()),
                          child: const Text('Penalty +1'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey('oncourse-penalty-2-btn'),
                          onPressed: _roundId == null
                              ? null
                              : () => LocalDatabaseService.instance
                                  .incrementPenalties(_roundId!, _holeNumber, 2)
                                  .then((_) => _refreshHoleState()),
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
                          key: const ValueKey('oncourse-mulligan-btn'),
                          onPressed: _roundId == null
                              ? null
                              : () => LocalDatabaseService.instance
                                  .incrementMulligans(_roundId!, _holeNumber)
                                  .then((_) => _refreshHoleState()),
                          child: Text('Mulligan ${_holeScore?.mulligans ?? 0}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey('oncourse-concede-btn'),
                          onPressed: _roundId == null
                              ? null
                              : () => LocalDatabaseService.instance
                                  .concedeHole(_roundId!, _holeNumber)
                                  .then((_) => _refreshHoleState()),
                          child: const Text('Concede'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: const ValueKey('oncourse-finish-hole-btn'),
                    onPressed: _roundId == null ? null : _finishHole,
                    child: Text(_holeNumber >= 18 ? 'Finish round' : 'Finish hole'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: FilledButton(
            key: const ValueKey('oncourse-record-shot-btn'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
            onPressed: (_busy || _roundId == null || _selectedClub == null) ? null : _recordShot,
            child: _busy
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
                  )
                : const Text('Record shot at ball'),
          ),
        ),
      ),
    );
  }
}
