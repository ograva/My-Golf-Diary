import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/data/practice_drill_seed.dart';
import 'package:golf_diary_app/models/golf_models.dart';
import 'package:golf_diary_app/models/practice_drill.dart';
import 'package:golf_diary_app/range/range_drill_clubs.dart';

PracticeDrill _drillById(String id) {
  final seed = kPracticeDrillSeed.firstWhere((d) => d.id == id);
  return PracticeDrill(
    id: seed.id,
    title: seed.title,
    category: seed.category,
    shortDescription: seed.shortDescription,
    steps: seed.steps,
    recommendedClubs: seed.recommendedClubs,
  );
}

void main() {
  final bag = [
    Club(id: 'driver', name: 'Driver', category: 'wood', avgDistance: 220),
    Club(id: '7iron', name: '7 Iron', category: 'iron', avgDistance: 145),
    Club(id: 'pw', name: 'Pitching Wedge', category: 'wedge', avgDistance: 110),
    Club(id: 'putter', name: 'Putter', category: 'putter', avgDistance: 0),
  ];

  test('default strip hides putter', () {
    final strip = clubsForRangeStrip(bag, null);
    expect(strip.map((c) => c.id), ['driver', '7iron', 'pw']);
  });

  test('putting drill shows only putter', () {
    final drill = _drillById('rng-drl-putt-gate-startline');
    final strip = clubsForRangeStrip(bag, drill);
    expect(strip.map((c) => c.id), ['putter']);
    expect(defaultClubForRangeStrip(strip, drill)?.id, 'putter');
  });

  test('approach drill prefers wedges', () {
    final drill = _drillById('rng-drl-approach-wedge-nine');
    final strip = clubsForRangeStrip(bag, drill);
    expect(strip.every((c) => c.category == 'wedge'), isTrue);
    expect(defaultClubForRangeStrip(strip, drill)?.id, 'pw');
  });

  test('seed includes new short-game drills', () {
    expect(kPracticeDrillSeed.length, 19);
    expect(
      kPracticeDrillSeed.map((d) => d.category),
      containsAll(['Putting', 'Approach']),
    );
  });
}
