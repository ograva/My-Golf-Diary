import 'package:flutter/material.dart';

import '../models/golf_models.dart';
import '../services/attest_pdf_fetch.dart';
import 'attest_card_sheet.dart';

/// Holes 1..[holeCount] with no score, strokes, or gimme.
/// [finishingHole] counts as scored because Finish Hole records it.
int blankHoleCount(
  List<RoundScore> holes,
  int holeCount, {
  int? finishingHole,
}) {
  var blank = 0;
  for (var hole = 1; hole <= holeCount; hole++) {
    if (hole == finishingHole) continue;
    final row = holes.where((h) => h.holeNumber == hole).firstOrNull;
    if (row == null || !isHolePlayed(row)) blank += 1;
  }
  return blank;
}

/// True when the round may finish. Asks first only when holes are blank.
Future<bool> confirmFinishRound(BuildContext context, int blankHoles) async {
  if (blankHoles <= 0) return true;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Finish round?'),
      content: Text(
        '$blankHoles ${blankHoles == 1 ? 'hole' : 'holes'} blank, finish anyway?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('scorecard-finish-confirm'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Finish'),
        ),
      ],
    ),
  );
  return ok == true;
}

/// Attestation sheet. Returns true when the card was attested.
/// With [afterFinish] the dismiss action reads Skip; the round stays finished.
/// A returned PDF is stored for [scorecard-attest-pdf-link]. Offline leaves
/// that link hidden and tells the golfer the PDF will be ready when online.
Future<bool> showAttestCardDialog(
  BuildContext context, {
  required String roundId,
  bool afterFinish = false,
  double? manualIndex,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => AttestCardSheet(
      roundId: roundId,
      afterFinish: afterFinish,
      manualIndex: manualIndex,
    ),
  );
  if (saved != true) return false;
  final ready = await AttestPdfFetch.tryFetch(roundId);
  if (!ready && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The PDF will be ready when online.'),
      ),
    );
  }
  return true;
}

/// Delete always confirms. Attested or flight rounds get a stronger warning.
Future<bool> confirmDeleteRound(
  BuildContext context, {
  required String courseName,
  required bool attested,
  required bool inFlight,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final warnings = [
    if (attested) 'This card is attested. The attestation is deleted with it.',
    if (inFlight)
      'This round is shared with a flight. Partners keep any card you published.',
  ];
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete round?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deletes $courseName and its shots from this device and every synced device. This cannot be undone.',
          ),
          for (final warning in warnings) ...[
            const SizedBox(height: 12),
            Text(
              warning,
              key: const ValueKey('scorecard-delete-warning'),
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('scorecard-delete-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return ok == true;
}
