import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/main.dart';

void main() {
  testWidgets('App loads home shell', (tester) async {
    await tester.pumpWidget(const GolfDiaryApp());
    await tester.pump();
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
