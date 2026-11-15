import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/caddy_session.dart';
import '../services/caddy_launch_config.dart';
import '../services/caddy_pairing_service.dart';
import '../services/local_database_service.dart';

/// Golfer-initiated single-use QR for caddy PWA pairing.
class CaddyInviteSheet extends StatefulWidget {
  const CaddyInviteSheet({
    super.key,
    required this.roundId,
    required this.courseName,
    this.pairing,
  });

  final String roundId;
  final String courseName;
  final CaddyPairingService? pairing;

  @override
  State<CaddyInviteSheet> createState() => _CaddyInviteSheetState();
}

class _CaddyInviteSheetState extends State<CaddyInviteSheet> {
  CaddySessionRecord? _session;
  String? _error;
  bool _loading = false;

  CaddyPairingService get _pairing => widget.pairing ?? CaddyPairingService();

  @override
  void initState() {
    super.initState();
    _mintOrLoad();
  }

  Future<void> _mintOrLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final existing = await _pairing.getGolferActiveSession();
      if (existing != null && existing.roundId == widget.roundId) {
        _session = existing;
      } else {
        _session = await _pairing.mintInvite(
          roundId: widget.roundId,
          courseName: widget.courseName,
        );
      }
    } catch (e) {
      _error = e.toString();
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final inviteUrl = _session == null
        ? ''
        : CaddyLaunchConfig.buildInviteUrl(_session!.requestToken);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Invite caddy',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan once to open the caddy scoring shell (On Course + Scorecard only).',
            ),
            const SizedBox(height: 16),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (!_loading && _session != null) ...[
              Center(
                child: QrImageView(
                  key: const ValueKey('caddy-invite-qr'),
                  data: inviteUrl,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                inviteUrl,
                key: const ValueKey('caddy-invite-url'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Status: ${_session!.status.name}',
                key: const ValueKey('caddy-invite-status'),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('caddy-invite-close'),
              onPressed: () => Navigator.of(context).pop(_session),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<CaddySessionRecord?> showCaddyInviteSheet(
  BuildContext context, {
  required String roundId,
  required String courseName,
}) async {
  final resolvedCourse = courseName.trim().isEmpty
      ? await LocalDatabaseService.instance.getCourseNameForRound(roundId)
      : courseName;
  if (!context.mounted) return null;
  return showModalBottomSheet<CaddySessionRecord>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => CaddyInviteSheet(
      roundId: roundId,
      courseName: resolvedCourse,
    ),
  );
}