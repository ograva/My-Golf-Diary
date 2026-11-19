import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/ph_golf_hole_coords.dart';
import '../models/course_map_manifest.dart';
import '../on_course/hole_map_geo.dart';

enum CourseMapResolveKind { satellite, vector, downloading }

class CourseMapResolveResult {
  const CourseMapResolveResult({
    required this.kind,
    this.frame,
  });

  final CourseMapResolveKind kind;
  final HoleMapFrame? frame;
}

String courseMapPackIdFromName(String canonicalCourseName) {
  return canonicalCourseName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

/// Local + Firebase Storage tier for course map packs (Architecture §5.5).
class CourseMapCacheService {
  CourseMapCacheService._();

  static final CourseMapCacheService instance = CourseMapCacheService._();

  /// Widget tests inject a resolved frame without disk or Storage.
  @visibleForTesting
  HoleMapFrame? debugHoleFrame;

  /// When non-null, overrides [hasPackForCourse] without reading disk.
  @visibleForTesting
  bool? debugHasPack;

  Future<Directory> _rootDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'course_maps'));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<Directory?> _packDir(String courseName) async {
    try {
      final canonical = canonicalCourseName(courseName);
      if (canonical == null) return null;
      final id = courseMapPackIdFromName(canonical);
      return Directory(p.join((await _rootDir()).path, id));
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasPackForCourse(String courseName) async {
    if (debugHasPack != null) return debugHasPack!;
    try {
      final dir = await _packDir(courseName);
      if (dir == null || !dir.existsSync()) return false;
      final manifest = File(p.join(dir.path, 'manifest.json'));
      return manifest.existsSync();
    } catch (_) {
      return false;
    }
  }

  Future<HoleMapFrame?> _loadLocalFrame({
    required String courseName,
    required int holeNumber,
    required HoleCoordinates coords,
  }) async {
    if (debugHoleFrame != null &&
        debugHoleFrame!.entry.holeNumber == holeNumber) {
      return debugHoleFrame;
    }
    final dir = await _packDir(courseName);
    if (dir == null) return null;
    final manifestFile = File(p.join(dir.path, 'manifest.json'));
    if (!manifestFile.existsSync()) return null;
    final manifest = CourseMapManifest.parseFile(manifestFile);
    if (manifest == null) return null;
    var entry = manifest.hole(holeNumber);
    entry ??= HoleMapManifestEntry(
      holeNumber: holeNumber,
      imagePath: 'hole_$holeNumber.webp',
      swLat: boundsForHole(coords).swLat,
      swLon: boundsForHole(coords).swLon,
      neLat: boundsForHole(coords).neLat,
      neLon: boundsForHole(coords).neLon,
      widthPx: 1280,
      heightPx: 1280,
    );
    final image = File(p.join(dir.path, entry.imagePath));
    return HoleMapFrame(
      entry: entry,
      packDirectory: dir.path,
      imageFile: image.existsSync() ? image : null,
    );
  }

  Future<bool> _downloadPackFromStorage(String courseName) async {
    if (kIsWeb) return false;
    try {
      if (Firebase.apps.isEmpty) return false;
    } catch (_) {
      return false;
    }
    final canonical = canonicalCourseName(courseName);
    if (canonical == null) return false;
    final courseId = courseMapPackIdFromName(canonical);
    final packDir = await _packDir(courseName);
    if (packDir == null) return false;

    try {
      final storage = FirebaseStorage.instance;
      final prefix = 'course_maps/$courseId';
      final manifestRef = storage.ref('$prefix/manifest.json');
      final manifestFile = File(p.join(packDir.path, 'manifest.json'));
      await manifestRef.writeToFile(manifestFile);
      final manifest = CourseMapManifest.parseFile(manifestFile);
      if (manifest == null) return false;
      for (final hole in manifest.holes) {
        final imageRef = storage.ref('$prefix/${hole.imagePath}');
        final dest = File(p.join(packDir.path, hole.imagePath));
        await imageRef.writeToFile(dest);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<CourseMapResolveResult> resolveHoleMap({
    required String courseName,
    required int holeNumber,
    required HoleCoordinates coords,
    bool allowDownload = false,
  }) async {
    if (debugHoleFrame != null) {
      return CourseMapResolveResult(
        kind: CourseMapResolveKind.satellite,
        frame: debugHoleFrame,
      );
    }

    final local = await _loadLocalFrame(
      courseName: courseName,
      holeNumber: holeNumber,
      coords: coords,
    );
    if (local != null) {
      return CourseMapResolveResult(
        kind: CourseMapResolveKind.satellite,
        frame: local,
      );
    }

    if (!allowDownload) {
      final hasPack = await hasPackForCourse(courseName);
      if (!hasPack) {
        return const CourseMapResolveResult(kind: CourseMapResolveKind.vector);
      }
      return const CourseMapResolveResult(
        kind: CourseMapResolveKind.downloading,
      );
    }

    final downloaded = await _downloadPackFromStorage(courseName);
    if (downloaded) {
      final after = await _loadLocalFrame(
        courseName: courseName,
        holeNumber: holeNumber,
        coords: coords,
      );
      if (after != null) {
        return CourseMapResolveResult(
          kind: CourseMapResolveKind.satellite,
          frame: after,
        );
      }
    }
    return const CourseMapResolveResult(kind: CourseMapResolveKind.vector);
  }
}