import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/ph_golf_hole_coords.dart';
import '../models/course_map_manifest.dart';
import '../on_course/hole_map_geo.dart';
import 'course_map_pack_store.dart';
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
  static const _fetchTimeout = Duration(seconds: 20);

  /// Download URLs carry a stable token, so each object costs one metadata
  /// call per session on web.
  static final Map<String, Future<String>> _downloadUrls = {};

  @override
  Future<Uint8List?> read(String path) async {
    try {
      if (Firebase.apps.isEmpty) return null;
      await SyncIdentity.ensureSignedIn();
      final ref = FirebaseStorage.instance.ref(path);
      if (!kIsWeb) return await ref.getData(_maxBytes);
      // Web getData() issues getMetadata + getDownloadURL + GET for every
      // call; the GET alone is what the browser HTTP cache can serve.
      final url = await (_downloadUrls[path] ??= ref.getDownloadURL());
      final response = await http.get(Uri.parse(url)).timeout(_fetchTimeout);
      if (response.statusCode == 200) return response.bodyBytes;
      _downloadUrls.remove(path);
      return null;
    } catch (_) {
      _downloadUrls.remove(path);
      return null;
    }
  }
}

/// Local + Firebase Storage tier for course map packs (Architecture §5.5).
///
/// Packs are stored per `courseId` + version in [store]: disk on native
/// (`<appDocDir>/course_maps/{courseId}/v{n}/`), the Cache API on web, so a
/// pack is downloaded once per version and opens offline. The newest stored
/// version is used straight away; `course_maps/index.json` is checked in the
/// background and a changed version is downloaded, switched to, and the old
/// one pruned. Remote objects live at `course_maps/{courseId}/v{n}/…`, with
/// the unversioned `course_maps/{courseId}/…` layout as a fallback.
class CourseMapCacheService {
  CourseMapCacheService._();

  static final CourseMapCacheService instance = CourseMapCacheService._();

  static const _prefix = 'course_maps';
  static const _manifestName = 'manifest.json';
  static const _parallelDownloads = 4;

  /// Widget tests inject a resolved frame without disk or Storage.
  @visibleForTesting
  HoleMapFrame? debugHoleFrame;

  /// When non-null, overrides [hasPackForCourse] without reading disk.
  @visibleForTesting
  bool? debugHasPack;

  /// Uses a session-only [MemoryCourseMapPackStore] instead of disk / Cache
  /// API (set before the first read).
  @visibleForTesting
  bool? debugUseMemoryCache;

  CourseMapPackSource source = const FirebaseCourseMapPackSource();

  CourseMapPackStore? _store;

  CourseMapPackStore get store => _store ??= debugUseMemoryCache == true
      ? MemoryCourseMapPackStore()
      : CourseMapPackStore.platformDefault();

  set store(CourseMapPackStore value) => _store = value;

  /// Version in use per course this session.
  final Map<String, int> _active = {};
  final Map<String, CourseMapManifest> _manifests = {};

  /// One [Uint8List] per stored image so `MemoryImage` keys stay equal.
  final Map<String, Uint8List> _images = {};
  final Map<String, Future<Uint8List?>> _inFlight = {};

  /// `courseId/vN` packs only found at the unversioned remote path.
  final Set<String> _legacyRemote = {};
  final Map<String, Future<void>> _syncs = {};
  Future<Map<String, int>?>? _remoteIndex;

  @visibleForTesting
  void debugReset() {
    debugHoleFrame = null;
    debugHasPack = null;
    debugUseMemoryCache = null;
    source = const FirebaseCourseMapPackSource();
    _store = null;
    _active.clear();
    _manifests.clear();
    _images.clear();
    _inFlight.clear();
    _legacyRemote.clear();
    _syncs.clear();
    _remoteIndex = null;
  }

  /// Completes when background version checks and pack downloads finish.
  @visibleForTesting
  Future<void> debugSettle() async {
    while (true) {
      final pending = _syncs.values.toList();
      await Future.wait(pending);
      if (_syncs.length == pending.length) return;
    }
  }

  /// Image bytes for a resolved frame, the same instance on every call.
  Uint8List? cachedImageBytes(HoleMapFrame frame) {
    final key = frame.imageKey;
    return key == null ? null : _images[key];
  }

  String? _courseId(String courseName) {
    final canonical = canonicalCourseName(courseName);
    if (canonical == null) return null;
    return courseMapPackId(canonical);
  }

  /// `courseId → version` from `course_maps/index.json`, fetched once per
  /// session; null when offline or not published (retried on next call).
  Future<Map<String, int>?> _fetchRemoteIndex() {
    final pending = _remoteIndex;
    if (pending != null) return pending;
    final fetch = () async {
      final bytes = await source.read('$_prefix/index.json');
      if (bytes == null) return null;
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
    _remoteIndex = fetch;
    fetch.then((index) {
      if (index == null && identical(_remoteIndex, fetch)) _remoteIndex = null;
    });
    return fetch;
  }

  /// Newest stored version, else the remote index version, else null.
  Future<int?> _activeVersion(String courseId) async {
    final known = _active[courseId];
    if (known != null) return known;
    int? version;
    try {
      version = await store.latestVersion(courseId);
    } catch (_) {}
    version ??= (await _fetchRemoteIndex())?[courseId];
    if (version != null) _active[courseId] ??= version;
    return _active[courseId];
  }

  /// True when a pack is stored locally or listed in the remote index.
  Future<bool> hasPackForCourse(String courseName) async {
    if (debugHasPack != null) return debugHasPack!;
    final id = _courseId(courseName);
    if (id == null) return false;
    try {
      return await _activeVersion(id) != null;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List?> _fetchRemote(String courseId, int version, String name) {
    final key = '$courseId/v$version/$name';
    return _inFlight[key] ??= () async {
      final pack = '$courseId/v$version';
      Uint8List? bytes;
      if (!_legacyRemote.contains(pack)) {
        bytes = await source.read('$_prefix/$pack/$name');
      }
      if (bytes == null) {
        bytes = await source.read('$_prefix/$courseId/$name');
        if (bytes != null) _legacyRemote.add(pack);
      }
      return bytes;
    }()
        .whenComplete(() {
      _inFlight.remove(key);
    });
  }

  Future<void> _persist(
      String courseId, int version, String name, Uint8List bytes) async {
    try {
      await store.write(courseId, version, name, bytes);
    } catch (error) {
      debugPrint('Map pack cache write failed for $courseId $name: $error');
    }
  }

  Future<CourseMapManifest?> _manifest(
    String courseId,
    int version, {
    required bool download,
  }) async {
    final key = '$courseId/v$version';
    final cached = _manifests[key];
    if (cached != null) return cached;
    var bytes = await store.read(courseId, version, _manifestName);
    final fromStore = bytes != null;
    if (bytes == null && download) {
      bytes = await _fetchRemote(courseId, version, _manifestName);
    }
    if (bytes == null) return null;
    final manifest = _parseManifest(bytes, version);
    if (manifest == null) return null;
    if (!fromStore) await _persist(courseId, version, _manifestName, bytes);
    return _manifests[key] ??= manifest;
  }

  CourseMapManifest? _parseManifest(Uint8List bytes, int version) {
    try {
      final manifest = CourseMapManifest.fromJson(
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
      );
      return manifest.version == version ? manifest : null;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _image(
    String courseId,
    int version,
    String imagePath, {
    required bool download,
  }) async {
    final key = '$courseId/v$version/$imagePath';
    final cached = _images[key];
    if (cached != null) return cached;
    var bytes = await store.read(courseId, version, imagePath);
    if (bytes == null && download) {
      bytes = await _fetchRemote(courseId, version, imagePath);
      if (bytes != null) await _persist(courseId, version, imagePath, bytes);
    }
    if (bytes == null) return null;
    return _images.putIfAbsent(key, () => bytes!);
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

  Future<HoleMapFrame?> _frame(
    String courseId,
    int version,
    int holeNumber,
    HoleCoordinates coords, {
    required bool download,
  }) async {
    final manifest = await _manifest(courseId, version, download: download);
    if (manifest == null) return null;
    final entry = _entryFor(manifest, holeNumber, coords);
    final bytes = await _image(courseId, version, entry.imagePath,
        download: download);
    if (bytes == null) return null;
    return HoleMapFrame(
      entry: entry,
      packDirectory: '$_prefix/$courseId/v$version',
      imageKey: '$courseId/v$version/${entry.imagePath}',
    );
  }

  /// Downloads every hole of [version] that is not stored yet; true when the
  /// whole pack is stored.
  Future<bool> _fillPack(String courseId, int version) async {
    final manifest = await _manifest(courseId, version, download: true);
    if (manifest == null) return false;
    final paths = [for (final h in manifest.holes) h.imagePath];
    var complete = true;
    var next = 0;
    Future<void> worker() async {
      while (next < paths.length) {
        final path = paths[next++];
        final bytes = await _image(courseId, version, path, download: true);
        if (bytes == null) complete = false;
      }
    }

    await Future.wait([
      for (var i = 0; i < _parallelDownloads; i++) worker(),
    ]);
    return complete;
  }

  /// Once per course per session: switch to a changed index version, fill
  /// the rest of the pack, and prune superseded versions.
  void _scheduleSync(String courseId) {
    _syncs[courseId] ??= _sync(courseId).catchError((Object error) {
      debugPrint('Map pack sync failed for $courseId: $error');
    });
  }

  Future<void> _sync(String courseId) async {
    final current = _active[courseId];
    if (current == null) return;
    final remote = (await _fetchRemoteIndex())?[courseId];
    if (remote != null && remote != current) {
      // The new manifest is stored last: the store treats a stored manifest
      // as the newest usable version, and a half-fetched one would hide the
      // complete old pack offline.
      final bytes = await _fetchRemote(courseId, remote, _manifestName);
      final manifest = bytes == null ? null : _parseManifest(bytes, remote);
      if (manifest == null) return;
      _manifests['$courseId/v$remote'] = manifest;
      if (await _fillPack(courseId, remote)) {
        await _persist(courseId, remote, _manifestName, bytes!);
        _active[courseId] = remote;
        _images.removeWhere((key, _) => key.startsWith('$courseId/v$current/'));
        _manifests.remove('$courseId/v$current');
        await store.prune(courseId, remote);
      }
      return;
    }
    if (await _fillPack(courseId, current)) {
      await store.prune(courseId, current);
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
    const vector = CourseMapResolveResult(kind: CourseMapResolveKind.vector);
    final id = _courseId(courseName);
    if (id == null) return vector;
    final version = await _activeVersion(id);
    if (version == null) return vector;

    final local = await _frame(id, version, holeNumber, coords, download: false);
    if (local != null) {
      _scheduleSync(id);
      return CourseMapResolveResult(
        kind: CourseMapResolveKind.satellite,
        frame: local,
      );
    }
    if (!allowDownload) {
      return const CourseMapResolveResult(
        kind: CourseMapResolveKind.downloading,
      );
    }

    // This hole first; the rest of the pack follows in the background.
    final fetched =
        await _frame(id, version, holeNumber, coords, download: true);
    _scheduleSync(id);
    if (fetched == null) return vector;
    return CourseMapResolveResult(
      kind: CourseMapResolveKind.satellite,
      frame: fetched,
    );
  }
}
