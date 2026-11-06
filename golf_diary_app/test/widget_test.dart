import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/main.dart';

void main() {
  testWidgets('App loads home shell', (tester) async {
    await tester.pumpWidget(const GolfDiaryApp());
    await tester.pump();
    expect(find.text('Fairway HUD'), findsOneWidget);
    expect(find.text('On Course'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });
}
