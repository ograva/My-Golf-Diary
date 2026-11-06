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
    );
    final restored = Club.fromMap(club.toMap());
    expect(restored.id, club.id);
    expect(restored.swingNotes, 'smooth tempo');
  });
}
