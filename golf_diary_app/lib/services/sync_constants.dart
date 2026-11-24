/// Named Firestore database created for this app. Not the `(default)` database.
const String kFirestoreDatabaseId = 'my-golf-diary';

const List<String> kSyncTables = [
  'clubs',
  'shots',
  'round_scores',
  'range_drills',
  ...kSwingDiarySyncTables,
];

/// Swing diary thread, replies, context notes, and the compiled range
/// sessions they cite. `diary_settings` stays local.
const List<String> kSwingDiarySyncTables = [
  'range_sessions',
  'diary_context_notes',
  'swing_diary_messages',
  'range_evaluations',
];
