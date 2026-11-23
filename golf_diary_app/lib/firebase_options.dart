import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Client config for Firebase project `novusinc-8df79`.
///
/// The web app id is the one registered for My Golf Diary. Android, iOS, and
/// desktop reuse it until `flutterfire configure` registers those apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCs1BB64kAYt-nilCV1oPSuga0E0bYtIRM',
    appId: '1:136052275501:web:c6c2a53466b0b163bdfba4',
    messagingSenderId: '136052275501',
    projectId: 'novusinc-8df79',
    authDomain: 'novusinc-8df79.firebaseapp.com',
    databaseURL: 'https://novusinc-8df79.firebaseio.com',
    storageBucket: 'novusinc-8df79.appspot.com',
  );

  /// OAuth Web client ID (Firebase console → Authentication → Google → Web SDK).
  ///
  /// Public client config (not a secret). Override at build time with
  /// `--dart-define=GOOGLE_WEB_CLIENT_ID=...` if you rotate the OAuth client.
  static const String kDefaultGoogleWebClientId =
      '136052275501-0bsk50jam3gcg9eibqgkcq7rnksr9533.apps.googleusercontent.com';

  static String get googleWebClientId {
    const fromEnv = String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue: kDefaultGoogleWebClientId,
    );
    return fromEnv.trim();
  }
}
