import 'package:flutter/material.dart';

import 'caddy_invite_sheet.dart';

/// QR invite for an active round (On Course + Scorecard only).
class CaddyInviteIconButton extends StatelessWidget {
  const CaddyInviteIconButton({
    super.key,
    required this.valueKey,
    required this.roundId,
    required this.courseName,
  });

  final String valueKey;
  final String roundId;
  final String courseName;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: ValueKey(valueKey),
      tooltip: 'Invite caddy',
      onPressed: () => showCaddyInviteSheet(
        context,
        roundId: roundId,
        courseName: courseName,
      ),
      icon: const Icon(Icons.qr_code_2),
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    );
  }
}