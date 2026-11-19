import 'dart:math' as math;
import 'dart:ui';

const kMetersPerYard = 0.9144;
const _metersPerDegreeLat = 111320.0;

double _rad(double deg) => deg * math.pi / 180;

/// Compass bearing (degrees clockwise from north) from one point to another.
double bearingDegrees({
  required double fromLat,
  required double fromLon,
  required double toLat,
  required double toLon,
}) {
  final dNorth = (toLat - fromLat) * _metersPerDegreeLat;
  final dEast =
      (toLon - fromLon) * _metersPerDegreeLat * math.cos(_rad(fromLat));
  final deg = math.atan2(dEast, dNorth) * 180 / math.pi;
  return (deg + 360) % 360;
}

/// Flat-earth hole frame in metres: +y points along [bearingDeg] (tee→green,
/// drawn up the screen), +x points to the golfer's right.
class HoleProjection {
  const HoleProjection({
    required this.centerLat,
    required this.centerLon,
    required this.bearingDeg,
  });

  final double centerLat;
  final double centerLon;
  final double bearingDeg;

  double get _cosLat => math.cos(_rad(centerLat)).abs().clamp(0.2, 1.0);

  Offset toLocal(double lat, double lon) {
    final dNorth = (lat - centerLat) * _metersPerDegreeLat;
    final dEast = (lon - centerLon) * _metersPerDegreeLat * _cosLat;
    final b = _rad(bearingDeg);
    return Offset(
      dEast * math.cos(b) - dNorth * math.sin(b),
      dEast * math.sin(b) + dNorth * math.cos(b),
    );
  }

  ({double lat, double lon}) toLatLon(Offset local) {
    final b = _rad(bearingDeg);
    final dEast = local.dx * math.cos(b) + local.dy * math.sin(b);
    final dNorth = -local.dx * math.sin(b) + local.dy * math.cos(b);
    return (
      lat: centerLat + dNorth / _metersPerDegreeLat,
      lon: centerLon + dEast / (_metersPerDegreeLat * _cosLat),
    );
  }
}

/// Maps hole-local metres to screen pixels with a uniform scale.
class HoleViewport {
  const HoleViewport({required this.origin, required this.pixelsPerMeter});

  /// Screen position of local (0, 0).
  final Offset origin;
  final double pixelsPerMeter;

  Offset toScreen(Offset local) => Offset(
        origin.dx + local.dx * pixelsPerMeter,
        origin.dy - local.dy * pixelsPerMeter,
      );

  Offset toLocal(Offset screen) => Offset(
        (screen.dx - origin.dx) / pixelsPerMeter,
        (origin.dy - screen.dy) / pixelsPerMeter,
      );

  /// Frames the tee→green corridor inside [free] (the map area left clear by
  /// the overlays, the rail, and the edge gutters).
  factory HoleViewport.fit({
    required Offset tee,
    required Offset green,
    required Rect free,
    double padding = 28,
    double maxPixelsPerMeter = 4,
    double corridorHalfWidthMeters = 30,
  }) {
    final spanY = (green.dy - tee.dy).abs().clamp(1.0, double.infinity);
    final spanX = (green.dx - tee.dx).abs() + corridorHalfWidthMeters * 2;
    final h = math.max(free.height - padding * 2, 40.0);
    final w = math.max(free.width - padding * 2, 40.0);
    final scale = math.min(math.min(h / spanY, w / spanX), maxPixelsPerMeter);
    final mid = Offset((tee.dx + green.dx) / 2, (tee.dy + green.dy) / 2);
    return HoleViewport(
      origin: Offset(
        free.center.dx - mid.dx * scale,
        free.center.dy + mid.dy * scale,
      ),
      pixelsPerMeter: scale,
    );
  }
}
