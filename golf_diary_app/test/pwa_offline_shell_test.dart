import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release shell is precached and startup does not wait on Firebase', () {
    final worker = File('web/pwa_service_worker.js').readAsStringSync();
    final build = File('tool/build_web.sh').readAsStringSync();
    final mainSource = File('lib/main.dart').readAsStringSync();
    final startup =
        File('lib/services/cloud_sync_service.dart').readAsStringSync();

    expect(worker, contains("const CACHE_NAME = 'golf-diary-shell-v2'"));
    expect(worker, contains('precache_manifest.json'));
    expect(worker, contains('skipWaiting'));
    expect(worker, contains("request.mode === 'navigate'"));
    expect(worker, contains('cache.put rejects a navigation request'));
    expect(worker, contains("'/canvaskit.js'"));
    expect(worker, contains("'/canvaskit.wasm'"));
    expect(worker, contains('BUILD_TIMEOUT_MS'));
    expect(worker, contains('AbortController'));
    expect(worker, contains("new Response('{\"buildId\":\"\"}'"));
    expect(worker, isNot(contains('caches.delete(key);\n')));
    // Activate must keep CacheApiCourseMapPackStore's cache.
    expect(
      worker,
      contains("const COURSE_MAP_CACHE_PREFIX = 'golf-diary-course-maps'"),
    );
    expect(worker, contains('!key.startsWith(COURSE_MAP_CACHE_PREFIX)'));
    expect(
      worker,
      contains("const ATTEST_CACHE_PREFIX = 'golf-diary-attestations'"),
    );
    expect(worker, contains('!key.startsWith(ATTEST_CACHE_PREFIX)'));
    expect(
      File('lib/services/course_map_pack_store_web.dart').readAsStringSync(),
      contains("cacheName = 'golf-diary-course-maps-"),
    );
    expect(worker, contains("pathname.endsWith('/app_build.json')"));
    final applyIdx = worker.indexOf('async function applyUpdate');
    expect(applyIdx, greaterThan(-1));
    expect(
      worker.indexOf('await precacheShell()', applyIdx),
      greaterThan(applyIdx),
    );

    expect(build, contains('--no-web-resources-cdn'));
    expect(build, contains('useLocalCanvasKit'));
    expect(build, contains('precache_manifest.json'));

    final mainBody = mainSource
        .split('Future<void> main()')
        .last
        .split('Future<void> _startOptionalCloud()')
        .first;
    expect(mainBody, contains('runApp(const GolfDiaryApp())'));
    expect(mainBody, contains('unawaited(_startOptionalCloud())'));
    expect(mainBody.indexOf('runApp('),
        lessThan(mainBody.indexOf('unawaited(_startOptionalCloud())')));
    expect(mainBody, isNot(contains('initializeFirebase')));

    expect(startup, contains('kOptionalFirebaseStartupLimit'));
    expect(
      startup,
      contains('.timeout(kOptionalFirebaseStartupLimit)'),
    );
  });
}
