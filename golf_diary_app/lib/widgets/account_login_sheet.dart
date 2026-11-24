import 'package:flutter/material.dart';

import '../services/account_auth_controller.dart';
import '../services/account_link_conflict.dart';
import '../services/sync_identity.dart';
import 'account_link_conflict_dialog.dart';
import 'diary_sync_runner.dart';

Future<bool?> showAccountLoginSheet(BuildContext context) async {
  final signedIn = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const AccountLoginSheet(),
  );
  if (signedIn == true && context.mounted) {
    await acknowledgeAccountSignIn(context);
  }
  return signedIn;
}

/// Snackbar after the sheet closes, then a sync when the account can upload.
Future<void> acknowledgeAccountSignIn(BuildContext context) async {
  final session = AccountAuthController.instance.session;
  final messenger = ScaffoldMessenger.of(context);
  final canSyncNow = session.canPushToCloud && SyncIdentity.canSync;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        canSyncNow
            ? 'Signed in. Syncing your diary…'
            : 'Signed in. Your diary is ready to sync.',
      ),
    ),
  );
  if (!canSyncNow || !context.mounted) return;
  await runDiarySync(context, session: session);
}

class AccountLoginSheet extends StatefulWidget {
  const AccountLoginSheet({super.key});

  @override
  State<AccountLoginSheet> createState() => _AccountLoginSheetState();
}

class _AccountLoginSheetState extends State<AccountLoginSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _createAccount = false;
  bool _busy = false;
  bool _googlePending = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _withBusy(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _googlePending = true;
      _busy = true;
      _error = null;
    });
    try {
      final err = await AccountAuthController.instance.signInWithGoogle();
      if (!mounted) return;
      if (isSignInCancelled(err)) {
        setState(() => _googlePending = false);
        return;
      }
      if (err != null && !isAccountLinkConflict(err)) {
        setState(() {
          _googlePending = false;
          _error = err;
        });
        return;
      }
      await _finishSignIn(err);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _emailSubmit() async {
    await _withBusy(() async {
      final err = await AccountAuthController.instance.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        createAccount: _createAccount,
      );
      await _finishSignIn(err);
    });
  }

  Future<void> _finishSignIn(String? err) async {
    if (!mounted) return;
    if (isAccountLinkConflict(err)) {
      await _resolveLinkConflict();
      return;
    }
    if (isSignInCancelled(err)) return;
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _resolveLinkConflict() async {
    final prompt =
        await AccountAuthController.instance.loadLinkConflictPrompt();
    if (!mounted) return;
    if (prompt.signInError != null) {
      setState(() => _error = prompt.signInError);
      return;
    }
    if (!prompt.needsDialog) {
      Navigator.of(context).pop(true);
      return;
    }
    final choice = await showAccountLinkConflictDialog(context, prompt);
    if (!mounted) return;
    if (choice == null || choice == AccountLinkChoice.cancel) {
      await AccountAuthController.instance.cancelLinkConflict();
      return;
    }
    String? message;
    if (choice == AccountLinkChoice.uploadFirst) {
      message =
          await AccountAuthController.instance.resolveLinkConflictUploadFirst();
    } else if (choice == AccountLinkChoice.downloadAndSync) {
      message =
          await AccountAuthController.instance.resolveLinkConflictDownload();
    } else if (choice == AccountLinkChoice.replaceLocal) {
      final confirmed = await confirmReplaceLocalDiary(context);
      if (!mounted) return;
      if (!confirmed) {
        Navigator.of(context).pop(true);
        return;
      }
      message = await AccountAuthController.instance
          .resolveLinkConflictReplaceLocal();
    }
    if (!mounted) return;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
    Navigator.of(context).pop(true);
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first.');
      return;
    }
    await _withBusy(() async {
      final err = await AccountAuthController.instance.sendPasswordReset(email);
      if (!mounted) return;
      if (err != null) {
        setState(() => _error = err);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    if (_googlePending) {
      return Padding(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
        child: const Column(
          key: Key('account-login-google-waiting'),
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12),
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Signing you in with Google…',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Finish in the Google window. This form stays hidden until you come back.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _createAccount ? 'Create account' : 'Sign in',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in to back up and open your diary on another phone or the web app.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('account-login-google'),
            onPressed: _busy ? null : _google,
            icon: const Icon(Icons.g_mobiledata, size: 28),
            label: const Text('Continue with Google'),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('account-login-email'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('account-login-password'),
            controller: _passwordController,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('account-login-submit'),
            onPressed: _busy ? null : _emailSubmit,
            child: Text(_createAccount ? 'Create account' : 'Sign in'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() => _createAccount = !_createAccount),
            child: Text(
              _createAccount
                  ? 'Already have an account? Sign in'
                  : 'New here? Create account',
            ),
          ),
          TextButton(
            onPressed: _busy ? null : _forgotPassword,
            child: const Text('Forgot password'),
          ),
        ],
      ),
    );
  }
}
