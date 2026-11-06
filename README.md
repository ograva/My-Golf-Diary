# My-Golf-Diary

Local-first **Golf Diary App** built with Flutter — club distances, fairway shot tracking (GPS + Haversine), scorekeeping, and driving-range drill logging with optional Firebase Firestore sync.

## Project layout

All application code lives in [`golf_diary_app/`](golf_diary_app/).

## Quick start

```bash
cd golf_diary_app
flutter pub get
flutter run
```

### Android location

Fine/coarse location permissions are declared in `android/app/src/main/AndroidManifest.xml`.

### Firebase sync (optional)

1. Create a Firebase project and add Android/iOS apps.
2. Run `flutterfire configure` inside `golf_diary_app/`.
3. Use the cloud upload button on the **On Course** tab (defaults to user id `local_user` until you wire auth).

## Features

| Tab | PRD feature |
|-----|-------------|
| **My Bag** | Club profiles, category filters, min/max/avg yardages, swing notes |
| **On Course** | Single-screen fairway HUD, GPS shot logging, penalties/mulligans/concede, hole scores |
| **Scorecard** | 18-hole table, tap-to-edit manual par/strokes/penalties per hole, out/in/total vs par |
| **Range** | 10-shot drill flow, swing cue card, updates club stats on save |

## Browser / PWA storage

On the web build, the same SQLite diary runs inside the browser (WASM + IndexedDB). Clubs, notes, rounds, and range sessions stay on that browser and survive a refresh. A new browser, cleared site storage, or the installed Android APK starts its own diary.

Before `flutter build web` or `flutter run -d chrome`, generate the web SQLite assets once (or after upgrading `sqflite_common_ffi_web`):

```bash
cd golf_diary_app
dart run sqflite_common_ffi_web:setup
```

## Tests

```bash
cd golf_diary_app
flutter test
```

