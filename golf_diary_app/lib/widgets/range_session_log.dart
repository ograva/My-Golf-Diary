import 'package:flutter/material.dart';

import '../models/golf_models.dart';

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
    this.showClubName = true,
  });

  final List<RangeDrillSummary> sessions;
  final String emptyMessage;
  final bool showClubName;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Text(emptyMessage, key: const Key('range-session-empty'));
    }
    return Column(
      children: [
        for (final entry in sessions)
          RangeSessionTile(entry: entry, showClubName: showClubName),
      ],
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
