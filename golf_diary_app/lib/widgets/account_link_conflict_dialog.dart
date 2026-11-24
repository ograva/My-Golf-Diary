import 'package:flutter/material.dart';

import '../services/account_link_conflict.dart';

Future<AccountLinkChoice?> showAccountLinkConflictDialog(
  BuildContext context,
  ConflictPrompt prompt,
) {
  return showDialog<AccountLinkChoice>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(prompt.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(prompt.body),
          const SizedBox(height: 16),
          if (prompt.offerUpload)
            TextButton(
              key: const Key('account-conflict-upload-first'),
              onPressed: () => Navigator.of(dialogContext)
                  .pop(AccountLinkChoice.uploadFirst),
              child: const Text('Upload this device, then download'),
            ),
          TextButton(
            key: const Key('account-conflict-download-sync'),
            onPressed: () => Navigator.of(dialogContext)
                .pop(AccountLinkChoice.downloadAndSync),
            child: const Text('Download and sync'),
          ),
          if (prompt.offerReplace)
            TextButton(
              key: const Key('account-conflict-replace-local'),
              onPressed: () => Navigator.of(dialogContext)
                  .pop(AccountLinkChoice.replaceLocal),
              child: const Text('Replace this device with the account'),
            ),
          TextButton(
            key: const Key('account-conflict-cancel'),
            onPressed: () =>
                Navigator.of(dialogContext).pop(AccountLinkChoice.cancel),
            child: const Text('Cancel'),
          ),
        ],
      ),
    ),
  );
}

/// Second confirm before local-only rows are removed.
Future<bool> confirmReplaceLocalDiary(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Replace this device?'),
      content: const Text(
        'The account has diary entries. Rows that exist only on this device '
        'will be removed.',
      ),
      actions: [
        TextButton(
          key: const Key('account-conflict-replace-cancel'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep this device'),
        ),
        FilledButton(
          key: const Key('account-conflict-replace-confirm'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Replace this device'),
        ),
      ],
    ),
  );
  return confirmed == true;
}
