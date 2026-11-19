import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golfer_profile.dart';
import 'package:golf_diary_app/ui/header_action_policy.dart';

void main() {
  const beginner = GolferProfile(skillTier: GolferSkillTier.beginner);
  const amateur = GolferProfile(skillTier: GolferSkillTier.amateur);
  const pro = GolferProfile(skillTier: GolferSkillTier.seasonedPro);

  test('bag shows avatar only', () {
    final p = HeaderActionPolicy.resolve(
      profile: beginner,
      tab: HeaderTabContext.bag,
      roundActive: false,
    );
    expect(p.showDiaryPinned, isFalse);
    expect(p.usePlayOverflow, isFalse);
  });

  test('beginner range puts diary in overflow', () {
    final p = HeaderActionPolicy.resolve(
      profile: beginner,
      tab: HeaderTabContext.range,
      roundActive: false,
    );
    expect(p.showDiaryInOverflow, isTrue);
    expect(p.usePlayOverflow, isTrue);
    expect(p.showDiaryPinned, isFalse);
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
