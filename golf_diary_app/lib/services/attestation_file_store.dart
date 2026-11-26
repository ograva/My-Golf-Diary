import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'attestation_file_store_io.dart'
    if (dart.library.js_interop) 'attestation_file_store_web.dart' as platform;

/// Local signature, selfie, and combined image for one round.
/// Relative paths are what `golf_rounds` stores. Bytes never sync.
abstract class AttestationFileStore {
  Future<AttestStoredFiles> writeRound({
    required String roundId,
    required Uint8List signaturePng,
    required Uint8List payloadJson,
    Uint8List? selfieJpeg,
    Uint8List? combinedJpeg,
  });

  /// Bytes returned by `attestScorePdf`. Not produced on the phone.
  Future<String> writePdf(String roundId, Uint8List pdfBytes);

  Future<Uint8List?> read(String relativePath);

  Future<void> deleteRound(String roundId);

  static AttestationFileStore? debugStore;

  static AttestationFileStore get instance =>
      debugStore ?? platform.createAttestationFileStore();
}

class AttestStoredFiles {
  const AttestStoredFiles({
    required this.signaturePath,
    required this.payloadPath,
    this.selfiePath,
    this.combinedPath,
  });

  final String signaturePath;
  final String payloadPath;
  final String? selfiePath;
  final String? combinedPath;
}

/// In-memory store for tests.
class MemoryAttestationFileStore implements AttestationFileStore {
  final files = <String, Uint8List>{};

  static String signaturePath(String roundId) =>
      'attestations/$roundId/signature.png';

  static String selfiePath(String roundId) =>
      'attestations/$roundId/selfie.jpg';

  static String combinedPath(String roundId) =>
      'attestations/$roundId/combined.jpg';

  static String payloadPath(String roundId) =>
      'attestations/$roundId/payload.json';

  static String pdfPath(String roundId) => 'attestations/$roundId/card.pdf';

  @override
  Future<AttestStoredFiles> writeRound({
    required String roundId,
    required Uint8List signaturePng,
    required Uint8List payloadJson,
    Uint8List? selfieJpeg,
    Uint8List? combinedJpeg,
  }) async {
    await deleteRound(roundId);
    final signature = signaturePath(roundId);
    files[signature] = Uint8List.fromList(signaturePng);
    final payload = payloadPath(roundId);
    files[payload] = Uint8List.fromList(payloadJson);
    String? selfie;
    String? combined;
    if (selfieJpeg != null) {
      selfie = selfiePath(roundId);
      files[selfie] = Uint8List.fromList(selfieJpeg);
    }
    if (combinedJpeg != null) {
      combined = combinedPath(roundId);
      files[combined] = Uint8List.fromList(combinedJpeg);
    }
    return AttestStoredFiles(
      signaturePath: signature,
      selfiePath: selfie,
      combinedPath: combined,
      payloadPath: payload,
    );
  }

  @override
  Future<String> writePdf(String roundId, Uint8List pdfBytes) async {
    final path = pdfPath(roundId);
    files[path] = Uint8List.fromList(pdfBytes);
    return path;
  }

  @override
  Future<Uint8List?> read(String relativePath) async => files[relativePath];

  @override
  Future<void> deleteRound(String roundId) async {
    final prefix = 'attestations/$roundId/';
    files.removeWhere((path, _) => path.startsWith(prefix));
  }
}
