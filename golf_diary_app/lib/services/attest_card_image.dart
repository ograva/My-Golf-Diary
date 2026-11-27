import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'attest_jpeg.dart';

/// Landscape canvas the signature is captured on, so it lays over a portrait
/// selfie as a band across the bottom.
const kSignaturePadAspect = 16 / 9;

/// White behind the signature on a selfie: 95% opaque, so a hint of the photo
/// shows through while the ink stays solid black.
const kSignatureOverlayGround = Color(0xF2FFFFFF);

/// Largest 16:9 rect centered in [area] (letterboxed when [area] is portrait).
Rect signaturePadRect(Size area) {
  var width = area.width;
  var height = width / kSignaturePadAspect;
  if (height > area.height) {
    height = area.height;
    width = height * kSignaturePadAspect;
  }
  return Rect.fromLTWH(
    (area.width - width) / 2,
    (area.height - height) / 2,
    width,
    height,
  );
}

/// Wide signature PNG, white ground, black ~3px stroke.
Future<Uint8List> renderSignaturePng(
  List<List<Offset>> strokes,
  Size source, {
  int width = 900,
  int height = 300,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFFFFFFF),
  );
  final sx = source.width <= 0 ? 1.0 : width / source.width;
  final sy = source.height <= 0 ? 1.0 : height / source.height;
  final paint = Paint()
    ..color = const Color(0xFF000000)
    ..strokeWidth = 3
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;
  for (final stroke in strokes) {
    if (stroke.isEmpty) continue;
    if (stroke.length == 1) {
      canvas.drawCircle(
        Offset(stroke.first.dx * sx, stroke.first.dy * sy),
        1.5,
        Paint()..color = const Color(0xFF000000),
      );
      continue;
    }
    final path = Path()..moveTo(stroke.first.dx * sx, stroke.first.dy * sy);
    for (final point in stroke.skip(1)) {
      path.lineTo(point.dx * sx, point.dy * sy);
    }
    canvas.drawPath(path, paint);
  }
  final image = await recorder.endRecording().toImage(width, height);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Long edge at most [maxEdge], encoded as JPEG.
Future<Uint8List> limitSelfieJpeg(Uint8List bytes, {int maxEdge = 1600}) async {
  final image = await _decode(bytes, maxEdge: maxEdge);
  try {
    final rgba =
        await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
    return encodeJpegRgba(
      rgba!.buffer.asUint8List(),
      image.width,
      image.height,
    );
  } finally {
    image.dispose();
  }
}

/// Where a signature sits on a selfie. Width matches the photo (a portrait
/// selfie, typically) and the height follows the signature's own aspect, so
/// a wide strip does not run past the frame. If that height would be taller
/// than the photo, the band shrinks uniformly and stays inside.
Rect signatureOverlayRect(Size selfie, Size signature) {
  var width = selfie.width;
  var height =
      signature.width <= 0 ? width : width * signature.height / signature.width;
  if (height > selfie.height) {
    height = selfie.height;
    width = signature.height <= 0
        ? selfie.width
        : height * signature.width / signature.height;
  }
  return Rect.fromLTWH(
    (selfie.width - width) / 2,
    selfie.height - height,
    width,
    height,
  );
}

/// Signature scaled to the selfie width and drawn on the photo. Output matches
/// the selfie size (after the 1600px limit).
Future<Uint8List> compositeSignatureOnSelfie({
  required Uint8List selfie,
  required Uint8List signature,
}) async {
  final photo = await _decode(selfie, maxEdge: 1600);
  final sign = await _decode(signature);
  try {
    final w = photo.width.toDouble();
    final h = photo.height.toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(photo, Offset.zero, Paint());
    final dest = signatureOverlayRect(
      Size(w, h),
      Size(sign.width.toDouble(), sign.height.toDouble()),
    );
    final src =
        Rect.fromLTWH(0, 0, sign.width.toDouble(), sign.height.toDouble());
    final edge = w < h ? w : h;
    canvas.drawRRect(
      RRect.fromRectAndRadius(dest, Radius.circular(edge * 0.02)),
      Paint()..color = kSignatureOverlayGround,
    );
    // Multiply: the PNG's white ground leaves the band untouched, ink stays black.
    canvas.drawImageRect(
      sign,
      src,
      dest,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..blendMode = BlendMode.multiply,
    );
    final image =
        await recorder.endRecording().toImage(photo.width, photo.height);
    try {
      final rgba =
          await image.toByteData(format: ui.ImageByteFormat.rawStraightRgba);
      return encodeJpegRgba(
        rgba!.buffer.asUint8List(),
        image.width,
        image.height,
      );
    } finally {
      image.dispose();
    }
  } finally {
    photo.dispose();
    sign.dispose();
  }
}

Future<Size> decodeImageSize(Uint8List bytes) async {
  final image = await _decode(bytes);
  try {
    return Size(image.width.toDouble(), image.height.toDouble());
  } finally {
    image.dispose();
  }
}

Future<ui.Image> _decode(Uint8List bytes, {int? maxEdge}) async {
  final probe = await ui.instantiateImageCodec(bytes);
  final frame = await probe.getNextFrame();
  final image = frame.image;
  if (maxEdge == null) {
    probe.dispose();
    return image;
  }
  final long = image.width > image.height ? image.width : image.height;
  if (long <= maxEdge) {
    probe.dispose();
    return image;
  }
  final scale = maxEdge / long;
  final tw = (image.width * scale).round();
  final th = (image.height * scale).round();
  image.dispose();
  probe.dispose();
  final limited = await ui.instantiateImageCodec(
    bytes,
    targetWidth: tw,
    targetHeight: th,
  );
  final resized = await limited.getNextFrame();
  limited.dispose();
  return resized.image;
}
