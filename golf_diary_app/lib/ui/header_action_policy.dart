import '../models/golfer_profile.dart';

/// Which tab is showing the shared header cluster.
enum HeaderTabContext {
  bag,
  range,
  onCourse,
  scorecard,
}

/// Tier-aware visibility for diary and caddy affordances (MGDV-206 / audit P0).
class HeaderActionPolicy {
  const HeaderActionPolicy({
    this.showDiaryPinned = false,
    this.showDiaryInOverflow = false,
    this.showCaddyPinned = false,
    this.showCaddyInOverflow = false,
    this.usePlayOverflow = false,
  });

  final bool showDiaryPinned;
  final bool showDiaryInOverflow;
  final bool showCaddyPinned;
  final bool showCaddyInOverflow;
  final bool usePlayOverflow;

  factory HeaderActionPolicy.resolve({
    required GolferProfile profile,
    required HeaderTabContext tab,
    required bool roundActive,
  }) {
    final tier = profile.skillTier.trim();
    final beginner =
        tier.isEmpty || tier == GolferSkillTier.beginner;
    final pro = tier == GolferSkillTier.seasonedPro;

    switch (tab) {
      case HeaderTabContext.bag:
        return const HeaderActionPolicy();
      case HeaderTabContext.range:
        if (beginner) {
          return const HeaderActionPolicy(
            showDiaryInOverflow: true,
            usePlayOverflow: true,
          );
        }
        return const HeaderActionPolicy(showDiaryPinned: true);
      case HeaderTabContext.onCourse:
      case HeaderTabContext.scorecard:
        if (beginner) {
          return HeaderActionPolicy(
            showDiaryInOverflow: true,
            showCaddyInOverflow: roundActive,
            usePlayOverflow: true,
          );
        }
        if (pro) {
          return HeaderActionPolicy(
            showDiaryPinned: true,
            showCaddyPinned: roundActive,
          );
        }
        return HeaderActionPolicy(
          showDiaryPinned: true,
          showCaddyInOverflow: roundActive,
        );
    }
  }
}