import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../on_course/fwy_aim.dart';
import '../on_course/hole_projection.dart';
import '../services/hole_map_pack_source.dart';
import '../theme/app_theme.dart';
import 'hole_map_image.dart';

/// Suggested aim point drawn as ■ (CRSE-041 manifest marker).
class FwyMapMarker {
  const FwyMapMarker({required this.id, required this.local});

  final String id;
  final Offset local;
}

/// Everything drawn on the FWY map, in hole-local metres (tee at the bottom).
class FwyHoleScene {
  const FwyHoleScene({
    required this.tee,
    required this.green,
    this.strokes = const [],
    this.segmentYards = const [],
    this.player,
    this.markers = const [],
    this.ball,
    this.aimTarget,
    this.aimRingMeters,
    this.aimRingFaint = false,
    this.aimArcFocus,
    this.manualPin,
    this.manualPinStale = false,
  });

  final Offset tee;
  final Offset green;

  /// Ball position at the start of each recorded stroke, stroke 1 first.
  final List<Offset> strokes;

  /// Yards for the segment that ends at `strokes[i + 1]`, or null.
  final List<int?> segmentYards;
  final Offset? player;
  final List<FwyMapMarker> markers;

  /// Ball the next shot is played from (aim ring and aim line origin).
  final Offset? ball;
  final Offset? aimTarget;
  final double? aimRingMeters;
  final bool aimRingFaint;

  /// Hole-local point the carry arc faces. Null aims the arc up the hole.
  final Offset? aimArcFocus;
  final Offset? manualPin;
  final bool manualPinStale;
}

/// Full-bleed FWY background: a pack image when one is loaded, otherwise a
/// plain drawn hole. Taps are reported in hole-local metres.
class FwyHoleMap extends StatelessWidget {
  const FwyHoleMap({
    super.key,
    required this.scene,
    required this.clearInsets,
    this.pack,
    this.onTapLocal,
    this.ignoreLeft = 24,
    this.ignoreRight = 16,
  });

  final FwyHoleScene scene;

  /// The part of the screen covered by overlays, the rail, and the gutters;
  /// the hole is framed in what is left.
  final EdgeInsets clearInsets;
  final HoleMapPack? pack;

  /// [pixelsPerMeter] lets the caller compare distances in screen space.
  final void Function(Offset local, double pixelsPerMeter)? onTapLocal;

  /// Taps in the system-gesture inset and the diary swipe strip are ignored.
  final double ignoreLeft;
  final double ignoreRight;

  static const markerSize = 22.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      final free = clearInsets.deflateRect(Offset.zero & size);
      final viewport =
          HoleViewport.fit(tee: scene.tee, green: scene.green, free: free);
      final pack = this.pack;
      final frame = pack?.entry.frame;
      final imageRect = pack == null || frame == null
          ? null
          : Rect.fromPoints(
              viewport.toScreen(Offset(
                -pack.entry.widthPx * frame.metersPerPixel / 2,
                pack.entry.heightPx * frame.metersPerPixel / 2,
              )),
              viewport.toScreen(Offset(
                pack.entry.widthPx * frame.metersPerPixel / 2,
                -pack.entry.heightPx * frame.metersPerPixel / 2,
              )),
            );

      Widget marker(String key, Offset local, Widget child) {
        final at = viewport.toScreen(local);
        return Positioned(
          left: at.dx - markerSize / 2,
          top: at.dy - markerSize / 2,
          width: markerSize,
          height: markerSize,
          child: IgnorePointer(
              child: KeyedSubtree(key: ValueKey(key), child: child)),
        );
      }

      return GestureDetector(
        key: const ValueKey('oncourse-map-tap-layer'),
        behavior: HitTestBehavior.opaque,
        onTapUp: onTapLocal == null
            ? null
            : (details) {
                final p = details.localPosition;
                if (p.dx < ignoreLeft || p.dx > size.width - ignoreRight) {
                  return;
                }
                onTapLocal!(viewport.toLocal(p), viewport.pixelsPerMeter);
              },
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: pack == null
                    ? GolfPalette.mapRough
                    : GolfPalette.mapOutside,
              ),
            ),
            if (pack != null && frame != null)
              Positioned.fromRect(
                rect: imageRect!,
                child: Image(
                  image: holeMapImageProvider(
                    pack.imageBytes,
                    decodeWidth: holeMapDecodeWidth(
                      imageRect.width,
                      MediaQuery.devicePixelRatioOf(context),
                      pack.entry.widthPx,
                    ),
                  ),
                  key: const ValueKey('oncourse-map-pack-image'),
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: GolfPalette.mapRough),
                ),
              ),
            Positioned.fill(
              child: CustomPaint(
                painter: _FwyScenePainter(
                  scene: scene,
                  viewport: viewport,
                  drawHole: pack == null,
                  textDirection: Directionality.of(context),
                ),
              ),
            ),
            marker('oncourse-tee-marker', scene.tee, const SizedBox.shrink()),
            for (final m in scene.markers)
              marker('oncourse-map-marker-${m.id}', m.local,
                  const _SquareMarker()),
            if (scene.aimTarget != null)
              marker('oncourse-aim-target', scene.aimTarget!,
                  const _AimTargetMarker()),
            if (scene.manualPin != null)
              marker('oncourse-manual-pin', scene.manualPin!,
                  _ManualPinMarker(stale: scene.manualPinStale)),
          ],
        ),
      );
    });
  }
}

class _SquareMarker extends StatelessWidget {
  const _SquareMarker();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: GolfPalette.mapMarker,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}

class _AimTargetMarker extends StatelessWidget {
  const _AimTargetMarker();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.adjust, color: Colors.white, size: 22, shadows: [
      Shadow(blurRadius: 3, color: Colors.black),
    ]);
  }
}

class _ManualPinMarker extends StatelessWidget {
  const _ManualPinMarker({required this.stale});

  final bool stale;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: stale ? 'Ball pin, move to your ball' : 'Ball pin',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: stale ? Colors.transparent : primary,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black54)],
        ),
        child: const Icon(Icons.add, size: 16, color: Colors.white),
      ),
    );
  }
}

class _FwyScenePainter extends CustomPainter {
  _FwyScenePainter({
    required this.scene,
    required this.viewport,
    required this.drawHole,
    required this.textDirection,
  });

  final FwyHoleScene scene;
  final HoleViewport viewport;
  final bool drawHole;
  final TextDirection textDirection;

  Offset _s(Offset local) => viewport.toScreen(local);

  @override
  void paint(Canvas canvas, Size size) {
    if (drawHole) _paintHole(canvas);
    _paintOverlay(canvas);
  }

  void _paintHole(Canvas canvas) {
    final ppm = viewport.pixelsPerMeter;
    final tee = _s(scene.tee);
    final green = _s(scene.green);
    if ((green - tee).distance > 80) {
      canvas.drawLine(
        Offset.lerp(tee, green, 0.18)!,
        Offset.lerp(tee, green, 0.9)!,
        Paint()
          ..color = GolfPalette.mapFairway
          ..strokeWidth = math.max(18, 32 * ppm)
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(
        green, math.max(12, 14 * ppm), Paint()..color = GolfPalette.mapGreen);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: tee,
            width: math.max(14, 12 * ppm),
            height: math.max(10, 8 * ppm)),
        const Radius.circular(3),
      ),
      Paint()..color = GolfPalette.mapTee,
    );
  }

  void _paintOverlay(Canvas canvas) {
    final tee = _s(scene.tee);
    final green = _s(scene.green);
    final halo = Paint()
      ..color = Colors.black54
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke;
    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final path = [
      for (final p in scene.strokes) _s(p),
      if (scene.player != null) _s(scene.player!),
    ];
    if (path.length < 2) {
      _dashed(canvas, tee, green, line);
    } else {
      for (var i = 0; i < path.length - 1; i++) {
        canvas.drawLine(path[i], path[i + 1], halo);
        canvas.drawLine(path[i], path[i + 1], line);
      }
    }

    for (var i = 0; i < scene.segmentYards.length; i++) {
      final yards = scene.segmentYards[i];
      if (yards == null || i + 1 >= scene.strokes.length) continue;
      final mid =
          Offset.lerp(_s(scene.strokes[i]), _s(scene.strokes[i + 1]), 0.5)!;
      _text(canvas, '${yards}y', mid + const Offset(10, 0),
          fontSize: 13, centered: false);
    }

    final ball = scene.ball;
    if (ball != null && scene.aimRingMeters != null) {
      final focus = scene.aimArcFocus ?? ball + const Offset(0, 1);
      final arc = carryArcAngles(ball: _s(ball), focus: _s(focus));
      canvas.drawArc(
        Rect.fromCircle(
          center: _s(ball),
          radius: scene.aimRingMeters! * viewport.pixelsPerMeter,
        ),
        arc.start,
        arc.sweep,
        false,
        Paint()
          ..color =
              Colors.white.withValues(alpha: scene.aimRingFaint ? 0.35 : 0.9)
          ..strokeWidth = scene.aimRingFaint ? 1.2 : 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
    if (ball != null && scene.aimTarget != null) {
      _dashed(canvas, _s(ball), _s(scene.aimTarget!), line);
    }

    // Pin flag on the green.
    final top = green - const Offset(0, 22);
    canvas.drawLine(green, top, halo);
    canvas.drawLine(green, top, line);
    canvas.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..lineTo(top.dx + 12, top.dy + 5)
        ..lineTo(top.dx, top.dy + 10)
        ..close(),
      Paint()..color = GolfPalette.negative,
    );
    canvas.drawCircle(green, 3, Paint()..color = Colors.white);

    // Tee triangle.
    final tri = Path()
      ..moveTo(tee.dx, tee.dy - 8)
      ..lineTo(tee.dx + 7, tee.dy + 5)
      ..lineTo(tee.dx - 7, tee.dy + 5)
      ..close();
    canvas.drawPath(tri, Paint()..color = Colors.white);
    canvas.drawPath(
        tri,
        Paint()
          ..color = GolfPalette.fairwayDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    for (var i = 0; i < scene.strokes.length; i++) {
      final at = _s(scene.strokes[i]);
      canvas.drawCircle(at, 10, Paint()..color = Colors.white);
      canvas.drawCircle(at, 8.5, Paint()..color = GolfPalette.fairwayDark);
      _text(canvas, '${i + 1}', at, fontSize: 11, centered: true);
    }

    if (scene.player != null) {
      final you = _s(scene.player!);
      canvas.drawCircle(you, 10, Paint()..color = Colors.white);
      canvas.drawCircle(you, 7, Paint()..color = GolfPalette.fairwayGreen);
    }
  }

  static void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    if (total < 1) return;
    const dash = 6.0, gap = 5.0;
    final dir = (b - a) / total;
    var t = 0.0;
    while (t < total) {
      final end = math.min(t + dash, total);
      canvas.drawLine(a + dir * t, a + dir * end, paint);
      t = end + gap;
    }
  }

  void _text(Canvas canvas, String text, Offset at,
      {required double fontSize, required bool centered}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          shadows: centered
              ? null
              : const [Shadow(blurRadius: 2, color: Colors.black)],
        ),
      ),
      textDirection: textDirection,
    )..layout();
    tp.paint(canvas, at - Offset(centered ? tp.width / 2 : 0, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _FwyScenePainter old) =>
      old.scene != scene ||
      old.viewport.origin != viewport.origin ||
      old.viewport.pixelsPerMeter != viewport.pixelsPerMeter ||
      old.drawHole != drawHole;
}
