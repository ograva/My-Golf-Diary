import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Busy indicator: a golf ball that hops on a tee while it spins.
class GolfBallLoader extends StatefulWidget {
  const GolfBallLoader({super.key, this.size = 24});

  final double size;

  @override
  State<GolfBallLoader> createState() => _GolfBallLoaderState();
}

class _GolfBallLoaderState extends State<GolfBallLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Waiting for a reply',
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _GolfBallPainter(
              t: _controller.value,
              outline: scheme.outline,
              tee: scheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class _GolfBallPainter extends CustomPainter {
  _GolfBallPainter({
    required this.t,
    required this.outline,
    required this.tee,
  });

  final double t;
  final Color outline;
  final Color tee;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final radius = w * 0.3;
    final teeTop = w * 0.78;

    final teePaint = Paint()..color = tee;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.46, teeTop, w * 0.08, w * 0.2),
        Radius.circular(w * 0.03),
      ),
      teePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.34, teeTop - w * 0.02, w * 0.32, w * 0.05),
        Radius.circular(w * 0.03),
      ),
      teePaint,
    );

    final hop = math.sin(t * math.pi);
    final squash = hop < 0.15 ? 1 - (0.15 - hop) * 0.8 : 1.0;
    final restY = teeTop - radius;
    final centre = Offset(w / 2, restY - hop * w * 0.18);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, teeTop + w * 0.01),
        width: radius * (1.6 - hop * 0.8),
        height: w * 0.05,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.15 * (1 - hop)),
    );

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(1 / squash, squash);
    final ball = Rect.fromCircle(center: Offset.zero, radius: radius);
    canvas.drawCircle(Offset.zero, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset.zero,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, w * 0.04)
        ..color = outline,
    );
    canvas.clipPath(Path()..addOval(ball.deflate(w * 0.02)));

    canvas.rotate(t * 2 * math.pi);
    final dimple = Paint()..color = outline.withValues(alpha: 0.55);
    for (var ring = 0; ring < 2; ring++) {
      final ringRadius = radius * (ring == 0 ? 0.35 : 0.72);
      final count = ring == 0 ? 4 : 8;
      for (var i = 0; i < count; i++) {
        final a = i * 2 * math.pi / count + ring * 0.4;
        canvas.drawCircle(
          Offset(math.cos(a) * ringRadius, math.sin(a) * ringRadius),
          radius * 0.11,
          dimple,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GolfBallPainter old) =>
      old.t != t || old.outline != outline || old.tee != tee;
}
