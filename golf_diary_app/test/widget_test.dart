import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/main.dart';

void main() {
  testWidgets('App loads home shell', (tester) async {
    await tester.pumpWidget(const GolfDiaryApp());
    await tester.pump();
    expect(find.text('Fairway HUD'), findsOneWidget);
    expect(find.text('On Course'), findsOneWidget);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      bar.destinations.map((destination) => (destination as NavigationDestination).label).toList(),
      ['My Bag', 'Range', 'On Course', 'Scorecard'],
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
