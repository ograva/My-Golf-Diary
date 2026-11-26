import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'attestation_file_store.dart';

AttestationFileStore createAttestationFileStore() => WebAttestationFileStore();

/// Browser Cache API so an installed PWA keeps the signature offline.
/// `pwa_service_worker.js` keeps caches named `golf-diary-attestations*`.
class WebAttestationFileStore implements AttestationFileStore {
  static const cacheName = 'golf-diary-attestations-v1';

  final _fallback = MemoryAttestationFileStore();
  Future<web.Cache?>? _cache;

  Future<web.Cache?> _open() => _cache ??= () async {
        try {
          return await web.window.caches.open(cacheName).toDart;
        } catch (_) {
          return null;
        }
      }();

  static String _url(String relativePath) =>
      '${Uri.base.origin}/__attestations/$relativePath';

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
    final cache = await _open();
    if (cache == null) {
      _fallback.files[relativePath] = Uint8List.fromList(bytes);
      return;
    }
    await cache.put(_url(relativePath).toJS, web.Response(bytes.toJS)).toDart;
  }

  @override
  Future<Uint8List?> read(String relativePath) async {
    final cache = await _open();
    if (cache == null) return _fallback.read(relativePath);
    try {
      final response = await cache.match(_url(relativePath).toJS).toDart;
      if (response == null) return null;
      return (await response.arrayBuffer().toDart).toDart.asUint8List();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> deleteRound(String roundId) async {
    final cache = await _open();
    if (cache == null) {
      await _fallback.deleteRound(roundId);
      return;
    }
    final prefix = 'attestations/$roundId/';
    for (final name in [
      'signature.png',
      'selfie.jpg',
      'combined.jpg',
      'payload.json',
      'card.pdf',
    ]) {
      try {
        await cache.delete(_url('$prefix$name').toJS).toDart;
      } catch (_) {}
    }
  }
}
