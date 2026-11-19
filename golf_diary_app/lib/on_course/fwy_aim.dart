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
        markerId = null;

  const FwyAimTarget.custom(Offset this.local)
      : kind = FwyAimKind.custom,
        markerId = null;

  const FwyAimTarget.marker(Offset this.local, String this.markerId)
      : kind = FwyAimKind.marker;

  final FwyAimKind kind;

  /// Hole-local metres; null for [FwyAimKind.pin].
  final Offset? local;
  final String? markerId;
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
