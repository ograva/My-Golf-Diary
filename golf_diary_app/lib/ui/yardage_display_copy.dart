import '../models/golfer_profile.dart';

/// Human category chip labels; underlying [Club.category] enum unchanged.
String bagCategoryLabel(String category) {
  return switch (category) {
    'wood' => 'Drivers & woods',
    'hybrid' => 'Hybrids',
    'iron' => 'Irons',
    'wedge' => 'Wedges',
    'putter' => 'Putters',
    'other' => 'Other',
    _ => category.isEmpty
        ? category
        : category[0].toUpperCase() + category.substring(1),
  };
}

class YardageStatLabels {
  const YardageStatLabels({
    required this.shortest,
    required this.usual,
    required this.longest,
  });

  final String shortest;
  final String usual;
  final String longest;

  static YardageStatLabels forDensity(YardageUiDensity density) {
    if (density == YardageUiDensity.full) {
      return const YardageStatLabels(
        shortest: 'Min',
        usual: 'Avg',
        longest: 'Max',
      );
    }
    return const YardageStatLabels(
      shortest: 'Shortest',
      usual: 'Usual',
      longest: 'Best',
    );
  }
}

String formatCarryYards(double yards) {
  if (yards <= 0) return '—';
  return '${yards.round()} yds';
}