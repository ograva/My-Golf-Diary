import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golf_models.dart';
import 'package:golf_diary_app/on_course/on_course_shot_segment.dart';

ShotRecord _shot({
  required int stroke,
  double lat = 37.0,
  double lon = -122.0,
  double distanceYards = 0,
}) {
  return ShotRecord(
    id: 's$stroke',
    roundId: 'r1',
    holeNumber: 1,
    strokeNumber: stroke,
    clubId: 'driver',
    lieType: 'tee',
    startLat: lat,
    startLon: lon,
    distanceYards: distanceYards,
    timestamp: stroke,
  );
}

void main() {
  test('segment yards uses stored distance on prior stroke', () {
    final shots = [
      _shot(stroke: 1, distanceYards: 156.2),
      _shot(stroke: 2, lat: 37.002, lon: -122.0),
    ];
    expect(segmentYardsEndingAt(shots, shots[1]), 156);
    expect(shotDistanceLabel(shots: shots, shot: shots[1], simulator: false),
        '156 yds');
  });

  test('stroke 1 course row omits distance line', () {
    final shots = [_shot(stroke: 1)];
    expect(
        shotDistanceLabel(shots: shots, shot: shots[0], simulator: false), '');
  });

  test('simulator uses typed carry on each row', () {
    final shots = [_shot(stroke: 1, distanceYards: 240)];
    expect(shotDistanceLabel(shots: shots, shot: shots[0], simulator: true),
        '240 yds');
  });
}
