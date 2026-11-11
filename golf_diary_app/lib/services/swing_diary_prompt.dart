import '../models/golf_models.dart';
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
    this.progressBrief,
    this.question = '',
    this.tokenCeiling = kDiaryTokenCeiling,
  });

  final DateTime now;
  final List<RangeDrillSummary> drills;
  final List<RangeSession> sessions;
  final List<DiaryTurn> turns;
  final List<ClubTally> tallies;
  final String? progressBrief;
  final String question;
  final int tokenCeiling;
}

class DiaryPromptPlan {
  const DiaryPromptPlan({
    required this.prompt,
    required this.tokens,
    this.summary,
    this.coveredThroughMs,
  });

  final String prompt;
  final int tokens;

  /// Set when the oldest history was folded. Null means send the raw history.
  final String? summary;
  final int? coveredThroughMs;
}

DiaryPromptPlan planDiaryPrompt(DiaryPromptInput input) {
  final full = _compose(input, brief: input.progressBrief, rawDrills: _earlier(input.drills, input.now), rawSessions: _earlierSessions(input.sessions, input.now));
  if (estimateDiaryTokens(full) <= input.tokenCeiling) {
    return DiaryPromptPlan(prompt: full, tokens: estimateDiaryTokens(full));
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
  if (folded.isEmpty) {
    return DiaryPromptPlan(prompt: prompt, tokens: estimateDiaryTokens(prompt));
  }
  final covered = folded.map((entry) => entry.drill.timestamp).reduce((a, b) => a > b ? a : b);
  return DiaryPromptPlan(
    prompt: prompt,
    tokens: estimateDiaryTokens(prompt),
    summary: brief,
    coveredThroughMs: covered,
  );
}

int _windowStart(DiaryPromptInput input) {
  final month = input.now.subtract(const Duration(days: kDiaryRecentWindowDays)).millisecondsSinceEpoch;
  final older = input.drills.where((entry) => !_isToday(entry.drill.timestamp, input.now)).toList()
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
        '${entry.clubName} average ${drill.avgYards.round()} over ${drill.shotCount} shots');
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
    ..writeln('System: Comment only from this golfer\'s notes, in yards.');
  if (brief != null && brief.trim().isNotEmpty) {
    buffer
      ..writeln('Progress brief:')
      ..writeln(brief.trim());
  }
  buffer.writeln('Per-club tally:');
  if (input.tallies.isEmpty) {
    buffer.writeln('No club tally yet.');
  }
  for (final tally in input.tallies) {
    final current = tally.thisPeriodAvg?.round().toString() ?? 'none';
    final previous = tally.previousPeriodAvg?.round().toString() ?? 'none';
    final titles = tally.drillTitles.isEmpty ? 'none' : tally.drillTitles.join(', ');
    buffer.writeln(
        '${tally.clubName}: ${tally.sessionCount} sessions, avg $current this period vs $previous previous, drills: $titles');
  }
  buffer.writeln('Earlier history:');
  _writeDrills(buffer, rawDrills);
  _writeSessions(buffer, rawSessions);
  final named = _namedDay(input);
  if (named.drills.isNotEmpty || named.sessions.isNotEmpty) {
    buffer.writeln('Named day:');
    _writeDrills(buffer, named.drills);
    _writeSessions(buffer, named.sessions);
  }
  buffer.writeln('Today:');
  _writeDrills(buffer, input.drills.where((entry) => _isToday(entry.drill.timestamp, input.now)).toList());
  _writeSessions(buffer, input.sessions.where((session) => _isToday(session.timestamp, input.now)).toList());
  buffer.writeln('Latest turns:');
  for (final turn in input.turns) {
    buffer.writeln('${turn.role}: ${turn.content}');
  }
  if (input.question.trim().isNotEmpty) {
    buffer.writeln('user: ${input.question.trim()}');
  }
  return buffer.toString().trim();
}

void _writeDrills(StringBuffer buffer, List<RangeDrillSummary> drills) {
  for (final entry in drills) {
    final drill = entry.drill;
    buffer.writeln(
        '${_day(drill.timestamp)} ${entry.clubName} min ${drill.minYards.round()} avg ${drill.avgYards.round()} max ${drill.maxYards.round()} cue ${drill.tempoNotes}');
  }
}

void _writeSessions(StringBuffer buffer, List<RangeSession> sessions) {
  for (final session in sessions) {
    buffer.writeln('${_day(session.timestamp)} session note ${session.sessionNote}');
    for (final block in session.blocks) {
      final steps = block.drillSteps.join(' | ');
      buffer.writeln(
          '${block.clubName} min ${block.minYards.round()} avg ${block.avgYards.round()} max ${block.maxYards.round()} cue ${block.tempoNotes} drill ${block.drillTitle ?? ''} steps $steps');
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
  final drills = input.drills.where((entry) => days.contains(_day(entry.drill.timestamp))).toList();
  final sessions = input.sessions.where((session) => days.contains(_day(session.timestamp))).toList();
  return _Named(drills, sessions);
}

List<RangeDrillSummary> _earlier(List<RangeDrillSummary> drills, DateTime now) =>
    drills.where((entry) => !_isToday(entry.drill.timestamp, now)).toList();

List<RangeSession> _earlierSessions(List<RangeSession> sessions, DateTime now) =>
    sessions.where((session) => !_isToday(session.timestamp, now)).toList();

bool _isToday(int timestamp, DateTime now) => _day(timestamp) == _day(now.millisecondsSinceEpoch);

String _day(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
