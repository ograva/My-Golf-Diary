import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'attestation_file_store.dart';

AttestationFileStore createAttestationFileStore() => IoAttestationFileStore();

class IoAttestationFileStore implements AttestationFileStore {
  static Directory? _cachedRoot;

  Future<Directory> _root() async {
    final cached = _cachedRoot;
    if (cached != null) return cached;
    try {
      final dir = await getApplicationDocumentsDirectory();
      return _cachedRoot = dir;
    } on MissingPluginException {
      final dir =
          Directory(p.join(Directory.systemTemp.path, 'golf_diary_attest'));
      dir.createSync(recursive: true);
      return _cachedRoot = dir;
    }
  }

  Future<File> _file(String relativePath) async {
    final root = await _root();
    return File(p.join(root.path, relativePath));
  }

  @override
  Future<AttestStoredFiles> writeRound({
    required String roundId,
    required Uint8List signaturePng,
    required Uint8List payloadJson,
    Uint8List? selfieJpeg,
    Uint8List? combinedJpeg,
  }) async {
    await deleteRound(roundId);
    final signature = MemoryAttestationFileStore.signaturePath(roundId);
    await _write(signature, signaturePng);
    final payload = MemoryAttestationFileStore.payloadPath(roundId);
    await _write(payload, payloadJson);
    String? selfie;
    String? combined;
    if (selfieJpeg != null) {
      selfie = MemoryAttestationFileStore.selfiePath(roundId);
      await _write(selfie, selfieJpeg);
    }
    if (combinedJpeg != null) {
      combined = MemoryAttestationFileStore.combinedPath(roundId);
      await _write(combined, combinedJpeg);
    }
    return AttestStoredFiles(
      signaturePath: signature,
      payloadPath: payload,
      selfiePath: selfie,
      combinedPath: combined,
    );
  }

  @override
  Future<String> writePdf(String roundId, Uint8List pdfBytes) async {
    final path = MemoryAttestationFileStore.pdfPath(roundId);
    await _write(path, pdfBytes);
    return path;
  }

  Future<void> _write(String relativePath, Uint8List bytes) async {
    final file = await _file(relativePath);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes, flush: true);
  }

  @override
  Future<Uint8List?> read(String relativePath) async {
    final file = await _file(relativePath);
    if (!file.existsSync()) return null;
    return file.readAsBytes();
  }

  @override
  Future<void> deleteRound(String roundId) async {
    final root = await _root();
    final dir = Directory(p.join(root.path, 'attestations', roundId));
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }
}
