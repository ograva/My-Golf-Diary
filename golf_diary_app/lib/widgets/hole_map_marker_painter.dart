import 'package:flutter/material.dart';

import '../data/ph_golf_hole_coords.dart';
import '../models/golf_models.dart';
import '../on_course/hole_map_geo.dart';
import '../services/pin_distance.dart';

/// Tee, green, stroke polyline, and live player overlay (shared vector + satellite).
class HoleMapMarkerPainter extends CustomPainter {
  HoleMapMarkerPainter({
    required this.coords,
    required this.shots,
    required this.bounds,
    this.player,
    required this.colorScheme,
  });

  final HoleCoordinates coords;
  final List<ShotRecord> shots;
  final HoleMapBounds bounds;
  final PinFix? player;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(12);
    final tee = projectLatLon(
      lat: coords.teeLat,
      lon: coords.teeLon,
      bounds: bounds,
      paintRect: inset,
    );
    final green = projectLatLon(
      lat: coords.greenLat,
      lon: coords.greenLon,
      bounds: bounds,
      paintRect: inset,
    );

    final pathPaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.75)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final shotPoints = <Offset>[tee];
    for (final shot in shots) {
      final lat = shot.endLat;
      final lon = shot.endLon;
      if (lat == null || lon == null) continue;
      shotPoints.add(projectLatLon(
        lat: lat,
        lon: lon,
        bounds: bounds,
        paintRect: inset,
      ));
    }
    if (shotPoints.length > 1) {
      for (var i = 0; i < shotPoints.length - 1; i++) {
        canvas.drawLine(shotPoints[i], shotPoints[i + 1], pathPaint);
      }
    } else {
      canvas.drawLine(tee, green, pathPaint);
    }

    final teePaint = Paint()..color = colorScheme.primary.withValues(alpha: 0.9);
    canvas.drawCircle(tee, 6, teePaint);

    final flagPaint = Paint()..color = colorScheme.tertiary;
    canvas.drawCircle(green, 7, flagPaint);

    final shotPaint = Paint()..color = colorScheme.onSurface;
    for (var i = 1; i < shotPoints.length; i++) {
      canvas.drawCircle(shotPoints[i], 5, shotPaint);
    }

    if (player != null) {
      final you = projectLatLon(
        lat: player!.latitude,
        lon: player!.longitude,
        bounds: bounds,
        paintRect: inset,
      );
      final playerPaint = Paint()..color = colorScheme.primary;
      canvas.drawCircle(you, 8, playerPaint);
      final ring = Paint()
        ..color = colorScheme.onPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(you, 8, ring);
    }
  }

  @override
  bool shouldRepaint(covariant HoleMapMarkerPainter oldDelegate) {
    return oldDelegate.coords != coords ||
        oldDelegate.shots != shots ||
        oldDelegate.bounds != bounds ||
        oldDelegate.player?.latitude != player?.latitude ||
        oldDelegate.player?.longitude != player?.longitude ||
        oldDelegate.colorScheme != colorScheme;
  }
}