import 'dart:typed_data';

/// Cloud Function that renders the attested score PDF.
const attestScorePdfName = 'attestScorePdf';

/// Callable region. The function is deployed to the same region.
const attestScorePdfRegion = 'asia-east1';

abstract class AttestPdfClient {
  Future<Uint8List> render(Map<String, Object?> body);
}

class AttestPdfUnavailable implements Exception {
  const AttestPdfUnavailable();
}
