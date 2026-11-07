import 'package:flutter/material.dart';

import '../services/cloud_sync_service.dart';
import '../services/sync_identity.dart';

class SyncCloudButton extends StatelessWidget {
  const SyncCloudButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('sync-cloud-button'),
      tooltip: 'Sync',
      onPressed: () => runDiarySync(context),
      icon: const Icon(Icons.cloud_sync_outlined),
    );
  }
}

Future<void> runDiarySync(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  if (!SyncIdentity.canSync) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Firebase not configured — local data is saved on device')),
    );
    return;
  }
  final userId = await SyncIdentity.ensureSignedIn();
  if (userId == null) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Firebase not configured — local data is saved on device')),
    );
    return;
  }
  final result = await CloudSyncService(userId: userId).syncFull();
  if (!context.mounted) return;
  final failure = result.failed == 0 ? '' : ' ${result.failed} failed.';
  messenger.showSnackBar(
    SnackBar(content: Text('Synced ${result.pulled} down, ${result.pushed} up.$failure')),
  );
}
