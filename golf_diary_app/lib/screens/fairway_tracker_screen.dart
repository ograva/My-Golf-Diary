import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../data/ph_golf_catalog.dart';
import '../data/ph_golf_hole_coords.dart';
import '../models/diary_context_note.dart';
import '../on_course/on_course_aim.dart';
import '../on_course/on_course_hud_gating.dart';
import '../on_course/on_course_shot_segment.dart';
import '../widgets/oncourse_map_pane.dart';
import '../models/golf_models.dart';
import '../services/diary_model.dart';
import '../services/local_database_service.dart';
import '../services/pin_distance.dart';
import '../widgets/account_avatar_app_bar_menu.dart';
import '../widgets/diary_launcher.dart';
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
  bool _showMapPane = false;
  String _aimDirection = kOnCourseAimCenter;
  bool _locationPermissionBlocked = false;
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

  void _clampMapPane() {
    if (!_mappedHoleFeatures && _showMapPane) {
      _showMapPane = false;
    }
  }

  void _syncPinWatch() {
    _clampMapPane();
    final coords = _screenVisible ? _activeCoords : null;
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
            const LocationSettings(accuracy: LocationAccuracy.high),
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
        final position = await _readGps();
        if (position == null) {
          if (mounted && !_locationPermissionBlocked) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Couldn't read location. Shot not saved."),
              ),
            );
          }
          return;
        }

        await LocalDatabaseService.instance.recordFairwayHit(
          roundId: _roundId!,
          holeNumber: _holeNumber,
          clubId: _selectedClub!.id,
          lieType: _lieType,
          currentLat: position.latitude,
          currentLon: position.longitude,
          aimDirection: _mappedHoleFeatures
              ? normalizeOnCourseAim(_aimDirection)
              : kOnCourseAimCenter,
        );
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

  static String _aimLabel(String aim) => switch (aim) {
        kOnCourseAimLeft => '◀ L',
        kOnCourseAimRight => 'R ▶',
        _ => '●',
      };

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
          ],
        ),
      ),
    );
    if (picked != null && picked != _holeNumber) {
      await _stepHole(picked - _holeNumber);
    }
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
    if (picked != null && mounted) setState(() => _selectedClub = picked);
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

  Future<void> _openAimSheet() async {
    final picked = await _openSheet<String>(
      key: 'oncourse-aim-sheet',
      title: 'Aim',
      builder: (sheetContext) => Wrap(
        spacing: 8,
        children: kOnCourseAimChoices.map((aim) {
          return ChoiceChip(
            key: ValueKey('oncourse-aim-$aim'),
            label: Text(_aimLabel(aim)),
            selected: _aimDirection == aim,
            onSelected: (_) => Navigator.of(sheetContext).pop(aim),
          );
        }).toList(),
      ),
    );
    if (picked != null && mounted) setState(() => _aimDirection = picked);
  }

  Widget _summaryPill({
    required String key,
    required String label,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return ActionChip(
      key: ValueKey(key),
      tooltip: tooltip,
      onPressed: onPressed,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const Icon(Icons.arrow_drop_down, size: 20),
        ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
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
    final caption = PhGolfCatalog.courseCaption(_appliedCourseName);
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
              Expanded(
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
                    if (caption != null) ...[
                      const SizedBox(width: 8),
                      Text(caption,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined,
                  size: 20, semanticLabel: 'Edit course'),
            ],
          ),
        ),
      ),
    );
    return Row(
      children: [
        Expanded(child: summary),
        const SizedBox(width: 8),
        _modeToggle(),
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

  Widget _modeToggle() {
    return SegmentedButton<bool>(
      key: const ValueKey('oncourse-mode-toggle'),
      emptySelectionAllowed: false,
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? GolfPalette.fairwayGreen
                : null),
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

  Widget? _courseMicroLine(BuildContext context) {
    if (!_mappedHoleFeatures) return null;
    final Widget distance;
    if (_yardsToPin != null) {
      distance = Text(
        '$_yardsToPin yds to pin',
        key: const ValueKey('on-course-distance-to-hole'),
        semanticsLabel: 'Yards to the pin',
        style: GolfTextStyles.tabularNum(context, fontSize: 20),
      );
    } else if (_readingLocation) {
      distance = Text(
        'Reading location…',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    } else {
      distance = const SizedBox.shrink();
    }
    return Row(
      children: [
        Expanded(child: distance),
        SegmentedButton<bool>(
          key: const ValueKey('on-course-map-toggle'),
          emptySelectionAllowed: false,
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: const [
            ButtonSegment<bool>(value: false, label: Text('HUD')),
            ButtonSegment<bool>(value: true, label: Text('Map')),
          ],
          selected: {_showMapPane},
          onSelectionChanged: (selection) {
            setState(() => _showMapPane = selection.first);
          },
        ),
      ],
    );
  }

  Widget _shotTile(ShotRecord s) {
    final aimNote = !_simulator && s.aimDirection != kOnCourseAimCenter
        ? ' · Aim ${s.aimDirection}'
        : '';
    final subtitle = _simulator
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
      trailing: s.notes.trim().isNotEmpty
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

  @override
  Widget build(BuildContext context) {
    final strokes = _holeScore?.strokes ?? _shots.length;
    final penalties = _holeScore?.penalties ?? 0;
    final mulligans = _holeScore?.mulligans ?? 0;
    final holeScore = computeFinalScore(strokes: strokes, penalties: penalties);
    final microLine = _simulator ? null : _courseMicroLine(context);
    final showAim = _mappedHoleFeatures && !_simulator;

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
        ),
        title: const Text('On Course'),
        actions: const [AccountAvatarAppBarMenu()],
      ),
      body: _withDiaryEdgeSwipe(LayoutBuilder(
        builder: (context, constraints) {
          final mapHeight = (constraints.maxHeight - 430).clamp(200.0, 520.0);
          return CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _courseSummary(context),
                          const SizedBox(height: 8),
                          if (!_simulator &&
                              _showMapPane &&
                              _activeCoords != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: SizedBox(
                                height: mapHeight,
                                child: Center(
                                  child: OncourseMapPane(
                                    courseName: _appliedCourseName,
                                    holeNumber: _holeNumber,
                                    coords: _activeCoords!,
                                    shots: _shots,
                                    player: _playerFix,
                                  ),
                                ),
                              ),
                            ),
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
                                    if (microLine != null)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: microLine,
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Wrap(
                                            spacing: 8,
                                            children: [
                                              _summaryPill(
                                                key: 'oncourse-club-summary',
                                                label: _selectedClub?.name ??
                                                    'Club',
                                                tooltip: 'Choose club',
                                                onPressed: _openClubSheet,
                                              ),
                                              _summaryPill(
                                                key: 'oncourse-lie-summary',
                                                label: _lieLabel(_lieType),
                                                tooltip: 'Choose lie',
                                                onPressed: _openLieSheet,
                                              ),
                                              if (showAim)
                                                _summaryPill(
                                                  key: 'oncourse-aim-summary',
                                                  label:
                                                      'Aim ${_aimLabel(_aimDirection)}',
                                                  tooltip: 'Choose aim',
                                                  onPressed: _openAimSheet,
                                                ),
                                            ],
                                          ),
                                          if (_simulator)
                                            ..._simulatorFieldWidgets(),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: _stepper(
                                                    label: 'Penalty',
                                                    keyPrefix:
                                                        'oncourse-penalty',
                                                    count: penalties,
                                                    onStep: (delta) =>
                                                        LocalDatabaseService
                                                            .instance
                                                            .incrementPenalties(
                                                                _roundId!,
                                                                _holeNumber,
                                                                delta),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: _stepper(
                                                    label: 'Mulligan',
                                                    keyPrefix:
                                                        'oncourse-mulligan',
                                                    count: mulligans,
                                                    onStep: (delta) =>
                                                        LocalDatabaseService
                                                            .instance
                                                            .incrementMulligans(
                                                                _roundId!,
                                                                _holeNumber,
                                                                delta),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (_locationPermissionBlocked && !_simulator) ...[
                            const SizedBox(height: 8),
                            MaterialBanner(
                              key: const ValueKey('oncourse-location-banner'),
                              content: const Text(
                                  'Location is off for shot tracking.'),
                              actions: [
                                TextButton(
                                  onPressed: Geolocator.openAppSettings,
                                  child: const Text('Open settings'),
                                ),
                              ],
                            ),
                          ],
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
