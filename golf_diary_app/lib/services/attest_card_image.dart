import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'attest_jpeg.dart';

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

/// Signature on a white bar in the bottom 22% of the selfie. Output matches
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
    final inset = w * 0.08;
    final bar = RRect.fromRectAndRadius(
      Rect.fromLTWH(inset, h * 0.78, w - inset * 2, h * 0.22),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(
      bar,
      Paint()..color = const Color(0xD9FFFFFF),
    );
    final pad = bar.height * 0.12;
    final inner = Rect.fromLTWH(
      bar.left + pad,
      bar.top + pad,
      bar.width - pad * 2,
      bar.height - pad * 2,
    );
    final src =
        Rect.fromLTWH(0, 0, sign.width.toDouble(), sign.height.toDouble());
    final fitted = applyBoxFit(BoxFit.contain, src.size, inner.size);
    final dest = Alignment.center.inscribe(fitted.destination, inner);
    canvas.drawImageRect(
      sign,
      src,
      dest,
      Paint()..filterQuality = FilterQuality.medium,
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

Future<ui.Image> _decode(Uint8List bytes, {int? maxEdge}) async {
  final probe = await ui.instantiateImageCodec(bytes);
  final frame = await probe.getNextFrame();
  final image = frame.image;
  if (maxEdge == null) return image;
  final long = image.width > image.height ? image.width : image.height;
  if (long <= maxEdge) return image;
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
