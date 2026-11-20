import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golfer_profile.dart';
import 'package:golf_diary_app/ui/header_action_policy.dart';

void main() {
  const beginner = GolferProfile(skillTier: GolferSkillTier.beginner);
  const amateur = GolferProfile(skillTier: GolferSkillTier.amateur);
  const pro = GolferProfile(skillTier: GolferSkillTier.seasonedPro);

  test('every tab pins the diary icon and never overflows it', () {
    for (final profile in [beginner, amateur, pro]) {
      for (final tab in HeaderTabContext.values) {
        for (final roundActive in [false, true]) {
          final p = HeaderActionPolicy.resolve(
            profile: profile,
            tab: tab,
            roundActive: roundActive,
          );
          expect(p.showDiaryPinned, isTrue,
              reason: '${profile.skillTier} $tab round=$roundActive');
          expect(p.usePlayOverflow, isFalse);
        }
      }
    }
  });

  test('bag and range show no caddy overflow', () {
    final p = HeaderActionPolicy.resolve(
      profile: beginner,
      tab: HeaderTabContext.bag,
      roundActive: false,
    );
    expect(p.showCaddyPinned, isFalse);
    expect(p.showCaddyInOverflow, isFalse);

    final range = HeaderActionPolicy.resolve(
      profile: beginner,
      tab: HeaderTabContext.range,
      roundActive: false,
    );
    expect(range.showCaddyInOverflow, isFalse);
  });

  test('pro on course with round pins QR and diary', () {
    final p = HeaderActionPolicy.resolve(
      profile: pro,
      tab: HeaderTabContext.onCourse,
      roundActive: true,
    );
    expect(p.showCaddyPinned, isTrue);
    expect(p.showDiaryPinned, isTrue);
    expect(p.usePlayOverflow, isFalse);
  });

  test('amateur scorecard active round hides pinned QR', () {
    final p = HeaderActionPolicy.resolve(
      profile: amateur,
      tab: HeaderTabContext.scorecard,
      roundActive: true,
    );
    expect(p.showDiaryPinned, isTrue);
    expect(p.showCaddyPinned, isFalse);
    expect(p.showCaddyInOverflow, isTrue);
  });
}
