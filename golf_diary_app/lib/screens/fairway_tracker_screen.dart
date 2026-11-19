import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/ph_golf_catalog.dart';
import '../data/ph_golf_hole_coords.dart';
import '../models/diary_context_note.dart';
import '../on_course/fwy_aim.dart';
import '../on_course/hole_projection.dart';
import '../on_course/on_course_aim.dart';
import '../on_course/on_course_hud_gating.dart';
import '../on_course/on_course_shot_segment.dart';
import '../models/golf_models.dart';
import '../services/diary_model.dart';
import '../services/hole_map_pack_source.dart';
import '../services/local_database_service.dart';
import '../services/on_course_settings.dart';
import '../services/pin_distance.dart';
import '../widgets/account_avatar_app_bar_menu.dart';
import '../widgets/diary_launcher.dart';
import '../widgets/fwy_hole_map.dart';
import '../widgets/fwy_overlays.dart';
import '../widgets/shared_header_actions.dart';
import '../widgets/venue_name_field.dart';
import '../theme/app_theme.dart';

class FairwayTrackerScreen extends StatefulWidget {
  const FairwayTrackerScreen({
    super.key,
    this.pinDistance,
    this.diary,
    this.onProfileSettingsChanged,
    this.positionForShot,
  });

  /// When null, the screen uses [GeolocatorPinDistanceClient].
  final PinDistanceClient? pinDistance;

  /// When null, diary entry uses [VertexDiaryModel]. Tests pass a fake.
  final DiaryModel? diary;
  final VoidCallback? onProfileSettingsChanged;

  /// When set, Course-mode **Record shot at ball** uses this instead of
  /// [Geolocator.getCurrentPosition] (widget tests only).
  final Future<Position?> Function()? positionForShot;

  @override
  State<FairwayTrackerScreen> createState() => FairwayTrackerScreenState();
}

class FairwayTrackerScreenState extends State<FairwayTrackerScreen>
    with WidgetsBindingObserver {
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
  final _carryController = TextEditingController();
  final _distanceToHoleController = TextEditingController();
  final _strokeNoteController = TextEditingController();
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
  int? _yardsToPin;
  PinFix? _playerFix;
  bool _readingLocation = false;
  bool _screenVisible = true;
  int _pinToken = 0;
  String? _watchedKey;
  StreamSubscription<PinFix>? _pinSub;
  bool _locationPermissionBlocked = false;
  RailSide _railSide = RailSide.right;
  GpsMode _gpsMode = GpsMode.live;
  String? _fwyHoleKey;
  HoleMapPack? _pack;
  bool _packLoading = false;
  int _packToken = 0;
  PinFix? _manualPin;
  bool _manualPinStale = false;
  bool _aimMode = false;
  FwyAimTarget _aimTarget = const FwyAimTarget.pin();
  bool _doubleParDismissed = false;
  final Map<String, double> _typicalYards = {};
  bool _showSimCarry = false;
  bool _showSimToHole = false;
  bool _showSimNote = false;
  List<String> _recentClubIds = [];
  double _diaryEdgeDragDx = 0;

  PinDistanceClient get _pinDistance =>
      widget.pinDistance ?? GeolocatorPinDistanceClient();

  bool get _mappedHoleFeatures => onCourseMappedHoleFeatures(
        simulator: _simulator,
        courseName: _appliedCourseName,
        holeNumber: _holeNumber,
      );

  HoleCoordinates? get _activeCoords => activeHoleCoordinates(
        simulator: _simulator,
        courseName: _appliedCourseName,
        holeNumber: _holeNumber,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _courseFocus.addListener(_onCourseFocus);
    _bootstrap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible == _screenVisible) return;
    _screenVisible = visible;
    _syncPinWatch();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopPinWatch();
    } else if (state == AppLifecycleState.resumed) {
      _syncPinWatch();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPinWatch();
    _courseFocus.removeListener(_onCourseFocus);
    _persistCourseName();
    _courseFocus.dispose();
    _courseController.dispose();
    _yardsController.dispose();
    _carryController.dispose();
    _distanceToHoleController.dispose();
    _strokeNoteController.dispose();
    super.dispose();
  }

  void _stopPinWatch() {
    _pinToken++;
    _pinSub?.cancel();
    _pinSub = null;
    _watchedKey = null;
    _yardsToPin = null;
    _playerFix = null;
    _readingLocation = false;
  }

  /// Resets per-hole FWY state and loads the hole's map pack when the
  /// course or hole changes.
  void _syncFwyHole() {
    final key = '${_appliedCourseName.trim().toLowerCase()}#$_holeNumber';
    if (key == _fwyHoleKey) return;
    _fwyHoleKey = key;
    _manualPin = null;
    _manualPinStale = false;
    _aimMode = false;
    _aimTarget = const FwyAimTarget.pin();
    _doubleParDismissed = false;
    _pack = null;
    final token = ++_packToken;
    final coords = holeCoordinates(_appliedCourseName, _holeNumber);
    if (coords == null) {
      _packLoading = false;
      return;
    }
    _packLoading = true;
    final course = _appliedCourseName;
    final hole = _holeNumber;
    HoleMapPackSource.instance.loadHole(course, hole).then((pack) {
      if (!mounted || token != _packToken) return;
      setState(() {
        _pack = pack;
        _packLoading = false;
        _aimTarget = const FwyAimTarget.pin();
      });
    }, onError: (_) {
      if (!mounted || token != _packToken) return;
      setState(() => _packLoading = false);
    });
  }

  void _syncPinWatch() {
    _syncFwyHole();
    final live = _gpsMode == GpsMode.live;
    final coords = _screenVisible && live ? _activeCoords : null;
    if (coords == null) {
      final hadLine = _yardsToPin != null ||
          _readingLocation ||
          _pinSub != null ||
          _watchedKey != null;
      _stopPinWatch();
      if (hadLine && mounted) setState(() {});
      return;
    }
    final key = '${_appliedCourseName.trim().toLowerCase()}#$_holeNumber';
    if (_watchedKey == key) return;
    _stopPinWatch();
    _watchedKey = key;
    _readingLocation = true;
    final token = ++_pinToken;
    if (mounted) setState(() {});
    _beginPinWatch(coords, token);
  }

  Future<void> _beginPinWatch(HoleCoordinates coords, int token) async {
    final fix = await _pinDistance.current();
    if (!mounted || token != _pinToken) return;
    if (fix == null) {
      setState(() {
        _yardsToPin = null;
        _playerFix = null;
        _readingLocation = false;
      });
      return;
    }
    setState(() {
      _playerFix = fix;
      _yardsToPin =
          yardsToHole(coords, fromLat: fix.latitude, fromLon: fix.longitude);
      _readingLocation = false;
    });
    _pinSub = _pinDistance.watch().listen(
      (next) {
        if (!mounted || token != _pinToken) return;
        setState(() {
          _playerFix = next;
          _yardsToPin = yardsToHole(coords,
              fromLat: next.latitude, fromLon: next.longitude);
        });
      },
      onError: (_) {
        if (!mounted || token != _pinToken) return;
        _stopPinWatch();
        setState(() {});
      },
    );
  }

  void _onCourseFocus() {
    if (!_courseFocus.hasFocus) {
      _persistCourseName();
    }
  }

  Future<void> _bootstrap() async {
    _railSide = await OnCourseSettings.instance.railSide();
    _gpsMode = await OnCourseSettings.instance.gpsMode();
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
    if (mounted) _syncPinWatch();
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
    _syncPinWatch();
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
    if (mounted) _syncPinWatch();
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
    _syncPinWatch();
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
      builder: (context) => ShotEditDialog(
        shot: shot,
        clubs: _clubs,
        lies: _lies,
        showAim: _mappedHoleFeatures && !_simulator,
      ),
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
        _loadTypicalYards(_selectedClub!);
      }
      if (_recentClubIds.isEmpty) {
        for (final shot in shots.reversed) {
          _rememberClub(shot.clubId);
        }
      }
      if (hole != null) {
        _par = hole.par;
      }
    });
  }

  Future<Position?> _readGps() async {
    final inject = widget.positionForShot;
    if (inject != null) {
      return inject();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _locationPermissionBlocked = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required for shot tracking'),
          ),
        );
      }
      return null;
    }
    if (mounted && _locationPermissionBlocked) {
      setState(() => _locationPermissionBlocked = false);
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
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

  double? _optionalSimYards(TextEditingController controller) {
    final trimmed = controller.text.trim();
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed <= 0) return null;
    return parsed.roundToDouble();
  }

  void _clearSimulatorDraft() {
    _yardsController.clear();
    _carryController.clear();
    _distanceToHoleController.clear();
    _strokeNoteController.clear();
    _showSimCarry = false;
    _showSimToHole = false;
    _showSimNote = false;
    _yardsError = null;
  }

  void _rememberClub(String clubId) {
    _recentClubIds = [
      clubId,
      ..._recentClubIds.where((id) => id != clubId),
    ].take(5).toList();
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
          simCarryYards: _optionalSimYards(_carryController),
          simDistanceToHoleYards: _optionalSimYards(_distanceToHoleController),
          notes: _strokeNoteController.text,
        );
        _clearSimulatorDraft();
      } else {
        final geometry = _fwyGeometry();
        final manual = _manualActive(geometry);
        double lat;
        double lon;
        if (manual) {
          final pin = _manualPin;
          if (pin == null || _manualPinStale) return;
          lat = pin.latitude;
          lon = pin.longitude;
        } else {
          final streamFix = widget.positionForShot == null && _pinSub != null
              ? _playerFix
              : null;
          final position = streamFix == null ? await _readGps() : null;
          final liveFix = streamFix ??
              (_locationPermissionBlocked ? null : _playerFix);
          if (position == null && liveFix != null) {
            lat = liveFix.latitude;
            lon = liveFix.longitude;
          } else if (position == null) {
            if (mounted && !_locationPermissionBlocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Couldn't read location. Shot not saved."),
                ),
              );
            }
            return;
          } else {
            lat = position.latitude;
            lon = position.longitude;
          }
        }
        final ball = geometry.projection == null
            ? _fwyBall(geometry)
            : geometry.projection!.toLocal(lat, lon);
        final target = _aimTarget.local ?? geometry.green;

        await LocalDatabaseService.instance.recordFairwayHit(
          roundId: _roundId!,
          holeNumber: _holeNumber,
          clubId: _selectedClub!.id,
          lieType: _lieType,
          currentLat: lat,
          currentLon: lon,
          aimDirection: deriveAimDirection(
              ball: ball, green: geometry.green, target: target),
        );
        if (mounted) {
          setState(() {
            _aimMode = false;
            _aimTarget = const FwyAimTarget.pin();
            if (manual) _manualPinStale = true;
          });
        }
      }
      _rememberClub(_selectedClub!.id);
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
    _syncPinWatch();
  }

  String _shotSubtitle(ShotRecord shot) {
    final parts = <String>[];
    if (shot.distanceYards > 0) {
      parts.add('${shot.distanceYards.round()} yds travelled');
    } else {
      parts.add('Distance pending');
    }
    if (shot.simCarryYards != null && shot.simCarryYards! > 0) {
      parts.add('carry ${shot.simCarryYards!.round()}');
    }
    if (shot.simDistanceToHoleYards != null &&
        shot.simDistanceToHoleYards! > 0) {
      parts.add('${shot.simDistanceToHoleYards!.round()} to hole');
    }
    if (shot.notes.trim().isNotEmpty) {
      parts.add(shot.notes.trim());
    }
    return parts.join(' · ');
  }

  static String _lieLabel(String lie) =>
      lie[0].toUpperCase() + lie.substring(1);

  static TextStyle? _chipLabel(bool selected) =>
      selected ? const TextStyle(color: Colors.white) : null;

  Future<T?> _openSheet<T>({
    required String key,
    required String title,
    required WidgetBuilder builder,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          key: ValueKey(key),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 12),
              Flexible(child: builder(sheetContext)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCourseSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        void apply() {
          _persistCourseName();
          if (ModalRoute.of(sheetContext)?.isCurrent ?? false) {
            Navigator.of(sheetContext).pop();
          }
        }

        return Padding(
          key: const ValueKey('oncourse-course-sheet'),
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SizedBox(
            height: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Course',
                    style: Theme.of(sheetContext).textTheme.titleMedium),
                const SizedBox(height: 12),
                VenueNameField(
                  key: const ValueKey('oncourse-course-name-field'),
                  controller: _courseController,
                  focusNode: _courseFocus,
                  labelText: 'Course name',
                  recentNames: _recentCourses,
                  catalogNames: PhGolfCatalog.courseNames,
                  captionFor: PhGolfCatalog.courseCaption,
                  onSelected: (_) => apply(),
                  onSubmitted: (_) => apply(),
                ),
              ],
            ),
          ),
        );
      },
    );
    await _persistCourseName();
  }

  Future<void> _openHoleSheet(int strokes, int penalties, int score) async {
    final picked = await _openSheet<int>(
      key: 'oncourse-hole-sheet',
      title: 'Hole $_holeNumber · Par $_par',
      builder: (sheetContext) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Strokes $strokes · Penalties $penalties · Score $score · '
              'Round $_roundTotal',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var hole = 1; hole <= _maxHole; hole++)
                  ChoiceChip(
                    key: ValueKey('oncourse-hole-sheet-chip-$hole'),
                    label: Text('$hole'),
                    selected: hole == _holeNumber,
                    onSelected: (_) => Navigator.of(sheetContext).pop(hole),
                  ),
              ],
            ),
            if (!_simulator) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('oncourse-hole-sheet-concede'),
                      onPressed: () =>
                          Navigator.of(sheetContext).pop(_kHoleSheetConcede),
                      child: const Text('Concede'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('oncourse-hole-sheet-finish'),
                      onPressed: () =>
                          Navigator.of(sheetContext).pop(_kHoleSheetFinish),
                      child: Text(_finishLabel),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
    if (picked == _kHoleSheetConcede) {
      await _concedeHole();
    } else if (picked == _kHoleSheetFinish) {
      await _finishHole();
    } else if (picked != null && picked != _holeNumber) {
      await _stepHole(picked - _holeNumber);
    }
  }

  static const _kHoleSheetConcede = -1;
  static const _kHoleSheetFinish = 0;

  String get _finishLabel =>
      _holeNumber >= _holeCount ? 'Finish Round' : 'Finish Hole';

  Future<void> _concedeHole() async {
    if (_roundId == null) return;
    await LocalDatabaseService.instance.concedeHole(_roundId!, _holeNumber);
    await _refreshHoleState();
  }

  Future<void> _openParSheet() async {
    final picked = await _openSheet<int>(
      key: 'oncourse-par-sheet',
      title: 'Par for hole $_holeNumber',
      builder: (sheetContext) => Wrap(
        spacing: 8,
        children: [3, 4, 5].map((p) {
          return ChoiceChip(
            key: ValueKey('oncourse-par-chip-$p'),
            label: Text('Par $p'),
            selected: _par == p,
            onSelected: (_) => Navigator.of(sheetContext).pop(p),
          );
        }).toList(),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _par = picked);
    if (_roundId != null && _holeScore != null) {
      await LocalDatabaseService.instance
          .upsertHoleScore(_holeScore!.copyWith(par: picked, isSynced: 0));
    }
  }

  Future<void> _openClubSheet() async {
    final recent = [
      for (final id in _recentClubIds) ..._clubs.where((club) => club.id == id),
    ];
    Widget chip(BuildContext sheetContext, Club club, String key) {
      return ChoiceChip(
        key: ValueKey(key),
        label: Text(club.name),
        selected: _selectedClub?.id == club.id,
        onSelected: (_) => Navigator.of(sheetContext).pop(club),
      );
    }

    final picked = await _openSheet<Club>(
      key: 'oncourse-club-sheet',
      title: 'Club',
      builder: (sheetContext) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (recent.isNotEmpty) ...[
              Text('Recent',
                  style: Theme.of(sheetContext).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recent
                    .map((club) => chip(
                        sheetContext, club, 'oncourse-club-recent-${club.id}'))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text('All clubs',
                  style: Theme.of(sheetContext).textTheme.labelLarge),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _clubs
                  .map((club) => chip(sheetContext, club,
                      'oncourse-club-sheet-chip-${club.id}'))
                  .toList(),
            ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedClub = picked);
      _loadTypicalYards(picked);
    }
  }

  Future<void> _loadTypicalYards(Club club) async {
    if (_typicalYards.containsKey(club.id)) return;
    try {
      final trend =
          await LocalDatabaseService.instance.getClubYardageTrend(club.id);
      if (!mounted) return;
      setState(() => _typicalYards[club.id] = typicalClubYards(club, trend));
    } catch (_) {}
  }

  Future<void> _openLieSheet() async {
    final picked = await _openSheet<String>(
      key: 'oncourse-lie-sheet',
      title: 'Lie',
      builder: (sheetContext) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _lies.map((lie) {
          return ChoiceChip(
            key: ValueKey('oncourse-lie-chip-$lie'),
            label: Text(_lieLabel(lie)),
            selected: _lieType == lie,
            onSelected: (_) => Navigator.of(sheetContext).pop(lie),
          );
        }).toList(),
      ),
    );
    if (picked != null && mounted) setState(() => _lieType = picked);
  }

  Widget _selectorButton({
    required String key,
    required String label,
    required String value,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip ?? label,
      child: SizedBox(
        height: 56,
        child: OutlinedButton(
          key: ValueKey(key),
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.only(left: 14, right: 6),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.labelSmall),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepper({
    required String label,
    required String keyPrefix,
    required int count,
    required Future<void> Function(int delta) onStep,
  }) {
    final enabled = _roundId != null;
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        IconButton(
          key: ValueKey('$keyPrefix-step-down'),
          tooltip: 'Remove ${label.toLowerCase()}',
          onPressed: enabled && count > 0
              ? () => onStep(-1).then((_) => _refreshHoleState())
              : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          '$count',
          key: ValueKey('$keyPrefix-count'),
          semanticsLabel: '$label $count',
          style: GolfTextStyles.tabularNum(context, fontSize: 18),
        ),
        IconButton(
          key: ValueKey('$keyPrefix-step-up'),
          tooltip: 'Add ${label.toLowerCase()}',
          onPressed:
              enabled ? () => onStep(1).then((_) => _refreshHoleState()) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  Widget _optionalSimField({
    required String fieldKey,
    required String hideKey,
    required TextEditingController controller,
    required String label,
    required VoidCallback onHide,
    bool numeric = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextField(
        key: ValueKey(fieldKey),
        controller: controller,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        maxLines: numeric ? 1 : 2,
        minLines: 1,
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          suffixIcon: IconButton(
            key: ValueKey(hideKey),
            tooltip: 'Hide',
            icon: const Icon(Icons.close),
            onPressed: () {
              controller.clear();
              setState(onHide);
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _simulatorFieldWidgets() {
    return [
      const SizedBox(height: 8),
      TextField(
        key: const ValueKey('oncourse-sim-yards-field'),
        controller: _yardsController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          isDense: true,
          labelText: 'Distance travelled (yds)',
          errorText: _yardsError,
        ),
        onChanged: (_) {
          if (_yardsError != null) {
            setState(() => _yardsError = null);
          }
        },
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          FilterChip(
            key: const ValueKey('oncourse-sim-carry-chip'),
            selectedColor: GolfPalette.fairwayGreen,
            labelStyle: _chipLabel(_showSimCarry),
            label: const Text('Carry'),
            selected: _showSimCarry,
            onSelected: (on) => setState(() {
              _showSimCarry = on;
              if (!on) _carryController.clear();
            }),
          ),
          FilterChip(
            key: const ValueKey('oncourse-sim-to-hole-chip'),
            selectedColor: GolfPalette.fairwayGreen,
            labelStyle: _chipLabel(_showSimToHole),
            label: const Text('To hole'),
            selected: _showSimToHole,
            onSelected: (on) => setState(() {
              _showSimToHole = on;
              if (!on) _distanceToHoleController.clear();
            }),
          ),
          FilterChip(
            key: const ValueKey('oncourse-sim-notes-chip'),
            selectedColor: GolfPalette.fairwayGreen,
            labelStyle: _chipLabel(_showSimNote),
            label: const Text('Notes'),
            selected: _showSimNote,
            onSelected: (on) => setState(() {
              _showSimNote = on;
              if (!on) _strokeNoteController.clear();
            }),
          ),
        ],
      ),
      if (_showSimCarry)
        _optionalSimField(
          fieldKey: 'oncourse-sim-carry-field',
          hideKey: 'oncourse-sim-carry-hide-btn',
          controller: _carryController,
          label: 'Carry (yds)',
          onHide: () => _showSimCarry = false,
        ),
      if (_showSimToHole)
        _optionalSimField(
          fieldKey: 'oncourse-sim-distance-to-hole-field',
          hideKey: 'oncourse-sim-to-hole-hide-btn',
          controller: _distanceToHoleController,
          label: 'Distance to hole (yds)',
          onHide: () => _showSimToHole = false,
        ),
      if (_showSimNote)
        _optionalSimField(
          fieldKey: 'oncourse-sim-stroke-note-field',
          hideKey: 'oncourse-sim-notes-hide-btn',
          controller: _strokeNoteController,
          label: 'Stroke note',
          numeric: false,
          onHide: () => _showSimNote = false,
        ),
    ];
  }

  Widget _courseSummary(BuildContext context) {
    final course = PhGolfCatalog.matchCourse(_appliedCourseName);
    final meta = course?.holePars == null
        ? null
        : '${course!.holes} holes · Par ${course.totalPar}';
    final summary = InkWell(
      key: const ValueKey('oncourse-course-summary'),
      onTap: _openCourseSheet,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  _appliedCourseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.edit_outlined,
                  size: 20, semanticLabel: 'Edit course'),
            ],
          ),
        ),
      ),
    );
    final nameRow = Row(
      children: [
        Expanded(child: Align(alignment: Alignment.centerLeft, child: summary)),
        const SizedBox(width: 8),
        _modeToggle(),
      ],
    );
    if (meta == null) return nameRow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        nameRow,
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            meta,
            key: const ValueKey('oncourse-course-meta'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  void _setSimulator(bool simulator) {
    if (simulator == _simulator) return;
    setState(() {
      _simulator = simulator;
      _yardsError = null;
    });
    _syncPinWatch();
  }

  Widget _modeToggle({bool overMap = false}) {
    final unselected = overMap
        ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.92)
        : null;
    return SegmentedButton<bool>(
      key: const ValueKey('oncourse-mode-toggle'),
      emptySelectionAllowed: false,
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? GolfPalette.fairwayGreen
                : unselected),
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.white : null),
      ),
      segments: const [
        ButtonSegment<bool>(
          value: false,
          label: Text(
            'FWY',
            key: ValueKey('oncourse-mode-course'),
            semanticsLabel: 'Fairway',
          ),
        ),
        ButtonSegment<bool>(
          value: true,
          label: Text(
            'SIM',
            key: ValueKey('oncourse-mode-simulator'),
            semanticsLabel: 'Simulator',
          ),
        ),
      ],
      selected: {_simulator},
      onSelectionChanged: (selection) => _setSimulator(selection.first),
    );
  }

  Widget _contextRow(
      BuildContext context, int strokes, int penalties, int holeScore) {
    return Row(
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  key: const Key('on-course-hole-previous'),
                  tooltip: 'Previous hole',
                  visualDensity: VisualDensity.compact,
                  onPressed: _holeNumber > 1 ? () => _stepHole(-1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                InkWell(
                  key: const Key('on-course-hole-label'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _openHoleSheet(strokes, penalties, holeScore),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                    child: Text(
                      'Hole $_holeNumber',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('on-course-hole-next'),
                  tooltip: 'Next hole',
                  visualDensity: VisualDensity.compact,
                  onPressed: _holeNumber < _maxHole ? () => _stepHole(1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
                const SizedBox(width: 4),
                ActionChip(
                  key: const ValueKey('oncourse-par-summary'),
                  tooltip: 'Change par',
                  visualDensity: VisualDensity.compact,
                  label: Text('Par $_par'),
                  onPressed: _openParSheet,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _shotTile(ShotRecord s) {
    final aimNote = !_simulator && s.aimDirection != kOnCourseAimCenter
        ? ' · Aim ${s.aimDirection}'
        : '';
    final subtitle = s.isHoled
        ? kHoledShotNote
        : _simulator
            ? _shotSubtitle(s)
            : shotDistanceLabel(shots: _shots, shot: s, simulator: _simulator);
    return ListTile(
      key: ValueKey('oncourse-shot-row-${s.strokeNumber}'),
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: () => _editShot(s),
      title: Text(
        'Stroke ${s.strokeNumber} · ${s.lieType} · ${_clubName(s.clubId)}$aimNote',
      ),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: s.isHoled
          ? const Icon(Icons.flag_outlined)
          : s.notes.trim().isNotEmpty
          ? const Icon(Icons.notes_outlined)
          : const Icon(Icons.edit_outlined),
    );
  }

  void _openDiary() {
    showSwingDiarySheet(
      context,
      diary: widget.diary,
      entrySource: DiaryContextSource.onCourse,
    );
  }

  /// A thin strip on the right edge opens the diary on a leftward swipe.
  /// It only claims horizontal drags, so taps and vertical scrolling pass
  /// through to the controls underneath.
  Widget _withDiaryEdgeSwipe(Widget child) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: 16,
          child: GestureDetector(
            key: const ValueKey('oncourse-diary-edge-swipe'),
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => _diaryEdgeDragDx = 0,
            onHorizontalDragUpdate: (details) =>
                _diaryEdgeDragDx += details.delta.dx,
            onHorizontalDragEnd: (details) {
              final velocity = details.primaryVelocity ?? 0;
              if (_diaryEdgeDragDx < -40 || velocity < -300) _openDiary();
            },
          ),
        ),
      ],
    );
  }

  // ─── FWY map shell (CRSE-036) ─────────────────────────────────────────────

  _FwyGeometry _fwyGeometry() {
    final coords = _activeCoords;
    if (coords == null) {
      final standin = StandinHole.forPar(_par);
      return _FwyGeometry(
          tee: standin.tee, green: standin.green, standin: standin);
    }
    final frame = _pack?.entry.frame;
    final projection = frame != null
        ? HoleProjection(
            centerLat: frame.centerLat,
            centerLon: frame.centerLon,
            bearingDeg: frame.bearingDeg,
          )
        : HoleProjection(
            centerLat: (coords.teeLat + coords.greenLat) / 2,
            centerLon: (coords.teeLon + coords.greenLon) / 2,
            bearingDeg: bearingDegrees(
              fromLat: coords.teeLat,
              fromLon: coords.teeLon,
              toLat: coords.greenLat,
              toLon: coords.greenLon,
            ),
          );
    return _FwyGeometry(
      tee: projection.toLocal(coords.teeLat, coords.teeLon),
      green: projection.toLocal(coords.greenLat, coords.greenLon),
      projection: projection,
      coords: coords,
    );
  }

  /// Manual positions need a real hole frame; stand-in holes record GPS.
  bool _manualActive(_FwyGeometry g) =>
      _gpsMode == GpsMode.manual && g.projection != null;

  List<Offset> _fwyStrokes(_FwyGeometry g) {
    final standin = g.standin;
    if (standin != null) return standin.strokePositions(_shots);
    return [
      for (final shot in _shots)
        if (shot.startLat != 0 || shot.startLon != 0)
          g.projection!.toLocal(shot.startLat, shot.startLon),
    ];
  }

  Offset _fwyBall(_FwyGeometry g) {
    final standin = g.standin;
    if (standin != null) {
      final travelled =
          _shots.fold<double>(0, (sum, shot) => sum + shot.distanceYards);
      return Offset(
          0, math.min(travelled * kMetersPerYard, standin.lengthMeters));
    }
    final projection = g.projection!;
    if (_manualActive(g)) {
      final pin = _manualPin;
      if (pin != null) return projection.toLocal(pin.latitude, pin.longitude);
    } else if (_playerFix != null) {
      return projection.toLocal(_playerFix!.latitude, _playerFix!.longitude);
    }
    final strokes = _fwyStrokes(g);
    return strokes.isEmpty ? g.tee : strokes.last;
  }

  List<FwyMapMarker> _fwyMarkers(_FwyGeometry g) {
    final projection = g.projection;
    final pack = _pack;
    if (projection == null || pack == null) return const [];
    return [
      for (final m in pack.entry.markers)
        FwyMapMarker(id: m.id, local: projection.toLocal(m.lat, m.lon)),
    ];
  }

  double _clubYards() {
    final club = _selectedClub;
    if (club == null) return 150;
    return _typicalYards[club.id] ?? typicalClubYards(club, const []);
  }

  double get _ringMeters => _clubYards() * kMetersPerYard;

  void _toggleAimMode() {
    if (_aimMode) {
      setState(() => _aimMode = false);
      return;
    }
    final g = _fwyGeometry();
    final ball = _fwyBall(g);
    final radius = _ringMeters;
    var target = const FwyAimTarget.pin();
    if ((g.green - ball).distance > radius) {
      for (final m in _fwyMarkers(g)) {
        if (((m.local - ball).distance - radius).abs() <=
            15 * kMetersPerYard) {
          target = FwyAimTarget.marker(m.local, m.id);
          break;
        }
      }
    }
    setState(() {
      _aimMode = true;
      _aimTarget = target;
    });
  }

  void _resetAim() {
    setState(() {
      _aimMode = false;
      _aimTarget = const FwyAimTarget.pin();
    });
  }

  void _onMapTap(_FwyGeometry g, Offset local, double pixelsPerMeter) {
    if (_aimMode) {
      final ball = _fwyBall(g);
      final radius = _ringMeters;
      if ((g.green - ball).distance <= radius) {
        setState(() => _aimTarget = const FwyAimTarget.pin());
        return;
      }
      for (final m in _fwyMarkers(g)) {
        if ((m.local - local).distance * pixelsPerMeter <= 12) {
          setState(() => _aimTarget = FwyAimTarget.marker(m.local, m.id));
          return;
        }
      }
      setState(() => _aimTarget = FwyAimTarget.custom(
          snapToRing(ball: ball, tap: local, radius: radius)));
      return;
    }
    if (!_manualActive(g)) return;
    final projection = g.projection!;
    final pin = _manualPin;
    if (pin != null && _manualPinStale) {
      final pinLocal = projection.toLocal(pin.latitude, pin.longitude);
      if ((pinLocal - local).distance * pixelsPerMeter <= 24) {
        setState(() => _manualPinStale = false);
        return;
      }
    }
    final at = projection.toLatLon(local);
    setState(() {
      _manualPin = PinFix(latitude: at.lat, longitude: at.lon);
      _manualPinStale = false;
    });
  }

  Future<void> _setGpsMode(GpsMode mode) async {
    if (mode == _gpsMode) return;
    setState(() {
      _gpsMode = mode;
      _manualPinStale = false;
      if (mode == GpsMode.manual) _locationPermissionBlocked = false;
    });
    _syncPinWatch();
    await OnCourseSettings.instance.setGpsMode(mode);
  }

  Future<void> _toggleRailSide() async {
    final next = _railSide == RailSide.right ? RailSide.left : RailSide.right;
    setState(() => _railSide = next);
    await OnCourseSettings.instance.setRailSide(next);
  }

  Future<void> _openGpsSheet() async {
    final picked = await _openSheet<GpsMode>(
      key: 'oncourse-gps-sheet',
      title: 'Ball position',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                key: const ValueKey('oncourse-gps-live'),
                avatar: const Icon(Icons.my_location, size: 18),
                label: const Text('Live GPS'),
                selected: _gpsMode == GpsMode.live,
                onSelected: (_) => Navigator.of(sheetContext).pop(GpsMode.live),
              ),
              ChoiceChip(
                key: const ValueKey('oncourse-gps-manual'),
                avatar: const Icon(Icons.pan_tool_alt_outlined, size: 18),
                label: const Text('Manual pin'),
                selected: _gpsMode == GpsMode.manual,
                onSelected: (_) =>
                    Navigator.of(sheetContext).pop(GpsMode.manual),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Manual: tap the map to put the pin on your ball before each '
            'Record. Sample holes without a map always use Live GPS.',
            style: Theme.of(sheetContext).textTheme.bodySmall,
          ),
        ],
      ),
    );
    if (picked != null) await _setGpsMode(picked);
  }

  Future<void> _openShotsSheet(int strokes, int penalties, int score) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        key: const ValueKey('oncourse-shots-sheet'),
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        snap: true,
        snapSizes: const [0.5, 0.9],
        builder: (sheetContext, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              'Strokes $strokes · Pen $penalties · Score $score · '
              'Round $_roundTotal',
              key: const ValueKey('oncourse-hole-stats-row'),
              style: Theme.of(sheetContext).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (_shots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No shots yet on this hole.'),
              ),
            ..._shots.map(_shotTile),
          ],
        ),
      ),
    );
  }

  Future<int> _stepCounter(
      Future<void> Function(String roundId, int hole, int delta) step,
      int delta,
      int Function() read) async {
    if (_roundId == null) return read();
    await step(_roundId!, _holeNumber, delta);
    await _refreshHoleState();
    return read();
  }

  List<PlayHeaderMenuAction> _fwyOverflowActions() {
    return [
      PlayHeaderMenuAction(
        id: 'concede',
        key: 'oncourse-overflow-concede',
        icon: Icons.handshake_outlined,
        label: 'Concede hole',
        dividerBefore: true,
        onSelected: _concedeHole,
      ),
      PlayHeaderMenuAction(
        id: 'finish',
        key: 'oncourse-overflow-finish',
        icon: Icons.flag_outlined,
        label: _finishLabel,
        onSelected: _finishHole,
      ),
      PlayHeaderMenuAction(
        id: 'gps',
        key: 'oncourse-overflow-gps',
        icon: Icons.my_location,
        label: _gpsMode == GpsMode.live
            ? 'Ball position: Live GPS'
            : 'Ball position: Manual',
        dividerBefore: true,
        onSelected: _openGpsSheet,
      ),
      PlayHeaderMenuAction(
        id: 'rail',
        key: 'oncourse-overflow-rail-side',
        icon: Icons.swap_horiz,
        label: _railSide == RailSide.right
            ? 'Move controls to the left'
            : 'Move controls to the right',
        onSelected: _toggleRailSide,
      ),
    ];
  }

  Widget _fwyTopOverlay(BuildContext context, int strokes, int penalties,
      int holeScore, _FwyGeometry g) {
    final course = PhGolfCatalog.matchCourse(_appliedCourseName);
    final meta = course?.holePars == null
        ? null
        : '${course!.holes} holes · Par ${course.totalPar}';
    final text = fwyOverlayText(context);
    final manual = _manualActive(g);

    Widget? yards;
    if (g.standin != null) {
      yards = Text(
        '≈ ${g.standin!.remainingYards(_shots)} yds',
        key: const ValueKey('oncourse-standin-yards'),
        semanticsLabel: 'About ${g.standin!.remainingYards(_shots)} yards',
        style: text.copyWith(fontSize: 20),
      );
    } else {
      final int? value;
      if (manual) {
        final pin = _manualPin;
        value = pin == null
            ? null
            : yardsToHole(g.coords!,
                fromLat: pin.latitude, fromLon: pin.longitude);
      } else {
        value = _yardsToPin;
      }
      if (value != null) {
        yards = Text(
          '$value yds',
          key: const ValueKey('on-course-distance-to-hole'),
          semanticsLabel: 'Yards to the pin',
          style: text.copyWith(
            fontSize: 20,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      } else if (_readingLocation && !manual) {
        yards = Text('Reading location…', style: text);
      }
    }

    final gpsBadge = InkWell(
      key: const ValueKey('oncourse-gps-badge'),
      onTap: _openGpsSheet,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _gpsMode == GpsMode.live
                  ? Icons.my_location
                  : Icons.pan_tool_alt_outlined,
              size: 16,
              color: Colors.white,
              shadows: kFwyOverlayShadow,
            ),
            const SizedBox(width: 4),
            Text(_gpsMode == GpsMode.live ? 'Live' : 'Manual', style: text),
          ],
        ),
      ),
    );

    return DecoratedBox(
      key: const ValueKey('oncourse-top-overlay'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GolfPalette.mapScrim, Color(0x00000000)],
          stops: [0.65, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 12, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    key: const ValueKey('oncourse-course-summary'),
                    onTap: _openCourseSheet,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 40),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                _appliedCourseName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.copyWith(fontSize: 17),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.edit_outlined,
                                size: 18,
                                color: Colors.white,
                                shadows: kFwyOverlayShadow,
                                semanticLabel: 'Edit course'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _modeToggle(overMap: true),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    meta ?? 'Custom course',
                    key: meta == null
                        ? null
                        : const ValueKey('oncourse-course-meta'),
                    style: text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                gpsBadge,
              ],
            ),
            Row(
              children: [
                IconButton(
                  key: const Key('on-course-hole-previous'),
                  tooltip: 'Previous hole',
                  visualDensity: VisualDensity.compact,
                  color: Colors.white,
                  disabledColor: Colors.white38,
                  onPressed: _holeNumber > 1 ? () => _stepHole(-1) : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                InkWell(
                  key: const Key('on-course-hole-label'),
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _openHoleSheet(strokes, penalties, holeScore),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Text('Hole $_holeNumber',
                        style: text.copyWith(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                ),
                IconButton(
                  key: const Key('on-course-hole-next'),
                  tooltip: 'Next hole',
                  visualDensity: VisualDensity.compact,
                  color: Colors.white,
                  disabledColor: Colors.white38,
                  onPressed: _holeNumber < _maxHole ? () => _stepHole(1) : null,
                  icon: const Icon(Icons.chevron_right),
                ),
                const SizedBox(width: 4),
                ActionChip(
                  key: const ValueKey('oncourse-par-summary'),
                  tooltip: 'Change par',
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text('Par $_par'),
                  onPressed: _openParSheet,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: yards == null
                        ? const SizedBox.shrink()
                        : FittedBox(fit: BoxFit.scaleDown, child: yards),
                  ),
                ),
              ],
            ),
            if (_packLoading)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: LinearProgressIndicator(
                    key: ValueKey('oncourse-map-download'), minHeight: 2),
              ),
          ],
        ),
      ),
    );
  }

  Widget _fwyRail(BuildContext context, double tile, int penalties,
      int mulligans) {
    final club = _selectedClub;
    final aimValue = switch (_aimTarget.kind) {
      FwyAimKind.pin => 'Pin',
      FwyAimKind.marker => 'Marker',
      FwyAimKind.custom => 'Custom',
    };
    const gap = SizedBox(height: _kRailGap);
    final small = tile * 0.8;
    return Column(
      key: const ValueKey('oncourse-side-rail'),
      mainAxisSize: MainAxisSize.min,
      children: [
        FwyRailTile(
          key: const ValueKey('oncourse-club-summary'),
          size: tile,
          label: 'Club',
          value: club?.name ?? 'Club',
          tooltip: 'Choose club',
          onTap: _openClubSheet,
        ),
        gap,
        FwyRailTile(
          key: const ValueKey('oncourse-lie-summary'),
          size: tile,
          label: 'Lie',
          value: _lieLabel(_lieType),
          tooltip: 'Choose lie',
          onTap: _openLieSheet,
        ),
        gap,
        FwyRailTile(
          key: const ValueKey('oncourse-aim-summary'),
          size: tile,
          label: 'Aim',
          value: aimValue,
          selected: _aimMode,
          tooltip: 'Aim (long press resets to the pin)',
          onTap: _toggleAimMode,
          onLongPress: _resetAim,
        ),
        gap,
        Builder(
          builder: (anchor) => FwyRailTile(
            key: const ValueKey('oncourse-rail-penalty'),
            size: tile,
            height: small,
            label: 'Pen',
            value: '$penalties',
            valueKey: const ValueKey('oncourse-rail-penalty-count'),
            tooltip: 'Penalties',
            onTap: () => showFwyCounterPopover(
              anchor: anchor,
              label: 'Penalty',
              keyPrefix: 'oncourse-penalty',
              initial: penalties,
              onStep: (delta) => _stepCounter(
                  LocalDatabaseService.instance.incrementPenalties,
                  delta,
                  () => _holeScore?.penalties ?? 0),
            ),
          ),
        ),
        gap,
        Builder(
          builder: (anchor) => FwyRailTile(
            key: const ValueKey('oncourse-rail-mulligan'),
            size: tile,
            height: small,
            label: 'Mul',
            value: '$mulligans',
            valueKey: const ValueKey('oncourse-rail-mulligan-count'),
            tooltip: 'Mulligans',
            onTap: () => showFwyCounterPopover(
              anchor: anchor,
              label: 'Mulligan',
              keyPrefix: 'oncourse-mulligan',
              initial: mulligans,
              onStep: (delta) => _stepCounter(
                  (roundId, hole, d) => LocalDatabaseService.instance
                      .incrementMulligans(roundId, hole, d),
                  delta,
                  () => _holeScore?.mulligans ?? 0),
            ),
          ),
        ),
        gap,
        FwyRailTile(
          key: const ValueKey('oncourse-rail-side-toggle'),
          size: tile,
          height: _kRailToggleHeight,
          label: '',
          icon: Icons.swap_horiz,
          tooltip: _railSide == RailSide.right
              ? 'Move controls to the left'
              : 'Move controls to the right',
          onTap: _toggleRailSide,
        ),
      ],
    );
  }

  Widget _fwyBody(BuildContext context, int strokes, int penalties,
      int mulligans, int holeScore) {
    final g = _fwyGeometry();
    final manual = _manualActive(g);
    final ball = _fwyBall(g);
    final strokesLocal = _fwyStrokes(g);
    final ringFaint = (g.green - ball).distance <= _ringMeters;
    final markers = _fwyMarkers(g);
    final segmentYards = <int?>[
      for (var i = 1; i < _shots.length; i++)
        g.standin != null
            ? (_shots[i - 1].distanceYards > 0
                ? _shots[i - 1].distanceYards.round()
                : null)
            : segmentYardsEndingAt(_shots, _shots[i]),
    ];
    final playerFix = manual ? null : _playerFix;
    final scene = FwyHoleScene(
      tee: g.tee,
      green: g.green,
      strokes: strokesLocal,
      segmentYards: segmentYards,
      player: playerFix == null || g.projection == null
          ? null
          : g.projection!.toLocal(playerFix.latitude, playerFix.longitude),
      markers: markers,
      ball: _aimMode ? ball : null,
      aimTarget: _aimTarget.local,
      aimRingMeters: _aimMode ? _ringMeters : null,
      aimRingFaint: ringFaint,
      manualPin: manual && _manualPin != null
          ? g.projection!
              .toLocal(_manualPin!.latitude, _manualPin!.longitude)
          : null,
      manualPinStale: _manualPinStale,
    );
    final doublePar = strokes + penalties >= 2 * _par && _par > 0;
    final recordReady = !manual || (_manualPin != null && !_manualPinStale);

    return LayoutBuilder(builder: (context, constraints) {
      final height = constraints.maxHeight;
      final railAvail = height - _kRailTop - _kDockHeight - 8;
      final tile = ((railAvail - 5 * _kRailGap - _kRailToggleHeight) / 4.6)
          .clamp(36.0, 56.0);
      final railRight = _railSide == RailSide.right;
      final railColumn = _kRailInset + tile + 8;
      final freeLeft = railRight ? 12.0 : railColumn;
      final freeRight = railRight ? railColumn : 20.0;

      final banners = <Widget>[
        if (_aimMode)
          _fwyBanner(
            key: 'oncourse-aim-mode-banner',
            icon: Icons.adjust,
            text: ringFaint
                ? 'Aim · ${_selectedClub?.name ?? 'Club'} reaches the pin'
                : 'Aim · ${_selectedClub?.name ?? 'Club'} '
                    '${_clubYards().round()}y · tap the ring',
            actions: [
              IconButton(
                key: const ValueKey('oncourse-aim-mode-close'),
                tooltip: 'Aim at the pin',
                visualDensity: VisualDensity.compact,
                onPressed: _resetAim,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        if (manual && !recordReady && !_aimMode)
          _fwyBanner(
            key: 'oncourse-manual-hint',
            icon: Icons.pan_tool_alt_outlined,
            text: _manualPin == null
                ? 'Tap the map where your ball is'
                : 'Move the pin to your ball (tap it if it has not moved)',
          ),
        if (doublePar && !_doubleParDismissed)
          _fwyBanner(
            key: 'oncourse-double-par-banner',
            icon: Icons.flag_outlined,
            text: 'Double par (${2 * _par}). Finish hole?',
            actions: [
              TextButton(
                key: const ValueKey('oncourse-double-par-keep'),
                style: _bannerButton,
                onPressed: () => setState(() => _doubleParDismissed = true),
                child: const Text('Keep putting'),
              ),
              FilledButton(
                key: const ValueKey('oncourse-double-par-finish'),
                style: _bannerButton,
                onPressed: _finishHole,
                child: const Text('Finish hole'),
              ),
            ],
          ),
        if (_locationPermissionBlocked && !manual)
          _fwyBanner(
            key: 'oncourse-location-banner',
            icon: Icons.location_off_outlined,
            text: 'Location is off for shot tracking.',
            actions: [
              if (g.projection != null)
                TextButton(
                  key: const ValueKey('oncourse-location-switch-manual'),
                  style: _bannerButton,
                  onPressed: () => _setGpsMode(GpsMode.manual),
                  child: const Text('Use Manual'),
                ),
              TextButton(
                style: _bannerButton,
                onPressed: Geolocator.openAppSettings,
                child: const Text('Settings'),
              ),
            ],
          ),
      ];

      final badges = <Widget>[
        if (g.standin != null)
          const FwyMapBadge(
            key: ValueKey('oncourse-standin-badge'),
            icon: Icons.info_outline,
            text: "Sample hole · not this course's shape",
          )
        else if (_pack == null && !_packLoading)
          const FwyMapBadge(
            key: ValueKey('oncourse-map-line-only-badge'),
            icon: Icons.timeline,
            text: 'Line only',
          ),
      ];

      return Stack(
        children: [
          Positioned.fill(
            child: FwyHoleMap(
              key: const ValueKey('oncourse-map-background'),
              scene: scene,
              pack: _pack,
              clearInsets: EdgeInsets.fromLTRB(
                  freeLeft,
                  _kRailTop + (badges.isEmpty ? 0 : _kBadgeReserve),
                  freeRight,
                  _kDockHeight),
              onTapLocal: (local, ppm) => _onMapTap(g, local, ppm),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _kDockHeight + 24,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [GolfPalette.mapScrim, Color(0x00000000)],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _fwyTopOverlay(context, strokes, penalties, holeScore, g),
          ),
          if (badges.isNotEmpty)
            Positioned(
              top: _kRailTop,
              left: freeLeft,
              right: freeRight,
              child: Align(
                alignment: Alignment.topLeft,
                child: Wrap(spacing: 6, runSpacing: 6, children: badges),
              ),
            ),
          Positioned(
            top: _kRailTop,
            right: railRight ? _kRailInset : null,
            left: railRight ? null : _kRailInset,
            child: _fwyRail(context, tile, penalties, mulligans),
          ),
          if (banners.isNotEmpty)
            Positioned(
              left: freeLeft,
              right: freeRight,
              bottom: _kDockHeight + 4,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final banner in banners)
                    Padding(
                        padding: const EdgeInsets.only(top: 6), child: banner),
                ],
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: _kPeekHeight,
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              key: const ValueKey('oncourse-shots-peek'),
                              borderRadius: BorderRadius.circular(8),
                              onTap: () =>
                                  _openShotsSheet(strokes, penalties, holeScore),
                              child: Center(
                                child: Text(
                                  'Shots this hole (${_shots.length}) ⌃',
                                  style: fwyOverlayText(context),
                                ),
                              ),
                            ),
                          ),
                          if (doublePar && _doubleParDismissed)
                            ActionChip(
                              key: const ValueKey(
                                  'oncourse-double-par-finish-chip'),
                              visualDensity: VisualDensity.compact,
                              avatar: const Icon(Icons.flag_outlined, size: 16),
                              label: const Text('Finish'),
                              onPressed: _finishHole,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: _kRecordHeight,
                      child: FilledButton(
                        key: const ValueKey('oncourse-record-shot-btn'),
                        onPressed:
                            _busy || !recordReady ? null : _recordShot,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.green,
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Record shot at ball',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_pack != null)
            Positioned(
              left: freeLeft,
              bottom: _kDockHeight - 2,
              child: IgnorePointer(
                child: Text(
                  _pack!.attribution,
                  key: const ValueKey('oncourse-map-attribution'),
                  style: fwyOverlayText(context, fontSize: 10),
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _fwyBanner({
    required String key,
    required IconData icon,
    required String text,
    List<Widget> actions = const [],
  }) {
    return DecoratedBox(
      key: ValueKey(key),
      decoration: fwySurface(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(text,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
                if (actions.length == 1) actions.single,
              ],
            ),
            if (actions.length > 1)
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                children: actions,
              ),
          ],
        ),
      ),
    );
  }

  static final _bannerButton = ButtonStyle(
    minimumSize: WidgetStateProperty.all(const Size(0, 40)),
    padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(horizontal: 12)),
    visualDensity: VisualDensity.compact,
  );

  @override
  Widget build(BuildContext context) {
    final strokes = _holeScore?.strokes ?? _shots.length;
    final penalties = _holeScore?.penalties ?? 0;
    final mulligans = _holeScore?.mulligans ?? 0;
    final holeScore = computeFinalScore(strokes: strokes, penalties: penalties);

    return Scaffold(
      appBar: AppBar(
        leading: PlayHeaderOverflowButton(
          showDiary: true,
          showCaddy: _roundId != null,
          diaryLabel: 'Diary',
          diaryEntryKey: 'diary-entry-on-course',
          diary: widget.diary,
          diaryStore: null,
          diarySource: DiaryContextSource.onCourse,
          roundId: _roundId,
          courseName: _appliedCourseName,
          caddyInviteKey: 'on-course-invite-caddy',
          extraActions: _simulator ? const [] : _fwyOverflowActions(),
        ),
        title: const Text('On Course'),
        actions: const [AccountAvatarAppBarMenu()],
      ),
      body: _withDiaryEdgeSwipe(Builder(
        builder: (context) {
          if (!_simulator) {
            return _fwyBody(context, strokes, penalties, mulligans, holeScore);
          }
          return CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: _courseSummary(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Card(
                            key: const ValueKey('oncourse-hud-tabular'),
                            margin: EdgeInsets.zero,
                            child: Semantics(
                              label: 'On course scoring summary',
                              container: true,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _contextRow(
                                        context, strokes, penalties, holeScore),
                                    Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(8, 0, 0, 4),
                                      child: Text(
                                        'Strokes $strokes · Penalties $penalties · '
                                        'Score $holeScore · Round total $_roundTotal',
                                        key: const ValueKey(
                                            'oncourse-hole-stats-row'),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _selectorButton(
                                                  key: 'oncourse-club-summary',
                                                  label: 'Club',
                                                  value: _selectedClub?.name ??
                                                      'Club',
                                                  tooltip: 'Choose club',
                                                  onPressed: _openClubSheet,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: _selectorButton(
                                                  key: 'oncourse-lie-summary',
                                                  label: 'Lie',
                                                  value: _lieLabel(_lieType),
                                                  tooltip: 'Choose lie',
                                                  onPressed: _openLieSheet,
                                                ),
                                              ),
                                            ],
                                          ),
                                          ..._simulatorFieldWidgets(),
                                          const SizedBox(height: 4),
                                          _stepper(
                                            label: 'Penalty',
                                            keyPrefix: 'oncourse-penalty',
                                            count: penalties,
                                            onStep: (delta) =>
                                                LocalDatabaseService.instance
                                                    .incrementPenalties(
                                                        _roundId!,
                                                        _holeNumber,
                                                        delta),
                                          ),
                                          _stepper(
                                            label: 'Mulligan',
                                            keyPrefix: 'oncourse-mulligan',
                                            count: mulligans,
                                            onStep: (delta) =>
                                                LocalDatabaseService.instance
                                                    .incrementMulligans(
                                                        _roundId!,
                                                        _holeNumber,
                                                        delta),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: 64,
                              width: double.infinity,
                              child: FilledButton(
                                key: const ValueKey('oncourse-record-shot-btn'),
                                onPressed: _busy ? null : _recordShot,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.green,
                                ),
                                child: _busy
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _simulator
                                            ? 'Record stroke'
                                            : 'Record shot at ball',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 48,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      key: const ValueKey(
                                          'oncourse-concede-btn'),
                                      onPressed: _roundId == null
                                          ? null
                                          : () => LocalDatabaseService.instance
                                              .concedeHole(
                                                  _roundId!, _holeNumber)
                                              .then((_) => _refreshHoleState()),
                                      child: const Text('Concede'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton(
                                      key: const ValueKey(
                                          'oncourse-finish-hole-btn'),
                                      onPressed: _finishHole,
                                      child: Text(
                                        _holeNumber >= _holeCount
                                            ? 'Finish Round'
                                            : 'Finish Hole',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_shots.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  sliver: SliverToBoxAdapter(
                    child: ExpansionTile(
                      key: const ValueKey('oncourse-shots-list-expander'),
                      initiallyExpanded: true,
                      tilePadding: EdgeInsets.zero,
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: Text('Shots this hole (${_shots.length})'),
                      children: _shots.map(_shotTile).toList(),
                    ),
                  ),
                ),
            ],
          );
        },
      )),
    );
  }
}

const double _kRailTop = 136;
const double _kBadgeReserve = 40;
const double _kRailInset = 20;
const double _kRailGap = 4;
const double _kRailToggleHeight = 36;
const double _kPeekHeight = 36;
const double _kRecordHeight = 56;
const double _kDockHeight = _kPeekHeight + 4 + _kRecordHeight + 12;

class _FwyGeometry {
  const _FwyGeometry({
    required this.tee,
    required this.green,
    this.projection,
    this.coords,
    this.standin,
  });

  final Offset tee;
  final Offset green;

  /// Null on a stand-in hole (no survey for this course or hole).
  final HoleProjection? projection;
  final HoleCoordinates? coords;
  final StandinHole? standin;
}

@visibleForTesting
class ShotEditDialog extends StatefulWidget {
  const ShotEditDialog({
    super.key,
    required this.shot,
    required this.clubs,
    required this.lies,
    this.showAim = false,
  });

  final ShotRecord shot;
  final List<Club> clubs;
  final List<String> lies;
  final bool showAim;

  @override
  State<ShotEditDialog> createState() => _ShotEditDialogState();
}

class _ShotEditDialogState extends State<ShotEditDialog> {
  late String _lie = widget.shot.lieType;
  late String _clubId = widget.shot.clubId;
  late String _aim = normalizeOnCourseAim(widget.shot.aimDirection);

  Future<void> _save() async {
    await LocalDatabaseService.instance.updateShotDetails(
      shotId: widget.shot.id,
      clubId: _clubId,
      lieType: _lie,
      aimDirection: widget.showAim ? _aim : null,
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
            if (widget.showAim) ...[
              const SizedBox(height: 16),
              const Text('Aim'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: kOnCourseAimChoices.map((aim) {
                  final label = switch (aim) {
                    kOnCourseAimLeft => '◀ L',
                    kOnCourseAimRight => 'R ▶',
                    _ => '●',
                  };
                  return ChoiceChip(
                    key: ValueKey('oncourse-aim-$aim'),
                    label: Text(label),
                    selected: _aim == aim,
                    onSelected: (_) => setState(() => _aim = aim),
                  );
                }).toList(),
              ),
            ],
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
