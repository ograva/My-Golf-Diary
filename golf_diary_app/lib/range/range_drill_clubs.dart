import '../models/golf_models.dart';
import '../models/practice_drill.dart';

/// Putting drills log against the putter; other drills hide putters from the strip.
bool rangeDrillShowsPutter(PracticeDrill? drill) =>
    drill?.category == 'Putting';

bool rangeDrillApproachMode(PracticeDrill? drill) =>
    drill?.category == 'Approach';

/// Clubs shown in the Range horizontal strip for the active drill context.
List<Club> clubsForRangeStrip(List<Club> all, PracticeDrill? drill) {
  if (rangeDrillShowsPutter(drill)) {
    final putters = all.where((c) => c.category == 'putter').toList();
    return putters.isNotEmpty ? putters : all;
  }

  var list = all.where((c) => c.category != 'putter').toList();

  if (rangeDrillApproachMode(drill)) {
    final wedges = list.where((c) => c.category == 'wedge').toList();
    if (wedges.isNotEmpty) return wedges;
    return list
        .where((c) =>
            c.category == 'wedge' ||
            c.category == 'iron' ||
            c.category == 'hybrid')
        .toList();
  }

  return list;
}

/// After drill selection, pick a sensible default club when the current one
/// is not in the filtered strip.
Club? defaultClubForRangeStrip(List<Club> strip, PracticeDrill? drill) {
  if (strip.isEmpty) return null;
  if (rangeDrillShowsPutter(drill)) {
    return strip.firstWhere(
      (c) => c.category == 'putter',
      orElse: () => strip.first,
    );
  }
  if (rangeDrillApproachMode(drill)) {
    return strip.firstWhere(
      (c) => c.category == 'wedge',
      orElse: () => strip.first,
    );
  }
  return strip.first;
}

String? rangeDrillFocusLabel(PracticeDrill? drill) {
  if (drill == null) return null;
  return switch (drill.category) {
    'Putting' => "Today's focus · Putting (practice green)",
    'Approach' => "Today's focus · Approach to green",
    'Distance Wedges' => "Today's focus · Wedge distances",
    _ => "Today's focus · ${drill.category}",
  };
}