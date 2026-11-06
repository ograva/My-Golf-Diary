# golf_diary_app

Flutter app for My Golf Diary: club yardages, on-course shot logging, scorecard, and range drills.

## Getting Started

```bash
flutter pub get
flutter run
```

### Browser / PWA storage

The web build keeps the diary in the browser (SQLite over WASM, persisted in IndexedDB). Data survives a refresh in that browser. A different browser, cleared site data, or the Android APK has its own separate diary.

Generate the web SQLite assets before a Chrome run or web build:

```bash
dart run sqflite_common_ffi_web:setup
flutter run -d chrome
# or
flutter build web
```

### Tests

```bash
flutter test
```

