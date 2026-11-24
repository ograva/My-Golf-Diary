/// Whether `users/{uid}` has live diary documents.
enum RemoteDiaryState {
  /// The account is readable and every synced table is empty of live rows.
  /// Tombstones alone are not entries.
  empty,

  /// At least one non-deleted row exists in a synced table.
  hasEntries,

  /// The cloud copy could not be read. Do not claim the account has entries.
  unclear,
}
