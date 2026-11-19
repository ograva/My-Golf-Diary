import 'package:flutter/material.dart';

import '../data/ph_golf_hole_coords.dart';
import '../models/course_map_manifest.dart';
import '../models/golf_models.dart';
import '../on_course/hole_map_geo.dart';
import '../services/pin_distance.dart';
import 'hole_map_marker_painter.dart';

/// Cached satellite still + marker overlay (no Maps SDK).
class OncourseSatelliteHoleMap extends StatelessWidget {
  const OncourseSatelliteHoleMap({
    super.key,
    required this.frame,
    required this.coords,
    required this.shots,
    this.player,
  });

  final HoleMapFrame frame;
  final HoleCoordinates coords;
  final List<ShotRecord> shots;
  final PinFix? player;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bounds = HoleMapBounds.fromManifest(frame.entry);
    final image = frame.imageFile;

    return Semantics(
      label: 'Satellite hole map',
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image != null && image.existsSync())
                  Image.file(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        ColoredBox(color: scheme.surfaceContainerHigh),
                  )
                else
                  ColoredBox(color: scheme.surfaceContainerHigh),
                CustomPaint(
                  painter: HoleMapMarkerPainter(
                    coords: coords,
                    shots: shots,
                    bounds: bounds,
                    player: player,
                    colorScheme: scheme,
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 6,
                  child: Text(
                    'Google',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.85),
                          shadows: const [
                            Shadow(blurRadius: 2, color: Colors.black26),
                          ],
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}