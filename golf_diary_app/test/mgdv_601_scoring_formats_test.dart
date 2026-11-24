import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/data/ph_golf_catalog.dart';
import 'package:golf_diary_app/models/caddy_session.dart';
import 'package:golf_diary_app/models/scoring_format.dart';
import 'package:golf_diary_app/theme/app_theme.dart';
import 'package:golf_diary_app/widgets/course_round_dialog.dart';
import 'package:golf_diary_app/widgets/scorecard_cart_panel.dart';
import 'package:golf_diary_app/services/caddy_event_applier.dart';
import 'package:golf_diary_app/services/caddy_pairing_service.dart';
import 'package:golf_diary_app/services/caddy_round_channel_store.dart';
import 'package:golf_diary_app/services/flight_channel_store.dart';
import 'package:golf_diary_app/services/flight_launch_config.dart';
import 'package:golf_diary_app/services/flight_service.dart';
import 'package:golf_diary_app/services/local_database_service.dart';

void main() {
  HoleScoreInput hole({
    required int par,
    required int gross,
    bool played = true,
    int paid = 0,
  }) {
    return HoleScoreInput(
      par: par,
      strokes: gross,
      penalties: 0,
      paidMulligans: paid,
      played: played,
    );
  }

  test('Molave points follow the modified Stableford table', () {
    expect(molaveHolePoints(hole(par: 4, gross: 1)), 6);
    expect(molaveHolePoints(hole(par: 5, gross: 2)), 7);
    expect(molaveHolePoints(hole(par: 5, gross: 2), doubleEaglePoints: 6), 6);
    expect(molaveHolePoints(hole(par: 4, gross: 2)), 5);
    expect(molaveHolePoints(hole(par: 4, gross: 3)), 4);
    expect(molaveHolePoints(hole(par: 4, gross: 4)), 3);
    expect(molaveHolePoints(hole(par: 4, gross: 5)), 2);
    expect(molaveHolePoints(hole(par: 4, gross: 6)), 1);
    expect(molaveHolePoints(hole(par: 4, gross: 7)), 0);
    expect(molaveHolePoints(hole(par: 4, gross: 1, paid: 1)), 7);
    expect(molaveHolePoints(hole(par: 4, gross: 4, played: false)), isNull);

    final even = scoreRound(
      [for (var i = 0; i < 18; i++) hole(par: 4, gross: 4)],
      format: ScoringFormat.molave,
    );
    expect(even.points, 54);
  });

  test('System 36 net waits for 18 holes', () {
    final partial = scoreRound(
      [for (var i = 0; i < 17; i++) hole(par: 4, gross: 4)],
      format: ScoringFormat.system36,
    );
    expect(partial.points, 34);
    expect(partial.dailyHandicap, isNull);
    expect(partial.net, isNull);

    final full = scoreRound(
      [
        for (var i = 0; i < 17; i++) hole(par: 4, gross: 4),
        hole(par: 4, gross: 5),
      ],
      format: ScoringFormat.system36,
    );
    expect(full.points, 35);
    expect(full.dailyHandicap, 1);
    expect(full.net, full.gross - 1);
  });

  test('paid mulligan is one per nine and handicap uses par plus 2', () {
    expect(
      clampPaidMulligan(
        holeNumber: 2,
        requested: 1,
        paidByHole: {1: 1},
      ),
      0,
    );
    expect(
      clampPaidMulligan(
        holeNumber: 10,
        requested: 1,
        paidByHole: {1: 1},
      ),
      1,
    );

    final capped = adjustedHoleGross(hole(par: 4, gross: 10));
    expect(capped, 6);
    expect(
      scoreDifferential(adjustedGross: 80, courseRating: 71.5, slopeRating: 130),
      7.4,
    );
    expect(unofficialHandicapIndex([7.4, 7.4, 7.4]), 5.4);
    expect(unofficialHandicapIndex([1, 2]), isNull);
  });

  test('round format, attestation, and unofficial index persist', () async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_mgdv601_fmt.db');
    addTearDown(() async {
      await LocalDatabaseService.debugClose();
      LocalDatabaseService.debugSetFileName('golf_diary.db');
    });
    final db = LocalDatabaseService.instance;
    const course = 'Club Intramuros Golf Course';

    for (var round = 0; round < 3; round++) {
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final roundId = await db.startNewRound(courseName: course, par: 3);
      for (var n = 1; n <= 18; n++) {
        final par = PhGolfCatalog.parForHole(course, n) ?? 4;
        await db.saveManualHoleScore(
          roundId: roundId,
          courseName: course,
          holeNumber: n,
          par: par,
          strokes: par,
          penalties: 0,
          holeComplete: true,
        );
      }
      await db.saveRoundFormat(RoundFormatSettings(
        roundId: roundId,
        format: ScoringFormat.molave,
        courseRating: 66,
        slopeRating: 113,
      ));
      await db.completeRound(roundId);
    }

    final rounds = await db.listRecentRounds(limit: 3);
    final settings = await db.getRoundFormat(rounds.first.roundId);
    expect(settings.format, ScoringFormat.molave);
    expect(settings.courseRating, 66);

    await db.attestRound(
      roundId: rounds.first.roundId,
      name: 'Reuben',
      role: 'self',
    );
    expect((await db.getRoundFormat(rounds.first.roundId)).isAttested, isTrue);
    await db.invalidateAttestation(rounds.first.roundId);
    final edited = await db.getRoundFormat(rounds.first.roundId);
    expect(edited.isAttested, isFalse);
    expect(edited.editedAfterAttest, isTrue);

    await db.saveManualHoleScore(
      roundId: rounds.first.roundId,
      courseName: course,
      holeNumber: 1,
      par: 3,
      strokes: 3,
      penalties: 0,
      holeComplete: true,
      paidMulligans: 1,
    );
    await db.saveManualHoleScore(
      roundId: rounds.first.roundId,
      courseName: course,
      holeNumber: 2,
      par: 4,
      strokes: 4,
      penalties: 0,
      holeComplete: true,
      paidMulligans: 1,
    );
    final second = await db.getHoleScore(rounds.first.roundId, 2);
    expect(second!.paidMulligans, 0);

    expect(await db.unofficialHandicapEstimate(), -2);
  });

  test('flight publish and partner attest flag a later edit', () async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_mgdv602_flight.db');
    addTearDown(() async {
      await LocalDatabaseService.debugClose();
      LocalDatabaseService.debugSetFileName('golf_diary.db');
    });
    final db = LocalDatabaseService.instance;
    final store = MemoryFlightChannelStore();
    final flights = FlightService(database: db, store: store);
    final roundId = await db.startNewRound(
      courseName: 'Local Course',
      par: 4,
    );
    await db.saveManualHoleScore(
      roundId: roundId,
      courseName: 'Local Course',
      holeNumber: 1,
      par: 4,
      strokes: 5,
      penalties: 0,
      holeComplete: true,
    );
    final flight = await flights.mintFlight(
      roundId: roundId,
      courseName: 'Local Course',
      format: ScoringFormat.gross,
      displayName: 'Host',
    );
    expect(FlightLaunchConfig.buildInviteUrl(flight.flightId),
        contains('mode=flight'));
    expect(flight.players.single.holeGross.first, 5);

    final joined = await flights.joinFlight(
      flightId: flight.flightId,
      roundId: roundId,
      displayName: 'Guest',
    );
    expect(joined!.players, hasLength(2));

    final attested = await flights.attestPlayer(
      flightId: flight.flightId,
      playerId: flight.players.single.playerId,
      attestorName: 'Guest',
    );
    expect(attested!.players.first.isAttested, isTrue);

    await db.saveManualHoleScore(
      roundId: roundId,
      courseName: 'Local Course',
      holeNumber: 1,
      par: 4,
      strokes: 6,
      penalties: 0,
      holeComplete: true,
    );
    final republished = await flights.publishRound(
      flightId: flight.flightId,
      playerId: flight.players.single.playerId,
      roundId: roundId,
      displayName: 'Host',
    );
    expect(republished!.players.first.mismatchesAttestation, isTrue);
  });

  test('caddy hole score for another player stays off the golfer card', () async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_mgdv603_caddy.db');
    addTearDown(() async {
      await LocalDatabaseService.debugClose();
      LocalDatabaseService.debugSetFileName('golf_diary.db');
    });
    final db = LocalDatabaseService.instance;
    final channel = MemoryCaddyRoundChannelStore();
    final pairing = CaddyPairingService(database: db, channelStore: channel);
    final roundId = await db.startNewRound(
      courseName: 'Club Intramuros Golf Course',
      par: 3,
    );
    final session = await pairing.mintInvite(
      roundId: roundId,
      courseName: 'Club Intramuros Golf Course',
    );
    final other = await pairing.publishEvent(
      channelId: session.channelId,
      roundId: roundId,
      type: CaddyEventType.setHoleScore,
      holeNumber: 1,
      authorUid: 'caddy',
      holeScore: 5,
      targetPlayerId: 'player_lee',
    );
    await CaddyEventApplier(database: db).apply(
      other,
      courseName: 'Club Intramuros Golf Course',
    );
    final golferHole = await db.getHoleScore(roundId, 1);
    expect(golferHole!.strokes, 0);
    final stored = await db.caddyPlayerGrossByHole(
      channelId: session.channelId,
      playerId: 'player_lee',
    );
    expect(stored[1], 5);

    final own = await pairing.publishEvent(
      channelId: session.channelId,
      roundId: roundId,
      type: CaddyEventType.setHoleScore,
      holeNumber: 1,
      authorUid: 'caddy',
      holeScore: 4,
    );
    await CaddyEventApplier(database: db).apply(
      own,
      courseName: 'Club Intramuros Golf Course',
    );
    expect((await db.getHoleScore(roundId, 1))!.strokes, 4);

    final attest = await pairing.publishEvent(
      channelId: session.channelId,
      roundId: roundId,
      type: CaddyEventType.attestPlayerCard,
      holeNumber: 1,
      authorUid: 'caddy',
    );
    await CaddyEventApplier(database: db).apply(
      attest,
      courseName: 'Club Intramuros Golf Course',
    );
    expect((await db.getRoundFormat(roundId)).attestedRole, 'caddy');
  });

  testWidgets('course dialog holds the format controls', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGolfTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showCourseRoundDialog(
                context: context,
                initial: const CourseRoundValues(courseName: 'Local Course'),
                recentNames: const [],
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Course'), findsOneWidget);
    expect(find.byKey(const ValueKey('scorecard-format-toggle')), findsOneWidget);
    expect(find.byKey(const ValueKey('scorecard-course-rating')), findsOneWidget);
    expect(find.byKey(const ValueKey('scorecard-slope')), findsOneWidget);
    expect(find.byKey(const ValueKey('scorecard-double-eagle-7')), findsNothing);
    expect(find.byKey(const ValueKey('scorecard-attest-btn')), findsNothing);

    await tester.tap(find.text('Molave'));
    await tester.pump();
    expect(find.byKey(const ValueKey('scorecard-double-eagle-7')), findsOneWidget);
    expect(find.byKey(const ValueKey('scorecard-double-eagle-6')), findsOneWidget);
  });

  testWidgets('cart panel keeps the format total', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildGolfTheme(),
        home: Scaffold(
          body: ScorecardCartPanel(
            courseName: 'Local Course',
            holeCount: 18,
            selectedHole: 1,
            totals: null,
            holeRow: (_) => null,
            highContrast: false,
            onHoleSelected: (_) {},
            onPlusStroke: () {},
            onPenalty: () {},
            onMulligan: () {},
            onGimme: () {},
            onHighContrastChanged: (_) {},
            formatSummary: 'Gross 0',
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('scorecard-cart-format-total')), findsOneWidget);
    expect(find.text('Gross 0'), findsOneWidget);
  });
}
