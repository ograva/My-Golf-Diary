import 'package:flutter/material.dart';

import '../models/golf_models.dart';
import '../models/scoring_format.dart';
import '../services/local_database_service.dart';

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

/// Attestation name/role dialog. Returns true when the card was attested.
/// With [afterFinish] the dismiss action reads Skip; the round stays finished.
Future<bool> showAttestCardDialog(
  BuildContext context, {
  required String roundId,
  bool afterFinish = false,
}) async {
  final saved = await showDialog<({String name, String role})>(
    context: context,
    builder: (context) => _AttestDialog(afterFinish: afterFinish),
  );
  if (saved == null) return false;
  await LocalDatabaseService.instance.attestRound(
    roundId: roundId,
    name: saved.name,
    role: saved.role,
  );
  return true;
}

class _AttestDialog extends StatefulWidget {
  const _AttestDialog({required this.afterFinish});

  final bool afterFinish;

  @override
  State<_AttestDialog> createState() => _AttestDialogState();
}

class _AttestDialogState extends State<_AttestDialog> {
  final _name = TextEditingController(text: 'Me');
  var _role = 'self';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Attest card'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('scorecard-attest-skip'),
          onPressed: () => Navigator.pop(context),
          child: Text(widget.afterFinish ? 'Skip' : 'Cancel'),
        ),
        FilledButton(
          key: const ValueKey('scorecard-attest-save'),
          onPressed: () =>
              Navigator.pop(context, (name: _name.text, role: _role)),
          child: const Text('Attest'),
        ),
      ],
    );
  }
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
