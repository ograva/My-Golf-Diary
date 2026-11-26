import 'dart:math' as math;
import 'dart:typed_data';

/// Baseline JPEG (4:4:4, quality 85) from straight RGBA bytes.
/// Drawn with `dart:ui`; this only packs the pixels. No `image` package.
Uint8List encodeJpegRgba(
  Uint8List rgba,
  int width,
  int height, {
  int quality = 85,
}) {
  if (rgba.length < width * height * 4) {
    throw ArgumentError('RGBA buffer is shorter than $width×$height');
  }
  final qy = _scaleQuant(_kLumaQuant, quality);
  final qc = _scaleQuant(_kChromaQuant, quality);
  final out = BytesBuilder(copy: false);
  out.addByte(0xFF);
  out.addByte(0xD8);
  _app0(out);
  _dqt(out, 0, qy);
  _dqt(out, 1, qc);
  _sof(out, width, height);
  _dht(out, 0, 0, _kDcLumaBits, _kDcLumaVal);
  _dht(out, 1, 0, _kAcLumaBits, _kAcLumaVal);
  _dht(out, 0, 1, _kDcChromaBits, _kDcChromaVal);
  _dht(out, 1, 1, _kAcChromaBits, _kAcChromaVal);
  _sos(out);

  final bits = _BitWriter(out);
  final dcY = _Huffman(_kDcLumaBits, _kDcLumaVal);
  final acY = _Huffman(_kAcLumaBits, _kAcLumaVal);
  final dcC = _Huffman(_kDcChromaBits, _kDcChromaVal);
  final acC = _Huffman(_kAcChromaBits, _kAcChromaVal);
  var prevY = 0;
  var prevCb = 0;
  var prevCr = 0;
  final yBuf = List<double>.filled(64, 0);
  final cbBuf = List<double>.filled(64, 0);
  final crBuf = List<double>.filled(64, 0);

  for (var by = 0; by < height; by += 8) {
    for (var bx = 0; bx < width; bx += 8) {
      var i = 0;
      for (var dy = 0; dy < 8; dy++) {
        final sy = math.min(by + dy, height - 1);
        for (var dx = 0; dx < 8; dx++) {
          final sx = math.min(bx + dx, width - 1);
          final p = (sy * width + sx) * 4;
          final r = rgba[p].toDouble();
          final g = rgba[p + 1].toDouble();
          final b = rgba[p + 2].toDouble();
          yBuf[i] = 0.299 * r + 0.587 * g + 0.114 * b - 128;
          cbBuf[i] = -0.168736 * r - 0.331264 * g + 0.5 * b;
          crBuf[i] = 0.5 * r - 0.418688 * g - 0.081312 * b;
          i++;
        }
      }
      prevY = _block(bits, yBuf, qy, dcY, acY, prevY);
      prevCb = _block(bits, cbBuf, qc, dcC, acC, prevCb);
      prevCr = _block(bits, crBuf, qc, dcC, acC, prevCr);
    }
  }
  bits.flush();
  out.addByte(0xFF);
  out.addByte(0xD9);
  return out.toBytes();
}

int _block(
  _BitWriter bits,
  List<double> samples,
  List<int> quant,
  _Huffman dc,
  _Huffman ac,
  int prevDc,
) {
  final coeffs = _zigzag(_dct(samples), quant);
  final diff = coeffs[0] - prevDc;
  final dcSize = _bitSize(diff);
  dc.write(bits, dcSize);
  if (dcSize > 0) bits.write(_magnitude(diff, dcSize), dcSize);
  var run = 0;
  var ended = true;
  for (var i = 1; i < 64; i++) {
    final v = coeffs[i];
    if (v == 0) {
      run++;
      continue;
    }
    ended = false;
    while (run > 15) {
      ac.write(bits, 0xF0);
      run -= 16;
    }
    final size = _bitSize(v);
    ac.write(bits, (run << 4) | size);
    bits.write(_magnitude(v, size), size);
    run = 0;
    ended = true;
  }
  if (!ended || run > 0) {
    // Trailing zeros, or a block that ended on a zero run.
    if (run > 0) ac.write(bits, 0x00);
  }
  return coeffs[0];
}

List<int> _zigzag(List<double> dct, List<int> quant) {
  final out = List<int>.filled(64, 0);
  for (var i = 0; i < 64; i++) {
    final q = quant[_kZigzag[i]];
    out[i] = (dct[_kZigzag[i]] / q).round();
  }
  return out;
}

List<double> _dct(List<double> samples) {
  final out = List<double>.filled(64, 0);
  for (var v = 0; v < 8; v++) {
    for (var u = 0; u < 8; u++) {
      var sum = 0.0;
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
          sum += samples[y * 8 + x] *
              _cos[(2 * x + 1) * u] *
              _cos[(2 * y + 1) * v];
        }
      }
      final cu = u == 0 ? _c0 : 1.0;
      final cv = v == 0 ? _c0 : 1.0;
      out[v * 8 + u] = 0.25 * cu * cv * sum;
    }
  }
  return out;
}

const double _c0 = 0.7071067811865476;

final List<double> _cos = [
  for (var i = 0; i < 16 * 8; i++) math.cos((i * math.pi) / 16),
];

int _bitSize(int value) {
  var v = value.abs();
  var n = 0;
  while (v > 0) {
    n++;
    v >>= 1;
  }
  return n;
}

int _magnitude(int value, int size) {
  if (value < 0) return value + (1 << size) - 1;
  return value;
}

List<int> _scaleQuant(List<int> base, int quality) {
  final q = quality.clamp(1, 100);
  final scale = q < 50 ? (5000 / q).floor() : 200 - q * 2;
  return [
    for (final v in base) ((v * scale + 50) ~/ 100).clamp(1, 255),
  ];
}

void _app0(BytesBuilder out) {
  _marker(out, 0xE0, [
    0x4A, 0x46, 0x49, 0x46, 0x00, // JFIF
    0x01, 0x01, // version
    0x00, // aspect ratio
    0x00, 0x01, 0x00, 0x01, // density
    0x00, 0x00, // no thumbnail
  ]);
}

void _dqt(BytesBuilder out, int id, List<int> natural) {
  final body = <int>[id];
  for (final index in _kZigzag) {
    body.add(natural[index]);
  }
  _marker(out, 0xDB, body);
}

void _sof(BytesBuilder out, int width, int height) {
  _marker(out, 0xC0, [
    8,
    height >> 8,
    height & 0xFF,
    width >> 8,
    width & 0xFF,
    3,
    1,
    0x11,
    0,
    2,
    0x11,
    1,
    3,
    0x11,
    1,
  ]);
}

void _dht(BytesBuilder out, int klass, int id, List<int> bits, List<int> vals) {
  _marker(out, 0xC4, [(klass << 4) | id, ...bits, ...vals]);
}

void _sos(BytesBuilder out) {
  _marker(out, 0xDA, [
    3,
    1,
    0x00,
    2,
    0x11,
    3,
    0x11,
    0,
    63,
    0,
  ]);
}

void _marker(BytesBuilder out, int code, List<int> body) {
  final length = body.length + 2;
  out
    ..addByte(0xFF)
    ..addByte(code)
    ..addByte(length >> 8)
    ..addByte(length & 0xFF)
    ..add(body);
}

class _BitWriter {
  _BitWriter(this.out);

  final BytesBuilder out;
  int _acc = 0;
  int _n = 0;

  void write(int value, int length) {
    if (length <= 0) return;
    _acc = (_acc << length) | (value & ((1 << length) - 1));
    _n += length;
    while (_n >= 8) {
      _n -= 8;
      final byte = (_acc >> _n) & 0xFF;
      out.addByte(byte);
      if (byte == 0xFF) out.addByte(0x00);
    }
  }

  void flush() {
    if (_n > 0) {
      write((1 << (8 - _n)) - 1, 8 - _n);
    }
  }
}

class _Huffman {
  _Huffman(List<int> bits, List<int> vals) : _codes = _build(bits, vals);

  final Map<int, (int, int)> _codes;

  void write(_BitWriter bits, int symbol) {
    final code = _codes[symbol];
    if (code == null) {
      throw StateError(
          'JPEG huffman symbol 0x${symbol.toRadixString(16)} missing');
    }
    bits.write(code.$1, code.$2);
  }

  static Map<int, (int, int)> _build(List<int> bits, List<int> vals) {
    final count = bits.fold<int>(0, (sum, n) => sum + n);
    if (count != vals.length) {
      throw StateError('JPEG huffman table $count != ${vals.length}');
    }
    final map = <int, (int, int)>{};
    var code = 0;
    var k = 0;
    for (var len = 1; len <= 16; len++) {
      for (var j = 0; j < bits[len - 1]; j++) {
        map[vals[k]] = (code, len);
        code++;
        k++;
      }
      code <<= 1;
    }
    return map;
  }
}

const _kZigzag = [
  0, 1, 8, 16, 9, 2, 3, 10, 17, 24, 32, 25, 18, 11, 4, 5, //
  12, 19, 26, 33, 40, 48, 41, 34, 27, 20, 13, 6, 7, 14, 21, 28,
  35, 42, 49, 56, 57, 50, 43, 36, 29, 22, 15, 23, 30, 37, 44, 51,
  58, 59, 52, 45, 38, 31, 39, 46, 53, 60, 61, 54, 47, 55, 62, 63,
];

const _kLumaQuant = [
  16, 11, 10, 16, 24, 40, 51, 61, //
  12, 12, 14, 19, 26, 58, 60, 55,
  14, 13, 16, 24, 40, 57, 69, 56,
  14, 17, 22, 29, 51, 87, 80, 62,
  18, 22, 37, 56, 68, 109, 103, 77,
  24, 35, 55, 64, 81, 104, 113, 92,
  49, 64, 78, 87, 103, 121, 120, 101,
  72, 92, 95, 98, 112, 100, 103, 99,
];

const _kChromaQuant = [
  17, 18, 24, 47, 99, 99, 99, 99, //
  18, 21, 26, 66, 99, 99, 99, 99,
  24, 26, 56, 99, 99, 99, 99, 99,
  47, 66, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99,
  99, 99, 99, 99, 99, 99, 99, 99,
];

const _kDcLumaBits = [0, 1, 5, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0];
const _kDcLumaVal = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

const _kDcChromaBits = [0, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0];
const _kDcChromaVal = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];

const _kAcLumaBits = [0, 2, 1, 3, 3, 2, 4, 3, 5, 5, 4, 4, 0, 0, 1, 0x7d];
const _kAcLumaVal = [
  0x01,
  0x02,
  0x03,
  0x00,
  0x04,
  0x11,
  0x05,
  0x12,
  0x21,
  0x31,
  0x41,
  0x06,
  0x13,
  0x51,
  0x61,
  0x07,
  0x22,
  0x71,
  0x14,
  0x32,
  0x81,
  0x91,
  0xa1,
  0x08,
  0x23,
  0x42,
  0xb1,
  0xc1,
  0x15,
  0x52,
  0xd1,
  0xf0,
  0x24,
  0x33,
  0x62,
  0x72,
  0x82,
  0x09,
  0x0a,
  0x16,
  0x17,
  0x18,
  0x19,
  0x1a,
  0x25,
  0x26,
  0x27,
  0x28,
  0x29,
  0x2a,
  0x34,
  0x35,
  0x36,
  0x37,
  0x38,
  0x39,
  0x3a,
  0x43,
  0x44,
  0x45,
  0x46,
  0x47,
  0x48,
  0x49,
  0x4a,
  0x53,
  0x54,
  0x55,
  0x56,
  0x57,
  0x58,
  0x59,
  0x5a,
  0x63,
  0x64,
  0x65,
  0x66,
  0x67,
  0x68,
  0x69,
  0x6a,
  0x73,
  0x74,
  0x75,
  0x76,
  0x77,
  0x78,
  0x79,
  0x7a,
  0x83,
  0x84,
  0x85,
  0x86,
  0x87,
  0x88,
  0x89,
  0x8a,
  0x92,
  0x93,
  0x94,
  0x95,
  0x96,
  0x97,
  0x98,
  0x99,
  0x9a,
  0xa2,
  0xa3,
  0xa4,
  0xa5,
  0xa6,
  0xa7,
  0xa8,
  0xa9,
  0xaa,
  0xb2,
  0xb3,
  0xb4,
  0xb5,
  0xb6,
  0xb7,
  0xb8,
  0xb9,
  0xba,
  0xc2,
  0xc3,
  0xc4,
  0xc5,
  0xc6,
  0xc7,
  0xc8,
  0xc9,
  0xca,
  0xd2,
  0xd3,
  0xd4,
  0xd5,
  0xd6,
  0xd7,
  0xd8,
  0xd9,
  0xda,
  0xe1,
  0xe2,
  0xe3,
  0xe4,
  0xe5,
  0xe6,
  0xe7,
  0xe8,
  0xe9,
  0xea,
  0xf1,
  0xf2,
  0xf3,
  0xf4,
  0xf5,
  0xf6,
  0xf7,
  0xf8,
  0xf9,
  0xfa,
];

const _kAcChromaBits = [0, 2, 1, 2, 4, 4, 3, 4, 7, 5, 4, 4, 0, 1, 2, 0x77];
const _kAcChromaVal = [
  0x00,
  0x01,
  0x02,
  0x03,
  0x11,
  0x04,
  0x05,
  0x21,
  0x31,
  0x06,
  0x12,
  0x41,
  0x51,
  0x07,
  0x61,
  0x71,
  0x13,
  0x22,
  0x32,
  0x81,
  0x08,
  0x14,
  0x42,
  0x91,
  0xa1,
  0xb1,
  0xc1,
  0x09,
  0x23,
  0x33,
  0x52,
  0xf0,
  0x15,
  0x62,
  0x72,
  0xd1,
  0x0a,
  0x16,
  0x24,
  0x34,
  0xe1,
  0x25,
  0xf1,
  0x17,
  0x18,
  0x19,
  0x1a,
  0x26,
  0x27,
  0x28,
  0x29,
  0x2a,
  0x35,
  0x36,
  0x37,
  0x38,
  0x39,
  0x3a,
  0x43,
  0x44,
  0x45,
  0x46,
  0x47,
  0x48,
  0x49,
  0x4a,
  0x53,
  0x54,
  0x55,
  0x56,
  0x57,
  0x58,
  0x59,
  0x5a,
  0x63,
  0x64,
  0x65,
  0x66,
  0x67,
  0x68,
  0x69,
  0x6a,
  0x73,
  0x74,
  0x75,
  0x76,
  0x77,
  0x78,
  0x79,
  0x7a,
  0x82,
  0x83,
  0x84,
  0x85,
  0x86,
  0x87,
  0x88,
  0x89,
  0x8a,
  0x92,
  0x93,
  0x94,
  0x95,
  0x96,
  0x97,
  0x98,
  0x99,
  0x9a,
  0xa2,
  0xa3,
  0xa4,
  0xa5,
  0xa6,
  0xa7,
  0xa8,
  0xa9,
  0xaa,
  0xb2,
  0xb3,
  0xb4,
  0xb5,
  0xb6,
  0xb7,
  0xb8,
  0xb9,
  0xba,
  0xc2,
  0xc3,
  0xc4,
  0xc5,
  0xc6,
  0xc7,
  0xc8,
  0xc9,
  0xca,
  0xd2,
  0xd3,
  0xd4,
  0xd5,
  0xd6,
  0xd7,
  0xd8,
  0xd9,
  0xda,
  0xe2,
  0xe3,
  0xe4,
  0xe5,
  0xe6,
  0xe7,
  0xe8,
  0xe9,
  0xea,
  0xf2,
  0xf3,
  0xf4,
  0xf5,
  0xf6,
  0xf7,
  0xf8,
  0xf9,
  0xfa,
];
