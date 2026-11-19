import 'package:sqflite/sqflite.dart';

import 'local_database_service.dart';

enum RailSide { left, right }

enum GpsMode { live, manual }

/// Per-device FWY preferences (rail side, Live/Manual GPS). Not synced.
class OnCourseSettings {
  OnCourseSettings._();

  static final OnCourseSettings instance = OnCourseSettings._();

  static const _table = 'oncourse_device_settings';

  Future<Database> _db() async {
    final db = await LocalDatabaseService.instance.database;
    await db.execute(
        'CREATE TABLE IF NOT EXISTS $_table (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
    return db;
  }

  Future<String?> _get(String key) async {
    try {
      final rows = await (await _db())
          .query(_table, where: 'key = ?', whereArgs: [key], limit: 1);
      return rows.isEmpty ? null : rows.first['value'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _set(String key, String value) async {
    try {
      await (await _db()).insert(_table, {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (_) {}
  }

  Future<RailSide> railSide() async =>
      await _get('rail_side') == 'left' ? RailSide.left : RailSide.right;

  Future<void> setRailSide(RailSide side) => _set('rail_side', side.name);

  Future<GpsMode> gpsMode() async =>
      await _get('gps_mode') == 'manual' ? GpsMode.manual : GpsMode.live;

  Future<void> setGpsMode(GpsMode mode) => _set('gps_mode', mode.name);
}
