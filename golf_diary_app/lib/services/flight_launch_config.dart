import 'package:flutter/foundation.dart';

/// Parsed deep link: `?mode=flight&token=<opaque>`.
class FlightLaunchConfig {
  const FlightLaunchConfig({required this.token});

  final String token;

  static FlightLaunchConfig? fromUri(Uri uri) {
    if (uri.queryParameters['mode'] != 'flight') return null;
    final token = uri.queryParameters['token']?.trim();
    if (token == null || token.isEmpty) return null;
    return FlightLaunchConfig(token: token);
  }

  static FlightLaunchConfig? currentPlatformLaunch() {
    if (!kIsWeb) return null;
    return fromUri(Uri.base);
  }

  static String buildInviteUrl(String token) {
    if (kIsWeb) {
      final base = Uri.base;
      final path = base.path.endsWith('/') ? base.path : '${base.path}/';
      return Uri(
        scheme: base.scheme,
        host: base.host,
        port: base.hasPort ? base.port : null,
        path: path,
        queryParameters: {
          'mode': 'flight',
          'token': token,
        },
      ).toString();
    }
    const hostedPwa = 'https://ograva.github.io/My-Golf-Diary/';
    return '$hostedPwa?mode=flight&token=$token';
  }
}
