import 'package:flutter/material.dart';

enum SaveRoundBeforeNewChoice {
  saveAndStartNew,
  discard,
  cancel,
}

/// Asks whether to keep the in-progress round before starting another.
Future<SaveRoundBeforeNewChoice?> showSaveRoundBeforeNewDialog({
  required BuildContext context,
  required String courseName,
}) {
  return showDialog<SaveRoundBeforeNewChoice>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Save this round?'),
        content: Text(
          'You have play in progress at $courseName. Save it to your scorecard '
          'history before starting a new round, or discard it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, SaveRoundBeforeNewChoice.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, SaveRoundBeforeNewChoice.discard),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, SaveRoundBeforeNewChoice.saveAndStartNew),
            child: const Text('Save & start new'),
          ),
        ],
      );
    },
  );
}
