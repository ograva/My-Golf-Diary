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
  var _saving = false;
  Size _padSize = const Size(300, 120);

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
      if (!mounted) return;
      setState(() => _selfie = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera unavailable. Sign the card to attest.'),
        ),
      );
    }
  }

  Future<void> _commit() async {
    setState(() => _saving = true);
    try {
      final signature = await renderSignaturePng(_strokes, _padSize);
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      _padSize = Size(constraints.maxWidth, 140);
                      return Listener(
                        key: const ValueKey('scorecard-attest-signature'),
                        onPointerDown: (event) {
                          setState(() => _strokes.add([event.localPosition]));
                        },
                        onPointerMove: (event) {
                          if (_strokes.isEmpty) return;
                          setState(
                              () => _strokes.last.add(event.localPosition));
                        },
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black26),
                          ),
                          child: SizedBox(
                            height: 140,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _SignaturePainter(_strokes),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const ValueKey('scorecard-attest-signature-clear'),
                      onPressed:
                          _hasStroke ? () => setState(_strokes.clear) : null,
                      child: const Text('Clear'),
                    ),
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
                            onPressed: () => setState(() => _selfie = null),
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
                    strokes: _strokes,
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
  const _Preview({super.key, required this.selfie, required this.strokes});

  final Uint8List? selfie;
  final List<List<Offset>> strokes;

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
          child: CustomPaint(painter: _SignaturePainter(strokes)),
        ),
      );
    }
    return SizedBox(
      height: 180,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(selfie!, fit: BoxFit.contain),
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: 0.22,
              widthFactor: 0.84,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xD9FFFFFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(painter: _SignaturePainter(strokes)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 1.5, Paint()..color = Colors.black);
        continue;
      }
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
