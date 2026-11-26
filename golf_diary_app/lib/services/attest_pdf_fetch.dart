import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import 'attest_pdf_client.dart';
import 'attestation_file_store.dart';
import 'local_database_service.dart';
import 'sync_identity.dart';

/// Asks [attestScorePdf] for the card and stores the returned bytes.
/// Returns false when the PDF is not ready (offline, or still waiting).
class AttestPdfFetch {
  static AttestPdfClient? debugClient;

  static Future<bool> tryFetch(String roundId) async {
    final db = LocalDatabaseService.instance;
    final settings = await db.getRoundFormat(roundId);
    if (!settings.isAttested || settings.attestPayloadPath.isEmpty) {
      return false;
    }
    if (settings.attestPdfPath.isNotEmpty) {
      final existing =
          await AttestationFileStore.instance.read(settings.attestPdfPath);
      if (existing != null && existing.isNotEmpty) return true;
    }
    final client = debugClient ?? _liveClient();
    if (client == null) return false;
    final store = AttestationFileStore.instance;
    final payloadBytes = await store.read(settings.attestPayloadPath);
    if (payloadBytes == null) return false;
    final imagePath = settings.attestCombinedPath.isNotEmpty
        ? settings.attestCombinedPath
        : settings.attestSignaturePath;
    if (imagePath.isEmpty) return false;
    final image = await store.read(imagePath);
    if (image == null) return false;
    final payload = Map<String, Object?>.from(
      jsonDecode(utf8.decode(payloadBytes)) as Map,
    );
    payload['imageBase64'] = base64Encode(image);
    payload['imageMime'] =
        settings.attestCombinedPath.isNotEmpty ? 'image/jpeg' : 'image/png';
    try {
      final pdf = await client.render(payload);
      if (pdf.length < 4 || utf8.decode(pdf.sublist(0, 4)) != '%PDF') {
        return false;
      }
      final path = await store.writePdf(roundId, pdf);
      await db.saveAttestPdfPath(roundId, path);
      return true;
    } on AttestPdfUnavailable {
      return false;
    } catch (_) {
      return false;
    }
  }

  static AttestPdfClient? _liveClient() {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAttestPdfClient();
  }
}

class FirebaseAttestPdfClient implements AttestPdfClient {
  FirebaseAttestPdfClient({FirebaseFunctions? functions})
      : _functions = functions;

  final FirebaseFunctions? _functions;

  @override
  Future<Uint8List> render(Map<String, Object?> body) async {
    final uid = await SyncIdentity.ensureSignedIn();
    if (uid == null) throw const AttestPdfUnavailable();
    final functions = _functions ??
        FirebaseFunctions.instanceFor(region: attestScorePdfRegion);
    try {
      final result = await functions
          .httpsCallable(
            attestScorePdfName,
            options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
          )
          .call(body);
      final data = Map<Object?, Object?>.from(result.data as Map);
      final encoded = data['pdfBase64'] as String?;
      if (encoded == null || encoded.isEmpty) {
        throw const AttestPdfUnavailable();
      }
      return base64Decode(encoded);
    } on FirebaseFunctionsException {
      throw const AttestPdfUnavailable();
    }
  }
}
