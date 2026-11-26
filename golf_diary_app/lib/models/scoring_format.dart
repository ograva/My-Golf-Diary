/// Offline scoring formats for one golfer's card (MGDV-601).
enum ScoringFormat {
  gross,
  molave,
  system36;

  String get storageValue => name;

  String get label => switch (this) {
        ScoringFormat.gross => 'Gross',
        ScoringFormat.molave => 'Molave',
        ScoringFormat.system36 => 'System 36',
      };

  static ScoringFormat parse(String? raw) => switch (raw) {
        'molave' => ScoringFormat.molave,
        'system36' => ScoringFormat.system36,
        _ => ScoringFormat.gross,
      };
}

/// One hole as the format calculators see it. Strokes are not rewritten.
class HoleScoreInput {
  const HoleScoreInput({
    required this.par,
    required this.strokes,
    required this.penalties,
    this.conceded = false,
    this.paidMulligans = 0,
    this.played = true,
    this.holeNumber = 0,
  });

  final int par;
  final int strokes;
  final int penalties;
  final bool conceded;
  final int paidMulligans;
  final bool played;
  final int holeNumber;

  int get gross => strokes + penalties;
}

class RoundFormatSettings {
  const RoundFormatSettings({
    required this.roundId,
    this.format = ScoringFormat.gross,
    this.molaveDoubleEaglePoints = 7,
    this.paidMulliganFeePhp = 0,
    this.courseRating,
    this.slopeRating,
    this.attestedAtMs,
    this.attestedByName = '',
    this.attestedRole = '',
    this.editedAfterAttestCount = 0,
    this.attestSignaturePath = '',
    this.attestSelfiePath = '',
    this.attestCombinedPath = '',
    this.attestPayloadPath = '',
    this.attestPdfPath = '',
  });

  final String roundId;
  final ScoringFormat format;
  final int molaveDoubleEaglePoints;
  final int paidMulliganFeePhp;
  final double? courseRating;
  final int? slopeRating;
  final int? attestedAtMs;
  final String attestedByName;
  final String attestedRole;
  final int editedAfterAttestCount;
  final String attestSignaturePath;
  final String attestSelfiePath;
  final String attestCombinedPath;
  final String attestPayloadPath;
  final String attestPdfPath;

  bool get isAttested => (attestedAtMs ?? 0) > 0;

  bool get hasAttestPdf => attestPdfPath.isNotEmpty;

  bool get editedAfterAttest =>
      editedAfterAttestCount > 0 && !isAttested && attestedByName.isNotEmpty;

  String get attestationLabel {
    if (isAttested) {
      final who = attestedByName.isEmpty ? attestedRole : attestedByName;
      return 'Attested by $who · $attestedRole';
    }
    if (editedAfterAttest) return 'Edited after attest';
    return 'Not attested';
  }

  RoundFormatSettings copyWith({
    ScoringFormat? format,
    int? molaveDoubleEaglePoints,
    int? paidMulliganFeePhp,
    double? courseRating,
    int? slopeRating,
    int? attestedAtMs,
    String? attestedByName,
    String? attestedRole,
    int? editedAfterAttestCount,
    String? attestSignaturePath,
    String? attestSelfiePath,
    String? attestCombinedPath,
    String? attestPayloadPath,
    String? attestPdfPath,
    bool clearAttestation = false,
    bool clearCourseRating = false,
    bool clearSlope = false,
  }) {
    return RoundFormatSettings(
      roundId: roundId,
      format: format ?? this.format,
      molaveDoubleEaglePoints:
          molaveDoubleEaglePoints ?? this.molaveDoubleEaglePoints,
      paidMulliganFeePhp: paidMulliganFeePhp ?? this.paidMulliganFeePhp,
      courseRating:
          clearCourseRating ? null : (courseRating ?? this.courseRating),
      slopeRating: clearSlope ? null : (slopeRating ?? this.slopeRating),
      attestedAtMs:
          clearAttestation ? null : (attestedAtMs ?? this.attestedAtMs),
      attestedByName: attestedByName ?? this.attestedByName,
      attestedRole: attestedRole ?? this.attestedRole,
      editedAfterAttestCount:
          editedAfterAttestCount ?? this.editedAfterAttestCount,
      attestSignaturePath: clearAttestation
          ? ''
          : (attestSignaturePath ?? this.attestSignaturePath),
      attestSelfiePath:
          clearAttestation ? '' : (attestSelfiePath ?? this.attestSelfiePath),
      attestCombinedPath: clearAttestation
          ? ''
          : (attestCombinedPath ?? this.attestCombinedPath),
      attestPayloadPath:
          clearAttestation ? '' : (attestPayloadPath ?? this.attestPayloadPath),
      attestPdfPath:
          clearAttestation ? '' : (attestPdfPath ?? this.attestPdfPath),
    );
  }
}

const attestRoles = ['self', 'marker', 'caddy', 'committee'];

int normalizeDoubleEaglePoints(int points) => points == 6 ? 6 : 7;

/// Molave (modified Stableford). Unplayed holes return null.
/// A hole-in-one is 6 unless a paid tournament mulligan was used on the hole.
int? molaveHolePoints(
  HoleScoreInput hole, {
  int doubleEaglePoints = 7,
}) {
  if (!hole.played || hole.par <= 0) return null;
  final eagle = normalizeDoubleEaglePoints(doubleEaglePoints);
  final toPar = hole.gross - hole.par;
  final holeInOne = hole.gross == 1 &&
      hole.paidMulligans == 0 &&
      !hole.conceded &&
      hole.par >= 3;
  if (holeInOne) return 6;
  if (toPar <= -3) return eagle;
  if (toPar == -2) return 5;
  if (toPar == -1) return 4;
  if (toPar == 0) return 3;
  if (toPar == 1) return 2;
  if (toPar == 2) return 1;
  return 0;
}

/// System 36 hole points. Unplayed holes return null.
int? system36HolePoints(HoleScoreInput hole) {
  if (!hole.played || hole.par <= 0) return null;
  final toPar = hole.gross - hole.par;
  if (toPar <= 0) return 2;
  if (toPar == 1) return 1;
  return 0;
}

class FormatCardResult {
  const FormatCardResult({
    required this.format,
    required this.gross,
    required this.points,
    required this.playedHoles,
    this.dailyHandicap,
    this.net,
  });

  final ScoringFormat format;
  final int gross;
  final int points;
  final int playedHoles;
  final int? dailyHandicap;
  final int? net;

  String get summary => switch (format) {
        ScoringFormat.gross when net != null => 'Gross $gross · Net $net',
        ScoringFormat.gross => 'Gross $gross',
        ScoringFormat.molave => 'Molave $points',
        ScoringFormat.system36 when dailyHandicap != null =>
          'System 36 $points pts · Hcp $dailyHandicap · Net $net',
        ScoringFormat.system36 => 'System 36 $points pts',
      };
}

FormatCardResult scoreRound(
  List<HoleScoreInput> holes, {
  required ScoringFormat format,
  int doubleEaglePoints = 7,
  double? manualIndex,
}) {
  var gross = 0;
  var points = 0;
  var played = 0;
  for (final hole in holes) {
    if (!hole.played) continue;
    played += 1;
    gross += hole.gross;
    if (format == ScoringFormat.molave) {
      points +=
          molaveHolePoints(hole, doubleEaglePoints: doubleEaglePoints) ?? 0;
    } else if (format == ScoringFormat.system36) {
      points += system36HolePoints(hole) ?? 0;
    }
  }
  int? daily;
  int? net;
  if (format == ScoringFormat.system36 && played >= 18) {
    daily = 36 - points;
    net = gross - daily;
  } else if (format == ScoringFormat.gross &&
      manualIndex != null &&
      played >= 18) {
    net = gross - manualIndex.round();
  }
  return FormatCardResult(
    format: format,
    gross: gross,
    points: points,
    playedHoles: played,
    dailyHandicap: daily,
    net: net,
  );
}

/// WHS-style cap until stroke index exists: no hole counts more than par + 2.
int adjustedHoleGross(HoleScoreInput hole) {
  final cap = hole.par + 2;
  if (hole.gross > cap) return cap;
  return hole.gross;
}

int adjustedRoundGross(Iterable<HoleScoreInput> holes) {
  var sum = 0;
  for (final hole in holes) {
    if (!hole.played) continue;
    sum += adjustedHoleGross(hole);
  }
  return sum;
}

double scoreDifferential({
  required int adjustedGross,
  required double courseRating,
  required int slopeRating,
}) {
  if (slopeRating <= 0) {
    throw ArgumentError.value(slopeRating, 'slopeRating', 'must be positive');
  }
  final raw = (113 / slopeRating) * (adjustedGross - courseRating);
  return (raw * 10).round() / 10;
}

/// Best-N and adjustment for 3 to 20 differentials (WHS 18-hole table).
({int use, double adjustment})? whsSelection(int roundCount) {
  final n = roundCount > 20 ? 20 : roundCount;
  const table = <int, (int, double)>{
    3: (1, -2),
    4: (1, -1),
    5: (1, 0),
    6: (2, -1),
    7: (2, 0),
    8: (2, 0),
    9: (3, 0),
    10: (3, 0),
    11: (3, 0),
    12: (4, 0),
    13: (4, 0),
    14: (4, 0),
    15: (5, 0),
    16: (5, 0),
    17: (6, 0),
    18: (6, 0),
    19: (7, 0),
    20: (8, 0),
  };
  final row = table[n];
  if (row == null) return null;
  return (use: row.$1, adjustment: row.$2);
}

/// Unofficial estimate from newest-first differentials. Null before 3 rounds.
double? unofficialHandicapIndex(List<double> differentialsNewestFirst) {
  final window = differentialsNewestFirst.take(20).toList();
  final selection = whsSelection(window.length);
  if (selection == null) return null;
  final sorted = [...window]..sort();
  final best = sorted.take(selection.use);
  final average = best.reduce((a, b) => a + b) / selection.use;
  final index = average + selection.adjustment;
  return (index * 10).round() / 10;
}

/// At most one paid tournament mulligan on each nine.
int clampPaidMulligan({
  required int holeNumber,
  required int requested,
  required Map<int, int> paidByHole,
}) {
  if (requested <= 0 || holeNumber <= 0) return 0;
  final nineStart = holeNumber <= 9 ? 1 : 10;
  final nineEnd = nineStart + 8;
  var usedElsewhere = 0;
  for (var hole = nineStart; hole <= nineEnd; hole++) {
    if (hole == holeNumber) continue;
    if ((paidByHole[hole] ?? 0) > 0) usedElsewhere += 1;
  }
  if (usedElsewhere >= 1) return 0;
  return 1;
}

bool readyForMolavePickup({
  required int par,
  required int strokes,
  required int penalties,
}) {
  return par > 0 && strokes + penalties >= par + 3;
}

HoleScoreInput holeInputFromScore({
  required int holeNumber,
  required int par,
  required int strokes,
  required int penalties,
  required int conceded,
  required int paidMulligans,
  required int finalScore,
}) {
  final played = finalScore > 0 || strokes > 0 || conceded == 1;
  return HoleScoreInput(
    holeNumber: holeNumber,
    par: par,
    strokes: conceded == 1 ? par * 2 : strokes,
    penalties: penalties,
    conceded: conceded == 1,
    paidMulligans: paidMulligans,
    played: played,
  );
}
