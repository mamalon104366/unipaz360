import 'package:sqlite3/wasm.dart';

Future<WasmSqlite3>? _cargando;

/// En la web se carga `sqlite3.wasm` una sola vez (está en `app/web/`).
Future<CommonSqlite3> cargarSqlite() =>
    _cargando ??= WasmSqlite3.loadFromUrlString('sqlite3.wasm');
