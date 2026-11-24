import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Busy indicator: a ball rolls along the green and drops into the cup.
class GolfPuttLoader extends StatefulWidget {
  const GolfPuttLoader({
    super.key,
    this.width = 56,
    this.height = 20,
    this.period = const Duration(milliseconds: 1600),
  });

  final double width;
  final double height;
  final Duration period;

  @override
  State<GolfPuttLoader> createState() => _GolfPuttLoaderState();
}

class _GolfPuttLoaderState extends State<GolfPuttLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.period)..repeat();

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
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: CustomPaint(
            painter: _PuttPainter(
              progress: _controller,
              turf: scheme.primary,
              cup: scheme.onSurface,
              ball: scheme.surface,
              outline: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _PuttPainter extends CustomPainter {
  _PuttPainter({
    required this.progress,
    required this.turf,
    required this.cup,
    required this.ball,
    required this.outline,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color turf;
  final Color cup;
  final Color ball;
  final Color outline;

  static const _rollEnd = 0.68;
  static const _dropEnd = 0.82;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final radius = math.min(size.height * 0.22, size.width * 0.1);
    final groundY = size.height * 0.72;
    final cupWidth = radius * 2.8;
    final cupCenterX = size.width - cupWidth / 2 - 1;
    final startX = radius + 1;

    canvas.drawLine(
      Offset(0, groundY),
      Offset(cupCenterX - cupWidth / 2, groundY),
      Paint()
        ..color = turf
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    final cupRect = Rect.fromCenter(
      center: Offset(cupCenterX, groundY),
      width: cupWidth,
      height: radius * 1.1,
    );
    canvas.drawOval(cupRect, Paint()..color = cup);

    final flagTop = Offset(cupCenterX, groundY - size.height * 0.68);
    canvas.drawLine(
      Offset(cupCenterX, groundY),
      flagTop,
      Paint()
        ..color = outline
        ..strokeWidth = 1,
    );
    canvas.drawPath(
      Path()
        ..moveTo(flagTop.dx, flagTop.dy)
        ..lineTo(flagTop.dx - radius * 1.8, flagTop.dy + radius * 0.7)
        ..lineTo(flagTop.dx, flagTop.dy + radius * 1.4)
        ..close(),
      Paint()..color = turf,
    );

    if (t > _dropEnd) return;

    double x;
    double y = groundY - radius;
    if (t <= _rollEnd) {
      final eased = Curves.easeOutCubic.transform(t / _rollEnd);
      x = startX + (cupCenterX - startX) * eased;
    } else {
      final drop = Curves.easeIn.transform((t - _rollEnd) / (_dropEnd - _rollEnd));
      x = cupCenterX;
      y += radius * 2.2 * drop;
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, groundY + 0.5));
    final center = Offset(x, y);
    canvas.drawCircle(center, radius, Paint()..color = ball);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final spin = (x - startX) / radius;
    canvas.drawCircle(
      center + Offset(math.cos(spin), math.sin(spin)) * radius * 0.45,
      radius * 0.18,
      Paint()..color = outline,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PuttPainter oldDelegate) =>
      oldDelegate.turf != turf ||
      oldDelegate.cup != cup ||
      oldDelegate.ball != ball ||
      oldDelegate.outline != outline;
}
