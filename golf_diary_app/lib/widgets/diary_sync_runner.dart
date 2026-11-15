import 'package:flutter/material.dart';

import '../services/account_session.dart';
import '../services/cloud_sync_service.dart';
import '../services/sync_identity.dart';

/// Manual pull-then-push used by the account menu and settings.
Future<void> runDiarySync(
  BuildContext context, {
  required AccountSession session,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  if (!SyncIdentity.canSync) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Firebase not configured — local data is saved on device',
        ),
      ),
    );
    return;
  }
  if (!session.isDurableAccount) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Sign in to save your diary to the cloud.'),
      ),
    );
    return;
  }
  final uid = session.uid;
  if (uid == null) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Sign in to sync.')),
    );
    return;
  }
  if (!session.canPushToCloud) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Verify your email before the first cloud upload. Pull still works after you verify.',
        ),
      ),
    );
    // Allow pull-only when unverified
    final pullOnly = CloudSyncService(userId: uid);
    final pulled = await pullOnly.pullAll();
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('Pulled $pulled rows. Verify email to upload.')),
    );
    return;
  }
  final result = await CloudSyncService(userId: uid).syncFull();
  if (!context.mounted) return;
  final failure = result.failed == 0 ? '' : ' ${result.failed} failed.';
  messenger.showSnackBar(
    SnackBar(
      content: Text('Synced ${result.pulled} down, ${result.pushed} up.$failure'),
    ),
  );
}