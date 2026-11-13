import '../models/golf_models.dart';
import '../models/golfer_profile.dart';
import '../models/range_session.dart';

/// Prompt ceiling from Architecture §5.6. Tests may pass a smaller ceiling.
const kDiaryTokenCeiling = 250000;

/// Recent raw window: the newer of the last 30 days and the last 36 logs.
///
/// The cutoff is the later of `now - 30 days` and the timestamp of the 36th
/// newest log that is not from today. A shorter history uses the 30-day
/// cutoff, so a years-old log is outside the window. Today is never part of
/// this window; callers always add today in full.
const kDiaryRecentWindowDays = 30;
const kDiaryRecentWindowLogs = 36;

/// Universal coaching method. The golfer's own baseline is assembled separately.
const String kCoachMethodologyPrompt = r'''
# Role & Persona
You are an elite, empathetic Golf Biomechanics Coach, Performance Physiotherapist, and Caddie Strategist. Your primary purpose is to process, analyze, and structure the golfer's practice logs, compiled range sessions, bag yardages, and swing notes into actionable mechanical refinements, injury-prevention protocols, and mental anchors.

Your tone is grounded, analytical, encouraging, and practical—like a trusted Tour caddie combined with a sports biomechanist. Avoid generic beginner clichés; connect every swing feel directly to physics, kinetic sequencing, logged yardage/dispersion numbers, and the equipment this golfer actually recorded.

# Data Grounding & Units
- Report all distances in **yards**.
- Base every yardage, shot count, dispersion spread, venue observation, and trend strictly on the golfer's logged SQLite records and the Golfer Profile below. Never fabricate unlogged numbers, sessions, venues, clubs, injuries, or swing methods.
- When the Golfer Profile is thin, coach from the logged numbers and ask at most the one check-in named at the end of these instructions.

# Core Operating Workflow
Whenever the golfer submits a session evaluation request, diary note, follow-up question, or equipment/physical update, execute these steps in order:

1. **Validate & Diagnose Biomechanically:** Translate subjective feels into cause-and-effect mechanics. Use shot counts, block order, and min/avg/max dispersion to separate a true fault from fatigue late in a bucket or round.
2. **Cross-Check Physical Safety:** If the profile names a joint, tissue, or fatigue pattern, flag any logged habit that loads it and offer a low-impact adjustment. Do not invent an injury that is not recorded.
3. **Connect to Existing Anchors & Numbers:** Map the session onto the recorded swing anchors and compare today's carry and spread with the per-club tally and earlier sessions.
4. **Output a Structured Diary Anchor:** Close session evaluations with a scannable Diary Anchor / Practice Blueprint. For a narrow follow-up, answer directly and include only the blueprint lines that add clarity.

# Formatting & Communication Rules
- Lead directly with substance. No greetings or filler.
- Never output LaTeX math delimiters (`$...$`). Use plain text and ASCII flow diagrams (`──►`) for sequencing.
- Use compact Markdown tables (2–4 columns) for club adjustments, yardage deltas, and fault-to-fix matrices.
- Keep drills to 3–5 minutes, doable in a low-ceiling room or on a range mat.
''';

String _recorded(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'Not recorded yet.' : trimmed;
}

String? _missingBaselinePillar(GolferProfile profile) {
  if (profile.physicalConstraints.trim().isEmpty) {
    return 'physical constraints (joints, tissues, or fatigue to protect)';
  }
  if (profile.swingAnchors.trim().isEmpty) {
    return 'swing anchors (tempo, setup, or a feel they want to keep)';
  }
  if (profile.trainingEnvironment.trim().isEmpty) {
    return 'training environment (aids, indoor space, or typical turf and mats)';
  }
  return null;
}

/// Coach method plus this golfer's saved baseline, bag, and venues.
String buildDiarySystemInstruction({
  required GolferProfile profile,
  required List<Club> clubs,
  required List<String> frequentVenues,
}) {
  final buffer = StringBuffer()
    ..writeln(kCoachMethodologyPrompt.trim())
    ..writeln()
    ..writeln('# Golfer Profile & Established Baseline')
    ..writeln('Equipment notes: ${_recorded(profile.equipmentNotes)}')
    ..writeln('Swing anchors: ${_recorded(profile.swingAnchors)}')
    ..writeln('Physical constraints: ${_recorded(profile.physicalConstraints)}')
    ..writeln('Training environment: ${_recorded(profile.trainingEnvironment)}');
  if (clubs.isEmpty) {
    buffer.writeln('Current bag: none saved.');
  } else {
    buffer.writeln('Current bag:');
    for (final club in clubs) {
      final spec = [club.brand.trim(), club.model.trim()]
          .where((part) => part.isNotEmpty)
          .join(' ');
      final label = spec.isEmpty ? club.name : '${club.name} ($spec)';
      final note = club.swingNotes.trim().isEmpty
          ? ''
          : ' | cue: ${club.swingNotes.trim()}';
      buffer.writeln('- $label [${club.category}]$note');
    }
  }
  buffer.writeln(frequentVenues.isEmpty
      ? 'Frequent venues: none logged yet.'
      : 'Frequent venues: ${frequentVenues.join(', ')}');
  final missing = _missingBaselinePillar(profile);
  if (missing != null) {
    buffer.writeln(
        'Caddie Check-In: $missing is still blank. End a substantive evaluation with one brief optional question that would fill only that gap. Skip the question on a narrow follow-up, and never ask more than one.');
  }
  return buffer.toString().trim();
}

int estimateDiaryTokens(String text) => (text.length / 4).ceil();

class DiaryTurn {
  const DiaryTurn({required this.role, required this.content});

  final String role;
  final String content;
}

class ClubTally {
  const ClubTally({
    required this.clubName,
    required this.sessionCount,
    required this.thisPeriodAvg,
    required this.previousPeriodAvg,
    required this.drillTitles,
  });

  final String clubName;
  final int sessionCount;
  final double? thisPeriodAvg;
  final double? previousPeriodAvg;
  final List<String> drillTitles;
}

class DiaryPromptInput {
  const DiaryPromptInput({
    required this.now,
    required this.drills,
    required this.sessions,
    required this.turns,
    required this.tallies,
    this.clubs = const [],
    this.profile = const GolferProfile(),
    this.frequentVenues = const [],
    this.progressBrief,
    this.question = '',
    this.systemPrompt,
    this.tokenCeiling = kDiaryTokenCeiling,
  });

  final DateTime now;
  final List<RangeDrillSummary> drills;
  final List<RangeSession> sessions;
  final List<DiaryTurn> turns;
  final List<ClubTally> tallies;
  final List<Club> clubs;
  final GolferProfile profile;
  final List<String> frequentVenues;
  final String? progressBrief;
  final String question;

  /// When null, the system text is built from [profile], [clubs], and [frequentVenues].
  final String? systemPrompt;
  final int tokenCeiling;
}

class DiaryPromptPlan {
  const DiaryPromptPlan({
    required this.systemInstruction,
    required this.prompt,
    required this.tokens,
    this.summary,
    this.coveredThroughMs,
  });

  final String systemInstruction;
  final String prompt;
  final int tokens;

  /// Set when the oldest history was folded. Null means send the raw history.
  final String? summary;
  final int? coveredThroughMs;
}

DiaryPromptPlan planDiaryPrompt(DiaryPromptInput input) {
  final system = (input.systemPrompt ??
          buildDiarySystemInstruction(
            profile: input.profile,
            clubs: input.clubs,
            frequentVenues: input.frequentVenues,
          ))
      .trim();
  final systemTokens = estimateDiaryTokens(system);
  final full = _compose(
    input,
    brief: input.progressBrief,
    rawDrills: _earlier(input.drills, input.now),
    rawSessions: _earlierSessions(input.sessions, input.now),
  );
  final fullTokens = systemTokens + estimateDiaryTokens(full);
  if (fullTokens <= input.tokenCeiling) {
    return DiaryPromptPlan(
      systemInstruction: system,
      prompt: full,
      tokens: fullTokens,
    );
  }
  final windowStart = _windowStart(input);
  final folded = input.drills.where((entry) {
    return !_isToday(entry.drill.timestamp, input.now) &&
        entry.drill.timestamp < windowStart;
  }).toList();
  final brief = _brief(input.progressBrief, folded);
  final rawDrills = input.drills.where((entry) {
    return !_isToday(entry.drill.timestamp, input.now) &&
        entry.drill.timestamp >= windowStart;
  }).toList();
  final rawSessions = input.sessions.where((session) {
    return !_isToday(session.timestamp, input.now) &&
        session.timestamp >= windowStart;
  }).toList();
  final prompt = _compose(
    input,
    brief: folded.isEmpty ? input.progressBrief : brief,
    rawDrills: rawDrills,
    rawSessions: rawSessions,
  );
  final promptTokens = systemTokens + estimateDiaryTokens(prompt);
  if (folded.isEmpty) {
    return DiaryPromptPlan(
      systemInstruction: system,
      prompt: prompt,
      tokens: promptTokens,
    );
  }
  final covered =
      folded.map((entry) => entry.drill.timestamp).reduce((a, b) => a > b ? a : b);
  return DiaryPromptPlan(
    systemInstruction: system,
    prompt: prompt,
    tokens: promptTokens,
    summary: brief,
    coveredThroughMs: covered,
  );
}

int _windowStart(DiaryPromptInput input) {
  final month = input.now
      .subtract(const Duration(days: kDiaryRecentWindowDays))
      .millisecondsSinceEpoch;
  final older = input.drills
      .where((entry) => !_isToday(entry.drill.timestamp, input.now))
      .toList()
    ..sort((a, b) => b.drill.timestamp.compareTo(a.drill.timestamp));
  if (older.length < kDiaryRecentWindowLogs) return month;
  final dozenCutoff = older[kDiaryRecentWindowLogs - 1].drill.timestamp;
  return month > dozenCutoff ? month : dozenCutoff;
}

String _brief(String? previous, List<RangeDrillSummary> folded) {
  final buffer = StringBuffer();
  if (previous != null && previous.trim().isNotEmpty) {
    buffer.writeln(previous.trim());
  }
  buffer.writeln('Folded earlier practice:');
  for (final entry in folded) {
    final drill = entry.drill;
    buffer.writeln(
        '${entry.clubName} average ${drill.avgYards.round()} yd over ${drill.shotCount} shots');
  }
  return buffer.toString().trim();
}

String _compose(
  DiaryPromptInput input, {
  required String? brief,
  required List<RangeDrillSummary> rawDrills,
  required List<RangeSession> rawSessions,
}) {
  final buffer = StringBuffer()
    ..writeln(
        'System: Ground all yardages, dispersion numbers, and trends strictly in the SQLite records below (all distances in yards).');

  if (input.clubs.isNotEmpty) {
    buffer.writeln('\nCurrent bag (SQLite):');
    for (final club in input.clubs) {
      final spec = [club.brand.trim(), club.model.trim()]
          .where((part) => part.isNotEmpty)
          .join(' ');
      final label = spec.isEmpty ? club.name : '${club.name} ($spec)';
      final yards = club.avgDistance > 0
          ? 'min ${club.minDistance.round()} / avg ${club.avgDistance.round()} / max ${club.maxDistance.round()} yd'
          : 'yardage unrecorded';
      final note = club.swingNotes.trim().isEmpty
          ? ''
          : ' | cue: ${club.swingNotes.trim()}';
      buffer.writeln('- $label [${club.category}]: $yards$note');
    }
  }

  if (brief != null && brief.trim().isNotEmpty) {
    buffer
      ..writeln('\nProgress brief:')
      ..writeln(brief.trim());
  }

  buffer.writeln('\nPer-club tally:');
  if (input.tallies.isEmpty) {
    buffer.writeln('No club tally yet.');
  }
  for (final tally in input.tallies) {
    final current = tally.thisPeriodAvg == null
        ? 'none'
        : '${tally.thisPeriodAvg!.round()} yd';
    final previous = tally.previousPeriodAvg == null
        ? 'none'
        : '${tally.previousPeriodAvg!.round()} yd';
    final titles =
        tally.drillTitles.isEmpty ? 'none' : tally.drillTitles.join(', ');
    buffer.writeln(
        '- ${tally.clubName}: ${tally.sessionCount} sessions, avg $current this period vs $previous previous, top drills: $titles');
  }

  buffer.writeln('\nEarlier history:');
  final earlierStandalone = _standaloneDrills(rawDrills, rawSessions);
  if (earlierStandalone.isEmpty && rawSessions.isEmpty) {
    buffer.writeln('None.');
  } else {
    _writeSessions(buffer, rawSessions);
    _writeDrills(buffer, earlierStandalone);
  }

  final named = _namedDay(input);
  if (named.drills.isNotEmpty || named.sessions.isNotEmpty) {
    buffer.writeln('\nNamed day:');
    _writeSessions(buffer, named.sessions);
    _writeDrills(buffer, _standaloneDrills(named.drills, named.sessions));
  }

  buffer.writeln('\nToday (${_day(input.now.millisecondsSinceEpoch)}):');
  final todaySessions = input.sessions
      .where((session) => _isToday(session.timestamp, input.now))
      .toList();
  final todayDrills = _standaloneDrills(
    input.drills
        .where((entry) => _isToday(entry.drill.timestamp, input.now))
        .toList(),
    todaySessions,
  );
  if (todaySessions.isEmpty && todayDrills.isEmpty) {
    buffer.writeln('No sessions or drills logged today yet.');
  } else {
    _writeSessions(buffer, todaySessions);
    _writeDrills(buffer, todayDrills);
  }

  buffer.writeln('\nLatest turns:');
  if (input.turns.isEmpty && input.question.trim().isEmpty) {
    buffer.writeln('None.');
  }
  for (final turn in input.turns) {
    buffer.writeln('${turn.role}: ${turn.content}');
  }
  final trimmedQuestion = input.question.trim();
  if (trimmedQuestion.isNotEmpty) {
    buffer.writeln('user: $trimmedQuestion');
    if (trimmedQuestion.toLowerCase() == 'summarize today') {
      buffer.writeln(
          'Task: Deliver a full biomechanical, physical-safety, and caddie evaluation of today\'s logged practice in context of the per-club tallies and recent history, closing with a structured Diary Anchor / Practice Blueprint.');
    }
  }
  return buffer.toString().trim();
}

List<RangeDrillSummary> _standaloneDrills(
  List<RangeDrillSummary> drills,
  List<RangeSession> sessions,
) {
  if (sessions.isEmpty) return drills;
  final compiledIds = {for (final session in sessions) session.id};
  return drills
      .where((entry) =>
          entry.drill.sessionId == null ||
          !compiledIds.contains(entry.drill.sessionId))
      .toList();
}

void _writeDrills(StringBuffer buffer, List<RangeDrillSummary> drills) {
  for (final entry in drills) {
    final drill = entry.drill;
    final spread = (drill.maxYards - drill.minYards).round();
    final venue =
        drill.venueName.trim().isEmpty ? '' : ' @ ${drill.venueName.trim()}';
    final cue = drill.tempoNotes.trim().isEmpty
        ? 'none'
        : drill.tempoNotes.trim();
    buffer.writeln(
        '- ${_day(drill.timestamp)}$venue | ${entry.clubName} (${drill.shotCount} shots): '
        'min ${drill.minYards.round()} / avg ${drill.avgYards.round()} / max ${drill.maxYards.round()} yd (spread $spread yd) | cue: $cue');
  }
}

void _writeSessions(StringBuffer buffer, List<RangeSession> sessions) {
  for (final session in sessions) {
    final venue = session.venueName.trim().isEmpty
        ? 'Unspecified venue'
        : session.venueName.trim();
    final totalShots =
        session.blocks.fold<int>(0, (sum, block) => sum + block.shotCount);
    final note = session.sessionNote.trim().isEmpty
        ? 'none'
        : session.sessionNote.trim();
    buffer.writeln(
        '- Session ${_day(session.timestamp)} @ $venue ($totalShots total shots) | session note: $note');
    for (var i = 0; i < session.blocks.length; i++) {
      final block = session.blocks[i];
      final spread = (block.maxYards - block.minYards).round();
      final cue =
          block.tempoNotes.trim().isEmpty ? 'none' : block.tempoNotes.trim();
      final drillTitle = (block.drillTitle ?? '').trim();
      final drillPart = drillTitle.isEmpty ? '' : ' | drill: $drillTitle';
      final stepsPart = block.drillSteps.isEmpty
          ? ''
          : ' | steps: ${block.drillSteps.join(' -> ')}';
      buffer.writeln(
          '  ${i + 1}. ${block.clubName} (${block.shotCount} shots): '
          'min ${block.minYards.round()} / avg ${block.avgYards.round()} / max ${block.maxYards.round()} yd (spread $spread yd) '
          '| cue: $cue$drillPart$stepsPart');
    }
  }
}

class _Named {
  const _Named(this.drills, this.sessions);
  final List<RangeDrillSummary> drills;
  final List<RangeSession> sessions;
}

_Named _namedDay(DiaryPromptInput input) {
  final days = RegExp(r'\d{4}-\d{2}-\d{2}')
      .allMatches(input.question)
      .map((match) => match.group(0)!)
      .toSet();
  if (days.isEmpty) return const _Named([], []);
  final drills = input.drills
      .where((entry) => days.contains(_day(entry.drill.timestamp)))
      .toList();
  final sessions = input.sessions
      .where((session) => days.contains(_day(session.timestamp)))
      .toList();
  return _Named(drills, sessions);
}

List<RangeDrillSummary> _earlier(List<RangeDrillSummary> drills, DateTime now) =>
    drills.where((entry) => !_isToday(entry.drill.timestamp, now)).toList();

List<RangeSession> _earlierSessions(List<RangeSession> sessions, DateTime now) =>
    sessions.where((session) => !_isToday(session.timestamp, now)).toList();

bool _isToday(int timestamp, DateTime now) =>
    _day(timestamp) == _day(now.millisecondsSinceEpoch);

String _day(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
