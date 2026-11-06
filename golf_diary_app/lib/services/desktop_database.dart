import 'desktop_database_stub.dart'
    if (dart.library.io) 'desktop_database_io.dart' as impl;

/// Opens SQLite on desktop targets that have no mobile sqflite plugin.
Future<void> initDesktopDatabase() => impl.initDesktopDatabase();
