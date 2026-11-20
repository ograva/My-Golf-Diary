import '../models/golfer_profile.dart';

/// Which tab is showing the shared header cluster.
enum HeaderTabContext {
  bag,
  range,
  onCourse,
  scorecard,
}

/// Tier-aware visibility for the caddy invite. The diary write icon is
/// always pinned; it is never moved into the overflow (one affordance).
class HeaderActionPolicy {
  const HeaderActionPolicy({
    this.showDiaryPinned = true,
    this.showCaddyPinned = false,
    this.showCaddyInOverflow = false,
    this.usePlayOverflow = false,
  });

  /// Book icon in the AppBar, immediately left of the account avatar.
  final bool showDiaryPinned;
  final bool showCaddyPinned;
  final bool showCaddyInOverflow;
  final bool usePlayOverflow;

  factory HeaderActionPolicy.resolve({
    required GolferProfile profile,
    required HeaderTabContext tab,
    required bool roundActive,
  }) {
    final tier = profile.skillTier.trim();
    final pro = tier == GolferSkillTier.seasonedPro;

    switch (tab) {
      case HeaderTabContext.bag:
      case HeaderTabContext.range:
        return const HeaderActionPolicy();
      case HeaderTabContext.onCourse:
      case HeaderTabContext.scorecard:
        if (pro) {
          return HeaderActionPolicy(showCaddyPinned: roundActive);
        }
        return HeaderActionPolicy(showCaddyInOverflow: roundActive);
    }
  }
}