import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:golf_diary_app/data/ph_golf_hole_coords.dart';
import 'package:golf_diary_app/services/pin_distance.dart';

void main() {
  test('mapped, partial, and unknown courses resolve without invented pins',
      () {
    final villamor = holeCoordinates('Villamor Golf Club', 1);
    expect(villamor, isNotNull);
    expect(villamor!.teeLat, 14.525017);
    expect(villamor.teeLon, 121.023699);
    expect(villamor.greenLat, 14.527490);
    expect(villamor.greenLon, 121.022171);
    expect(holeCoordinates('  villamor golf club ', 18), isNotNull);
    expect(holeCoordinates('Villamor Golf Club Course', 1), isNotNull);

    expect(holeCoordinates('Sherwood Hills Golf Club', 1), isNotNull);
    expect(holeCoordinates('Sherwood Hills Golf Club', 3), isNull);
    expect(holeCoordinates('Sherwood Hills Golf Club', 19), isNull);

    expect(holeCoordinates('Hallow Ridge Filipinas Golf (KC Filipinas)', 1),
        isNotNull);
    expect(holeCoordinates('Hallow Ridge Filipinas Golf', 1), isNotNull);
    expect(holeCoordinates('Hallow Ridge Filipinas Golf (KC Filipinas)', 10),
        isNull);

    expect(holeCoordinates('Southlinks Golf Club', 1), isNull);
    expect(holeCoordinates('Eagle Ridge G&CC — Pete Dye Course', 1), isNull);
    expect(holeCoordinates('My Backyard', 1), isNull);
    expect(holeCoordinates('   ', 1), isNull);
  });

  test('yards to the pin are distanceBetween meters times 1.09361', () {
    const fromLat = 14.525017;
    const fromLon = 121.023699;
    const greenLat = 14.527490;
    const greenLon = 121.022171;
    final meters =
        Geolocator.distanceBetween(fromLat, fromLon, greenLat, greenLon);
    expect(
      yardsToPin(
          fromLat: fromLat,
          fromLon: fromLon,
          greenLat: greenLat,
          greenLon: greenLon),
      (meters * 1.09361).round(),
    );
    expect(GeolocatorPinDistanceClient.locationSettings.distanceFilter, 3);
  });
}
