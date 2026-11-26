import 'dart:math' as math;

import '../models/golf_models.dart';

/// Shots starting this close to the green count as the approach.
const approachYards = 60;

/// Measured segments outside this range are treated as GPS noise.
const _minSegmentYards = 5;
const _maxSegmentYards = 400;

/// Make-rate ranges for paced putt distances, in yards (upper bound inclusive).
const puttRanges = [
  (label: '0-3', max: 3),
  (label: '4-7', max: 7),
  (label: '8-15', max: 15),
  (label: '16+', max: 999),
];

typedef GreenLookup = ({double lat, double lon})? Function(int holeNumber);

/// Summary for page 2 of the attested PDF, or null when the round has no
/// recorded on-course strokes. Penalties, mulligans, and gimmes come from
/// [scores]; strokes, clubs, and distances come from [shots].
Map<String, Object?>? buildStrokeStats({
  required List<ShotRecord> shots,
  required Map<String, Club> clubs,
  required List<RoundScore> scores,
  GreenLookup? greenFor,
}) {
  if (!shots.any((s) => !s.isHoled)) return null;

  final byHole = <int, List<ShotRecord>>{};
  for (final shot in shots) {
    byHole.putIfAbsent(shot.holeNumber, () => []).add(shot);
  }
  for (final list in byHole.values) {
    list.sort((a, b) => a.strokeNumber.compareTo(b.strokeNumber));
  }
  final scoreByHole = {for (final s in scores) s.holeNumber: s};
  final holeNumbers = {...byHole.keys, ...scoreByHole.keys}.toList()..sort();

  final clubAcc = <String, _ClubAcc>{};
  final usage = <String, int>{};
  Map<String, Object?>? longest;
  final holes = <Map<String, Object?>>[];
  var totStrokes = 0, totPutts = 0, totPen = 0, totMull = 0, totGimme = 0;
  var totToApproach = 0;
  var girHit = 0, girOf = 0, fwHit = 0, fwOf = 0, udMade = 0, udOf = 0;
  var threePutts = 0;
  final rangeMade = List.filled(puttRanges.length, 0);
  final rangeTries = List.filled(puttRanges.length, 0);
  final firstPutts = <int>[];

  for (final number in holeNumbers) {
    final list = byHole[number] ?? const <ShotRecord>[];
    final score = scoreByHole[number];
    final par = score?.par ?? 0;
    final gimme = score?.conceded == 1;
    final penalties = score?.penalties ?? 0;
    final mulligans = score?.mulligans ?? 0;
    totPen += penalties;
    totMull += mulligans;
    if (gimme) totGimme++;
    if (list.isEmpty) {
      holes.add({
        'hole': number,
        'par': par,
        'tracked': false,
        'penalties': penalties,
        'mulligans': mulligans,
        'gimme': gimme,
      });
      continue;
    }

    final green = greenFor?.call(number);
    bool isPutt(ShotRecord s) =>
        s.lieType == 'green' || clubs[s.clubId]?.category == 'putter' ||
        s.clubId == 'putter';
    final firstPutt = list.indexWhere(isPutt);
    final beforeGreen = firstPutt < 0 ? list.length : firstPutt;

    var approach = -1;
    var estimated = false;
    if (green != null) {
      for (var i = 0; i < beforeGreen; i++) {
        final s = list[i];
        if (!_hasGps(s.startLat, s.startLon)) continue;
        if (_yards(s.startLat, s.startLon, green.lat, green.lon) <=
            approachYards) {
          approach = i;
          break;
        }
      }
    }
    if (approach < 0 && beforeGreen > 0) {
      approach = beforeGreen - 1;
      estimated = green == null ||
          !list.take(beforeGreen).any((s) => _hasGps(s.startLat, s.startLon));
    }
    final toApproach = approach < 0 ? 0 : approach;

    final puttShots = list.where(isPutt).toList();
    int? firstPuttYds;
    if (puttShots.isNotEmpty && puttShots.first.puttDistanceYards != null) {
      firstPuttYds = puttShots.first.puttDistanceYards!.round();
      firstPutts.add(firstPuttYds);
    }
    // Every putt before the holed one missed; the holed putt was made.
    for (final putt in puttShots) {
      final yards = putt.puttDistanceYards;
      if (yards == null || yards <= 0) continue;
      final range = puttRanges.indexWhere((r) => yards.round() <= r.max);
      rangeTries[range]++;
      if (putt.isHoled) rangeMade[range]++;
    }

    var putts = puttShots.length;
    if (gimme && !list.any((s) => s.isHoled)) putts++;

    for (var i = 0; i < list.length; i++) {
      final s = list[i];
      if (isPutt(s)) continue;
      final club = clubs[s.clubId];
      final yards = _segmentYards(list, i);
      if (yards != null && (longest == null || yards > (longest['yds'] as int))) {
        longest = {'club': club?.name ?? 'Club ?', 'yds': yards, 'hole': number};
      }
      if (approach < 0 || i < approach) {
        usage[s.clubId] = (usage[s.clubId] ?? 0) + 1;
      }
      if (club == null || !_inClubTable(club)) continue;
      final acc = clubAcc.putIfAbsent(s.clubId, () => _ClubAcc(club));
      acc.count++;
      if (yards != null) acc.distances.add(yards);
    }

    final strokes = list.length + (gimme && !list.any((s) => s.isHoled) ? 1 : 0);
    totStrokes += strokes;
    totPutts += putts;
    totToApproach += toApproach;

    if (par > 0) {
      girOf++;
      final gir = beforeGreen <= par - 2;
      if (gir) {
        girHit++;
      } else if (approach >= 0) {
        udOf++;
        if (putts <= 1) udMade++;
      }
      if (par >= 4 && list.length >= 2) {
        fwOf++;
        if (list[1].lieType == 'fairway') fwHit++;
      }
    }
    if (putts >= 3) threePutts++;

    holes.add({
      'hole': number,
      'par': par,
      'tracked': true,
      'strokes': strokes,
      'gross': score == null ? strokes + penalties : score.strokes + penalties,
      'strokesToApproach': toApproach,
      'approachEstimated': estimated,
      'putts': putts,
      'firstPuttYds': firstPuttYds,
      'penalties': penalties,
      'mulligans': mulligans,
      'gimme': gimme,
      'sequence': [
        for (final s in list.take(toApproach)) _short(clubs[s.clubId]),
      ],
    });
  }

  final tableClubs = clubAcc.values.toList()
    ..sort((a, b) => compareClubs(a.club, b.club));
  String? mostUsedId;
  for (final entry in usage.entries) {
    final category = clubs[entry.key]?.category;
    if (category == 'putter') continue;
    if (mostUsedId == null || entry.value > usage[mostUsedId]!) {
      mostUsedId = entry.key;
    }
  }

  return {
    'version': 1,
    'clubs': [
      for (final acc in tableClubs)
        {
          'name': acc.club.name,
          'category': acc.club.category,
          'count': acc.count,
          'measured': acc.distances.length,
          'minYds': acc.distances.isEmpty ? null : acc.distances.reduce(math.min),
          'maxYds': acc.distances.isEmpty ? null : acc.distances.reduce(math.max),
          'avgYds': acc.distances.isEmpty
              ? null
              : (acc.distances.reduce((a, b) => a + b) / acc.distances.length)
                  .round(),
        },
    ],
    'holes': holes,
    'totals': {
      'strokes': totStrokes,
      'putts': totPutts,
      'penalties': totPen,
      'mulligans': totMull,
      'gimmes': totGimme,
      'strokesToApproach': totToApproach,
      'threePutts': threePutts,
    },
    'putting': {
      'firstPuttAvgYds': firstPutts.isEmpty
          ? null
          : firstPutts.reduce((a, b) => a + b) / firstPutts.length,
      'firstPuttHoles': firstPutts.length,
      'ranges': [
        for (var i = 0; i < puttRanges.length; i++)
          {
            'label': puttRanges[i].label,
            'made': rangeMade[i],
            'attempts': rangeTries[i],
          },
      ],
    },
    'highlights': {
      'longest': longest,
      'mostUsed': mostUsedId == null
          ? null
          : {
              'club': clubs[mostUsedId]?.name ?? 'Club ?',
              'count': usage[mostUsedId],
            },
    },
    'extras': {
      'girHit': girHit,
      'girOf': girOf,
      'fairwaysHit': fwHit,
      'fairwaysOf': fwOf,
      'upAndDownMade': udMade,
      'upAndDownOf': udOf,
      'threePutts': threePutts,
    },
  };
}

/// Woods, hybrids, and irons down to the 9-iron.
bool _inClubTable(Club club) {
  if (club.category == 'wood' || club.category == 'hybrid') return true;
  if (club.category != 'iron') return false;
  final name = club.name.toLowerCase();
  if (name.contains('wedge') || RegExp(r'\b[pgsl]w\b').hasMatch(name)) {
    return false;
  }
  final number = RegExp(r'(\d+)').firstMatch(name);
  return number == null || int.parse(number.group(1)!) <= 9;
}

String _short(Club? club) {
  if (club == null) return '?';
  final name = club.name.trim();
  return name.length <= 10 ? name : name.substring(0, 10);
}

int? _segmentYards(List<ShotRecord> list, int i) {
  final s = list[i];
  int? yards;
  if (s.distanceYards > 0) {
    yards = s.distanceYards.round();
  } else if (i + 1 < list.length) {
    final next = list[i + 1];
    if (_hasGps(s.startLat, s.startLon) &&
        _hasGps(next.startLat, next.startLon)) {
      yards = _yards(s.startLat, s.startLon, next.startLat, next.startLon);
    }
  }
  if (yards == null || yards < _minSegmentYards || yards > _maxSegmentYards) {
    return null;
  }
  return yards;
}

bool _hasGps(double lat, double lon) => lat != 0 || lon != 0;

int _yards(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final meters = 2 * r * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return (meters * 1.09361).round();
}

class _ClubAcc {
  _ClubAcc(this.club);
  final Club club;
  int count = 0;
  final List<int> distances = [];
}
