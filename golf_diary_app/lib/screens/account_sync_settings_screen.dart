import 'package:flutter/material.dart';

import '../services/account_auth_controller.dart';
import '../services/golfer_profile_store.dart';
import '../services/local_database_service.dart';
import '../services/sync_constants.dart';
import '../services/sync_identity.dart';
import 'golfer_profile_settings_screen.dart';
import '../widgets/diary_sync_runner.dart';
import '../widgets/golfer_avatar_circle.dart';

class AccountSyncSettingsScreen extends StatefulWidget {
  const AccountSyncSettingsScreen({super.key});

  @override
  State<AccountSyncSettingsScreen> createState() =>
      _AccountSyncSettingsScreenState();
}

class _AccountSyncSettingsScreenState extends State<AccountSyncSettingsScreen> {
  int _dirtyCount = 0;
  int _lastPulledMs = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AccountAuthController.instance.addListener(_rebuild);
    _refreshStats();
  }

  @override
  void dispose() {
    AccountAuthController.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshStats() async {
    final db = LocalDatabaseService.instance;
    var dirty = 0;
    for (final table in kSyncTables) {
      dirty += (await db.getUnsynced(table)).length;
    }
    final pulled = await db.getLastPulledAt();
    if (!mounted) return;
    setState(() {
      _dirtyCount = dirty;
      _lastPulledMs = pulled;
      _loading = false;
    });
  }

  String _formatLastSync() {
    if (_lastPulledMs <= 0) return 'Never';
    final dt = DateTime.fromMillisecondsSinceEpoch(_lastPulledMs).toLocal();
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openGolferProfile() async {
    final store = GolferProfileScope.maybeOf(context);
    if (store == null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => const GolferProfileSettingsScreen(),
        ),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GolferProfileSettingsScreen(
          initialProfile: store.profile,
        ),
      ),
    );
    await store.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final session = AccountAuthController.instance.session;
    final firebaseOk = SyncIdentity.canSync;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Cloud backup', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Firebase: ${firebaseOk ? 'Available' : 'Not configured'}'),
                Text(
                  'Signed in: ${session.isDurableAccount ? (session.email ?? session.displayName ?? 'Yes') : 'Not signed in'}',
                ),
                Text('Last successful pull: ${_formatLastSync()}'),
                Text('Rows waiting to upload: $_dirtyCount'),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('account-settings-sync-now'),
                  onPressed: () async {
                    await runDiarySync(context, session: session);
                    await _refreshStats();
                  },
                  child: const Text('Sync now'),
                ),
                if (session.isDurableAccount &&
                    session.isEmailPasswordAccount &&
                    !session.isEmailVerified) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () async {
                      final err =
                          await AccountAuthController.instance.sendEmailVerification();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            err ?? 'Verification email sent. Check your inbox.',
                          ),
                        ),
                      );
                    },
                    child: const Text('Send verification email'),
                  ),
                ],
                const Divider(height: 32),
                Text(
                  'Golfer skill profile (this device)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GolferAvatarCircle(session: session, radius: 28),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Skill tier, avatar, and coaching baseline stay in SQLite and are not part of cloud account profile.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  key: const ValueKey('settings-golfer-profile-entry'),
                  onPressed: _openGolferProfile,
                  child: const Text('Edit golfer profile'),
                ),
              ],
            ),
    );
  }
}