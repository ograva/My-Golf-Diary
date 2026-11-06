import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Linux and Windows have no sqflite plugin, so use the FFI factory.
Future<void> initDesktopDatabase() async {
  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
