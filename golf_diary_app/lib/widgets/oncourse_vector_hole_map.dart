import 'package:flutter/material.dart';

import '../data/ph_golf_hole_coords.dart';
import '../models/golf_models.dart';
import '../on_course/hole_map_geo.dart';
import '../services/pin_distance.dart';
import 'hole_map_marker_painter.dart';

/// Offline vector tee→green schematic with shot dots (Architecture §5.5).
class OncourseVectorHoleMap extends StatelessWidget {
  const OncourseVectorHoleMap({
    super.key,
    required this.coords,
    required this.shots,
    this.player,
  });

  final HoleCoordinates coords;
  final List<ShotRecord> shots;
  final PinFix? player;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bounds = boundsForHole(coords, shots: shots, player: player);

    return Semantics(
      label: 'Hole line from tee to green',
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
            child: CustomPaint(
              key: const ValueKey('oncourse-map-vector'),
              painter: HoleMapMarkerPainter(
                coords: coords,
                shots: shots,
                bounds: bounds,
                player: player,
                colorScheme: scheme,
              ),
            ),
          ),
        ),
      ),
    );
  }
}