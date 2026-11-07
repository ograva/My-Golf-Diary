import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/screens/fairway_tracker_screen.dart';
import 'package:golf_diary_app/theme/app_theme.dart';

void main() {
  testWidgets('Simulator mode asks for yards and rejects a blank distance', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(theme: buildGolfTheme(), home: const FairwayTrackerScreen()));
    await tester.pump();

    expect(find.text('Record Shot at Ball'), findsOneWidget);
    expect(find.text('Distance travelled (yds)'), findsNothing);

    await tester.tap(find.text('Simulator'));
    await tester.pump();

    expect(find.text('Record shot'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Distance travelled (yds)'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Record shot'));
    await tester.pump();
    expect(find.text('Enter a distance greater than 0'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Distance travelled (yds)'), '0');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Record shot'));
    await tester.pump();
    expect(find.text('Enter a distance greater than 0'), findsOneWidget);

    await tester.tap(find.text('Course'));
    await tester.pump();
    expect(find.text('Record Shot at Ball'), findsOneWidget);
    expect(find.text('Distance travelled (yds)'), findsNothing);
  });
}
