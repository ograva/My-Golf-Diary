import 'dart:async';
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  sqfliteFfiInit();
  // The isolate factory does not complete inside flutter test after sqflite 2.4.
  // sqlite3 3 loads its native library through build hooks, so no manual open() override.
  databaseFactory = databaseFactoryFfiNoIsolate;
  await databaseFactory.setDatabasesPath(
    Directory.systemTemp.createTempSync('golf_diary_test').path,
  );
  await testMain();
}
