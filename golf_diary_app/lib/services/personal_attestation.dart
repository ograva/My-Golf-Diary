import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/golf_models.dart';
import '../models/scoring_format.dart';
import 'attestation_file_store.dart';
import 'local_database_service.dart';

/// Writes the signature, optional selfie, composite, and score payload, then
/// marks the round attested. The PDF is not created here.
class PersonalAttestation {
  static Future<void> save({
    required String roundId,
    required String name,
    required String role,
    required Uint8List signaturePng,
    Uint8List? selfieJpeg,
    Uint8List? combinedJpeg,
    double? manualIndex,
  }) async {
    final db = LocalDatabaseService.instance;
    final settings = await db.getRoundFormat(roundId);
    final holes = await db.getScoresForRound(roundId);
    final database = await db.database;
    final rows = await database.query(
      'golf_rounds',
      columns: ['course_name', 'completed_at_ms'],
      where: 'round_id = ?',
      whereArgs: [roundId],
      limit: 1,
    );
    final courseName = rows.isEmpty
        ? 'Local Course'
        : rows.first['course_name'] as String? ?? 'Local Course';
    final completedAtMs =
        rows.isEmpty ? null : rows.first['completed_at_ms'] as int?;
    final attestedAtMs = DateTime.now().millisecondsSinceEpoch;
    final inputs = [
      for (final hole in holes)
        holeInputFromScore(
          holeNumber: hole.holeNumber,
          par: hole.par,
          strokes: hole.strokes,
          penalties: hole.penalties,
          conceded: hole.conceded,
          paidMulligans: hole.paidMulligans,
          finalScore: hole.finalScore,
        ),
    ];
    final card = scoreRound(
      inputs,
      format: settings.format,
      doubleEaglePoints: settings.molaveDoubleEaglePoints,
      manualIndex: manualIndex,
    );
    final payload = <String, Object?>{
      'courseName': courseName,
      'completedAtMs': completedAtMs ?? attestedAtMs,
      'attestedAtMs': attestedAtMs,
      'name': name.trim(),
      'role': role,
      'formatSummary': card.summary,
      'completedLabel': _formatLocal(completedAtMs ?? attestedAtMs),
      'attestedLabel': _formatLocal(attestedAtMs),
      'holes': [
        for (final hole in holes)
          {
            'hole': hole.holeNumber,
            'par': hole.par,
            'gross': hole.strokes + hole.penalties,
            'played': isHolePlayed(hole),
          },
      ],
    };
    final stored = await AttestationFileStore.instance.writeRound(
      roundId: roundId,
      signaturePng: signaturePng,
      payloadJson: Uint8List.fromList(utf8.encode(jsonEncode(payload))),
      selfieJpeg: selfieJpeg,
      combinedJpeg: combinedJpeg,
    );
    await db.attestRound(
      roundId: roundId,
      name: name,
      role: role,
      attestedAtMs: attestedAtMs,
      signaturePath: stored.signaturePath,
      selfiePath: stored.selfiePath,
      combinedPath: stored.combinedPath,
      payloadPath: stored.payloadPath,
    );
  }
}

String _formatLocal(int ms) {
  final date = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} '
      '${two(date.hour)}:${two(date.minute)}';
}
