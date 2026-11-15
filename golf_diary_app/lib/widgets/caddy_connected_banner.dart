import 'package:flutter/material.dart';

import '../models/caddy_session.dart';
import '../services/caddy_pairing_service.dart';

class CaddyConnectedBanner extends StatelessWidget {
  const CaddyConnectedBanner({
    super.key,
    required this.session,
    required this.onRevoked,
    this.pairing,
  });

  final CaddySessionRecord session;
  final VoidCallback onRevoked;
  final CaddyPairingService? pairing;

  @override
  Widget build(BuildContext context) {
    final label = session.status == CaddySessionStatus.pending
        ? 'Waiting for caddy to scan QR…'
        : 'Caddy connected';

    return MaterialBanner(
      key: const ValueKey('caddy-connected-banner'),
      content: Text(label),
      leading: Icon(
        session.status == CaddySessionStatus.active
            ? Icons.link
            : Icons.qr_code_scanner,
      ),
      actions: [
        TextButton(
          key: const ValueKey('caddy-revoke-btn'),
          onPressed: () async {
            final service = pairing ?? CaddyPairingService();
            await service.revokeSession(session.channelId);
            onRevoked();
          },
          child: const Text('Revoke'),
        ),
      ],
    );
  }
}