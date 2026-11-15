import 'package:flutter/material.dart';

import '../services/account_auth_controller.dart';

Future<bool?> showAccountLoginSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const AccountLoginSheet(),
  );
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
    await _withBusy(() async {
      final err = await AccountAuthController.instance.signInWithGoogle();
      if (!mounted) return;
      if (isAccountLinkConflict(err)) {
        Navigator.of(context).pop();
        await _showLinkConflictDialog();
        return;
      }
      if (err != null) {
        setState(() => _error = err);
        return;
      }
      Navigator.of(context).pop(true);
    });
  }

  Future<void> _emailSubmit() async {
    await _withBusy(() async {
      final err = await AccountAuthController.instance.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        createAccount: _createAccount,
      );
      if (!mounted) return;
      if (isAccountLinkConflict(err)) {
        Navigator.of(context).pop();
        await _showLinkConflictDialog();
        return;
      }
      if (err != null) {
        setState(() => _error = err);
        return;
      }
      Navigator.of(context).pop(true);
    });
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

  Future<void> _showLinkConflictDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Account already exists'),
        content: const Text(
          'That Google or email account already has a diary in the cloud. '
          'Choose how to combine it with this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('account-conflict-upload-first'),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final msg =
                  await AccountAuthController.instance.resolveLinkConflictUploadFirst();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg ?? 'Upload flow coming soon.'),
                ),
              );
            },
            child: const Text('Upload this device, then download'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
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