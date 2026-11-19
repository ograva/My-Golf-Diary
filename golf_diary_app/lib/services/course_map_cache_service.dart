import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/ph_golf_hole_coords.dart';
import '../models/course_map_manifest.dart';
import '../on_course/hole_map_geo.dart';
import 'sync_identity.dart';

enum CourseMapResolveKind { satellite, vector, downloading }

class CourseMapResolveResult {
  const CourseMapResolveResult({
    required this.kind,
    this.frame,
  });

  final CourseMapResolveKind kind;
  final HoleMapFrame? frame;
}

/// Lower-cased name with non-alphanumeric runs turned into `-`
/// (same rule as `name_slug` in `tools/map_pack/courses.py`).
String courseMapPackIdFromName(String canonicalCourseName) {
  return canonicalCourseName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

/// Established `ph-crse-*` IDs from `docs/context/PH_Golf_Venues.md`, keyed
/// by canonical course name. Must match `python tools/map_pack/courses.py`.
const Map<String, String> kCourseMapPackIds = {
  'Wack Wack Golf & Country Club — East': 'ph-crse-wack-wack-east',
  'Wack Wack Golf & Country Club — West': 'ph-crse-wack-wack-west',
  'Manila Golf and Country Club': 'ph-crse-manila-golf',
  'Villamor Golf Club': 'ph-crse-villamor',
  'Club Intramuros Golf Course': 'ph-crse-club-intramuros',
  'Camp Aguinaldo Golf Club': 'ph-crse-camp-aguinaldo',
  'Veterans Golf Club': 'ph-crse-veterans',
  'Philippine Navy Golf Club': 'ph-crse-phil-navy',
  'Manila Southwoods — Masters Course': 'ph-crse-southwoods-masters',
  'Manila Southwoods — Legends Course': 'ph-crse-southwoods-legends',
  'Valley Golf & Country Club — South': 'ph-crse-valley-south',
  'Valley Golf & Country Club — North': 'ph-crse-valley-north',
  'Eagle Ridge G&CC — Nick Faldo Course': 'ph-crse-eagle-ridge-faldo',
  'Ayala Greenfield Golf & Leisure Club': 'ph-crse-ayala-greenfield',
  'Cebu Country Club': 'ph-crse-cebu-cc',
  'Hallow Ridge Filipinas Golf (KC Filipinas)': 'ph-crse-hallow-ridge',
  'Sherwood Hills Golf Club': 'ph-crse-sherwood-hills',
};

/// Storage `courseId` for a canonical course name (CRSE-041 contract).
String courseMapPackId(String canonicalCourseName) =>
    kCourseMapPackIds[canonicalCourseName] ??
    'ph-crse-${courseMapPackIdFromName(canonicalCourseName)}';

/// Reads objects under the map pack bucket; tests substitute a fake.
abstract class CourseMapPackSource {
  /// Bytes at [path] (e.g. `course_maps/index.json`), or null when missing
  /// or unreadable.
  Future<Uint8List?> read(String path);
}

class FirebaseCourseMapPackSource implements CourseMapPackSource {
  const FirebaseCourseMapPackSource();

  static const _maxBytes = 10 * 1024 * 1024;

  @override
  Future<Uint8List?> read(String path) async {
    try {
      if (Firebase.apps.isEmpty) return null;
      await SyncIdentity.ensureSignedIn();
      return await FirebaseStorage.instance.ref(path).getData(_maxBytes);
    } catch (_) {
      return null;
    }
  }
}

class _MemoryPack {
  _MemoryPack(this.manifest, this.images);

  final CourseMapManifest manifest;
  final Map<String, Uint8List> images;
}

/// Local + Firebase Storage tier for course map packs (Architecture §5.5).
///
/// Native builds cache packs under `<appDocDir>/course_maps/{courseId}/`.
/// Web has no file system, so packs are held in memory for the session and
/// repeat fetches are served by the browser HTTP cache (`Cache-Control` set
/// at upload).
class CourseMapCacheService {
  CourseMapCacheService._();

  static final CourseMapCacheService instance = CourseMapCacheService._();

  static const _prefix = 'course_maps';

  /// Widget tests inject a resolved frame without disk or Storage.
  @visibleForTesting
  HoleMapFrame? debugHoleFrame;

  /// When non-null, overrides [hasPackForCourse] without reading disk.
  @visibleForTesting
  bool? debugHasPack;

  /// Forces the web (in-memory) cache path on the VM.
  @visibleForTesting
  bool? debugUseMemoryCache;

  CourseMapPackSource source = const FirebaseCourseMapPackSource();

  final Map<String, _MemoryPack> _memoryPacks = {};
  final Map<String, Future<bool>> _inFlight = {};
  Future<Map<String, int>?>? _remoteIndex;

  bool get _useMemoryCache => debugUseMemoryCache ?? kIsWeb;

  @visibleForTesting
  void debugReset() {
    debugHoleFrame = null;
    debugHasPack = null;
    debugUseMemoryCache = null;
    source = const FirebaseCourseMapPackSource();
    _memoryPacks.clear();
    _inFlight.clear();
    _remoteIndex = null;
  }

  /// Image bytes for a frame resolved from the in-memory (web) cache.
  Uint8List? cachedImageBytes(HoleMapFrame frame) {
    final id = p.posix.basename(frame.packDirectory);
    return _memoryPacks[id]?.images[frame.entry.imagePath];
  }

  String? _courseId(String courseName) {
    final canonical = canonicalCourseName(courseName);
    if (canonical == null) return null;
    return courseMapPackId(canonical);
  }

  /// `courseId → version` from `course_maps/index.json`, fetched once per
  /// session; null when offline or not published.
  Future<Map<String, int>?> _fetchRemoteIndex() {
    return _remoteIndex ??= () async {
      final bytes = await source.read('$_prefix/index.json');
      if (bytes == null) {
        _remoteIndex = null;
        return null;
      }
      try {
        final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
        final courses = json['courses'] as List<dynamic>? ?? const [];
        return {
          for (final c in courses.cast<Map<String, dynamic>>())
            c['courseId'] as String: (c['version'] as num?)?.toInt() ?? 1,
        };
      } catch (_) {
        return null;
      }
    }();
  }

  Future<Directory> _rootDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _prefix));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<Directory?> _packDir(String courseName) async {
    try {
      final id = _courseId(courseName);
      if (id == null) return null;
      return Directory(p.join((await _rootDir()).path, id));
    } catch (_) {
      return null;
    }
  }

  bool _hasLocalPackSync(Directory? dir) {
    if (dir == null || !dir.existsSync()) return false;
    return File(p.join(dir.path, 'manifest.json')).existsSync();
  }

  /// True when a pack is cached locally or listed in the remote index.
  Future<bool> hasPackForCourse(String courseName) async {
    if (debugHasPack != null) return debugHasPack!;
    final id = _courseId(courseName);
    if (id == null) return false;
    try {
      if (_useMemoryCache) {
        if (_memoryPacks.containsKey(id)) return true;
      } else if (_hasLocalPackSync(await _packDir(courseName))) {
        return true;
      }
      final index = await _fetchRemoteIndex();
      return index?.containsKey(id) ?? false;
    } catch (_) {
      return false;
    }
  }

  HoleMapManifestEntry _entryFor(
    CourseMapManifest manifest,
    int holeNumber,
    HoleCoordinates coords,
  ) {
    final entry = manifest.hole(holeNumber);
    if (entry != null) return entry;
    final bounds = boundsForHole(coords);
    return HoleMapManifestEntry(
      holeNumber: holeNumber,
      imagePath: 'hole_$holeNumber.webp',
      swLat: bounds.swLat,
      swLon: bounds.swLon,
      neLat: bounds.neLat,
      neLon: bounds.neLon,
      widthPx: 1280,
      heightPx: 1280,
    );
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
    if (_useMemoryCache) {
      final id = _courseId(courseName);
      final pack = id == null ? null : _memoryPacks[id];
      if (pack == null) return null;
      return HoleMapFrame(
        entry: _entryFor(pack.manifest, holeNumber, coords),
        packDirectory: '$_prefix/$id',
      );
    }
    final dir = await _packDir(courseName);
    if (dir == null) return null;
    final manifestFile = File(p.join(dir.path, 'manifest.json'));
    if (!manifestFile.existsSync()) return null;
    final manifest = CourseMapManifest.parseFile(manifestFile);
    if (manifest == null) return null;
    final entry = _entryFor(manifest, holeNumber, coords);
    final image = File(p.join(dir.path, entry.imagePath));
    return HoleMapFrame(
      entry: entry,
      packDirectory: dir.path,
      imageFile: image.existsSync() ? image : null,
    );
  }

  Future<bool> _downloadPackToMemory(String courseId) async {
    final prefix = '$_prefix/$courseId';
    final manifestBytes = await source.read('$prefix/manifest.json');
    if (manifestBytes == null) return false;
    final CourseMapManifest manifest;
    try {
      manifest = CourseMapManifest.fromJson(
        jsonDecode(utf8.decode(manifestBytes)) as Map<String, dynamic>,
      );
    } catch (_) {
      return false;
    }
    final images = <String, Uint8List>{};
    await Future.wait(manifest.holes.map((hole) async {
      final bytes = await source.read('$prefix/${hole.imagePath}');
      if (bytes != null) images[hole.imagePath] = bytes;
    }));
    if (images.isEmpty && manifest.holes.isNotEmpty) return false;
    _memoryPacks[courseId] = _MemoryPack(manifest, images);
    return true;
  }

  Future<bool> _downloadPackToDisk(String courseName, String courseId) async {
    try {
      if (Firebase.apps.isEmpty) return false;
    } catch (_) {
      return false;
    }
    final packDir = await _packDir(courseName);
    if (packDir == null) return false;

    try {
      await SyncIdentity.ensureSignedIn();
      final storage = FirebaseStorage.instance;
      final prefix = '$_prefix/$courseId';
      if (!packDir.existsSync()) packDir.createSync(recursive: true);
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

  Future<bool> _downloadPackFromStorage(String courseName) {
    final courseId = _courseId(courseName);
    if (courseId == null) return Future.value(false);
    return _inFlight[courseId] ??= (_useMemoryCache
            ? _downloadPackToMemory(courseId)
            : _downloadPackToDisk(courseName, courseId))
        .whenComplete(() {
      _inFlight.remove(courseId);
    });
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
