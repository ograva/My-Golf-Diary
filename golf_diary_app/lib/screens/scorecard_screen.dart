import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/ph_golf_catalog.dart';
import '../models/scorecard_preferences.dart';
import '../models/diary_context_note.dart';
import '../models/golf_models.dart';
import '../models/round_summary.dart';
import '../models/scoring_format.dart';
import '../services/diary_model.dart';
import '../services/local_database_service.dart';
import '../services/swing_diary_service.dart';
import '../theme/app_theme.dart';
import '../widgets/account_avatar_app_bar_menu.dart';
import '../widgets/course_round_dialog.dart';
import '../widgets/diary_launcher.dart';
import '../widgets/flight_sheet.dart';
import '../widgets/round_finish_dialogs.dart';
import '../widgets/save_round_before_new_dialog.dart';
import '../widgets/scorecard_cart_panel.dart';
import '../widgets/shared_header_actions.dart';
import 'scorecard_hole_editor.dart';

class ScorecardScreen extends StatefulWidget {
  const ScorecardScreen({
    super.key,
    this.diary,
    this.onProfileSettingsChanged,
  });

  /// When null, diary entry uses [VertexDiaryModel]. Tests pass a fake.
  final DiaryModel? diary;
  final VoidCallback? onProfileSettingsChanged;

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
  String _viewMode = ScorecardViewMode.classic;
  bool _cartHighContrast = false;
  int _cartSelectedHole = 1;
  bool _wakelockActive = false;
  RoundFormatSettings? _format;
  double? _handicap;
  String? _unlockedRoundId;

  @override
  void initState() {
    super.initState();
    _loadViewPreferences();
    loadScorecard();
  }

  @override
  void dispose() {
    if (_wakelockActive) {
      try {
        WakelockPlus.disable();
      } catch (_) {}
      _wakelockActive = false;
    }
    super.dispose();
  }

  Future<void> _loadViewPreferences() async {
    final profile = await LocalDatabaseService.instance.getGolferProfile();
    if (!mounted) return;
    setState(() {
      _viewMode = profile.scorecardViewMode;
      _cartHighContrast = profile.scorecardCartHighContrastEnabled;
    });
  }

  Future<void> _persistViewMode(String mode) async {
    final db = LocalDatabaseService.instance;
    final profile = await db.getGolferProfile();
    await db.saveGolferProfile(profile.copyWith(scorecardViewMode: mode));
    if (!mounted) return;
    setState(() => _viewMode = mode);
    await _syncWakelock();
  }

  Future<void> _persistHighContrast(bool value) async {
    final db = LocalDatabaseService.instance;
    final profile = await db.getGolferProfile();
    await db.saveGolferProfile(
      profile.copyWith(scorecardCartHighContrast: value ? 1 : 0),
    );
    if (!mounted) return;
    setState(() => _cartHighContrast = value);
  }

  Future<void> _syncWakelock() async {
    final roundActive = _selectedRoundId != null &&
        _recentRounds.any(
          (r) => r.roundId == _selectedRoundId && !r.isCompleted,
        );
    final shouldLock =
        _viewMode == ScorecardViewMode.cart && roundActive;
    if (shouldLock && !_wakelockActive) {
      try {
        await WakelockPlus.enable();
        _wakelockActive = true;
      } catch (_) {
        // Unsupported in widget tests and some desktop embedders.
      }
    } else if (!shouldLock && _wakelockActive) {
      try {
        await WakelockPlus.disable();
        _wakelockActive = false;
      } catch (_) {}
    }
  }

  Future<void> _primeCartHole() async {
    final roundId = _selectedRoundId;
    if (roundId == null) return;
    final current = await LocalDatabaseService.instance
        .currentHoleNumber(roundId);
    if (!mounted) return;
    setState(() => _cartSelectedHole = current.clamp(1, _holesOnCard));
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
    RoundFormatSettings? format;
    if (roundId != null) {
      holes = await db.getScoresForRound(roundId);
      totals = await db.computeRoundTotals(roundId);
      format = await db.getRoundFormat(roundId);
    }
    final handicap = await db.unofficialHandicapEstimate();
    if (!mounted) return;
    final loadedCourse = totals?.courseName ??
        (holes.isNotEmpty ? holes.first.courseName : 'Local Course');
    final holeCount = _holesOnCardForCourse(loadedCourse);
    setState(() {
      _recentRounds = recent;
      _selectedRoundId = roundId;
      _holes = holes;
      _totals = totals;
      _format = format;
      _handicap = handicap;
      _loading = false;
      if (_cartSelectedHole > holeCount) {
        _cartSelectedHole = 1;
      }
    });
    await _primeCartHole();
    await _syncWakelock();
  }

  int _holesOnCardForCourse(String courseName) =>
      PhGolfCatalog.holeCount(courseName);

  Future<void> _startNewRound() async {
    final db = LocalDatabaseService.instance;
    final activeId = await db.getActiveRoundId();
    if (activeId != null && await db.roundHasMeaningfulPlay(activeId)) {
      final course = await db.getCourseNameForRound(activeId);
      if (!mounted) return;
      final choice = await showSaveRoundBeforeNewDialog(
          context: context, courseName: course);
      if (choice == null || choice == SaveRoundBeforeNewChoice.cancel) return;
      if (choice == SaveRoundBeforeNewChoice.saveAndStartNew) {
        await db.completeRound(activeId);
        await _writeRoundDiary(activeId);
      } else {
        await db.discardRound(activeId);
      }
    }

    final recentCourses = await db.distinctCourseNames();
    if (!mounted) return;
    final result = await showCourseRoundDialog(
      context: context,
      initial: const CourseRoundValues(courseName: 'Local Course'),
      recentNames: recentCourses,
    );
    if (result == null || !mounted) return;
    final roundId = await db.startNewRound(
      courseName: result.courseName,
      par: PhGolfCatalog.parForHole(result.courseName, 1) ?? 4,
    );
    await db.saveRoundFormat(
      applyCourseRoundValues(
        RoundFormatSettings(roundId: roundId),
        result,
      ),
    );
    if (!mounted) return;
    setState(() => _selectedRoundId = roundId);
    await loadScorecard();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Started round at ${result.courseName}'),
          backgroundColor: AppColors.green),
    );
  }

  Future<void> _editCourse() async {
    final roundId = _selectedRoundId;
    final settings = _format;
    if (roundId == null || settings == null) return;
    if (_locked) {
      _showReadOnly();
      return;
    }
    final recent =
        await LocalDatabaseService.instance.distinctCourseNames();
    if (!mounted) return;
    final result = await showCourseRoundDialog(
      context: context,
      initial: CourseRoundValues(
        courseName: _courseName,
        format: settings.format,
        molaveDoubleEaglePoints: settings.molaveDoubleEaglePoints,
        courseRating: settings.courseRating,
        slopeRating: settings.slopeRating,
      ),
      recentNames: recent,
    );
    if (result == null || !mounted) return;
    if (!courseRoundChanged(
      courseName: _courseName,
      settings: settings,
      next: result,
    )) {
      return;
    }
    if (!await _allowEdit() || !mounted) return;
    final db = LocalDatabaseService.instance;
    if (result.courseName != _courseName) {
      await db.applyCoursePar(roundId, result.courseName);
    }
    await db.saveRoundFormat(applyCourseRoundValues(settings, result));
    await loadScorecard();
  }

  RoundScore? _holeRow(int holeNumber) {
    for (final h in _holes) {
      if (h.holeNumber == holeNumber) return h;
    }
    return null;
  }

  String get _courseName =>
      _totals?.courseName ??
      (_holes.isNotEmpty ? _holes.first.courseName : 'Local Course');

  int get _holesOnCard => PhGolfCatalog.holeCount(_courseName);

  String _formatIndicator(RoundFormatSettings settings) {
    if (settings.format == ScoringFormat.molave) {
      final points =
          normalizeDoubleEaglePoints(settings.molaveDoubleEaglePoints);
      return '${settings.format.label} · double eagle $points';
    }
    return settings.format.label;
  }

  String? _ratingIndicator(RoundFormatSettings settings) {
    final parts = <String>[];
    final rating = settings.courseRating;
    if (rating != null) parts.add('CR ${rating.toStringAsFixed(1)}');
    if (settings.slopeRating != null) {
      parts.add('Slope ${settings.slopeRating}');
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  int? _unplayedPar(int hole) {
    if (PhGolfCatalog.matchCourse(_courseName)?.holePars == null) return null;
    final row = _holeRow(hole);
    if (row != null) return row.par;
    return PhGolfCatalog.parForHole(_courseName, hole);
  }

  Future<void> _writeRoundDiary(String roundId) async {
    final db = LocalDatabaseService.instance;
    final settings = await db.getRoundFormat(roundId);
    final holes = await db.getScoresForRound(roundId);
    final card = scoreRound(
      [
        for (final hole in holes)
          holeInputFromScore(
            holeNumber: hole.holeNumber,
            par: hole.par,
            strokes: hole.strokes,
            penalties: hole.penalties,
            conceded: hole.conceded,
            paidMulligans: hole.paidMulligans,
            finalScore: hole.finalScore,
          ),
      ],
      format: settings.format,
      doubleEaglePoints: settings.molaveDoubleEaglePoints,
      manualIndex: _handicap,
    );
    await SwingDiaryService(database: db).appendContextNote(
      content: 'Round finished. ${card.summary}. ${settings.attestationLabel}.',
      source: DiaryContextSource.scorecard,
      roundId: roundId,
    );
  }

  List<HoleScoreInput> get _holeInputs => [
        for (final hole in _holes)
          holeInputFromScore(
            holeNumber: hole.holeNumber,
            par: hole.par,
            strokes: hole.strokes,
            penalties: hole.penalties,
            conceded: hole.conceded,
            paidMulligans: hole.paidMulligans,
            finalScore: hole.finalScore,
          ),
      ];

  FormatCardResult? get _card {
    final settings = _format;
    if (settings == null) return null;
    return scoreRound(
      _holeInputs,
      format: settings.format,
      doubleEaglePoints: settings.molaveDoubleEaglePoints,
      manualIndex: _handicap,
    );
  }

  RoundSummary? get _selectedSummary {
    for (final r in _recentRounds) {
      if (r.roundId == _selectedRoundId) return r;
    }
    return null;
  }

  bool get _finished => _selectedSummary?.isCompleted ?? false;

  bool get _locked => _finished && _unlockedRoundId != _selectedRoundId;

  Future<bool> _allowAttestedEdit() async {
    final settings = _format;
    final roundId = _selectedRoundId;
    if (settings == null || roundId == null || !settings.isAttested) {
      return true;
    }
    final ok = await showAttestedEditConfirm(context);
    if (!ok || !mounted) return false;
    await LocalDatabaseService.instance.invalidateAttestation(roundId);
    return true;
  }

  /// Finished rounds are read-only until unlocked from the ⋮ menu.
  Future<bool> _allowEdit() async {
    if (_locked) {
      _showReadOnly();
      return false;
    }
    return _allowAttestedEdit();
  }

  void _showReadOnly() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        key: ValueKey('scorecard-read-only-snack'),
        content:
            Text('Round finished. Use ⋮ › Edit finished round to change it.'),
      ),
    );
  }

  void _unlockFinishedRound() {
    setState(() => _unlockedRoundId = _selectedRoundId);
  }

  Future<void> _attest() async {
    final roundId = _selectedRoundId;
    if (roundId == null) return;
    final saved = await showAttestCardDialog(context, roundId: roundId);
    if (!saved || !mounted) return;
    await loadScorecard();
  }

  Future<void> _finishRound() async {
    final roundId = _selectedRoundId;
    if (roundId == null) return;
    final blank = blankHoleCount(_holes, _holesOnCard);
    if (!await confirmFinishRound(context, blank) || !mounted) return;
    final db = LocalDatabaseService.instance;
    await db.completeRound(roundId);
    await _writeRoundDiary(roundId);
    if (!mounted) return;
    setState(() => _unlockedRoundId = null);
    await loadScorecard();
    if (!mounted) return;
    await showAttestCardDialog(context, roundId: roundId, afterFinish: true);
    if (!mounted) return;
    await loadScorecard();
  }

  Future<void> _deleteRound() async {
    final roundId = _selectedRoundId;
    if (roundId == null) return;
    final db = LocalDatabaseService.instance;
    final inFlight = await db.roundHasFlight(roundId);
    if (!mounted) return;
    final ok = await confirmDeleteRound(
      context,
      courseName: _courseName,
      attested: _format?.isAttested ?? false,
      inFlight: inFlight,
    );
    if (!ok || !mounted) return;
    await db.deleteRound(roundId);
    final remaining = await db.listRecentRounds(limit: 1);
    if (!mounted) return;
    setState(() {
      _selectedRoundId = remaining.isEmpty ? null : remaining.first.roundId;
      _unlockedRoundId = null;
    });
    await loadScorecard();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Round deleted')),
    );
  }

  Future<void> _openFlight() async {
    final roundId = _selectedRoundId;
    final settings = _format;
    if (roundId == null || settings == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: FlightSheet(
          roundId: roundId,
          courseName: _courseName,
          format: settings.format,
          displayName: 'Me',
        ),
      ),
    );
  }

  Future<void> _cartMutation(Future<void> Function() action) async {
    await action();
    await loadScorecard();
  }

  Future<void> _cartPlusStroke() async {
    final roundId = _selectedRoundId;
    if (roundId == null) return;
    if (!await _allowEdit() || !mounted) return;
    await _cartMutation(() => LocalDatabaseService.instance.incrementStrokes(
          roundId: roundId,
          courseName: _courseName,
          holeNumber: _cartSelectedHole,
        ));
  }

  Future<void> _cartPenalty() async {
    final roundId = _selectedRoundId;
    if (roundId == null) return;
    if (!await _allowEdit() || !mounted) return;
    await _cartMutation(() async {
      await LocalDatabaseService.instance.ensureHoleRow(
        roundId: roundId,
        courseName: _courseName,
        holeNumber: _cartSelectedHole,
      );
      await LocalDatabaseService.instance
          .incrementPenalties(roundId, _cartSelectedHole, 1);
    });
  }

  Future<void> _cartMulligan() async {
    final roundId = _selectedRoundId;
    if (roundId == null) return;
    if (!await _allowEdit() || !mounted) return;
    await _cartMutation(() async {
      await LocalDatabaseService.instance.ensureHoleRow(
        roundId: roundId,
        courseName: _courseName,
        holeNumber: _cartSelectedHole,
      );
      await LocalDatabaseService.instance
          .incrementMulligans(roundId, _cartSelectedHole);
    });
  }

  Future<void> _cartGimme() async {
    final roundId = _selectedRoundId;
    if (roundId == null) return;
    if (!await _allowEdit() || !mounted) return;
    await _cartMutation(() async {
      await LocalDatabaseService.instance.ensureHoleRow(
        roundId: roundId,
        courseName: _courseName,
        holeNumber: _cartSelectedHole,
      );
      await LocalDatabaseService.instance
          .concedeHole(roundId, _cartSelectedHole);
    });
  }

  Future<void> _editHole(int holeNumber) async {
    final roundId = _selectedRoundId;
    if (roundId == null) return;
    if (!await _allowEdit() || !mounted) return;
    await showScorecardHoleEditor(
      context: context,
      roundId: roundId,
      courseName: _courseName,
      holeNumber: holeNumber,
      existing: _holeRow(holeNumber),
      format: _format?.format ?? ScoringFormat.gross,
      doubleEaglePoints: _format?.molaveDoubleEaglePoints ?? 7,
    );
    await loadScorecard();
  }

  @override
  Widget build(BuildContext context) {
    final format = _format;
    final ratingLine = format == null ? null : _ratingIndicator(format);

    return Scaffold(
      appBar: AppBar(
        leading: PlayHeaderOverflowButton(
          showCaddy: _selectedRoundId != null,
          roundId: _selectedRoundId,
          courseName: _selectedRoundId == null ? '' : _courseName,
          caddyInviteKey: 'scorecard-invite-caddy',
          extraActions: [
            if (_selectedRoundId != null)
              PlayHeaderMenuAction(
                id: 'flight',
                key: 'scorecard-flight-btn',
                icon: Icons.groups_outlined,
                label: 'Flight',
                dividerBefore: true,
                onSelected: () {
                  _openFlight();
                },
              ),
            if (_locked)
              PlayHeaderMenuAction(
                id: 'edit-finished-round',
                key: 'scorecard-edit-finished-round',
                icon: Icons.lock_open_outlined,
                label: 'Edit finished round',
                onSelected: _unlockFinishedRound,
              ),
          ],
        ),
        title: const Text('Scorecard'),
        actions: [
          DiaryEntryButton(
            entryKey: 'diary-entry-scorecard',
            diary: widget.diary,
            entrySource: DiaryContextSource.scorecard,
          ),
          const AccountAvatarAppBarMenu(),
        ],
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(key: ValueKey('scorecard-loading')),
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
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            key: const ValueKey('scorecard-course-summary'),
                            onTap: _editCourse,
                            borderRadius: BorderRadius.circular(8),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 40),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _courseName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                      semanticLabel: 'Edit course',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SegmentedButton<String>(
                          key: const ValueKey('scorecard-view-mode-toggle'),
                          style: const ButtonStyle(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          segments: const [
                            ButtonSegment(
                              value: ScorecardViewMode.classic,
                              label: Text('Classic'),
                            ),
                            ButtonSegment(
                              value: ScorecardViewMode.cart,
                              label: Text('Cart'),
                            ),
                          ],
                          selected: {_viewMode},
                          onSelectionChanged: (selection) {
                            _persistViewMode(selection.first);
                          },
                          showSelectedIcon: false,
                        ),
                      ],
                    ),
                    if (PhGolfCatalog.courseCaption(_courseName) != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          PhGolfCatalog.courseCaption(_courseName)!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (format != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          _formatIndicator(format),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (ratingLine != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          ratingLine,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (_handicap != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          'Unofficial estimate $_handicap',
                          key: const ValueKey('scorecard-handicap-estimate'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    if (_selectedSummary != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 4),
                        child: Text(
                          !_finished
                              ? 'In progress'
                              : _locked
                                  ? 'Finished · read-only'
                                  : 'Finished · editing',
                          key: const ValueKey('scorecard-round-status'),
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
                                key: ValueKey(
                                    'scorecard-round-chip-${summary.roundId}'),
                                label: Text(summary.label,
                                    overflow: TextOverflow.ellipsis),
                                selected: _selectedRoundId == summary.roundId,
                                onSelected: (_) {
                                  setState(
                                      () => _selectedRoundId = summary.roundId);
                                  loadScorecard();
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (_viewMode == ScorecardViewMode.classic) ...[
                      const SizedBox(height: 8),
                      _SummaryBanner(
                        totals: _totals,
                        formatSummary: _card?.summary,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_viewMode == ScorecardViewMode.cart &&
                        _selectedRoundId != null)
                      ScorecardCartPanel(
                        courseName: _courseName,
                        holeCount: _holesOnCard,
                        selectedHole: _cartSelectedHole,
                        totals: _totals,
                        holeRow: _holeRow,
                        highContrast: _cartHighContrast,
                        onHoleSelected: (hole) =>
                            setState(() => _cartSelectedHole = hole),
                        onPlusStroke: _cartPlusStroke,
                        onPenalty: _cartPenalty,
                        onMulligan: _cartMulligan,
                        onGimme: _cartGimme,
                        onHighContrastChanged: _persistHighContrast,
                        formatSummary: _card?.summary,
                      ),
                    if (_viewMode == ScorecardViewMode.classic)
                      _NineGrid(
                      title: 'FRONT 9',
                      startHole: 1,
                      holeRow: _holeRow,
                      unplayedPar: _unplayedPar,
                        onHoleTap: _editHole,
                      ),
                    if (_viewMode == ScorecardViewMode.classic &&
                        _holesOnCard > 9) ...[
                      const SizedBox(height: 16),
                      _NineGrid(
                        title: 'BACK 9',
                        startHole: 10,
                        holeRow: _holeRow,
                        unplayedPar: _unplayedPar,
                        onHoleTap: _editHole,
                      ),
                    ],
                    if (_finished && format != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        format.attestationLabel,
                        key: const ValueKey('scorecard-attest-badge'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_selectedRoundId != null && !_finished)
                      FilledButton.icon(
                        key: const ValueKey('scorecard-finish-round'),
                        onPressed: _finishRound,
                        icon: const Icon(Icons.flag_outlined),
                        label: const Text('Finish round'),
                      )
                    else if (_finished &&
                        format != null &&
                        !format.isAttested)
                      FilledButton.icon(
                        key: const ValueKey('scorecard-attest-btn'),
                        onPressed: _attest,
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('Attest card'),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey('scorecard-new-round-btn'),
                            onPressed: _startNewRound,
                            icon: const Icon(Icons.add),
                            label: const Text('Start new round'),
                          ),
                        ),
                        if (_selectedRoundId != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const ValueKey('scorecard-delete-round'),
                              onPressed: _deleteRound,
                              style: OutlinedButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.error,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete round'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.totals, this.formatSummary});

  final RoundTotals? totals;
  final String? formatSummary;

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
                _SummaryCell(
                    label: 'OUT',
                    value: '${t.frontNineScore}',
                    toPar: t.frontNineToPar),
                _SummaryCell(
                    label: 'IN',
                    value: '${t.backNineScore}',
                    toPar: t.backNineToPar),
                _SummaryCell(
                    label: 'TOT',
                    value: '${t.totalScore}',
                    toPar: t.totalToPar),
              ],
            ),
            if (formatSummary != null) ...[
              const SizedBox(height: 8),
              Text(
                formatSummary!,
                key: const ValueKey('scorecard-format-total'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
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
  const _SummaryCell(
      {required this.label, required this.value, required this.toPar});

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
    required this.unplayedPar,
    required this.onHoleTap,
  });

  final String title;
  final int startHole;
  final RoundScore? Function(int holeNumber) holeRow;
  final int? Function(int holeNumber) unplayedPar;
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
                      unplayedPar: unplayedPar(startHole + row * 3 + col),
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
  const _HoleTile({
    required this.hole,
    required this.row,
    required this.unplayedPar,
    required this.onTap,
  });

  final int hole;
  final RoundScore? row;
  final int? unplayedPar;
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
            ? (unplayedPar == null ? '—' : 'Par $unplayedPar')
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
                    : (toPar == null
                        ? Theme.of(context).textTheme.labelSmall
                        : _deltaStyle(context, toPar)),
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
  return GolfTextStyles.tabularNum(context,
      fontSize: 12, fontWeight: FontWeight.w600);
}
