import 'package:flutter/material.dart';

import '../models/golf_models.dart';
import '../models/range_session.dart';

String formatRangeSessionWhen(int timestamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '${date.month}/${date.day}/${date.year} $hour:$minute $suffix';
}

class RangeSessionLog extends StatelessWidget {
  const RangeSessionLog({
    super.key,
    required this.sessions,
    required this.emptyMessage,
    this.compiled = const [],
    this.showClubName = true,
  });

  final List<RangeDrillSummary> sessions;
  final List<RangeSession> compiled;
  final String emptyMessage;
  final bool showClubName;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty && compiled.isEmpty) {
      return Column(
        key: const Key('range-session-log-list'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emptyMessage, key: const Key('range-session-empty')),
        ],
      );
    }
    return Column(
      key: const Key('range-session-log-list'),
      children: [
        for (final session in compiled) CompiledRangeSessionCard(session: session),
        for (final entry in sessions)
          RangeSessionTile(entry: entry, showClubName: showClubName),
      ],
    );
  }
}

class CompiledRangeSessionCard extends StatelessWidget {
  const CompiledRangeSessionCard({super.key, required this.session});

  final RangeSession session;

  @override
  Widget build(BuildContext context) {
    final venue = session.venueName.isEmpty ? 'Unnamed venue' : session.venueName;
    final blocks = session.blocks.map((block) {
      final drill = block.drillTitle == null ? '' : ' · ${block.drillTitle}';
      return '${block.clubName}$drill · min ${block.minYards.round()} · '
          'avg ${block.avgYards.round()} · max ${block.maxYards.round()}';
    }).join('\n');
    final note = session.sessionNote.trim();
    return Card(
      key: ValueKey('range-compiled-session-${session.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('Compiled session · $venue'),
        subtitle: Text(
          '${formatRangeSessionWhen(session.timestamp)}'
          '${note.isEmpty ? '' : '\n$note'}'
          '${blocks.isEmpty ? '' : '\n$blocks'}',
        ),
        isThreeLine: true,
      ),
    );
  }
}

class RangeSessionTile extends StatelessWidget {
  const RangeSessionTile({
    super.key,
    required this.entry,
    required this.showClubName,
  });

  final RangeDrillSummary entry;
  final bool showClubName;

  @override
  Widget build(BuildContext context) {
    final drill = entry.drill;
    final venue = drill.venueName.isEmpty ? 'Unnamed venue' : drill.venueName;
    final notes = drill.tempoNotes.trim();
    final title = showClubName ? '${entry.clubName} · $venue' : venue;
    return Card(
      key: ValueKey('range-session-${drill.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          '${formatRangeSessionWhen(drill.timestamp)}\n'
          '${drill.shotCount} shots · min ${drill.minYards.round()} · '
          'avg ${drill.avgYards.round()} · max ${drill.maxYards.round()}'
          '${notes.isEmpty ? '' : '\n$notes'}',
        ),
        isThreeLine: true,
      ),
    );
  }
}
