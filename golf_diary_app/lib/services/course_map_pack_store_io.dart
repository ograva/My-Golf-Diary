import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/course_map_manifest.dart';
import 'course_map_pack_store.dart';

CourseMapPackStore createPackStore() => DiskCourseMapPackStore();

/// `<root>/{courseId}/v{version}/{name}`, where root defaults to
/// `<appDocDir>/course_maps`. Packs cached before versioned folders sit
/// directly in `<root>/{courseId}/` and are read as their manifest version
/// until a newer version replaces them.
class DiskCourseMapPackStore implements CourseMapPackStore {
  DiskCourseMapPackStore({Future<Directory> Function()? root})
      : _rootOverride = root;

  final Future<Directory> Function()? _rootOverride;

  /// Only a resolved root is kept: a pending lookup is not shared, so one
  /// that never completes cannot stall later reads.
  Directory? _root;

  Future<Directory> _rootDir() async {
    final cached = _root;
    if (cached != null) return cached;
    final override = _rootOverride;
    final dir = override != null
        ? await override()
        : Directory(p.join(
            (await getApplicationDocumentsDirectory()).path, 'course_maps'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return _root = dir;
  }

  Future<Directory> _courseDir(String courseId) async =>
      Directory(p.join((await _rootDir()).path, courseId));

  Future<File> _file(String courseId, int version, String name) async =>
      File(p.join((await _courseDir(courseId)).path, 'v$version', name));

  Future<int?> _legacyVersion(String courseId) async {
    final manifest =
        File(p.join((await _courseDir(courseId)).path, 'manifest.json'));
    if (!manifest.existsSync()) return null;
    return CourseMapManifest.parseString(await manifest.readAsString())
        ?.version;
  }

  @override
  Future<Uint8List?> read(String courseId, int version, String name) async {
    try {
      final file = await _file(courseId, version, name);
      if (file.existsSync()) return await file.readAsBytes();
      if (await _legacyVersion(courseId) != version) return null;
      final legacy = File(p.join((await _courseDir(courseId)).path, name));
      return legacy.existsSync() ? await legacy.readAsBytes() : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(
      String courseId, int version, String name, Uint8List bytes) async {
    final file = await _file(courseId, version, name);
    file.parent.createSync(recursive: true);
    // Written aside and renamed so a killed download never leaves a
    // truncated image that reads as cached.
    final partial = File('${file.path}.part');
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(file.path);
  }

  @override
  Future<int?> latestVersion(String courseId) async {
    try {
      final dir = await _courseDir(courseId);
      if (!dir.existsSync()) return null;
      final keys = [
        for (final entity in dir.listSync())
          if (entity is Directory &&
              File(p.join(entity.path, 'manifest.json')).existsSync())
            '$courseId/${p.basename(entity.path)}/manifest.json',
      ];
      return latestManifestVersion(courseId, keys) ??
          await _legacyVersion(courseId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> prune(String courseId, int keep) async {
    try {
      final dir = await _courseDir(courseId);
      if (!dir.existsSync()) return;
      final keepDir = Directory(p.join(dir.path, 'v$keep'));
      if (!File(p.join(keepDir.path, 'manifest.json')).existsSync()) return;
      for (final entity in dir.listSync()) {
        if (p.equals(entity.path, keepDir.path)) continue;
        await entity.delete(recursive: true);
      }
    } catch (_) {}
  }
}
