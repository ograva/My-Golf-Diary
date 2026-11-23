import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/flight_session.dart';
import '../models/scoring_format.dart';
import '../services/flight_launch_config.dart';
import '../services/flight_service.dart';
import '../services/sync_identity.dart';

/// Share or join a flight and attest a partner's card.
class FlightSheet extends StatefulWidget {
  const FlightSheet({
    super.key,
    required this.roundId,
    required this.courseName,
    required this.format,
    required this.displayName,
    this.service,
    this.initialFlightId,
  });

  final String roundId;
  final String courseName;
  final ScoringFormat format;
  final String displayName;
  final FlightService? service;
  final String? initialFlightId;

  @override
  State<FlightSheet> createState() => _FlightSheetState();
}

class _FlightSheetState extends State<FlightSheet> {
  FlightSnapshot? _flight;
  String? _error;
  final _joinController = TextEditingController();

  FlightService get _service => widget.service ?? FlightService();

  String get _playerId => SyncIdentity.currentUserId ?? 'local_golfer';

  @override
  void dispose() {
    _joinController.dispose();
    super.dispose();
  }

  Future<void> _mint() async {
    final flight = await _service.mintFlight(
      roundId: widget.roundId,
      courseName: widget.courseName,
      format: widget.format,
      displayName: widget.displayName,
    );
    if (!mounted) return;
    setState(() => _flight = flight);
  }

  Future<void> _join() async {
    final id = _joinController.text.trim();
    if (id.isEmpty) return;
    final flight = await _service.joinFlight(
      flightId: id,
      roundId: widget.roundId,
      displayName: widget.displayName,
    );
    if (!mounted) return;
    setState(() {
      _flight = flight;
      _error = flight == null ? 'No flight with that code' : null;
    });
  }

  Future<void> _publish() async {
    final flight = _flight;
    if (flight == null) return;
    final next = await _service.publishRound(
      flightId: flight.flightId,
      playerId: _playerId,
      roundId: widget.roundId,
      displayName: widget.displayName,
    );
    if (!mounted) return;
    setState(() => _flight = next);
  }

  Future<void> _attest(FlightPlayerScore player) async {
    final flight = _flight;
    if (flight == null) return;
    final next = await _service.attestPlayer(
      flightId: flight.flightId,
      playerId: player.playerId,
      attestorName: widget.displayName,
    );
    if (!mounted) return;
    setState(() => _flight = next);
  }

  @override
  Widget build(BuildContext context) {
    final flight = _flight;
    final url = flight == null
        ? null
        : FlightLaunchConfig.buildInviteUrl(flight.flightId);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Flight', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (flight == null) ...[
            FilledButton(
              key: const ValueKey('flight-mint-btn'),
              onPressed: _mint,
              child: const Text('Share this round'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('flight-join-field'),
              controller: _joinController,
              decoration: const InputDecoration(labelText: 'Flight code'),
            ),
            TextButton(
              key: const ValueKey('flight-join-btn'),
              onPressed: _join,
              child: const Text('Join flight'),
            ),
            if (_error != null) Text(_error!),
          ] else ...[
            Text(
              flight.flightId,
              key: const ValueKey('flight-code'),
            ),
            if (url != null)
              QrImageView(
                key: const ValueKey('flight-qr'),
                data: url,
                size: 160,
              ),
            TextButton(
              key: const ValueKey('flight-publish-btn'),
              onPressed: _publish,
              child: const Text('Publish my card'),
            ),
            for (final player in flight.players)
              ListTile(
                key: ValueKey('flight-player-${player.playerId}'),
                title: Text(player.displayName),
                subtitle: Text(
                  player.mismatchesAttestation
                      ? 'Edited after attest · ${player.total}'
                      : player.isAttested
                          ? 'Attested by ${player.attestedByName} · ${player.total}'
                          : 'Total ${player.total}',
                ),
                trailing: player.playerId == _playerId
                    ? null
                    : TextButton(
                        key: ValueKey('flight-attest-${player.playerId}'),
                        onPressed: () => _attest(player),
                        child: const Text('Attest'),
                      ),
              ),
          ],
        ],
      ),
    );
  }
}
