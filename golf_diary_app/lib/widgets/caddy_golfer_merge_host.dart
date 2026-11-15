import 'dart:async';

import 'package:flutter/material.dart';

import '../models/caddy_session.dart';
import '../services/caddy_event_applier.dart';
import '../services/caddy_pairing_service.dart';
import '../services/local_database_service.dart';
import 'caddy_connected_banner.dart';

/// Subscribes to caddy round events and merges into golfer SQLite.
class CaddyGolferMergeHost extends StatefulWidget {
  const CaddyGolferMergeHost({
    super.key,
    required this.child,
    this.pairing,
    this.applier,
    this.onSessionChanged,
  });

  final Widget child;
  final CaddyPairingService? pairing;
  final CaddyEventApplier? applier;
  final VoidCallback? onSessionChanged;

  @override
  State<CaddyGolferMergeHost> createState() => _CaddyGolferMergeHostState();
}

class _CaddyGolferMergeHostState extends State<CaddyGolferMergeHost> {
  CaddySessionRecord? _session;
  StreamSubscription<List<CaddyRoundEvent>>? _sub;
  final _db = LocalDatabaseService.instance;

  CaddyPairingService get _pairing => widget.pairing ?? CaddyPairingService();
  CaddyEventApplier get _applier => widget.applier ?? CaddyEventApplier();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final session = await _pairing.getGolferActiveSession();
    if (!mounted) return;
    setState(() => _session = session);
    _attach(session);
  }

  void _attach(CaddySessionRecord? session) {
    _sub?.cancel();
    if (session == null ||
        session.status == CaddySessionStatus.revoked ||
        session.status == CaddySessionStatus.ended) {
      return;
    }
    _sub = _pairing.watchGolferEvents(session).listen((events) async {
      if (events.isEmpty) return;
      var working = session;
      for (final event in events) {
        if (event.type == CaddyEventType.revoke) {
          await _db.updateCaddySessionStatus(
            working.channelId,
            CaddySessionStatus.revoked,
          );
          if (mounted) {
            setState(() => _session = null);
            widget.onSessionChanged?.call();
          }
          return;
        }
        await _applier.apply(
          event,
          courseName: working.courseName,
        );
        await _db.setCaddySessionLastEventMs(
          working.channelId,
          event.updatedAtMs,
        );
        if (event.updatedAtMs > working.lastEventMs) {
          working = working.copyWith(lastEventMs: event.updatedAtMs);
        }
      }
      if (session.status == CaddySessionStatus.pending) {
        await _db.updateCaddySessionStatus(
          session.channelId,
          CaddySessionStatus.active,
        );
        working = working.copyWith(status: CaddySessionStatus.active);
      }
      if (mounted) {
        setState(() => _session = working);
        widget.onSessionChanged?.call();
      }
    });
  }

  Future<void> refreshSession() async {
    await _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_session != null &&
            _session!.status != CaddySessionStatus.revoked &&
            _session!.status != CaddySessionStatus.ended)
          CaddyConnectedBanner(
            session: _session!,
            pairing: _pairing,
            onRevoked: () {
              setState(() => _session = null);
              widget.onSessionChanged?.call();
            },
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}