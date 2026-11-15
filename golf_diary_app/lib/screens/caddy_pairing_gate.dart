import 'package:flutter/material.dart';

import '../services/caddy_launch_config.dart';
import '../services/caddy_pairing_service.dart';
import 'caddy_shell.dart';

/// Validates `?mode=caddy&request=` and opens the two-tab caddy shell.
class CaddyPairingGate extends StatefulWidget {
  const CaddyPairingGate({
    super.key,
    required this.requestToken,
    this.pairing,
  });

  final String requestToken;
  final CaddyPairingService? pairing;

  @override
  State<CaddyPairingGate> createState() => _CaddyPairingGateState();
}

class _CaddyPairingGateState extends State<CaddyPairingGate> {
  bool _loading = true;
  String? _error;

  CaddyPairingService get _pairing => widget.pairing ?? CaddyPairingService();

  @override
  void initState() {
    super.initState();
    _redeem();
  }

  Future<void> _redeem() async {
    final session = await _pairing.redeemInvite(widget.requestToken);
    if (!mounted) return;
    if (session == null) {
      setState(() {
        _loading = false;
        _error = 'This QR link is invalid, expired, or already used.';
      });
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => CaddyShell(session: session, pairing: _pairing),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error ?? 'Unable to open caddy session.',
              key: const ValueKey('caddy-pairing-error'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

Future<Widget?> buildCaddyLaunchRoot(CaddyPairingService? pairing) async {
  final config = CaddyLaunchConfig.currentPlatformLaunch();
  if (config == null) return null;
  return CaddyPairingGate(
    requestToken: config.requestToken,
    pairing: pairing,
  );
}