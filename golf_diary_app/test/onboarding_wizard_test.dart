import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golfer_profile.dart';
import 'package:golf_diary_app/screens/onboarding_starter_wizard.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/widgets/onboarding_gate.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  setUp(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary_onboarding.db');
    await deleteDatabase(
        join(await getDatabasesPath(), 'golf_diary_onboarding.db'));
  });

  tearDown(() async {
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName('golf_diary.db');
  });

  test('validateOnboardingAge and years reject out-of-range values', () {
    expect(validateOnboardingAge('7'), isNotNull);
    expect(validateOnboardingAge('100'), isNotNull);
    expect(validateOnboardingAge('30'), isNull);
    expect(validateOnboardingYears('81'), isNotNull);
    expect(validateOnboardingYears('5'), isNull);
  });

  Future<void> waitForGate(WidgetTester tester) async {
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
      if (find
              .byKey(const ValueKey('onboarding-age-field'))
              .evaluate()
              .isNotEmpty ||
          find.byKey(const ValueKey('shell-nav-bar')).evaluate().isNotEmpty) {
        return;
      }
    }
  }

  testWidgets('wizard shows when onboarding is incomplete', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingGate()));
    await tester.pump();
    await waitForGate(tester);

    expect(find.byKey(const ValueKey('onboarding-age-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('shell-nav-bar')), findsNothing);
  });

  testWidgets('invalid age shows inline validation', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingStarterWizard(
          initialProfile: const GolferProfile(),
          onFinished: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('onboarding-age-field')), '5');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Use an age between 8 and 99'), findsOneWidget);
  });

  test('saveGolferProfile persists onboarding demographics', () async {
    await LocalDatabaseService.instance.saveGolferProfile(
      const GolferProfile(
        age: 35,
        yearsPlaying: 10,
        gender: GolferGender.female,
        skillTier: GolferSkillTier.amateur,
        onboardingCompleted: 1,
      ),
    );
    final profile = await LocalDatabaseService.instance.getGolferProfile();
    expect(profile.hasCompletedOnboarding, isTrue);
    expect(profile.age, 35);
    expect(profile.yearsPlaying, 10);
    expect(profile.skillTier, GolferSkillTier.amateur);
  });

  test('completed profile skips wizard gate', () async {
    await LocalDatabaseService.instance.saveGolferProfile(
      const GolferProfile(onboardingCompleted: 1),
    );
    final profile = await LocalDatabaseService.instance.getGolferProfile();
    expect(profile.hasCompletedOnboarding, isTrue);
  });
}
