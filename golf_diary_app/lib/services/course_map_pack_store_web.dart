import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'course_map_pack_store.dart';

CourseMapPackStore createPackStore() => CacheApiCourseMapPackStore();

/// Map packs in the browser Cache API, which outlives reloads and works
/// offline in the installed PWA. `web/pwa_service_worker.js` keeps caches
/// named `golf-diary-course-maps*` when it clears old shell caches.
class CacheApiCourseMapPackStore implements CourseMapPackStore {
  static const cacheName = 'golf-diary-course-maps-v1';

  final _fallback = MemoryCourseMapPackStore();
  Future<web.Cache?>? _cache;
  var _persistRequested = false;

  Future<web.Cache?> _open() => _cache ??= () async {
        try {
          return await web.window.caches.open(cacheName).toDart;
        } catch (_) {
          // No Cache API outside a secure context (plain http on a LAN IP).
          return null;
        }
      }();

  static String _url(String courseId, int version, String name) =>
      '${Uri.base.origin}/__course_maps/$courseId/v$version/$name';

  @override
  Future<Uint8List?> read(String courseId, int version, String name) async {
    final cache = await _open();
    if (cache == null) return _fallback.read(courseId, version, name);
    try {
      final response =
          await cache.match(_url(courseId, version, name).toJS).toDart;
      if (response == null) return null;
      return (await response.arrayBuffer().toDart).toDart.asUint8List();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(
      String courseId, int version, String name, Uint8List bytes) async {
    final cache = await _open();
    if (cache == null) return _fallback.write(courseId, version, name, bytes);
    _requestPersistence();
    await cache
        .put(_url(courseId, version, name).toJS, web.Response(bytes.toJS))
        .toDart;
  }

  Future<List<String>> _keys() async {
    final cache = await _open();
    if (cache == null) return _fallback.files.keys.toList();
    final requests = (await cache.keys().toDart).toDart;
    return [for (final r in requests) r.url];
  }

  @override
  Future<int?> latestVersion(String courseId) async {
    try {
      return latestManifestVersion(courseId, await _keys());
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> prune(String courseId, int keep) async {
    final cache = await _open();
    if (cache == null) return _fallback.prune(courseId, keep);
    try {
      final prefix = '/__course_maps/$courseId/v';
      for (final url in await _keys()) {
        final path = Uri.parse(url).path;
        if (path.startsWith(prefix) && !path.startsWith('$prefix$keep/')) {
          await cache.delete(url.toJS).toDart;
        }
      }
    } catch (_) {}
  }

  /// Asks the browser not to evict the cache under storage pressure; an
  /// installed PWA is usually granted this without a prompt.
  void _requestPersistence() {
    if (_persistRequested) return;
    _persistRequested = true;
    try {
      web.window.navigator.storage.persist().toDart.ignore();
    } catch (_) {}
  }
}
