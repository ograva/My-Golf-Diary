import 'package:geolocator/geolocator.dart';

import '../data/ph_golf_hole_coords.dart';

/// Meters from [Geolocator.distanceBetween], shown as whole yards.
int yardsToPin({
  required double fromLat,
  required double fromLon,
  required double greenLat,
  required double greenLon,
}) {
  final meters =
      Geolocator.distanceBetween(fromLat, fromLon, greenLat, greenLon);
  return (meters * 1.09361).round();
}

int yardsToHole(HoleCoordinates hole,
    {required double fromLat, required double fromLon}) {
  return yardsToPin(
    fromLat: fromLat,
    fromLon: fromLon,
    greenLat: hole.greenLat,
    greenLon: hole.greenLon,
  );
}

class PinFix {
  const PinFix({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Location reads for the yards-to-pin line. Tests supply a fake.
abstract class PinDistanceClient {
  Future<PinFix?> current();

  Stream<PinFix> watch();
}

class GeolocatorPinDistanceClient implements PinDistanceClient {
  /// About 3 meters of movement before the next yardage update.
  static const locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 3,
  );

  @override
  Future<PinFix?> current() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return PinFix(latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<PinFix> watch() {
    return Geolocator.getPositionStream(locationSettings: locationSettings).map(
      (position) =>
          PinFix(latitude: position.latitude, longitude: position.longitude),
    );
  }
}
