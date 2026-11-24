import 'dart:typed_data';

import 'package:flutter/widgets.dart';

/// Decode width for a pack image shown [displayWidth] logical pixels wide,
/// rounded up to 128 px so small layout changes keep one cache entry; null
/// when the source is no wider than that (decode at full size).
int? holeMapDecodeWidth(
  double displayWidth,
  double devicePixelRatio,
  int sourceWidthPx,
) {
  if (!displayWidth.isFinite || displayWidth <= 0) return null;
  final px = ((displayWidth * devicePixelRatio) / 128).ceil() * 128;
  return px < sourceWidthPx ? px : null;
}

/// Pack image provider. A full-size decode is keyed by the bytes instance,
/// which is what [precacheImage] warms for the next hole.
ImageProvider holeMapImageProvider(Uint8List bytes, {int? decodeWidth}) =>
    ResizeImage.resizeIfNeeded(decodeWidth, null, MemoryImage(bytes));
