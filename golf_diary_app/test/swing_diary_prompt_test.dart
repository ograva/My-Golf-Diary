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
    String? drillId,
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
        timestamp: timestamp,
        drillId: drillId,
      ),
    );
  }

  test('a prompt under the ceiling keeps raw history and writes no summary', () {
    final now = DateTime(2026, 11, 11, 18);
    final plan = planDiaryPrompt(DiaryPromptInput(
      now: now,
      drills: [
        drill(id: 'old', timestamp: DateTime(2026, 11, 10, 9).millisecondsSinceEpoch, cue: 'YESTERDAY CUE', avg: 140),
        drill(id: 'today', timestamp: now.millisecondsSinceEpoch, cue: 'TODAY CUE', avg: 160),
      ],
      sessions: [
        RangeSession(
          id: 'rsess_today',
          venueName: 'Topgolf',
          sessionNote: 'Felt easy',
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
    expect(plan.prompt.indexOf('System:'), lessThan(plan.prompt.indexOf('Per-club tally:')));
    expect(plan.prompt.indexOf('Per-club tally:'), lessThan(plan.prompt.indexOf('Earlier history:')));
    expect(plan.prompt.indexOf('Earlier history:'), lessThan(plan.prompt.indexOf('Today:')));
    expect(plan.prompt.indexOf('Today:'), lessThan(plan.prompt.indexOf('Latest turns:')));
    expect(plan.prompt, contains('YESTERDAY CUE'));
    expect(plan.prompt, contains('TODAY CUE'));
    expect(plan.prompt, contains('Felt easy'));
    expect(plan.prompt, contains('Count to four'));
    expect(plan.prompt, contains('2 sessions'));
    expect(plan.prompt, contains('3:1 Tour Tempo Rhythm'));
    expect(plan.prompt, contains('Named day:'));
  });

  test('a prompt over the ceiling folds old notes and keeps today', () {
    final now = DateTime(2026, 11, 11, 18);
    final ancientCue = 'ANCIENT CUE ${'x' * 4000}';
    final plan = planDiaryPrompt(DiaryPromptInput(
      now: now,
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
    expect(plan.prompt, contains('avg 160 this period vs 140 previous'));

    final again = planDiaryPrompt(DiaryPromptInput(
      now: now,
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
