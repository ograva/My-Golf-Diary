import 'package:flutter/material.dart';

import '../data/ph_golf_hole_coords.dart';
import '../models/golf_models.dart';

/// Offline vector tee→green schematic with shot dots (Architecture §5.5).
class OncourseVectorHoleMap extends StatelessWidget {
  const OncourseVectorHoleMap({
    super.key,
    required this.coords,
    required this.shots,
  });

  final HoleCoordinates coords;
  final List<ShotRecord> shots;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hole line from tee to green',
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CustomPaint(
              key: const ValueKey('oncourse-map-vector'),
              painter: _VectorHolePainter(coords: coords, shots: shots),
            ),
          ),
        ),
      ),
    );
  }
}

class _VectorHolePainter extends CustomPainter {
  _VectorHolePainter({required this.coords, required this.shots});

  final HoleCoordinates coords;
  final List<ShotRecord> shots;

  Offset _project(double lat, double lon, Rect bounds) {
    final lats = [coords.teeLat, coords.greenLat];
    final lons = [coords.teeLon, coords.greenLon];
    for (final shot in shots) {
      final lat = shot.endLat;
      final lon = shot.endLon;
      if (lat != null && lon != null) {
        lats.add(lat);
        lons.add(lon);
      }
    }
    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLon = lons.reduce((a, b) => a < b ? a : b);
    final maxLon = lons.reduce((a, b) => a > b ? a : b);
    final latSpan = (maxLat - minLat).abs() < 1e-9 ? 1e-9 : (maxLat - minLat);
    final lonSpan = (maxLon - minLon).abs() < 1e-9 ? 1e-9 : (maxLon - minLon);
    final x = bounds.left + (lon - minLon) / lonSpan * bounds.width;
    final y = bounds.bottom - (lat - minLat) / latSpan * bounds.height;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
  final inset = rect.deflate(16);
    final tee = _project(coords.teeLat, coords.teeLon, inset);
    final green = _project(coords.greenLat, coords.greenLon, inset);

    final linePaint = Paint()
      ..color = const Color(0xFF2E6B3E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(tee, green, linePaint);

    final teePaint = Paint()..color = const Color(0xFF1565C0);
    canvas.drawCircle(tee, 6, teePaint);

    final flagPaint = Paint()..color = const Color(0xFFC62828);
    canvas.drawCircle(green, 7, flagPaint);

    final shotPaint = Paint()..color = const Color(0xFF37474F);
    for (final shot in shots) {
      final lat = shot.endLat;
      final lon = shot.endLon;
      if (lat == null || lon == null) continue;
      final p = _project(lat, lon, inset);
      canvas.drawCircle(p, 5, shotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VectorHolePainter oldDelegate) {
    return oldDelegate.coords != coords || oldDelegate.shots != shots;
  }
}