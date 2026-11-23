import 'package:flutter/material.dart';

import '../data/ph_golf_catalog.dart';
import '../models/caddy_session.dart';
import '../models/golf_models.dart';
import '../services/caddy_event_applier.dart';
import '../services/caddy_pairing_service.dart';
import '../services/local_database_service.dart';
import '../services/sync_identity.dart';

/// Scorecard for one golfer, plus hole-score entry when the caddy has a flight.
class CaddyScorecardScreen extends StatefulWidget {
  const CaddyScorecardScreen({
    super.key,
    required this.session,
    this.pairing,
  });

  final CaddySessionRecord session;
  final CaddyPairingService? pairing;

  @override
  State<CaddyScorecardScreen> createState() => _CaddyScorecardScreenState();
}

class _CaddyScorecardScreenState extends State<CaddyScorecardScreen> {
  List<RoundScore> _holes = [];
  List<({String id, String name})> _players = const [
    (id: 'primary', name: 'Golfer'),
  ];
  String _playerId = 'primary';
  int _selectedHole = 1;
  Map<int, int> _otherGross = {};

  CaddyPairingService get _pairing => widget.pairing ?? CaddyPairingService();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final db = LocalDatabaseService.instance;
    final rows = await db.getScoresForRound(widget.session.roundId);
    final extra = await db.listCaddyFlightPlayers(widget.session.channelId);
    final other = _playerId == 'primary'
        ? <int, int>{}
        : await db.caddyPlayerGrossByHole(
            channelId: widget.session.channelId,
            playerId: _playerId,
          );
    if (!mounted) return;
    setState(() {
      _holes = rows;
      _players = [(id: 'primary', name: 'Golfer'), ...extra];
      _otherGross = other;
    });
  }

  Future<void> _addPlayer() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Player'),
        content: TextField(
          key: const ValueKey('caddy-player-name'),
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('caddy-player-add'),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    final id = 'player_${name.toLowerCase().replaceAll(' ', '_')}';
    await LocalDatabaseService.instance.addCaddyFlightPlayer(
      channelId: widget.session.channelId,
      playerId: id,
      playerName: name,
    );
    await _reload();
  }

  Future<void> _setHoleScore(int gross) async {
    final uid = SyncIdentity.currentUserId ?? 'caddy';
    final event = await _pairing.publishEvent(
      channelId: widget.session.channelId,
      roundId: widget.session.roundId,
      type: CaddyEventType.setHoleScore,
      holeNumber: _selectedHole,
      authorUid: uid,
      holeScore: gross,
      targetPlayerId: _playerId == 'primary' ? null : _playerId,
    );
    await CaddyEventApplier().apply(
      event,
      courseName: widget.session.courseName,
    );
    await _reload();
  }

  Future<void> _attest() async {
    final uid = SyncIdentity.currentUserId ?? 'caddy';
    final event = await _pairing.publishEvent(
      channelId: widget.session.channelId,
      roundId: widget.session.roundId,
      type: CaddyEventType.attestPlayerCard,
      holeNumber: _selectedHole,
      authorUid: uid,
      targetPlayerId: _playerId == 'primary' ? null : _playerId,
    );
    await CaddyEventApplier().apply(
      event,
      courseName: widget.session.courseName,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Card attested')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final holeCount = PhGolfCatalog.holeCount(widget.session.courseName);
    final byHole = {for (final h in _holes) h.holeNumber: h};
    final selectedGross = _playerId == 'primary'
        ? (byHole[_selectedHole]?.finalScore ?? byHole[_selectedHole]?.strokes ?? 0)
        : (_otherGross[_selectedHole] ?? 0);

    return RefreshIndicator(
      key: const ValueKey('caddy-scorecard-refresh'),
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              key: const ValueKey('caddy-player-strip'),
              scrollDirection: Axis.horizontal,
              children: [
                for (final player in _players)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      key: ValueKey('caddy-player-${player.id}'),
                      label: Text(player.name),
                      selected: _playerId == player.id,
                      onSelected: (_) async {
                        setState(() => _playerId = player.id);
                        await _reload();
                      },
                    ),
                  ),
                ActionChip(
                  key: const ValueKey('caddy-add-player'),
                  label: const Text('Add player'),
                  onPressed: _addPlayer,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hole $_selectedHole · $selectedGross',
            key: const ValueKey('caddy-hole-score'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  key: const ValueKey('caddy-score-minus'),
                  onPressed: () => _setHoleScore((selectedGross - 1).clamp(0, 20)),
                  child: const Text('-1'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  key: const ValueKey('caddy-score-plus'),
                  onPressed: () => _setHoleScore(selectedGross + 1),
                  child: const Text('+1'),
                ),
              ),
            ],
          ),
          TextButton(
            key: const ValueKey('caddy-attest-card'),
            onPressed: _attest,
            child: const Text('Submit and attest card'),
          ),
          for (var n = 1; n <= holeCount; n++)
            Builder(builder: (context) {
              final row = byHole[n];
              final par = row?.par ??
                  PhGolfCatalog.parForHole(widget.session.courseName, n) ??
                  4;
              final strokes = _playerId == 'primary'
                  ? (row?.strokes ?? 0)
                  : (_otherGross[n] ?? 0);
              final gross = _playerId == 'primary'
                  ? (row != null && row.finalScore > 0
                      ? row.finalScore
                      : computeFinalScore(
                          strokes: strokes,
                          penalties: row?.penalties ?? 0,
                        ))
                  : strokes;
              return ListTile(
                key: ValueKey('caddy-scorecard-hole-$n'),
                selected: n == _selectedHole,
                onTap: () => setState(() => _selectedHole = n),
                title: Text('Hole $n'),
                subtitle: Text('Par $par'),
                trailing: Text(
                  strokes > 0 ? '$strokes ($gross)' : '—',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              );
            }),
        ],
      ),
    );
  }
}
