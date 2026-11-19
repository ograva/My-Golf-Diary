import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golf_models.dart';

void main() {
  test('computeFinalScore adds strokes and penalties', () {
    expect(computeFinalScore(strokes: 4, penalties: 1), 5);
    expect(computeFinalScore(strokes: 0, penalties: 2), 2);
  });

  test('manual hole gross uses strokes plus penalties', () {
    expect(computeFinalScore(strokes: 5, penalties: 2), 7);
  });

  test('effectiveHoleScore prefers finalized score', () {
    final hole = RoundScore(
      id: 'x',
      roundId: 'r',
      courseName: 'Test',
      holeNumber: 1,
      par: 4,
      strokes: 5,
      penalties: 1,
      finalScore: 6,
    );
    expect(effectiveHoleScore(hole), 6);
  });

  test('Club round-trips through map', () {
    final club = Club(
      id: '7iron',
      name: '7 Iron',
      category: 'iron',
      avgDistance: 145,
      swingNotes: 'smooth tempo',
      brand: 'Titleist',
      model: 'T200',
    );
    final restored = Club.fromMap(club.toMap());
    expect(restored.id, club.id);
    expect(restored.swingNotes, 'smooth tempo');
    expect(restored.brand, 'Titleist');
    expect(restored.model, 'T200');
  });

  test('sortClubs orders driver first, woods and hybrids incrementally, irons 2-9, wedges P/G/S, putter last', () {
    final unsorted = [
      Club(id: 'putter', name: 'Putter', category: 'putter', avgDistance: 300),
      Club(id: 'sw', name: 'Sand Wedge', category: 'wedge', avgDistance: 90),
      Club(id: '9i', name: '9 Iron', category: 'iron', avgDistance: 130),
      Club(id: '5w', name: '5 Wood', category: 'wood', avgDistance: 210),
      Club(id: 'gw', name: 'Gap Wedge', category: 'wedge', avgDistance: 100),
      Club(id: '4h', name: '4 Hybrid', category: 'hybrid', avgDistance: 185),
      Club(id: '2i', name: '2 Iron', category: 'iron', avgDistance: 200),
      Club(id: 'pw', name: 'Pitching Wedge', category: 'wedge', avgDistance: 115),
      Club(id: '3w', name: '3 Wood', category: 'wood', avgDistance: 235),
      Club(id: '3h', name: '3 Hybrid', category: 'hybrid', avgDistance: 195),
      Club(id: '7i', name: '7 Iron', category: 'iron', avgDistance: 155),
      Club(id: 'driver', name: 'Driver', category: 'wood', avgDistance: 0),
      Club(id: '5i', name: '5 Iron', category: 'iron', avgDistance: 175),
    ];

    final sorted = sortClubs(unsorted);
    expect(
      sorted.map((c) => c.name).toList(),
      [
        'Driver',
        '3 Wood',
        '5 Wood',
        '3 Hybrid',
        '4 Hybrid',
        '2 Iron',
        '5 Iron',
        '7 Iron',
        '9 Iron',
        'Pitching Wedge',
        'Gap Wedge',
        'Sand Wedge',
        'Putter',
      ],
    );
  });

  test('sortClubs orders irons 2 through 9 and wedge variants intuitively', () {
    final irons = [
      for (final n in [8, 3, 6, 2, 9, 4, 7, 5])
        Club(id: '${n}i', name: '$n Iron', category: 'iron'),
    ];
    expect(
      sortClubs(irons).map((c) => c.name).toList(),
      ['2 Iron', '3 Iron', '4 Iron', '5 Iron', '6 Iron', '7 Iron', '8 Iron', '9 Iron'],
    );

    final wedges = [
      Club(id: 'lw', name: 'Lob Wedge', category: 'wedge'),
      Club(id: 'sw', name: 'Sand Wedge', category: 'wedge'),
      Club(id: 'pw', name: 'Pitching Wedge', category: 'wedge'),
      Club(id: 'gw', name: 'Gap Wedge', category: 'wedge'),
    ];
    expect(
      sortClubs(wedges).map((c) => c.name).toList(),
      ['Pitching Wedge', 'Gap Wedge', 'Sand Wedge', 'Lob Wedge'],
    );
  });
}
