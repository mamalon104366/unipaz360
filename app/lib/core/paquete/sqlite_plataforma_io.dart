import 'package:sqlite3/sqlite3.dart';

/// En Android, Windows, macOS e iOS SQLite ya está cargado.
Future<CommonSqlite3> cargarSqlite() async => sqlite3;
