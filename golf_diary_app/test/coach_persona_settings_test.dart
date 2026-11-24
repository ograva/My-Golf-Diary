import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golfer_profile.dart';
import 'package:golf_diary_app/screens/golfer_profile_settings_screen.dart';
import 'package:golf_diary_app/services/coach_persona_store.dart';
import 'package:golf_diary_app/services/swing_diary_prompt.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  bool isChecked(WidgetTester tester, CoachPersona persona) {
    final tile = tester.widget<RadioListTile<CoachPersona>>(
      find.byKey(ValueKey('profile-coach-persona-${persona.id}')),
    );
    // ignore: deprecated_member_use
    return tile.checked;
  }

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GolferProfileSettingsScreen(
          initialProfile: GolferProfile(skillTier: GolferSkillTier.amateur),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('profile-coach-persona-og-golf-pro')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('store defaults to golf-pro and round-trips a choice', () async {
    const store = CoachPersonaStore();
    expect(await store.load(), CoachPersona.golfPro);
    await store.save(CoachPersona.golfLady);
    expect(await store.load(), CoachPersona.golfLady);
  });

  testWidgets('Settings lists four coaches with golf-pro selected by default',
      (tester) async {
    await pumpSettings(tester);
    for (final persona in CoachPersona.values) {
      expect(find.byKey(ValueKey('profile-coach-persona-${persona.id}')),
          findsOneWidget);
    }
    expect(isChecked(tester, CoachPersona.golfPro), isTrue);
    expect(isChecked(tester, CoachPersona.golfBuddy), isFalse);
    expect(find.text('Golf Pro'), findsOneWidget);
    expect(find.text('Golf Buddy'), findsOneWidget);
    expect(find.text('Golf Lady'), findsOneWidget);
    expect(find.text('OG Golf Pro'), findsOneWidget);
    expect(CoachPersona.values, hasLength(4));
    expect(
      find.text('Tour-level advice from a playing partner, in plain '
          'range-and-fairway talk.'),
      findsOneWidget,
    );
  });

  testWidgets('picking a coach saves it on this device', (tester) async {
    await pumpSettings(tester);
    await tester
        .tap(find.byKey(const ValueKey('profile-coach-persona-og-golf-pro')));
    await tester.pumpAndSettle();
    expect(isChecked(tester, CoachPersona.ogGolfPro), isTrue);
    expect(await const CoachPersonaStore().load(), CoachPersona.ogGolfPro);

    await tester.pumpWidget(const SizedBox());
    await pumpSettings(tester);
    expect(isChecked(tester, CoachPersona.ogGolfPro), isTrue);
  });
}
