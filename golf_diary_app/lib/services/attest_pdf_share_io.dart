import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> shareAttestPdf(Uint8List bytes, String filename) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          bytes,
          mimeType: 'application/pdf',
          name: filename,
        ),
      ],
      fileNameOverrides: [filename],
    ),
  );
}
