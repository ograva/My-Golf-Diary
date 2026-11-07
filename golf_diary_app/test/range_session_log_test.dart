import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golf_models.dart';
import 'package:golf_diary_app/screens/clubs_screen.dart';
import 'package:golf_diary_app/screens/range_drill_screen.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/theme/app_theme.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  final db = LocalDatabaseService.instance;

  Future<void> useFreshDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_range_log.db');
    await deleteDatabase(join(await getDatabasesPath(), 'golf_diary_range_log.db'));
  }

  Future<void> restoreDatabase() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  }

  testWidgets('range log starts on the selected club and can show every club', (tester) async {
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));

    await tester.runAsync(() async {
      final clubs = await db.getAllClubs();
      final driver = clubs.firstWhere((club) => club.id == 'driver');
      final iron = clubs.firstWhere((club) => club.id == '7iron');
      await db.saveRangeDrill(RangeDrillLog(
        id: 'drill_driver',
        clubId: driver.id,
        shotCount: 10,
        minYards: 200,
        maxYards: 240,
        avgYards: 220,
        venueName: 'Topgolf',
        timestamp: 1700000000000,
      ));
      await db.saveRangeDrill(RangeDrillLog(
        id: 'drill_iron',
        clubId: iron.id,
        shotCount: 8,
        minYards: 140,
        maxYards: 160,
        avgYards: 150,
        venueName: 'Home sim',
        timestamp: 1700000100000,
      ));
    });

    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(theme: buildGolfTheme(), home: const RangeDrillScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();

    expect(find.byKey(const Key('range-log-this-club')), findsOneWidget);
    expect(find.text('Session log · Driver'), findsOneWidget);
    expect(find.byKey(const ValueKey('range-session-drill_driver')), findsOneWidget);
    expect(find.byKey(const ValueKey('range-session-drill_iron')), findsNothing);

    await tester.tap(find.byKey(const Key('range-log-all')));
    await tester.pump();

    expect(find.text('Session log'), findsOneWidget);
    expect(find.text('Driver · Topgolf'), findsOneWidget);
    expect(find.text('7 Iron · Home sim'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '7 Iron'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('range-log-this-club')));
    await tester.pump();

    expect(find.text('Session log · 7 Iron'), findsOneWidget);
    expect(find.byKey(const ValueKey('range-session-drill_iron')), findsOneWidget);
    expect(find.byKey(const ValueKey('range-session-drill_driver')), findsNothing);
  });

  testWidgets('my bag opens past range sessions for the tapped club', (tester) async {
    await tester.runAsync(useFreshDatabase);
    addTearDown(() => tester.runAsync(restoreDatabase));
    await tester.runAsync(() async {
      await db.saveRangeDrill(RangeDrillLog(
        id: 'drill_driver',
        clubId: 'driver',
        shotCount: 10,
        minYards: 200,
        maxYards: 240,
        avgYards: 220,
        venueName: 'Topgolf',
        timestamp: 1700000000000,
      ));
      await db.saveRangeDrill(RangeDrillLog(
        id: 'drill_iron',
        clubId: '7iron',
        shotCount: 8,
        minYards: 140,
        maxYards: 160,
        avgYards: 150,
        venueName: 'Home sim',
        timestamp: 1700000100000,
      ));
    });

    await tester.pumpWidget(MaterialApp(theme: buildGolfTheme(), home: const ClubsScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();

    expect(find.text('Range logs (1)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('bag-range-logs-driver')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();

    expect(find.text('Past range sessions'), findsOneWidget);
    expect(find.text('Topgolf'), findsOneWidget);
    expect(find.text('Home sim'), findsNothing);
  });

  testWidgets('bag range log sheet lists one club and an empty club', (tester) async {
    final club = Club(id: '7iron', name: '7 Iron', category: 'iron');
    final sessions = [
      RangeDrillSummary(
        clubName: '7 Iron',
        drill: RangeDrillLog(
          id: 'drill_iron',
          clubId: '7iron',
          shotCount: 8,
          minYards: 140,
          maxYards: 160,
          avgYards: 150,
          venueName: 'Home sim',
          tempoNotes: 'Pause at the top',
          timestamp: DateTime(2026, 3, 2, 15, 5).millisecondsSinceEpoch,
        ),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGolfTheme(),
        home: Scaffold(body: ClubRangeLogSheet(club: club, sessions: const [])),
      ),
    );
    await tester.pump();
    expect(find.text('No range sessions for 7 Iron yet.'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildGolfTheme(),
        home: Scaffold(body: ClubRangeLogSheet(club: club, sessions: sessions)),
      ),
    );
    await tester.pump();
    expect(find.text('Home sim'), findsOneWidget);
    expect(find.textContaining('Pause at the top'), findsOneWidget);
    expect(find.textContaining('7 Iron ·'), findsNothing);
  });
}
