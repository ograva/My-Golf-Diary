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

@JS('golfDiaryReadDismissedBuildId')
external JSString? _readDismissedBuildId();

@JS('golfDiaryWriteDismissedBuildId')
external void _writeDismissedBuildId(JSString? buildId);

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

Future<String?> readDismissedBuildId() async {
  try {
    final raw = _readDismissedBuildId();
    if (raw == null) return null;
    final value = raw.toDart.trim();
    return value.isEmpty ? null : value;
  } catch (_) {
    return null;
  }
}

Future<void> writeDismissedBuildId(String? buildId) async {
  try {
    _writeDismissedBuildId(
      buildId == null || buildId.trim().isEmpty ? null : buildId.trim().toJS,
    );
  } catch (_) {
    // sessionStorage blocked in some privacy modes
  }
}

Future<void> preparePwaSession() async {
  if (!kDebugMode) return;
  try {
    await _disableServiceWorker().toDart;
  } catch (_) {
    // The page script is absent in widget tests that compile this library.
  }
}
