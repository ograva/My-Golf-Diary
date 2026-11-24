import 'package:flutter/foundation.dart';

import 'course_map_pack_store_io.dart'
    if (dart.library.js_interop) 'course_map_pack_store_web.dart' as platform;

/// Persistent map pack files keyed by `courseId` + pack `version` + file
/// name (`manifest.json`, `hole_1.png`, …). A new version never overwrites an
/// old one; [prune] drops superseded versions once the new one is complete.
abstract class CourseMapPackStore {
  Future<Uint8List?> read(String courseId, int version, String name);

  Future<void> write(
      String courseId, int version, String name, Uint8List bytes);

  /// Highest version with a stored `manifest.json`, or null.
  Future<int?> latestVersion(String courseId);

  /// Deletes every stored version of [courseId] except [keep].
  Future<void> prune(String courseId, int keep);

  /// Disk on native (`<appDocDir>/course_maps/`), the Cache API on web.
  static CourseMapPackStore platformDefault() => platform.createPackStore();
}

/// Session-only store for tests and browsers without the Cache API.
class MemoryCourseMapPackStore implements CourseMapPackStore {
  final Map<String, Uint8List> files = {};

  static String _key(String courseId, int version, String name) =>
      '$courseId/v$version/$name';

  @override
  Future<Uint8List?> read(String courseId, int version, String name) async =>
      files[_key(courseId, version, name)];

  @override
  Future<void> write(
      String courseId, int version, String name, Uint8List bytes) async {
    files[_key(courseId, version, name)] = bytes;
  }

  @override
  Future<int?> latestVersion(String courseId) async =>
      latestManifestVersion(courseId, files.keys);

  @override
  Future<void> prune(String courseId, int keep) async {
    files.removeWhere((key, _) =>
        key.startsWith('$courseId/v') && !key.startsWith('$courseId/v$keep/'));
  }
}

/// Highest `N` among keys ending in `{courseId}/vN/manifest.json`.
int? latestManifestVersion(String courseId, Iterable<String> keys) {
  final pattern =
      RegExp('(?:^|/)${RegExp.escape(courseId)}/v(\\d+)/manifest\\.json\$');
  int? best;
  for (final key in keys) {
    final match = pattern.firstMatch(key);
    if (match == null) continue;
    final v = int.parse(match.group(1)!);
    if (best == null || v > best) best = v;
  }
  return best;
}
