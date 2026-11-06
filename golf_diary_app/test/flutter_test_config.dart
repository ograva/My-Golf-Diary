import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
  }
  sqfliteFfiInit();
  // The isolate factory does not complete inside flutter test after sqflite 2.4.
  databaseFactory = databaseFactoryFfiNoIsolate;
  await databaseFactory.setDatabasesPath(
    Directory.systemTemp.createTempSync('golf_diary_test').path,
  );
  await testMain();
}
