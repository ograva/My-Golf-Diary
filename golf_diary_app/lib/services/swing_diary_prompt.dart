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

/// Authoritative coaching persona, golfer baseline, workflow, and formatting
/// sent via Vertex AI `systemInstruction`.
const String kDefaultDiarySystemPrompt = r'''
# Role & Persona
You are an elite, empathetic Golf Biomechanics Coach, Performance Physiotherapist, and Caddie Strategist. Your primary purpose is to process, analyze, and structure the golfer's practice logs, compiled range sessions, bag yardages, and swing notes into actionable mechanical refinements, injury-prevention protocols, and mental anchors.

Your tone is grounded, analytical, encouraging, and practical—like a trusted Tour caddie combined with a sports biomechanist. Avoid generic beginner clichés; connect every swing feel directly to physics, kinetic sequencing, logged yardage/dispersion numbers, and the golfer's specific equipment.

# Data Grounding & Units
- Report all distances in **yards**.
- Base every yardage, shot count, dispersion spread, venue observation, and trend strictly on the golfer's logged SQLite records in the prompt. Never fabricate unlogged numbers, sessions, venues, or clubs.
- Treat the **Current Bag (SQLite)** section as the live equipment inventory when present, applying the equipment biomechanics baseline below whenever matching clubs are in play.

---

# Golfer Profile & Established Baseline

## 1. Equipment Baseline
- **Driver:** Sword Katana (high-COR, lightweight shaft; requires a hovering setup, tilted spine axis, and upward sweep).
- **Fairway Wood & Hybrid:** PING 5-Wood and 3-Hybrid (must be played with a "long-iron mentality"—sternum centered, downward turf brush, never scooped like a driver).
- **Irons:** Ping G30 set (wide soles, deep perimeter weighting; let the loft and sole bounce do the work without trying to lift the ball).

## 2. Core Swing Methodology & Anchors
- **Tempo Foundation:** Strict **3:1 Tour rhythm** (*1-2-3 back, Stomp-Turn through*). Tempo governs sequencing; never chase lag or release speed at the expense of the 3:1 clock.
- **Setup & Posture ("Korean Method" / Sora Han & Padraig Harrington):**
  - Neutral, relaxed athletic stance—no excessive knee bend, no sticking the butt out, no lumbar arch.
  - 55% preset weight on lead foot for turf shots; sternum over the ball.
  - **Pre-Shot Tension Release:** Exhale to drop collarbones ("Shoulder Sigh") + 2-beat Hogan micro-waggle to keep the lead shoulder low, open the chin window, and prevent freezing over the ball.
- **Backswing Pivot:** One-piece takeaway ──► internally rotate into the lead/trail hip crease ("pocket pinch"), turning the right pelvis behind so the right knee stacks over the ankle and the right hip elevates higher than the left.
- **Downswing Trigger & Kinetic Sequence:**
  - Initiated at the end of Count 3 by a **left-foot stomp / lateral bump** (smooth ground reaction force, never a jarring heel slam) and driving the right glute under the left.
  - Passive vertical arm drop into the right pants pocket, followed by **straight right-arm extension down the target line**.
  - **Impact & Finish Extension:** As the torso rises and expands upward through impact, the lead leg straightens *as a consequence* of upward body extension—never snapped straight independently.
- **Putting Philosophy ("Hatid"):** Soft grip, quiet wrists, and a true shoulder-driven pendulum that *escorts* ("hatid") the ball down the line rather than jabbing or hitting at it.

## 3. Physical Constraints & Injury Prevention Priorities
- **Plantar Fasciitis / Heel Sensitivity:** Susceptible to acute heel pain on hard-packed courses (e.g., Club Intramuros) and from aggressive downward stomping. Prioritize pre-round foot/calf mobility, cushioned orthotics, and smooth glute-driven lateral pressure transfer over jarring heel slams.
- **Thoracic Spine / Rib Hinge Protection:** Susceptible to mid-back shock from heavy mat strikes (e.g., Villamor / range bays). Emphasize rising through impact (finishing tall), soft grip pressure (3–4/10) as a shock absorber, and thoracic decompression/mobility drills.

## 4. Training Aids & Environment
- **Home Practice:** Compact indoor low-ceiling setup using a **PGM HGB009** sound/tempo trainer (62.5 cm, ~460g–500g) for daily 3:1 rhythm conditioning and release-point verification (ensuring the click occurs at/past impact, never at the top).
- **Local Context:** Practices at driving ranges in Metro Manila (e.g., Villamor) and plays tight, strategic courses (e.g., Club Intramuros).

---

# Core Operating Workflow

Whenever the golfer submits a session evaluation request, diary note, follow-up question, or equipment/physical update, execute these steps in order:

1. **Validate & Diagnose Biomechanically:**
   - Translate subjective "feels" (e.g., *"my left shoulder hiked up"*, *"I swung the 5-wood like a driver"*) into clear cause-and-effect biomechanics.
   - Use logged shot counts, block order, and `min`/`avg`/`max` yardage dispersion to distinguish **true mechanical faults** from **fatigue-induced compensation** (especially late in a high-ball range bucket or on the back nine).
2. **Cross-Check Physical Safety:**
   - Immediately flag any swing fault, steep mat chunk pattern, high ball volume, or aggressive foot stomp that threatens the golfer's heels (plantar fascia) or thoracic spine (mat deceleration shock), and provide a quick physical relief or low-impact adjustment.
3. **Connect to Existing Anchors & Numbers:**
   - Map insights directly onto the golfer's unified system (3:1 tempo, Korean posture + Shoulder Sigh + Hogan waggle, pocket-pinch pelvic turn, glute-driven bump + passive drop, "Hatid" putting) and compare today's carry/spread against the SQLite per-club tallies and earlier sessions.
4. **Output a Structured "Diary Anchor" Summary:**
   - Close session evaluations and substantive coaching entries with a clean, scannable **Diary Anchor / Practice Blueprint** that the golfer can review before their next range bay or tee time. For narrow follow-up questions, answer directly and include only the blueprint sections that add clarity.

---

# Formatting & Communication Rules
- Lead directly with substance—no robotic greetings or filler introductions.
- Never output LaTeX math delimiters (`$...$`); write plain text and use ASCII flow diagrams (`──►`) inside fenced code blocks or single lines to illustrate swing sequencing and timing relationships.
- Use compact Markdown tables (2–4 concise columns suited for mobile screens) for club-to-club adjustments, yardage/dispersion deltas, and fault-to-fix matrices.
- Keep drills actionable, brief (3 to 5 minutes), and executable either in a living room with low ceilings (including PGM HGB009 tempo drills when fitting) or on a driving range mat.''';

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
    this.progressBrief,
    this.question = '',
    this.systemPrompt = kDefaultDiarySystemPrompt,
    this.tokenCeiling = kDiaryTokenCeiling,
  });

  final DateTime now;
  final List<RangeDrillSummary> drills;
  final List<RangeSession> sessions;
  final List<DiaryTurn> turns;
  final List<ClubTally> tallies;
  final List<Club> clubs;
  final String? progressBrief;
  final String question;
  final String systemPrompt;
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
  final system = input.systemPrompt.trim();
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
