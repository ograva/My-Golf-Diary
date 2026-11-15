import 'package:flutter/material.dart';

import '../screens/account_profile_screen.dart';
import '../screens/account_sync_settings_screen.dart';
import '../services/account_auth_controller.dart';
import 'account_login_sheet.dart';
import 'diary_sync_runner.dart';

/// Account avatar replacing the legacy cloud sync icon (SYNC-005).
class AccountAvatarAppBarMenu extends StatefulWidget {
  const AccountAvatarAppBarMenu({super.key});

  @override
  State<AccountAvatarAppBarMenu> createState() =>
      _AccountAvatarAppBarMenuState();
}

class _AccountAvatarAppBarMenuState extends State<AccountAvatarAppBarMenu> {
  @override
  void initState() {
    super.initState();
    AccountAuthController.instance.addListener(_rebuild);
  }

  @override
  void dispose() {
    AccountAuthController.instance.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _onLoginOrSignOut() async {
    final session = AccountAuthController.instance.session;
    if (session.isDurableAccount) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sign out?'),
          content: const Text('Your diary stays on this device.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Sign out'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await AccountAuthController.instance.signOut();
      }
      return;
    }
    await showAccountLoginSheet(context);
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AccountProfileScreen()),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AccountSyncSettingsScreen()),
    );
  }

  Future<void> _sync() async {
    final session = AccountAuthController.instance.session;
    await runDiarySync(context, session: session);
  }

  @override
  Widget build(BuildContext context) {
    final session = AccountAuthController.instance.session;
    final durable = session.isDurableAccount;
    Widget avatarChild;
    if (durable && session.photoUrl != null) {
      avatarChild = CircleAvatar(
        backgroundImage: NetworkImage(session.photoUrl!),
      );
    } else if (durable) {
      avatarChild = CircleAvatar(child: Text(session.initials));
    } else {
      avatarChild = const CircleAvatar(child: Icon(Icons.person_outline));
    }

    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 48),
      child: Padding(
        key: const Key('account-avatar-button'),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: avatarChild,
      ),
      onSelected: (value) async {
        switch (value) {
          case 'login':
            await _onLoginOrSignOut();
          case 'sync':
            await _sync();
          case 'profile':
            _openProfile();
          case 'settings':
            _openSettings();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          key: const Key('account-menu-login'),
          value: 'login',
          child: Text(durable ? 'Sign out' : 'Login'),
        ),
        const PopupMenuItem<String>(
          key: Key('account-menu-sync'),
          value: 'sync',
          child: Text('Sync'),
        ),
        const PopupMenuItem<String>(
          key: Key('account-menu-profile'),
          value: 'profile',
          child: Text('Profile'),
        ),
        const PopupMenuItem<String>(
          key: Key('account-menu-settings'),
          value: 'settings',
          child: Text('Settings'),
        ),
      ],
    );
  }
}