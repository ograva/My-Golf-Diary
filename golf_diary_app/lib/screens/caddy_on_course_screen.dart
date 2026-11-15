import 'package:flutter/material.dart';

import '../data/ph_golf_catalog.dart';
import '../models/caddy_session.dart';
import '../services/caddy_pairing_service.dart';
import '../services/local_database_service.dart';
import '../services/sync_identity.dart';

class CaddyOnCourseScreen extends StatefulWidget {
  const CaddyOnCourseScreen({
    super.key,
    required this.session,
    this.pairing,
  });

  final CaddySessionRecord session;
  final CaddyPairingService? pairing;

  @override
  State<CaddyOnCourseScreen> createState() => _CaddyOnCourseScreenState();
}

class _CaddyOnCourseScreenState extends State<CaddyOnCourseScreen> {
  int _hole = 1;
  int _strokes = 0;
  bool _busy = false;

  CaddyPairingService get _pairing => widget.pairing ?? CaddyPairingService();

  @override
  void initState() {
    super.initState();
    _loadHole();
  }

  Future<void> _loadHole() async {
    final hole = await LocalDatabaseService.instance.getHoleScore(
      widget.session.roundId,
      _hole,
    );
    if (!mounted) return;
    setState(() {
      _strokes = hole?.strokes ?? 0;
    });
  }

  int get _par => PhGolfCatalog.parForHole(widget.session.courseName, _hole) ?? 4;

  Future<void> _recordStroke() async {
    setState(() => _busy = true);
    final uid = SyncIdentity.currentUserId ?? 'caddy';
    try {
      await _pairing.publishEvent(
        channelId: widget.session.channelId,
        roundId: widget.session.roundId,
        type: CaddyEventType.strokeAdd,
        holeNumber: _hole,
        authorUid: uid,
      );
      await LocalDatabaseService.instance.recordCaddyStroke(
        roundId: widget.session.roundId,
        holeNumber: _hole,
        courseName: widget.session.courseName,
      );
      await _pairing.flushOfflineQueue(widget.session.channelId);
      await _loadHole();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Queued offline — will sync when online ($e)')),
        );
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _scoreAction(CaddyEventType type) async {
    final uid = SyncIdentity.currentUserId ?? 'caddy';
    try {
      await _pairing.publishEvent(
        channelId: widget.session.channelId,
        roundId: widget.session.roundId,
        type: type,
        holeNumber: _hole,
        authorUid: uid,
      );
      switch (type) {
        case CaddyEventType.penaltyAdd:
          await LocalDatabaseService.instance.incrementPenalties(
            widget.session.roundId,
            _hole,
            1,
          );
        case CaddyEventType.mulliganAdd:
          await LocalDatabaseService.instance.incrementMulligans(
            widget.session.roundId,
            _hole,
          );
        case CaddyEventType.concede:
          await LocalDatabaseService.instance.concedeHole(
            widget.session.roundId,
            _hole,
          );
        default:
          break;
      }
      await _pairing.flushOfflineQueue(widget.session.channelId);
      await _loadHole();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved locally — retrying sync…')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Hole $_hole · Par $_par',
          key: ValueKey('caddy-on-course-hole-$_hole'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          widget.session.courseName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            '$_strokes',
            key: const ValueKey('caddy-on-course-stroke-count'),
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const ValueKey('caddy-on-course-stroke-plus'),
          onPressed: _busy ? null : _recordStroke,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
          child: const Text('+1 stroke'),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: const ValueKey('caddy-on-course-penalty'),
              onPressed: () => _scoreAction(CaddyEventType.penaltyAdd),
              child: const Text('Penalty'),
            ),
            OutlinedButton(
              key: const ValueKey('caddy-on-course-mulligan'),
              onPressed: () => _scoreAction(CaddyEventType.mulliganAdd),
              child: const Text('Mulligan'),
            ),
            OutlinedButton(
              key: const ValueKey('caddy-on-course-gimme'),
              onPressed: () => _scoreAction(CaddyEventType.concede),
              child: const Text('Gimme'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            IconButton(
              key: const ValueKey('caddy-on-course-hole-prev'),
              onPressed: _hole > 1
                  ? () {
                      setState(() => _hole -= 1);
                      _loadHole();
                    }
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            const Spacer(),
            IconButton(
              key: const ValueKey('caddy-on-course-hole-next'),
              onPressed: _hole < 18
                  ? () {
                      setState(() => _hole += 1);
                      _loadHole();
                    }
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}