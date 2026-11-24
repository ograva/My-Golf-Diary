import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/widgets/golf_ball_loader.dart';

void main() {
  testWidgets('GolfBallLoader animates and labels itself', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: GolfBallLoader(size: 40))),
    );
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.bySemanticsLabel('Waiting for a reply'), findsOneWidget);
    expect(tester.getSize(find.byType(GolfBallLoader)), const Size(40, 40));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('GolfBallLoader holds still when animations are disabled',
      (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: Center(child: GolfBallLoader())),
      ),
    );
    expect(tester.hasRunningAnimations, isFalse);
  });
}
