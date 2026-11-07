import 'dart:io';

/// google_fonts 6.3 downloads font files at runtime. `flutter test` stubs HTTP,
/// so those downloads throw. The app still loads the families outside tests.
bool get useGoogleFonts => !Platform.environment.containsKey('FLUTTER_TEST');
