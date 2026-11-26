import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/models/golf_models.dart';
import 'package:golf_diary_app/services/attest_stroke_stats.dart';

Club _club(String id, String name, String category) =>
    Club(id: id, name: name, category: category);

final _clubs = {
  for (final c in [
    _club('d', 'Driver', 'wood'),
    _club('h4', '4 Hybrid', 'hybrid'),
    _club('i7', '7 Iron', 'iron'),
    _club('i9', '9 Iron', 'iron'),
    _club('pw', 'Pitching Wedge', 'wedge'),
    _club('pt', 'Putter', 'putter'),
  ])
    c.id: c,
};

// Green at (14.0, 121.0); 0.0001 deg latitude is about 12 yards.
const _green = (lat: 14.0, lon: 121.0);
double _lat(int yardsFromGreen) => 14.0 - yardsFromGreen / 12.16 * 0.0001;

ShotRecord _shot(int hole, int n, String club,
        {String lie = 'fairway',
        double? lat,
        double distance = 0,
        String notes = ''}) =>
    ShotRecord(
      id: 'h${hole}s$n',
      roundId: 'r',
      holeNumber: hole,
      strokeNumber: n,
      clubId: club,
      lieType: lie,
      startLat: lat ?? 0,
      startLon: lat == null ? 0 : 121.0,
      distanceYards: distance,
      notes: notes,
      timestamp: n,
    );

RoundScore _score(int hole, int par,
        {int strokes = 0,
        int penalties = 0,
        int mulligans = 0,
        int conceded = 0}) =>
    RoundScore(
      id: 'r_h$hole',
      roundId: 'r',
      courseName: 'C',
      holeNumber: hole,
      par: par,
      strokes: strokes,
      penalties: penalties,
      mulligans: mulligans,
      conceded: conceded,
    );

void main() {
  test('no shots or only auto holed putts gives no stats', () {
    expect(
      buildStrokeStats(shots: [], clubs: _clubs, scores: [_score(1, 4)]),
      isNull,
    );
    expect(
      buildStrokeStats(
        shots: [_shot(1, 1, 'pt', lie: 'green', notes: kHoledShotNote)],
        clubs: _clubs,
        scores: [_score(1, 4)],
      ),
      isNull,
    );
  });

  group('par 4 with GPS', () {
    late Map<String, Object?> stats;
    setUp(() {
      stats = buildStrokeStats(
        shots: [
          _shot(1, 1, 'd', lie: 'tee', lat: _lat(380)),
          _shot(1, 2, 'i7', lat: _lat(150)),
          _shot(1, 3, 'pw', lie: 'rough', lat: _lat(40)),
          _shot(1, 4, 'pt', lie: 'green', lat: _lat(5)),
          _shot(1, 5, 'pt', lie: 'green', notes: kHoledShotNote),
        ],
        clubs: _clubs,
        scores: [_score(1, 4, strokes: 5, penalties: 1, mulligans: 2)],
        greenFor: (_) => _green,
      )!;
    });

    test('clubs table keeps woods and irons with GPS distances', () {
      final clubs = stats['clubs'] as List;
      expect(clubs.map((c) => (c as Map)['name']), ['Driver', '7 Iron']);
      final driver = clubs.first as Map;
      expect(driver['count'], 1);
      expect((driver['avgYds'] as int), closeTo(230, 3));
    });

    test('approach is first shot inside 60 yards; penalties excluded', () {
      final hole = (stats['holes'] as List).single as Map;
      expect(hole['strokesToApproach'], 2);
      expect(hole['approachEstimated'], false);
      expect(hole['sequence'], ['Driver', '7 Iron']);
      expect(hole['putts'], 2);
      expect(hole['penalties'], 1);
      expect(hole['mulligans'], 2);
      expect(hole['gross'], 6);
    });

    test('highlights and extras', () {
      final h = stats['highlights'] as Map;
      expect((h['longest'] as Map)['club'], 'Driver');
      expect((h['mostUsed'] as Map)['club'], isNot('Pitching Wedge'));
      final e = stats['extras'] as Map;
      expect(e['girHit'], 0);
      expect(e['fairwaysHit'], 1);
      expect(e['fairwaysOf'], 1);
      expect(e['upAndDownOf'], 1);
      expect(e['upAndDownMade'], 0);
    });
  });

  test('gimme counts one putt and no GPS falls back to estimated approach', () {
    final stats = buildStrokeStats(
      shots: [
        _shot(2, 1, 'i9', lie: 'tee', distance: 140),
        _shot(2, 2, 'pt', lie: 'green'),
      ],
      clubs: _clubs,
      scores: [_score(2, 3, strokes: 6, conceded: 1)],
    )!;
    final hole = (stats['holes'] as List).single as Map;
    expect(hole['gimme'], true);
    expect(hole['putts'], 2);
    expect(hole['strokesToApproach'], 0);
    expect(hole['approachEstimated'], true);
    final totals = stats['totals'] as Map;
    expect(totals['gimmes'], 1);
    final e = stats['extras'] as Map;
    expect(e['girHit'], 1);
    final clubs = stats['clubs'] as List;
    expect((clubs.single as Map)['maxYds'], 140);
  });

  test('three putts, untracked holes, and noise filter', () {
    final stats = buildStrokeStats(
      shots: [
        _shot(3, 1, 'h4', lie: 'tee', distance: 900),
        _shot(3, 2, 'pt', lie: 'green'),
        _shot(3, 3, 'pt', lie: 'green'),
        _shot(3, 4, 'pt', lie: 'green', notes: kHoledShotNote),
      ],
      clubs: _clubs,
      scores: [_score(3, 3), _score(4, 4, penalties: 2)],
    )!;
    expect((stats['totals'] as Map)['threePutts'], 1);
    expect((stats['totals'] as Map)['penalties'], 2);
    final holes = stats['holes'] as List;
    expect((holes[1] as Map)['tracked'], false);
    expect(((stats['clubs'] as List).single as Map)['minYds'], isNull);
  });

  test('paced putt distances give first-putt and make rate by range', () {
    ShotRecord putt(int hole, int n, double? yds, {bool holed = false}) =>
        ShotRecord(
          id: 'p$hole$n',
          roundId: 'r',
          holeNumber: hole,
          strokeNumber: n,
          clubId: 'pt',
          lieType: 'green',
          startLat: 0,
          startLon: 0,
          puttDistanceYards: yds,
          notes: holed ? kHoledShotNote : '',
          timestamp: n,
        );
    final stats = buildStrokeStats(
      shots: [
        _shot(1, 1, 'i7', lie: 'tee'),
        putt(1, 2, 10),
        putt(1, 3, 2, holed: true),
        _shot(2, 1, 'i9', lie: 'tee'),
        putt(2, 2, 5, holed: true),
        _shot(3, 1, 'i9', lie: 'tee'),
        putt(3, 2, null, holed: true),
      ],
      clubs: _clubs,
      scores: [_score(1, 3), _score(2, 3), _score(3, 3)],
    )!;
    final holes = stats['holes'] as List;
    expect((holes[0] as Map)['firstPuttYds'], 10);
    expect((holes[2] as Map)['firstPuttYds'], isNull);
    final putting = stats['putting'] as Map;
    expect(putting['firstPuttAvgYds'], 7.5);
    expect(putting['firstPuttHoles'], 2);
    final ranges = {
      for (final r in putting['ranges'] as List)
        (r as Map)['label']: '${r['made']}/${r['attempts']}',
    };
    expect(ranges, {'0-3': '1/1', '4-7': '1/1', '8-15': '0/1', '16+': '0/0'});
  });
}
