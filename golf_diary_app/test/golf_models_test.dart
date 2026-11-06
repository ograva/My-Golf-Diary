import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golf_models.dart';

void main() {
  test('computeFinalScore adds strokes and penalties', () {
    expect(computeFinalScore(strokes: 4, penalties: 1), 5);
    expect(computeFinalScore(strokes: 0, penalties: 2), 2);
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
