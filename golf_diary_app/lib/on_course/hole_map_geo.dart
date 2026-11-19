import 'dart:math' as math;
import 'dart:ui';

import '../data/ph_golf_hole_coords.dart';
import '../models/course_map_manifest.dart';
import '../models/golf_models.dart';
import '../services/pin_distance.dart';

const _metersPerYard = 0.9144;
const _metersPerDegreeLat = 111320.0;

class HoleMapBounds {
  const HoleMapBounds({
    required this.swLat,
    required this.swLon,
    required this.neLat,
    required this.neLon,
  });

  final double swLat;
  final double swLon;
  final double neLat;
  final double neLon;

  factory HoleMapBounds.fromManifest(HoleMapManifestEntry entry) {
    return HoleMapBounds(
      swLat: entry.swLat,
      swLon: entry.swLon,
      neLat: entry.neLat,
      neLon: entry.neLon,
    );
  }
}

HoleMapBounds boundsForHole(
  HoleCoordinates coords, {
  List<ShotRecord> shots = const [],
  PinFix? player,
  double padYards = 60,
}) {
  final lats = <double>[coords.teeLat, coords.greenLat];
  final lons = <double>[coords.teeLon, coords.greenLon];
  for (final shot in shots) {
    if (shot.endLat != null && shot.endLon != null) {
      lats.add(shot.endLat!);
      lons.add(shot.endLon!);
    }
  }
  if (player != null) {
    lats.add(player.latitude);
    lons.add(player.longitude);
  }
  var minLat = lats.reduce(math.min);
  var maxLat = lats.reduce(math.max);
  var minLon = lons.reduce(math.min);
  var maxLon = lons.reduce(math.max);

  final midLat = (minLat + maxLat) / 2;
  final padM = padYards * _metersPerYard;
  final latPad = padM / _metersPerDegreeLat;
  final lonPad =
      padM / (_metersPerDegreeLat * math.cos(midLat * math.pi / 180).abs().clamp(0.2, 1));

  minLat -= latPad;
  maxLat += latPad;
  minLon -= lonPad;
  maxLon += lonPad;

  final latSpan = (maxLat - minLat).abs();
  final lonSpan = (maxLon - minLon).abs();
  final minSpan = 80 / _metersPerDegreeLat;
  if (latSpan < minSpan) {
    final extra = (minSpan - latSpan) / 2;
    minLat -= extra;
    maxLat += extra;
  }
  if (lonSpan < minSpan) {
    final extra = (minSpan - lonSpan) / 2;
    minLon -= extra;
    maxLon += extra;
  }

  return HoleMapBounds(
    swLat: minLat,
    swLon: minLon,
    neLat: maxLat,
    neLon: maxLon,
  );
}

/// WGS84 → widget pixel using a simple equirectangular crop inside [bounds].
Offset projectLatLon({
  required double lat,
  required double lon,
  required HoleMapBounds bounds,
  required Rect paintRect,
}) {
  final latSpan = (bounds.neLat - bounds.swLat).abs() < 1e-12
      ? 1e-12
      : (bounds.neLat - bounds.swLat);
  final lonSpan = (bounds.neLon - bounds.swLon).abs() < 1e-12
      ? 1e-12
      : (bounds.neLon - bounds.swLon);
  final x = paintRect.left + (lon - bounds.swLon) / lonSpan * paintRect.width;
  final y = paintRect.bottom - (lat - bounds.swLat) / latSpan * paintRect.height;
  return Offset(x, y);
}