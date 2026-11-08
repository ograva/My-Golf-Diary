import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/ph_golf_catalog.dart';
import '../models/golf_models.dart';
import '../services/local_database_service.dart';
import '../widgets/sync_cloud_button.dart';
import '../widgets/venue_name_field.dart';
import '../theme/app_theme.dart';

class FairwayTrackerScreen extends StatefulWidget {
  const FairwayTrackerScreen({super.key});

  @override
  State<FairwayTrackerScreen> createState() => FairwayTrackerScreenState();
}

class FairwayTrackerScreenState extends State<FairwayTrackerScreen> {
  static const _lies = [
    'tee',
    'fairway',
    'rough',
    'bunker',
    'green',
    'penalty'
  ];

  final _courseController = TextEditingController(text: 'Local Course');
  final _yardsController = TextEditingController();
  final _courseFocus = FocusNode();

  List<Club> _clubs = [];
  String? _roundId;
  int _holeNumber = 1;
  int _maxHole = 1;
  int _holeCount = 18;
  int _par = 4;
  String _appliedCourseName = 'Local Course';
  List<String> _recentCourses = [];
  Club? _selectedClub;
  String _lieType = 'tee';
  RoundScore? _holeScore;
  List<ShotRecord> _shots = [];
  int _roundTotal = 0;
  bool _busy = false;
  bool _courseReady = false;
  bool _simulator = false;
  String? _yardsError;

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
    _yardsController.dispose();
    super.dispose();
  }

  void _onCourseFocus() {
    if (!_courseFocus.hasFocus) {
      _persistCourseName();
    }
  }

  Future<void> _bootstrap() async {
    _clubs = await LocalDatabaseService.instance.getAllClubs();
    _recentCourses = await LocalDatabaseService.instance.distinctCourseNames();
    _roundId = await LocalDatabaseService.instance.ensureActiveRound(
      courseName: _courseController.text.trim().isEmpty
          ? 'Local Course'
          : _courseController.text.trim(),
    );
    await _loadCourseName();
    _courseReady = true;
    await _restoreHole();
    await _refreshHoleState();
  }

  Future<void> _loadCourseName() async {
    if (_roundId == null) return;
    final name =
        await LocalDatabaseService.instance.getCourseNameForRound(_roundId!);
    if (!mounted || name.isEmpty) return;
    _courseController.text = name;
    _appliedCourseName = name;
    _holeCount = PhGolfCatalog.holeCount(name);
  }

  Future<void> _persistCourseName() async {
    if (!_courseReady) return;
    final roundId = _roundId;
    final name = _courseController.text.trim();
    if (roundId == null || name.isEmpty) return;
    if (name == _appliedCourseName) return;
    _appliedCourseName = name;
    await LocalDatabaseService.instance.applyCoursePar(roundId, name);
    if (!mounted) return;
    setState(() => _holeCount = PhGolfCatalog.holeCount(name));
    await _refreshHoleState();
  }

  /// Follows the latest in-progress round, including one started from the scorecard.
  Future<void> reloadActiveRound() async {
    final active = await LocalDatabaseService.instance.getActiveRoundId();
    if (!mounted || active == null) return;
    _roundId = active;
    _clubs = await LocalDatabaseService.instance.getAllClubs();
    _recentCourses = await LocalDatabaseService.instance.distinctCourseNames();
    await _loadCourseName();
    _courseReady = true;
    await _restoreHole();
    await _refreshHoleState();
  }

  Future<void> _restoreHole() async {
    if (_roundId == null) return;
    final hole =
        await LocalDatabaseService.instance.currentHoleNumber(_roundId!);
    if (!mounted) return;
    setState(() {
      _maxHole = hole;
      _holeNumber = hole;
      _lieType = 'tee';
    });
  }

  Future<void> _stepHole(int delta) async {
    final next = _holeNumber + delta;
    if (next < 1 || next > _maxHole) return;
    setState(() {
      _holeNumber = next;
      _lieType = 'tee';
    });
    await _refreshHoleState();
  }

  String _clubName(String clubId) {
    for (final club in _clubs) {
      if (club.id == clubId) return club.name;
    }
    return clubId;
  }

  Future<void> _editShot(ShotRecord shot) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) =>
          ShotEditDialog(shot: shot, clubs: _clubs, lies: _lies),
    );
    if (saved == true) await _refreshHoleState();
  }

  Future<void> _refreshHoleState() async {
    if (_roundId == null) return;
    final hole = await LocalDatabaseService.instance
        .getHoleScore(_roundId!, _holeNumber);
    final shots = await LocalDatabaseService.instance
        .getShotsForHole(_roundId!, _holeNumber);
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
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Location permission is required for shot tracking')),
        );
      }
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  double? _typedYards() {
    final parsed = double.tryParse(_yardsController.text.trim());
    if (parsed == null || parsed <= 0) {
      setState(() => _yardsError = 'Enter a distance greater than 0');
      return null;
    }
    setState(() => _yardsError = null);
    return parsed.roundToDouble();
  }

  Future<void> _recordShot() async {
    if (_busy) return;
    final typedYards = _simulator ? _typedYards() : null;
    if (_simulator && typedYards == null) return;
    if (_roundId == null || _selectedClub == null) return;

    setState(() => _busy = true);
    try {
      if (_simulator) {
        await LocalDatabaseService.instance.recordFairwayHit(
          roundId: _roundId!,
          holeNumber: _holeNumber,
          clubId: _selectedClub!.id,
          lieType: _lieType,
          currentLat: 0,
          currentLon: 0,
          distanceYards: typedYards,
        );
        _yardsController.clear();
      } else {
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
      }
      await _refreshHoleState();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishHole() async {
    if (_roundId == null) return;
    final holeCount = _holeCount;
    final finishingRound = _holeNumber >= holeCount;
    final nextPar =
        PhGolfCatalog.parForHole(_courseController.text, _holeNumber + 1) ?? 4;
    await LocalDatabaseService.instance.finishHole(
      roundId: _roundId!,
      holeNumber: _holeNumber,
      nextPar: nextPar,
      holeCount: holeCount,
    );
    if (_holeNumber < holeCount) {
      setState(() {
        _holeNumber += 1;
        _maxHole = _holeNumber;
        _lieType = 'tee';
      });
    }
    await _refreshHoleState();
    if (finishingRound && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Round saved on this device'),
          backgroundColor: AppColors.green,
        ),
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
          const SyncCloudButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VenueNameField(
              controller: _courseController,
              focusNode: _courseFocus,
              labelText: 'Course name',
              recentNames: _recentCourses,
              catalogNames: PhGolfCatalog.courseNames,
              captionFor: PhGolfCatalog.courseCaption,
              onSelected: (_) => _persistCourseName(),
              onSubmitted: (_) => _persistCourseName(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Course'),
                  selected: !_simulator,
                  onSelected: (_) => setState(() {
                    _simulator = false;
                    _yardsError = null;
                  }),
                ),
                ChoiceChip(
                  label: const Text('Simulator'),
                  selected: _simulator,
                  onSelected: (_) => setState(() => _simulator = true),
                ),
              ],
            ),
            if (_simulator) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _yardsController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Distance travelled (yds)',
                  errorText: _yardsError,
                ),
                onChanged: (_) {
                  if (_yardsError != null) setState(() => _yardsError = null);
                },
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  key: const Key('on-course-hole-previous'),
                  tooltip: 'Previous hole',
                  onPressed: _holeNumber > 1 ? () => _stepHole(-1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Hole $_holeNumber',
                    key: const Key('on-course-hole-label'),
                    style: Theme.of(context).textTheme.headlineSmall),
                IconButton(
                  key: const Key('on-course-hole-next'),
                  tooltip: 'Next hole',
                  onPressed: _holeNumber < _maxHole ? () => _stepHole(1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
                const Spacer(),
                Text('Round total: $_roundTotal',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
                'Par $_par · Strokes $strokes · Penalties $penalties · Score $holeScore'),
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
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                child: _busy
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _simulator ? 'Record shot' : 'Record Shot at Ball',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
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
                    onPressed: _roundId == null
                        ? null
                        : () => LocalDatabaseService.instance
                            .incrementMulligans(_roundId!, _holeNumber)
                            .then((_) => _refreshHoleState()),
                    child: Text('Mulligans ${_holeScore?.mulligans ?? 0}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _roundId == null
                        ? null
                        : () => LocalDatabaseService.instance
                            .concedeHole(_roundId!, _holeNumber)
                            .then((_) => _refreshHoleState()),
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
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: Colors.black87),
                child: Text(
                  _holeNumber >= _holeCount ? 'Finish Round' : 'Finish Hole',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (_shots.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Shots this hole',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._shots.map(
                (s) => ListTile(
                  key: ValueKey('on-course-shot-${s.id}'),
                  dense: true,
                  onTap: () => _editShot(s),
                  title: Text(
                      'Stroke ${s.strokeNumber} · ${s.lieType} · ${_clubName(s.clubId)}'),
                  subtitle: Text(
                    s.distanceYards > 0
                        ? '${s.distanceYards.round()} yds'
                        : 'Distance pending',
                  ),
                  trailing: const Icon(Icons.edit_outlined),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

@visibleForTesting
class ShotEditDialog extends StatefulWidget {
  const ShotEditDialog(
      {super.key, required this.shot, required this.clubs, required this.lies});

  final ShotRecord shot;
  final List<Club> clubs;
  final List<String> lies;

  @override
  State<ShotEditDialog> createState() => _ShotEditDialogState();
}

class _ShotEditDialogState extends State<ShotEditDialog> {
  late String _lie = widget.shot.lieType;
  late String _clubId = widget.shot.clubId;

  Future<void> _save() async {
    await LocalDatabaseService.instance.updateShotDetails(
      shotId: widget.shot.id,
      clubId: _clubId,
      lieType: _lie,
    );
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    await LocalDatabaseService.instance.deleteShot(widget.shot);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final clubs = widget.clubs.any((club) => club.id == _clubId)
        ? widget.clubs
        : [
            ...widget.clubs,
            Club(id: _clubId, name: _clubId, category: 'other')
          ];
    return AlertDialog(
      title: Text('Stroke ${widget.shot.strokeNumber}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _clubId,
              decoration: const InputDecoration(labelText: 'Club'),
              items: clubs
                  .map((club) =>
                      DropdownMenuItem(value: club.id, child: Text(club.name)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _clubId = value);
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: widget.lies.map((lie) {
                final label = lie[0].toUpperCase() + lie.substring(1);
                return ChoiceChip(
                  label: Text(label),
                  selected: _lie == lie,
                  onSelected: (_) => setState(() => _lie = lie),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('on-course-shot-delete'),
          onPressed: _delete,
          style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error),
          child: const Text('Delete shot'),
        ),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          key: const Key('on-course-shot-save'),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
