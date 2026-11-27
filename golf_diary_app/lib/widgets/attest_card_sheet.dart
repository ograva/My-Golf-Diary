import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/scoring_format.dart';
import '../services/attest_card_image.dart';
import '../services/personal_attestation.dart';

/// Name, role, a required signature, and an optional front-camera selfie.
class AttestCardSheet extends StatefulWidget {
  const AttestCardSheet({
    super.key,
    required this.roundId,
    required this.afterFinish,
    this.manualIndex,
  });

  final String roundId;
  final bool afterFinish;
  final double? manualIndex;

  @override
  State<AttestCardSheet> createState() => _AttestCardSheetState();
}

class _AttestCardSheetState extends State<AttestCardSheet> {
  final _name = TextEditingController(text: 'Me');
  final _strokes = <List<Offset>>[];
  var _role = 'self';
  Uint8List? _selfie;
  Size? _selfieSize;
  var _saving = false;
  Size _padSize = const Size(320, 180);

  bool get _hasStroke => _strokes.any((stroke) => stroke.isNotEmpty);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _takeSelfie() async {
    try {
      final shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (shot == null || !mounted) return;
      final bytes = await shot.readAsBytes();
      final size = await decodeImageSize(bytes);
      if (!mounted) return;
      setState(() {
        _selfie = bytes;
        _selfieSize = size;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera unavailable. Sign the card to attest.'),
        ),
      );
    }
  }

  Future<void> _openSignaturePad() async {
    final size = await showDialog<Size>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SignaturePadDialog(
        strokes: _strokes,
        padSize: _hasStroke ? _padSize : Size.zero,
        onChanged: () {
          if (mounted) setState(() {});
        },
      ),
    );
    if (!mounted || size == null || size.width <= 0 || size.height <= 0) {
      return;
    }
    setState(() => _padSize = size);
  }

  Future<void> _commit() async {
    setState(() => _saving = true);
    try {
      final width = 900;
      final height = math.max(
        1,
        (width * _padSize.height / math.max(_padSize.width, 1)).round(),
      );
      final signature = await renderSignaturePng(
        _strokes,
        _padSize,
        width: width,
        height: height,
      );
      Uint8List? selfie;
      Uint8List? combined;
      if (_selfie != null) {
        selfie = await limitSelfieJpeg(_selfie!);
        combined = await compositeSignatureOnSelfie(
          selfie: selfie,
          signature: signature,
        );
      }
      await PersonalAttestation.save(
        roundId: widget.roundId,
        name: _name.text,
        role: _role,
        signaturePng: signature,
        selfieJpeg: selfie,
        combinedJpeg: combined,
        manualIndex: widget.manualIndex,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the attestation.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SizedBox(
              width: constraints.maxWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Attest card',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const ValueKey('scorecard-attest-name'),
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    key: const ValueKey('scorecard-attest-role'),
                    value: _role,
                    isExpanded: true,
                    items: [
                      for (final item in attestRoles)
                        DropdownMenuItem(value: item, child: Text(item)),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _role = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Signature',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    key: const ValueKey('scorecard-attest-signature'),
                    onPressed: _openSignaturePad,
                    icon: const Icon(Icons.draw_outlined),
                    label: Text(_hasStroke ? 'Edit signature' : 'Sign'),
                  ),
                  if (_selfie == null)
                    OutlinedButton.icon(
                      key: const ValueKey('scorecard-attest-selfie'),
                      onPressed: _takeSelfie,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Take selfie'),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const ValueKey(
                                'scorecard-attest-selfie-retake'),
                            onPressed: _takeSelfie,
                            child: const Text('Retake'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            key: const ValueKey(
                                'scorecard-attest-selfie-remove'),
                            onPressed: () => setState(() {
                              _selfie = null;
                              _selfieSize = null;
                            }),
                            child: const Text('Remove'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Preview',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  _Preview(
                    key: const ValueKey('scorecard-attest-preview'),
                    selfie: _selfie,
                    selfieSize: _selfieSize,
                    strokes: _strokes,
                    padSize: _padSize,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    key: const ValueKey('scorecard-attest-skip'),
                    onPressed:
                        _saving ? null : () => Navigator.pop(context, false),
                    child: Text(widget.afterFinish ? 'Skip' : 'Cancel'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const ValueKey('scorecard-attest-save'),
                    onPressed: _hasStroke && !_saving ? _commit : null,
                    child: const Text('Attest'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    super.key,
    required this.selfie,
    required this.selfieSize,
    required this.strokes,
    required this.padSize,
  });

  final Uint8List? selfie;
  final Size? selfieSize;
  final List<List<Offset>> strokes;
  final Size padSize;

  @override
  Widget build(BuildContext context) {
    if (selfie == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black26),
        ),
        child: SizedBox(
          height: 80,
          width: double.infinity,
          child: CustomPaint(
            painter: _SignaturePainter(strokes, source: padSize),
          ),
        ),
      );
    }
    final photo = selfieSize;
    if (photo == null) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const maxH = 180.0;
        final fitted = applyBoxFit(
          BoxFit.contain,
          photo,
          Size(constraints.maxWidth, maxH),
        ).destination;
        final band = signatureOverlayRect(fitted, padSize);
        return Center(
          child: SizedBox(
            width: fitted.width,
            height: fitted.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.memory(selfie!, fit: BoxFit.fill),
                ),
                Positioned.fromRect(
                  rect: band,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: kSignatureOverlayGround,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomPaint(
                      painter: _SignaturePainter(strokes, source: padSize),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SignaturePadDialog extends StatefulWidget {
  const _SignaturePadDialog({
    required this.strokes,
    required this.padSize,
    required this.onChanged,
  });

  final List<List<Offset>> strokes;

  /// Size [strokes] were drawn at, or zero when there are none yet.
  final Size padSize;
  final VoidCallback onChanged;

  @override
  State<_SignaturePadDialog> createState() => _SignaturePadDialogState();
}

class _SignaturePadDialogState extends State<_SignaturePadDialog> {
  late Size _padSize = widget.padSize;

  bool get _hasStroke => widget.strokes.any((stroke) => stroke.isNotEmpty);

  /// Strokes follow the pad when it resizes (e.g. on rotation); the aspect is
  /// fixed, so one scale factor keeps the signature intact.
  void _resizeTo(Size size) {
    if (size.width <= 0 || size.height <= 0 || size == _padSize) return;
    if (_padSize.width > 0) {
      final scale = size.width / _padSize.width;
      for (final stroke in widget.strokes) {
        for (var i = 0; i < stroke.length; i++) {
          stroke[i] = stroke[i] * scale;
        }
      }
    }
    _padSize = size;
  }

  void _changed() {
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Signature',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('scorecard-attest-signature-clear'),
                    onPressed: _hasStroke
                        ? () {
                            widget.strokes.clear();
                            _changed();
                          }
                        : null,
                    child: const Text('Clear'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, _padSize),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final pad = signaturePadRect(
                      Size(constraints.maxWidth, constraints.maxHeight),
                    );
                    _resizeTo(pad.size);
                    final portrait =
                        constraints.maxHeight > constraints.maxWidth;
                    return Stack(
                      children: [
                        Positioned.fromRect(
                          rect: pad,
                          child: Listener(
                            key: const ValueKey(
                                'scorecard-attest-signature-pad'),
                            onPointerDown: (event) {
                              widget.strokes.add([event.localPosition]);
                              _changed();
                            },
                            onPointerMove: (event) {
                              if (widget.strokes.isEmpty) return;
                              widget.strokes.last.add(event.localPosition);
                              _changed();
                            },
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.black26),
                              ),
                              child: CustomPaint(
                                key: const ValueKey(
                                    'scorecard-attest-signature-guide'),
                                painter: const _SignatureGuidePainter(),
                                foregroundPainter:
                                    _SignaturePainter(widget.strokes),
                                child: const SizedBox.expand(),
                              ),
                            ),
                          ),
                        ),
                        if (portrait)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: pad.bottom + 12,
                            child: Text(
                              'Rotate your phone for a bigger pad',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pad-only signing line with an "x" at its left; never part of the saved PNG.
class _SignatureGuidePainter extends CustomPainter {
  const _SignatureGuidePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * 0.72;
    final left = size.width * 0.08;
    final right = size.width * 0.92;
    final line = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(left, y), Offset(right, y), line);
    final x = (size.height * 0.05).clamp(5.0, 12.0);
    final cx = left + x;
    final cy = y - x - 6;
    final mark = Paint()
      ..color = Colors.black38
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - x, cy - x), Offset(cx + x, cy + x), mark);
    canvas.drawLine(Offset(cx - x, cy + x), Offset(cx + x, cy - x), mark);
  }

  @override
  bool shouldRepaint(covariant _SignatureGuidePainter oldDelegate) => false;
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.strokes, {this.source = Size.zero});

  final List<List<Offset>> strokes;
  final Size source;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = source.width <= 0 ? 1.0 : size.width / source.width;
    final sy = source.height <= 0 ? 1.0 : size.height / source.height;
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(
          Offset(stroke.first.dx * sx, stroke.first.dy * sy),
          1.5,
          Paint()..color = Colors.black,
        );
        continue;
      }
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx * sx, stroke.first.dy * sy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx * sx, point.dy * sy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
