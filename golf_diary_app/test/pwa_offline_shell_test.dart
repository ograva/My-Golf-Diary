import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release shell is precached and startup does not wait on Firebase', () {
    final worker = File('web/pwa_service_worker.js').readAsStringSync();
    final build = File('tool/build_web.sh').readAsStringSync();
    final mainSource = File('lib/main.dart').readAsStringSync();
    final startup = File('lib/services/cloud_sync_service.dart').readAsStringSync();

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
    expect(worker, contains("pathname.endsWith('/app_build.json')"));

    expect(build, contains('--no-web-resources-cdn'));
    expect(build, contains('useLocalCanvasKit'));
    expect(build, contains('precache_manifest.json'));

    final mainBody = mainSource.split('Future<void> main()').last.split('Future<void> _startOptionalCloud()').first;
    expect(mainBody, contains('runApp(const GolfDiaryApp())'));
    expect(mainBody, contains('unawaited(_startOptionalCloud())'));
    expect(mainBody.indexOf('runApp('), lessThan(mainBody.indexOf('unawaited(_startOptionalCloud())')));
    expect(mainBody, isNot(contains('initializeFirebase')));

    expect(startup, contains('kOptionalFirebaseStartupLimit'));
    expect(
      startup,
      contains('.timeout(kOptionalFirebaseStartupLimit)'),
    );
  });
}