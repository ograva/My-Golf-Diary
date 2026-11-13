import 'package:flutter/material.dart';

import '../data/ph_golf_catalog.dart';
import '../models/golf_models.dart';
import '../models/golfer_profile.dart';
import '../models/practice_drill.dart';
import '../models/range_session.dart';
import '../services/diary_model.dart';
import '../services/local_database_service.dart';
import '../services/swing_diary_service.dart';
import '../services/vertex_diary_model.dart';
import '../theme/app_theme.dart';
import '../widgets/practice_drill_sheet.dart';
import '../widgets/range_session_log.dart';
import '../widgets/swing_diary_sheet.dart';
import '../widgets/sync_cloud_button.dart';
import '../widgets/venue_name_field.dart';

class RangeDrillScreen extends StatefulWidget {
  const RangeDrillScreen({super.key, this.diary});

  /// When null, calls go through [VertexDiaryModel]. Tests pass a fake.
  final DiaryModel? diary;

  @override
  State<RangeDrillScreen> createState() => RangeDrillScreenState();
}

class RangeDrillScreenState extends State<RangeDrillScreen> {
  List<Club> _clubs = [];
  List<RangeDrillSummary> _log = [];
  List<RangeSession> _compiled = [];
  List<String> _recentVenues = [];
  Club? _selectedClub;
  PracticeDrill? _selectedDrill;
  int _shotCounter = 0;
  bool _logThisClubOnly = true;
  late final DiaryModel _diary;
  final SwingDiaryService _diaryStore = SwingDiaryService();

  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();
  final TextEditingController _avgController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _sessionNoteController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final FocusNode _sessionNoteFocus = FocusNode();
  GolferProfile _profile = const GolferProfile();
  bool _clubsMissingSpecs = false;

  @override
  void initState() {
    super.initState();
    _diary = widget.diary ?? VertexDiaryModel();
    reload();
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _avgController.dispose();
    _notesController.dispose();
    _sessionNoteController.dispose();
    _venueController.dispose();
    _sessionNoteFocus.dispose();
    super.dispose();
  }

  Future<void> reload() async {
    final clubs = await LocalDatabaseService.instance.getAllClubs();
    final profile = await LocalDatabaseService.instance.getGolferProfile();
    final log = await LocalDatabaseService.instance.listUncompiledRangeDrills();
    final compiled = await LocalDatabaseService.instance.listRangeSessions();
    final venues = await LocalDatabaseService.instance.distinctVenueNames();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _clubsMissingSpecs = clubsMissingEquipmentSpecs(clubs);
      _clubs = clubs.where((c) => c.category != 'putter').toList();
      _log = log;
      _compiled = compiled;
      _recentVenues = venues;
      if (_selectedClub == null && _clubs.isNotEmpty) {
        _selectedClub = _clubs.first;
        _notesController.text = _selectedClub!.swingNotes;
      } else if (_selectedClub != null &&
          !_clubs.any((c) => c.id == _selectedClub!.id)) {
        _selectedClub = _clubs.isNotEmpty ? _clubs.first : null;
      }
    });
  }

  bool get _hasPendingBlock =>
      _shotCounter > 0 ||
      _minController.text.trim().isNotEmpty ||
      _avgController.text.trim().isNotEmpty ||
      _maxController.text.trim().isNotEmpty;

  Future<void> _saveDrillSet({bool quiet = false}) async {
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
      drillId: _selectedDrill?.id,
    );

    await LocalDatabaseService.instance.saveRangeDrill(log);

    if (mounted) {
      if (!quiet) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved drill for ${_selectedClub!.name}!'),
            backgroundColor: AppColors.green,
          ),
        );
      }
      setState(() => _shotCounter = 0);
      _minController.clear();
      _maxController.clear();
      _avgController.clear();
      await reload();
    }
  }

  Future<void> _saveAndEvaluate() async {
    if (_hasPendingBlock) {
      await _saveDrillSet(quiet: true);
    }
    try {
      await LocalDatabaseService.instance.compileRangeSession(
        sessionNote: _sessionNoteController.text,
        venueName: _venueController.text.trim(),
      );
    } on ArgumentError catch (error) {
      if (!mounted) return;
      final message = error.message?.toString() ?? kEmptyRangeSessionMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    if (!mounted) return;
    _sessionNoteController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session log saved. It is stored for later evaluation.'),
      ),
    );
    await reload();
  }

  void _applyLeadIn(LeadInPrompt prompt) {
    final current = _sessionNoteController.text.trim();
    if (!current.contains(prompt.prefix)) {
      _sessionNoteController.text =
          current.isEmpty ? prompt.prefix : '$current\n${prompt.prefix}';
    }
    _sessionNoteFocus.requestFocus();
  }

  Future<void> _dismissLeadIn(LeadInPrompt prompt) async {
    final dismissed = {..._profile.dismissedPrompts, prompt.id}.toList();
    await LocalDatabaseService.instance.saveGolferProfile(
      _profile.copyWith(dismissedPrompts: dismissed),
    );
    await reload();
  }

  Future<void> _openDiary() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SwingDiarySheet(diary: _diary, store: _diaryStore),
    );
    await reload();
  }

  Future<void> _openDrills() async {
    final pick = await showModalBottomSheet<PracticeDrillPick>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const PracticeDrillSheet(),
    );
    if (!mounted || pick == null) return;
    setState(() {
      _selectedDrill = pick.drill;
      if (pick.copyTitleToNote) {
        _notesController.text = pick.drill.title;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final thisClubOnly = _logThisClubOnly && _selectedClub != null;
    final visibleLog = thisClubOnly
        ? _log
            .where((entry) => entry.drill.clubId == _selectedClub!.id)
            .toList()
        : _log;
    final visibleCompiled = thisClubOnly
        ? _compiled.where((session) => session.includesClub(_selectedClub!.id)).toList()
        : _compiled;
    final visitLines = _log
        .map((entry) =>
            '${entry.clubName} · avg ${entry.drill.avgYards.round()} · ${entry.drill.tempoNotes}')
        .join('\n');
    final leadIn = leadInPrompts(
      _profile,
      clubsMissingSpecs: _clubsMissingSpecs,
      limit: 1,
    ).firstOrNull;
    final emptyLogMessage = thisClubOnly
        ? 'No range sessions for ${_selectedClub!.name} yet.'
        : 'Saved drills show up here, newest first.';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const ValueKey('range-header-drills-btn'),
          tooltip: 'Practice drills',
          onPressed: _openDrills,
          icon: const Icon(Icons.list_alt),
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
        title: const Text('Range Drill Instructor'),
        actions: [
          IconButton(
            key: const ValueKey('range-swing-diary-btn'),
            tooltip: 'Swing diary',
            onPressed: _openDiary,
            icon: const Icon(Icons.auto_stories_outlined),
          ),
          const SyncCloudButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VenueNameField(
              controller: _venueController,
              labelText: 'Driving range or simulator',
              hintText: 'Topgolf, local range, sim bay…',
              recentNames: _recentVenues,
              catalogNames: PhGolfCatalog.rangeAndSimNames,
            ),
            if (_selectedDrill != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDrill!.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedDrill = null),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ],
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: AppColors.amber),
                        SizedBox(width: 8),
                        Text('Swing Cue & Mechanics Note',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        hintText:
                            'e.g., 3:1 tempo, pause at top, smooth transition',
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
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _shotCounter >= 10
                      ? null
                      : () => setState(() => _shotCounter++),
                  icon: const Icon(Icons.sports_golf),
                  label: const Text('Hit Shot'),
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(140, 56)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Min (Yds)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _avgController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Avg (Yds)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Max (Yds)', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 72,
              child: ElevatedButton(
                onPressed: _saveDrillSet,
                child: const Text('Save Drill Session',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              key: const ValueKey('range-visit-wrapup-card'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Session note',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    TextField(
                      key: const ValueKey('range-session-note-field'),
                      controller: _sessionNoteController,
                      focusNode: _sessionNoteFocus,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'How the session went',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (leadIn != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: ActionChip(
                                key: ValueKey('range-lead-in-chip-${leadIn.id}'),
                                label: Text(leadIn.label),
                                onPressed: () => _applyLeadIn(leadIn),
                              ),
                            ),
                          ),
                          IconButton(
                            key: ValueKey('range-lead-in-dismiss-${leadIn.id}'),
                            tooltip: 'Dismiss',
                            onPressed: () => _dismissLeadIn(leadIn),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      visitLines.isEmpty
                          ? 'No club blocks in this visit yet.'
                          : visitLines,
                      key: const ValueKey('range-visit-summary-preview'),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      key: const ValueKey('range-save-evaluate-session-btn'),
                      onPressed: _saveAndEvaluate,
                      child: const Text('Save and evaluate session'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              thisClubOnly
                  ? 'Session log · ${_selectedClub!.name}'
                  : 'Session log',
              key: const Key('range-session-log-title'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  key: const Key('range-log-this-club'),
                  label: const Text('This club'),
                  selected: thisClubOnly,
                  onSelected: _selectedClub == null
                      ? null
                      : (_) => setState(() => _logThisClubOnly = true),
                ),
                FilterChip(
                  key: const Key('range-log-all'),
                  label: const Text('All clubs'),
                  selected: !thisClubOnly,
                  onSelected: (_) => setState(() => _logThisClubOnly = false),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RangeSessionLog(
              sessions: visibleLog,
              compiled: visibleCompiled,
              showClubName: !thisClubOnly,
              emptyMessage: emptyLogMessage,
            ),
          ],
        ),
      ),
    );
  }
}
