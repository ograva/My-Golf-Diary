import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Browser builds have no mobile sqflite plugin, so use the WASM factory.
Future<void> initDesktopDatabase() async {
  databaseFactory = databaseFactoryFfiWeb;
}
