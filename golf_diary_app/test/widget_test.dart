import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/main.dart';
import 'package:golf_diary_app/models/golfer_profile.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  setUp(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_widget.db');
    await deleteDatabase(join(await getDatabasesPath(), 'golf_diary_widget.db'));
    await LocalDatabaseService.instance.saveGolferProfile(
      const GolferProfile(onboardingCompleted: 1),
    );
  });

  tearDown(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  });

  testWidgets('App loads home shell', (tester) async {
    await tester.pumpWidget(const GolfDiaryApp());
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      if (find.byKey(const ValueKey('shell-nav-bar')).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.byKey(const ValueKey('shell-nav-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('shell-tab-oncourse')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('oncourse-record-shot-btn')), findsOneWidget);
    expect(find.text('On Course'), findsOneWidget);
    final bar = tester
        .widget<NavigationBar>(find.byKey(const ValueKey('shell-nav-bar')));
    expect(
      bar.destinations
          .map((destination) => (destination as NavigationDestination).label)
          .toList(),
      ['My Bag', 'Range', 'On Course', 'Scorecard'],
    );
    await tester.pump(const Duration(seconds: 2));
  });
}
