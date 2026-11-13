import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golf_models.dart';
import 'package:golf_diary_app/models/range_session.dart';
import 'package:golf_diary_app/services/swing_diary_prompt.dart';

void main() {
  RangeDrillSummary drill({
    required String id,
    required int timestamp,
    required String cue,
    required double avg,
    String clubId = 'driver',
    String clubName = 'Driver',
    String venueName = '',
    String? drillId,
    String? sessionId,
  }) {
    return RangeDrillSummary(
      clubName: clubName,
      drill: RangeDrillLog(
        id: id,
        clubId: clubId,
        shotCount: 10,
        minYards: avg - 5,
        maxYards: avg + 5,
        avgYards: avg,
        tempoNotes: cue,
        venueName: venueName,
        timestamp: timestamp,
        drillId: drillId,
        sessionId: sessionId,
      ),
    );
  }

  test('default system instruction captures coaching persona, baseline, safety, and formatting rules', () {
    expect(kDefaultDiarySystemPrompt, contains('Golf Biomechanics Coach'));
    expect(kDefaultDiarySystemPrompt, contains('Performance Physiotherapist'));
    expect(kDefaultDiarySystemPrompt, contains('Sword Katana'));
    expect(kDefaultDiarySystemPrompt, contains('PING 5-Wood and 3-Hybrid'));
    expect(kDefaultDiarySystemPrompt, contains('Ping G30'));
    expect(kDefaultDiarySystemPrompt, contains('3:1 Tour rhythm'));
    expect(kDefaultDiarySystemPrompt, contains('Korean Method'));
    expect(kDefaultDiarySystemPrompt, contains('Shoulder Sigh'));
    expect(kDefaultDiarySystemPrompt, contains('pocket pinch'));
    expect(kDefaultDiarySystemPrompt, contains('Hatid'));
    expect(kDefaultDiarySystemPrompt, contains('Plantar Fasciitis'));
    expect(kDefaultDiarySystemPrompt, contains('Thoracic Spine'));
    expect(kDefaultDiarySystemPrompt, contains('PGM HGB009'));
    expect(kDefaultDiarySystemPrompt, contains('Diary Anchor'));
    expect(kDefaultDiarySystemPrompt, contains('──►'));
    expect(kDefaultDiarySystemPrompt, isNot(contains(r'$\rightarrow$')));
  });

  test('a prompt under the ceiling keeps raw history, bag context, and deduplicates compiled blocks', () {
    final now = DateTime(2026, 11, 11, 18);
    final plan = planDiaryPrompt(DiaryPromptInput(
      now: now,
      clubs: [
        Club(
          id: 'driver',
          name: 'Driver',
          category: 'wood',
          brand: 'Sword',
          model: 'Katana',
          minDistance: 195,
          avgDistance: 215,
          maxDistance: 230,
          swingNotes: 'Hover head, tilted spine',
        ),
      ],
      drills: [
        drill(
          id: 'old',
          timestamp: DateTime(2026, 11, 10, 9).millisecondsSinceEpoch,
          cue: 'YESTERDAY CUE',
          avg: 140,
          venueName: 'Villamor Driving Range',
        ),
        drill(
          id: 'compiled_block',
          timestamp: now.millisecondsSinceEpoch,
          cue: 'DUPLICATE_IF_NOT_FILTERED',
          avg: 160,
          sessionId: 'rsess_today',
        ),
        drill(
          id: 'standalone_today',
          timestamp: now.millisecondsSinceEpoch,
          cue: 'EXTRA WEDGE CUE',
          avg: 95,
          clubId: 'pw',
          clubName: 'Pitching Wedge',
        ),
      ],
      sessions: [
        RangeSession(
          id: 'rsess_today',
          venueName: 'Villamor Driving Range',
          sessionNote: 'Felt easy off mats',
          timestamp: now.millisecondsSinceEpoch,
          blocks: const [
            RangeSessionBlock(
              clubId: 'driver',
              clubName: 'Driver',
              shotCount: 10,
              minYards: 150,
              avgYards: 160,
              maxYards: 170,
              tempoNotes: 'TODAY CUE',
              drillTitle: '3:1 Tour Tempo Rhythm',
              drillSteps: ['Count to four'],
            ),
          ],
        ),
      ],
      turns: const [DiaryTurn(role: 'user', content: 'Earlier question')],
      tallies: const [
        ClubTally(
          clubName: 'Driver',
          sessionCount: 2,
          thisPeriodAvg: 150,
          previousPeriodAvg: null,
          drillTitles: ['3:1 Tour Tempo Rhythm'],
        ),
      ],
      question: 'What about 2026-11-10?',
    ));

    expect(plan.summary, isNull);
    expect(plan.systemInstruction, contains('Golf Biomechanics Coach'));
    expect(plan.prompt.indexOf('System:'), lessThan(plan.prompt.indexOf('Current bag (SQLite):')));
    expect(plan.prompt.indexOf('Current bag (SQLite):'), lessThan(plan.prompt.indexOf('Per-club tally:')));
    expect(plan.prompt.indexOf('Per-club tally:'), lessThan(plan.prompt.indexOf('Earlier history:')));
    expect(plan.prompt.indexOf('Earlier history:'), lessThan(plan.prompt.indexOf('Named day:')));
    expect(plan.prompt.indexOf('Named day:'), lessThan(plan.prompt.indexOf('Today (2026-11-11):')));
    expect(plan.prompt.indexOf('Today (2026-11-11):'), lessThan(plan.prompt.indexOf('Latest turns:')));
    expect(plan.prompt, contains('Driver (Sword Katana) [wood]: min 195 / avg 215 / max 230 yd | cue: Hover head, tilted spine'));
    expect(plan.prompt, contains('YESTERDAY CUE'));
    expect(plan.prompt, contains('Villamor Driving Range'));
    expect(plan.prompt, contains('TODAY CUE'));
    expect(plan.prompt, contains('EXTRA WEDGE CUE'));
    expect(plan.prompt, isNot(contains('DUPLICATE_IF_NOT_FILTERED')));
    expect(plan.prompt, contains('spread 20 yd'));
    expect(plan.prompt, contains('Felt easy off mats'));
    expect(plan.prompt, contains('Count to four'));
    expect(plan.prompt, contains('2 sessions'));
    expect(plan.prompt, contains('3:1 Tour Tempo Rhythm'));
  });

  test('summarize today appends the structured coaching task directive', () {
    final now = DateTime(2026, 11, 11, 18);
    final plan = planDiaryPrompt(DiaryPromptInput(
      now: now,
      drills: [
        drill(
          id: 'today',
          timestamp: now.millisecondsSinceEpoch,
          cue: 'TODAY CUE',
          avg: 160,
        ),
      ],
      sessions: const [],
      turns: const [],
      tallies: const [],
      question: 'Summarize today',
    ));

    expect(plan.prompt, contains('user: Summarize today'));
    expect(plan.prompt, contains('Diary Anchor / Practice Blueprint'));
  });

  test('a prompt over the ceiling folds old notes and keeps today', () {
    final now = DateTime(2026, 11, 11, 18);
    final ancientCue = 'ANCIENT CUE ${'x' * 4000}';
    final plan = planDiaryPrompt(DiaryPromptInput(
      now: now,
      systemPrompt: 'Coach system prompt',
      tokenCeiling: 200,
      progressBrief: 'Previous brief fact: held the face',
      drills: [
        drill(
          id: 'ancient',
          timestamp: DateTime(2020, 1, 2, 9).millisecondsSinceEpoch,
          cue: ancientCue,
          avg: 140,
        ),
        drill(id: 'today', timestamp: now.millisecondsSinceEpoch, cue: 'TODAY CUE', avg: 160),
      ],
      sessions: const [],
      turns: const [],
      tallies: const [
        ClubTally(
          clubName: 'Driver',
          sessionCount: 2,
          thisPeriodAvg: 160,
          previousPeriodAvg: 140,
          drillTitles: [],
        ),
      ],
    ));

    expect(plan.summary, isNotNull);
    expect(plan.summary, contains('Previous brief fact: held the face'));
    expect(plan.summary, isNot(contains('ANCIENT CUE')));
    expect(plan.coveredThroughMs, DateTime(2020, 1, 2, 9).millisecondsSinceEpoch);
    expect(plan.prompt, isNot(contains('ANCIENT CUE')));
    expect(plan.prompt, contains('Previous brief fact: held the face'));
    expect(plan.prompt, contains('TODAY CUE'));
    expect(plan.prompt, contains('avg 160 yd this period vs 140 yd previous'));

    final again = planDiaryPrompt(DiaryPromptInput(
      now: now,
      systemPrompt: 'Coach system prompt',
      tokenCeiling: 200,
      progressBrief: plan.summary,
      drills: [
        drill(id: 'today', timestamp: now.millisecondsSinceEpoch, cue: 'TODAY CUE', avg: 160),
      ],
      sessions: const [],
      turns: const [],
      tallies: const [],
      question: 'What changed on 2020-01-02?',
    ));
    expect(again.summary, isNull);
    expect(again.prompt, contains('Previous brief fact: held the face'));
    expect(again.prompt, contains('TODAY CUE'));
  });
}
