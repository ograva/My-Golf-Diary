/// Last-write-wins: a newer remote `updatedAtMs` replaces the local row,
/// including a row that has not been pushed yet. An equal or older remote
/// leaves the local row alone so the following push can win.
enum MergeAction { applyRemote, keepLocal }

MergeAction decideMerge({
  required bool localExists,
  required int localUpdatedAtMs,
  required int remoteUpdatedAtMs,
}) {
  if (!localExists) return MergeAction.applyRemote;
  if (remoteUpdatedAtMs > localUpdatedAtMs) return MergeAction.applyRemote;
  return MergeAction.keepLocal;
}

int readUpdatedAtMs(Map<String, dynamic> row) {
  final value = row['updatedAtMs'] ?? row['updated_at_ms'] ?? 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

bool readDeleted(Map<String, dynamic> row) {
  final value = row['deleted'];
  return value == true || value == 1;
}
