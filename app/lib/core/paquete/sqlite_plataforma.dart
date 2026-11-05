/// SQLite en cada plataforma: la biblioteca nativa en Android, Windows, macOS e iOS
/// (la trae el paquete `sqlite3` con sus *hooks*) y WebAssembly en la web
/// (`web/sqlite3.wasm`, de la misma versión del paquete).
library;

export 'sqlite_plataforma_io.dart'
    if (dart.library.js_interop) 'sqlite_plataforma_web.dart';
