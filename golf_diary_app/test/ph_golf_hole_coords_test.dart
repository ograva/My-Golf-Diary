import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/data/ph_golf_catalog.dart';
import 'package:golf_diary_app/data/ph_golf_hole_coords.dart';

void main() {
  test('a fully mapped course returns tee and green for every hole', () {
    const name = 'Manila Golf and Country Club';
    final hole1 = PhGolfHoleCoords.holeCoordinates(name, 1);
    expect(hole1, isNotNull);
    expect(hole1!.teeLat, 14.549992);
    expect(hole1.teeLon, 121.039469);
    expect(hole1.greenLat, 14.547707);
    expect(hole1.greenLon, 121.040977);

    expect(PhGolfHoleCoords.holeCoordinates(name, 18), isNotNull);
    expect(PhGolfHoleCoords.holeCoordinates(name, 19), isNull);

    final trimmed = PhGolfHoleCoords.holeCoordinates(
      '  manila golf and country club  ',
      1,
    );
    expect(trimmed!.teeLat, hole1.teeLat);
    expect(trimmed.greenLon, hole1.greenLon);
  });

  test('a partial layout returns surveyed holes and skips the rest', () {
    const name = 'Sherwood Hills Golf Club';
    final hole1 = PhGolfHoleCoords.holeCoordinates(name, 1);
    expect(hole1, isNotNull);
    expect(hole1!.teeLat, 14.249943);
    expect(hole1.greenLat, 14.247415);

    expect(PhGolfHoleCoords.holeCoordinates(name, 3), isNull);
    expect(PhGolfHoleCoords.holeCoordinates(name, 7), isNull);
    expect(PhGolfHoleCoords.holeCoordinates(name, 8), isNotNull);
  });

  test('unknown, custom, and unsurveyed course names return null', () {
    expect(PhGolfHoleCoords.holeCoordinates('Not A Real Course', 1), isNull);
    expect(PhGolfHoleCoords.holeCoordinates('Sunday skins', 1), isNull);
    expect(PhGolfHoleCoords.holeCoordinates('Southlinks Golf Club', 1), isNull);
    expect(PhGolfHoleCoords.holeCoordinates('   ', 1), isNull);
  });

  test('mapped names are canonical venue catalog names', () {
    const mapped = [
      'Wack Wack Golf & Country Club — East',
      'Wack Wack Golf & Country Club — West',
      'Manila Golf and Country Club',
      'Villamor Golf Club',
      'Club Intramuros Golf Course',
      'Camp Aguinaldo Golf Club',
      'Veterans Golf Club',
      'Philippine Navy Golf Club',
      'Manila Southwoods — Masters Course',
      'Manila Southwoods — Legends Course',
      'Valley Golf & Country Club — South',
      'Valley Golf & Country Club — North',
      'Eagle Ridge G&CC — Nick Faldo Course',
      'Eagle Ridge G&CC — Pete Dye Course',
      'Ayala Greenfield Golf & Leisure Club',
      'Cebu Country Club',
      'Hallow Ridge Filipinas Golf (KC Filipinas)',
      'Sherwood Hills Golf Club',
    ];
    for (final name in mapped) {
      expect(PhGolfCatalog.matchCourse(name), isNotNull, reason: name);
      expect(PhGolfHoleCoords.holeCoordinates(name, 1), isNotNull,
          reason: name);
    }
  });
}
