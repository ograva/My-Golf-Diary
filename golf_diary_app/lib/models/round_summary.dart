class RoundSummary {
  const RoundSummary({
    required this.roundId,
    required this.courseName,
    required this.holesRecorded,
    required this.startedAtMs,
    this.completedAtMs,
  });

  final String roundId;
  final String courseName;
  final int holesRecorded;
  final int startedAtMs;
  final int? completedAtMs;

  bool get isCompleted => completedAtMs != null;

  String get label {
    final date = DateTime.fromMillisecondsSinceEpoch(startedAtMs);
    final d = '${date.month}/${date.day}';
    final status = isCompleted ? '' : ' · in progress';
    return '$courseName · $d$status';
  }
}

class RoundTotals {
  const RoundTotals({
    required this.roundId,
    required this.courseName,
    required this.frontNineScore,
    required this.backNineScore,
    required this.totalScore,
    required this.frontNinePar,
    required this.backNinePar,
    required this.totalPar,
    required this.penaltiesTotal,
    required this.mulligansTotal,
  });

  final String roundId;
  final String courseName;
  final int frontNineScore;
  final int backNineScore;
  final int totalScore;
  final int frontNinePar;
  final int backNinePar;
  final int totalPar;
  final int penaltiesTotal;
  final int mulligansTotal;

  int get frontNineToPar => frontNineScore - frontNinePar;
  int get backNineToPar => backNineScore - backNinePar;
  int get totalToPar => totalScore - totalPar;
}
