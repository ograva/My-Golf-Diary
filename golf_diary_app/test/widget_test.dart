import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/main.dart';
import 'package:golf_diary_app/screens/range_drill_screen.dart';
import 'package:golf_diary_app/services/local_database_service.dart';

void main() {
  Future<void> preloadDatabase(WidgetTester tester) {
    return tester.runAsync(() => LocalDatabaseService.instance.getAllClubs());
  }

  testWidgets('App loads On Course shell', (tester) async {
    await preloadDatabase(tester);
    await tester.pumpWidget(const GolfDiaryApp());
    await tester.pump();

    expect(find.text('Fairway HUD'), findsNothing);
    expect(find.byKey(const ValueKey('shell-nav-bar')), findsOneWidget);
    expect(find.byKey(const ValueKey('shell-tab-oncourse')), findsOneWidget);
    expect(find.byKey(const ValueKey('oncourse-record-shot-btn')), findsOneWidget);
    expect(find.text('On Course'), findsWidgets);
  });

  testWidgets('Bag, scorecard, and range expose wireframe keys', (tester) async {
    await preloadDatabase(tester);
    await tester.pumpWidget(const GolfDiaryApp());
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('shell-tab-bag')));
    await tester.pump();

    expect(find.byKey(const ValueKey('bag-category-chip-wood')), findsOneWidget);
    expect(find.byKey(const ValueKey('bag-club-card-driver')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('shell-tab-range')));
    await tester.pump();

    expect(find.byKey(const ValueKey('range-shot-counter-increment')), findsOneWidget);
    expect(find.byKey(const ValueKey('range-save-drill-btn')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('shell-tab-scorecard')));
    await tester.pump();

    expect(find.byKey(const ValueKey('scorecard-hole-tile-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('scorecard-hole-tile-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('hole-editor-gross')), findsOneWidget);
    expect(find.byKey(const ValueKey('hole-editor-save-btn')), findsOneWidget);
  });

  test('sqlite opens under the test factory', () async {
    final clubs = await LocalDatabaseService.instance
        .getClubsByCategory('wood')
        .timeout(const Duration(seconds: 8));
    expect(clubs.map((club) => club.id), contains('driver'));
  });

  test('resolveDrillYardages copies empty sides and rejects bad order', () {
    final copied = resolveDrillYardages(minText: '', avgText: '150', maxText: '');
    expect(copied, isNotNull);
    expect(copied!.min, 150);
    expect(copied.avg, 150);
    expect(copied.max, 150);

    final ordered = resolveDrillYardages(minText: '140', avgText: '155', maxText: '170');
    expect(ordered!.min, 140);
    expect(ordered.avg, 155);
    expect(ordered.max, 170);

    expect(resolveDrillYardages(minText: '180', avgText: '150', maxText: '190'), isNull);
    expect(resolveDrillYardages(minText: '', avgText: '', maxText: ''), isNull);
    expect(resolveDrillYardages(minText: '10', avgText: 'nope', maxText: '12'), isNull);
  });
}
