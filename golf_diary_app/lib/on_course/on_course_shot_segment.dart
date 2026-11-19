import 'package:geolocator/geolocator.dart';

import '../models/golf_models.dart';

/// Whole yards traveled on the segment ending at [shot], when the prior stroke
/// and [shot] both have ball positions (CRSE-032).
int? segmentYardsEndingAt(List<ShotRecord> shots, ShotRecord shot) {
  if (shot.strokeNumber <= 1) return null;

  ShotRecord? prior;
  for (final s in shots) {
    if (s.strokeNumber == shot.strokeNumber - 1) {
      prior = s;
      break;
    }
  }
  if (prior == null) return null;

  if (prior.distanceYards > 0) {
    return prior.distanceYards.round();
  }

  final hasPriorStart = prior.startLat != 0 || prior.startLon != 0;
  final hasCurrentStart = shot.startLat != 0 || shot.startLon != 0;
  if (!hasPriorStart || !hasCurrentStart) return null;

  final meters = Geolocator.distanceBetween(
    prior.startLat,
    prior.startLon,
    shot.startLat,
    shot.startLon,
  );
  return (meters * 1.09361).round();
}

/// Label for a shot list row in Course vs Simulator mode. Empty when Course
/// stroke 1 has no prior segment yet.
String shotDistanceLabel({
  required List<ShotRecord> shots,
  required ShotRecord shot,
  required bool simulator,
}) {
  if (simulator) {
    if (shot.distanceYards > 0) {
      return '${shot.distanceYards.round()} yds';
    }
    return 'Distance pending';
  }

  if (shot.strokeNumber == 1) {
    return '';
  }

  final segment = segmentYardsEndingAt(shots, shot);
  if (segment != null) {
    return '$segment yds';
  }
  return 'Distance pending';
}