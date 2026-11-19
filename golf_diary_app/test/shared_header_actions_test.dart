import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/diary_context_note.dart';
import 'package:golf_diary_app/models/golfer_profile.dart';
import 'package:golf_diary_app/services/golfer_profile_store.dart';
import 'package:golf_diary_app/ui/header_action_policy.dart';
import 'package:golf_diary_app/widgets/shared_header_actions.dart';

void main() {
  Future<void> pumpHeader(
    WidgetTester tester, {
    required HeaderTabContext tab,
    required GolferProfile profile,
    String? roundId,
  }) async {
    final store = GolferProfileStore()..profile = profile;
    await tester.pumpWidget(
      MaterialApp(
        home: GolferProfileScope(
          store: store,
          child: Scaffold(
            appBar: AppBar(
              actions: [
                SharedHeaderActions(
                tab: tab,
                roundId: roundId,
                courseName: 'Test Course',
                diaryEntryKey: tab == HeaderTabContext.bag
                    ? null
                    : 'diary-entry-test',
                diarySource: tab == HeaderTabContext.bag
                    ? null
                    : DiaryContextSource.range,
                caddyInviteKey: tab == HeaderTabContext.scorecard
                    ? 'scorecard-invite-caddy'
                    : 'on-course-invite-caddy',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('beginner bag shows only account avatar', (tester) async {
    await pumpHeader(
      tester,
      tab: HeaderTabContext.bag,
      profile: const GolferProfile(skillTier: GolferSkillTier.beginner),
    );
    expect(find.byKey(const Key('account-avatar-button')), findsOneWidget);
    expect(find.byKey(const Key('shell-header-overflow-btn')), findsNothing);
  });

  testWidgets('beginner on course with round uses overflow not pinned QR',
      (tester) async {
    await pumpHeader(
      tester,
      tab: HeaderTabContext.onCourse,
      profile: const GolferProfile(skillTier: GolferSkillTier.beginner),
      roundId: 'round-1',
    );
    expect(find.byKey(const ValueKey('on-course-invite-caddy')), findsNothing);
    expect(find.byKey(const Key('shell-header-overflow-btn')), findsOneWidget);
    await tester.tap(find.byKey(const Key('shell-header-overflow-btn')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('on-course-invite-caddy')), findsOneWidget);
  });

  testWidgets('pro scorecard with round shows pinned invite',
      (tester) async {
    await pumpHeader(
      tester,
      tab: HeaderTabContext.scorecard,
      profile: const GolferProfile(skillTier: GolferSkillTier.seasonedPro),
      roundId: 'round-9',
    );
    expect(
      find.byKey(const ValueKey('scorecard-invite-caddy')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('diary-entry-test')), findsOneWidget);
  });
}