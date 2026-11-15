import 'package:flutter/foundation.dart';

/// Parsed deep link: `?mode=caddy&request=<opaque_token>`.
class CaddyLaunchConfig {
  const CaddyLaunchConfig({required this.requestToken});

  final String requestToken;

  static CaddyLaunchConfig? fromUri(Uri uri) {
    if (uri.queryParameters['mode'] != 'caddy') return null;
    final token = uri.queryParameters['request']?.trim();
    if (token == null || token.isEmpty) return null;
    return CaddyLaunchConfig(requestToken: token);
  }

  static CaddyLaunchConfig? currentPlatformLaunch() {
    if (!kIsWeb) return null;
    return fromUri(Uri.base);
  }

  /// PWA invite URL embedded in the golfer QR (no golfer uid in query).
  static String buildInviteUrl(String requestToken) {
    if (kIsWeb) {
      final base = Uri.base;
      final path = base.path.endsWith('/') ? base.path : '${base.path}/';
      return Uri(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
        path: path,
        queryParameters: {
          'mode': 'caddy',
          'request': requestToken,
        },
      ).toString();
    }
    const hostedPwa =
        'https://ograva.github.io/My-Golf-Diary/';
    return '$hostedPwa?mode=caddy&request=$requestToken';
  }
}