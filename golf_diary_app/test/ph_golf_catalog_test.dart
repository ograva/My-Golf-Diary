import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/data/ph_golf_catalog.dart';

void main() {
  test('course cards match their hole counts and documented totals', () {
    final names = <String>{};
    for (final course in PhGolfCatalog.courses) {
      expect(names.add(course.name.toLowerCase()), isTrue, reason: course.name);
      final pars = course.holePars;
      if (pars == null) continue;
      expect(pars.length, course.holes, reason: course.name);
      expect(pars.fold<int>(0, (sum, par) => sum + par), course.totalPar,
          reason: course.name);
      expect(pars.every((par) => par >= 3 && par <= 5), isTrue,
          reason: course.name);
    }
    for (final name in [...PhGolfCatalog.ranges, ...PhGolfCatalog.simulators]) {
      expect(names.add(name.toLowerCase()), isTrue, reason: name);
    }
  });

  test('parForHole reads a card, stops past a nine, and ignores unknown names',
      () {
    expect(PhGolfCatalog.parForHole('Club Intramuros Golf Course', 1), 3);
    expect(PhGolfCatalog.parForHole('  club intramuros golf course ', 7), 5);
    expect(
        PhGolfCatalog.parForHole('Philippine Army Golf Club (Kagitingan)', 9),
        4);
    expect(
        PhGolfCatalog.parForHole('Philippine Army Golf Club (Kagitingan)', 10),
        isNull);
    expect(
        PhGolfCatalog.parForHole('Mount Malarayat Golf & Country Club', 1), 4);
    expect(PhGolfCatalog.parForHole('Mount Malarayat Golf & Country Club', 10),
        isNull);
    expect(PhGolfCatalog.parForHole('Southlinks Golf Club', 1), isNull);
    expect(PhGolfCatalog.parForHole('My Backyard', 1), isNull);
    expect(
        PhGolfCatalog.holeCount('Philippine Army Golf Club (Kagitingan)'), 9);
    expect(PhGolfCatalog.holeCount('My Backyard'), 18);
    expect(PhGolfCatalog.courseCaption('Club Intramuros Golf Course'),
        '18 holes · par 66');
    expect(PhGolfCatalog.courseCaption('Southlinks Golf Club'), isNull);
  });
}
