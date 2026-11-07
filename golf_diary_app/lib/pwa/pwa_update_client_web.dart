import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';

import 'pwa_published_build.dart';

@JS('golfDiaryFetchPublishedBuild')
external JSPromise<JSAny?> _fetchPublishedBuild();

@JS('golfDiaryApplyUpdate')
external void _applyPwaUpdate();

@JS('golfDiaryDisableServiceWorker')
external JSPromise<JSAny?> _disableServiceWorker();

Future<PwaPublishedBuild?> fetchPublishedBuild() async {
  try {
    final JSAny? result = await _fetchPublishedBuild().toDart;
    if (result == null) return null;
    final decoded = jsonDecode((result as JSString).toDart);
    if (decoded is! Map) return null;
    final buildId = decoded['buildId'];
    if (buildId is! String || buildId.trim().isEmpty) return null;
    final version = decoded['version'];
    return PwaPublishedBuild(
      buildId: buildId.trim(),
      version: version is String ? version.trim() : '',
    );
  } catch (_) {
    return null;
  }
}

Future<void> applyPwaUpdate() async {
  _applyPwaUpdate();
}

Future<void> preparePwaSession() async {
  if (!kDebugMode) return;
  try {
    await _disableServiceWorker().toDart;
  } catch (_) {
    // The page script is absent in widget tests that compile this library.
  }
}
