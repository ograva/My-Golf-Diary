import 'dart:math' as math;
import 'dart:ui';

import '../models/golf_models.dart';
import 'hole_projection.dart';
import 'on_course_aim.dart';

/// Where the next shot is aimed (FWY Aim mode, CRSE-039 shell).
enum FwyAimKind { pin, custom, marker }

class FwyAimTarget {
  const FwyAimTarget.pin()
      : kind = FwyAimKind.pin,
        local = null,
        markerId = null,
        explicit = false;

  const FwyAimTarget.custom(Offset this.local, {this.explicit = true})
      : kind = FwyAimKind.custom,
        markerId = null;

  const FwyAimTarget.marker(
    Offset this.local,
    String this.markerId, {
    this.explicit = false,
  }) : kind = FwyAimKind.marker;

  final FwyAimKind kind;

  /// Hole-local metres; null for [FwyAimKind.pin].
  final Offset? local;
  final String? markerId;

  /// True when the golfer tapped this target. A pre-selected marker is not explicit.
  final bool explicit;
}

/// Sweep of the FWY carry arc, centred on the aim direction.
const kCarryArcDegrees = 30.0;

/// Where the carry arc faces, in hole-local metres.
///
/// A point the golfer set ([golferAim]) wins. Otherwise the arc faces the
/// hole when the hole is the aim target, or the nearest marker that lies
/// toward the hole when it is not. With no such marker, it still faces the
/// hole so the mark stays an arc.
Offset carryArcFocus({
  required Offset ball,
  required Offset hole,
  required bool holeIsAimTarget,
  Offset? golferAim,
  List<Offset> markers = const [],
}) {
  if (golferAim != null) return golferAim;
  if (!holeIsAimTarget) {
    final marker = nearestMarkerTowardHole(
      ball: ball,
      hole: hole,
      markers: markers,
    );
    if (marker != null) return marker;
  }
  return hole;
}

/// Closest marker in front of [ball] and within 45° of the line to [hole].
Offset? nearestMarkerTowardHole({
  required Offset ball,
  required Offset hole,
  required List<Offset> markers,
}) {
  final toHole = hole - ball;
  final holeDist = toHole.distance;
  if (holeDist < 1e-6 || markers.isEmpty) return null;
  final forward = toHole / holeDist;
  const minCos = 0.70710678118; // cos(45°)
  Offset? best;
  var bestDist = double.infinity;
  for (final marker in markers) {
    final toMarker = marker - ball;
    final dist = toMarker.distance;
    if (dist < 1e-6) continue;
    final along = toMarker.dx * forward.dx + toMarker.dy * forward.dy;
    if (along <= 0 || along / dist < minCos) continue;
    if (dist < bestDist) {
      bestDist = dist;
      best = marker;
    }
  }
  return best;
}

/// Canvas arc centred on the screen direction from [ball] to [focus].
///
/// Flutter measures [start] clockwise from the +x axis. A zero-length
/// direction faces up the screen, which is up the hole in the tee-bottom frame.
({double start, double sweep}) carryArcAngles({
  required Offset ball,
  required Offset focus,
}) {
  final sweep = kCarryArcDegrees * math.pi / 180;
  final delta = focus - ball;
  final center =
      delta.distance < 1e-6 ? -math.pi / 2 : math.atan2(delta.dy, delta.dx);
  return (start: center - sweep / 2, sweep: sweep);
}

const _categoryDefaultYards = {
  'wood': 210.0,
  'hybrid': 180.0,
  'iron': 150.0,
  'wedge': 100.0,
  'putter': 10.0,
};

/// Typical carry for the aim ring: the median of logged range averages,
/// else the bag average, else a per-category default.
double typicalClubYards(Club club, List<double> trend) {
  final logged = trend.where((y) => y > 0).toList()..sort();
  if (logged.isNotEmpty) {
    final mid = logged.length ~/ 2;
    return logged.length.isOdd
        ? logged[mid]
        : (logged[mid - 1] + logged[mid]) / 2;
  }
  if (club.avgDistance > 0) return club.avgDistance;
  return _categoryDefaultYards[club.category] ?? 150;
}

/// The point where the ray from [ball] through [tap] meets the ring.
Offset snapToRing(
    {required Offset ball, required Offset tap, required double radius}) {
  final d = tap - ball;
  final len = d.distance;
  if (len < 1e-6) return ball + Offset(0, radius);
  return ball + d * (radius / len);
}

/// L/C/R for older clients: the side of the ball→green line the target is on.
String deriveAimDirection({
  required Offset ball,
  required Offset green,
  required Offset target,
  double centerDegrees = 5,
}) {
  final toGreen = green - ball;
  final toTarget = target - ball;
  if (toGreen.distance < 1e-6 || toTarget.distance < 1e-6) {
    return kOnCourseAimCenter;
  }
  final cross = toGreen.dx * toTarget.dy - toGreen.dy * toTarget.dx;
  final dot = toGreen.dx * toTarget.dx + toGreen.dy * toTarget.dy;
  final angle = math.atan2(cross, dot) * 180 / math.pi;
  if (angle.abs() <= centerDegrees) return kOnCourseAimCenter;
  // Local +y is up the hole and +x is the golfer's right, so a positive
  // cross product means the target is to the left.
  return angle > 0 ? kOnCourseAimLeft : kOnCourseAimRight;
}

/// Straight stand-in hole sized from par (no survey or pack for this hole).
class StandinHole {
  const StandinHole(this.lengthYards);

  factory StandinHole.forPar(int par) => StandinHole(switch (par) {
        <= 3 => 165,
        4 => 380,
        _ => 510,
      });

  final int lengthYards;

  double get lengthMeters => lengthYards * kMetersPerYard;

  Offset get tee => Offset.zero;

  Offset get green => Offset(0, lengthMeters);

  /// Balls placed along the centreline by cumulative distance travelled.
  List<Offset> strokePositions(List<ShotRecord> shots) {
    final out = <Offset>[];
    var along = 0.0;
    final sorted = [...shots]
      ..sort((a, b) => a.strokeNumber.compareTo(b.strokeNumber));
    for (final shot in sorted) {
      out.add(Offset(0, math.min(along, lengthMeters)));
      along += shot.distanceYards * kMetersPerYard;
    }
    return out;
  }

  int remainingYards(List<ShotRecord> shots) {
    final travelled =
        shots.fold<double>(0, (sum, shot) => sum + shot.distanceYards);
    return math.max(0, (lengthYards - travelled).round());
  }
}
