import 'package:flutter/material.dart';

import '../services/account_auth_controller.dart';
import '../widgets/account_login_sheet.dart';

class AccountProfileScreen extends StatefulWidget {
  const AccountProfileScreen({super.key});

  @override
  State<AccountProfileScreen> createState() => _AccountProfileScreenState();
}

class _AccountProfileScreenState extends State<AccountProfileScreen> {
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

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Your diary stays on this device. Sign in again to sync.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('account-profile-sign-out'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await AccountAuthController.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final session = AccountAuthController.instance.session;
    return Scaffold(
      appBar: AppBar(title: const Text('Account profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (!session.isDurableAccount) ...[
            const Text(
              'Your diary is saved on this device only until you sign in.',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => showAccountLoginSheet(context),
              child: const Text('Sign in'),
            ),
          ] else ...[
            CircleAvatar(
              radius: 36,
              backgroundImage:
                  session.photoUrl != null ? NetworkImage(session.photoUrl!) : null,
              child: session.photoUrl == null
                  ? Text(session.initials, style: const TextStyle(fontSize: 24))
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              session.displayName ?? session.email ?? 'Account',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (session.email != null) Text(session.email!),
            const SizedBox(height: 8),
            Text('Provider: ${session.providerLabel}'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _signOut,
              child: const Text('Sign out'),
            ),
          ],
        ],
      ),
    );
  }
}