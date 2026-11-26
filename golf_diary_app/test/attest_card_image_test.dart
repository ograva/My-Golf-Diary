import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golf_diary_app/services/attest_card_image.dart';
import 'package:golf_diary_app/services/attest_jpeg.dart';
import 'package:golf_diary_app/services/local_database_service.dart';
import 'package:golf_diary_app/services/personal_attestation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('selfie composite matches the selfie size', () async {
    final selfie = encodeJpegRgba(_solid(40, 24, 30, 90, 200), 40, 24);
    final signature = await renderSignaturePng(
      [
        [const Offset(4, 8), const Offset(40, 12)],
      ],
      const Size(90, 30),
      width: 90,
      height: 30,
    );
    final combined = await compositeSignatureOnSelfie(
      selfie: selfie,
      signature: signature,
    );
    final codec = await ui.instantiateImageCodec(combined);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 40);
    expect(frame.image.height, 24);
    frame.image.dispose();
    codec.dispose();
  });

  test('a wide signature scales to a portrait selfie width', () {
    const selfie = Size(600, 800);
    const signature = Size(900, 300);
    final band = signatureOverlayRect(selfie, signature);
    expect(band.width, selfie.width);
    expect(band.height, 200);
    expect(band.left, 0);
    expect(band.bottom, selfie.height);
    expect(band.top, greaterThanOrEqualTo(0));
  });

  test('portrait composite keeps the signature inside the photo', () async {
    final selfie = encodeJpegRgba(_solid(30, 40, 20, 40, 90), 30, 40);
    final signature = await renderSignaturePng(
      [
        [const Offset(4, 8), const Offset(80, 12)],
      ],
      const Size(90, 30),
      width: 90,
      height: 30,
    );
    final combined = await compositeSignatureOnSelfie(
      selfie: selfie,
      signature: signature,
    );
    final codec = await ui.instantiateImageCodec(combined);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    expect(image.width, 30);
    expect(image.height, 40);
    final bytes =
        await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    final top = bytes!.getUint8(0);
    final bottomIndex = (39 * 30 + 15) * 4;
    final bottom = bytes.getUint8(bottomIndex);
    expect(bottom, greaterThan(top + 80));
    image.dispose();
    codec.dispose();
  });

  test('no-selfie attest leaves the combined path null', () async {
    const file = 'golf_diary_attest_files.db';
    await LocalDatabaseService.debugClose();
    LocalDatabaseService.debugSetFileName(file);
    addTearDown(() async {
      await LocalDatabaseService.debugClose();
      LocalDatabaseService.debugSetFileName('golf_diary.db');
    });
    await deleteDatabase(join(await getDatabasesPath(), file));
    final db = LocalDatabaseService.instance;
    final roundId = await db.startNewRound(courseName: 'Local Course');
    await db.completeRound(roundId);
    final signature = await renderSignaturePng(
      [
        [const Offset(2, 2), const Offset(20, 8)],
      ],
      const Size(60, 20),
      width: 60,
      height: 20,
    );
    await PersonalAttestation.save(
      roundId: roundId,
      name: 'Pat',
      role: 'self',
      signaturePng: signature,
    );
    final rows = await (await db.database).query(
      'golf_rounds',
      where: 'round_id = ?',
      whereArgs: [roundId],
    );
    expect(rows.single['attest_combined_path'], isNull);
    expect(rows.single['attest_pdf_path'], isNull);
    expect(rows.single['attest_signature_path'], isNotNull);
    expect(rows.single['attest_payload_path'], isNotNull);
  });
}

Uint8List _solid(int width, int height, int r, int g, int b) {
  final bytes = Uint8List(width * height * 4);
  for (var i = 0; i < width * height; i++) {
    bytes[i * 4] = r;
    bytes[i * 4 + 1] = g;
    bytes[i * 4 + 2] = b;
    bytes[i * 4 + 3] = 255;
  }
  return bytes;
}
