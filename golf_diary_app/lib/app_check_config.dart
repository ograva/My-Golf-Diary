import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Public reCAPTCHA Enterprise site key for the web app on `novusinc-8df79`.
///
/// This is client config, like the Firebase web API key. It is not a server secret.
const String kRecaptchaSiteKey = '6Lcd0xwuAAAAAITS9nQa0SdLNAUqYqkSYJKlbnc3';

/// Web App Check turns on only when a site key is present.
bool shouldActivateAppCheck({required bool isWeb, required String siteKey}) {
  return isWeb && siteKey.trim().isNotEmpty;
}

/// Activates App Check for the web PWA. A failure here does not take Firebase down.
Future<void> activateWebAppCheck() async {
  if (!shouldActivateAppCheck(isWeb: kIsWeb, siteKey: kRecaptchaSiteKey)) {
    return;
  }
  try {
    await FirebaseAppCheck.instance.activate(
      providerWeb: ReCaptchaEnterpriseProvider(kRecaptchaSiteKey),
    );
  } catch (error, stack) {
    debugPrint('App Check activation failed: $error\n$stack');
  }
}

/// `ready` when a token exists. The token itself is never returned.
Future<String> appCheckDebugState() async {
  if (Firebase.apps.isEmpty) return 'missing';
  try {
    final token = await FirebaseAppCheck.instance.getToken();
    if (token == null || token.isEmpty) return 'missing';
    return 'ready';
  } catch (_) {
    return 'missing';
  }
}
