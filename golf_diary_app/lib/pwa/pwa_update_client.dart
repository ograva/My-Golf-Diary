import 'pwa_published_build.dart';
import 'pwa_update_client_stub.dart'
    if (dart.library.js_interop) 'pwa_update_client_web.dart' as impl;

/// Reads the published build id and applies an update the golfer already accepted.
abstract class PwaUpdateClient {
  const PwaUpdateClient();

  Future<PwaPublishedBuild?> fetchPublishedBuild();

  Future<void> applyUpdate();
}

class PlatformPwaUpdateClient extends PwaUpdateClient {
  const PlatformPwaUpdateClient();

  @override
  Future<PwaPublishedBuild?> fetchPublishedBuild() =>
      impl.fetchPublishedBuild();

  @override
  Future<void> applyUpdate() => impl.applyPwaUpdate();
}

Future<void> preparePwaSession() => impl.preparePwaSession();
