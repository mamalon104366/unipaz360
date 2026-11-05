// `dart.library.js_interop` existe en la web con dart2js y con dart2wasm;
// `dart.library.html` no existe en dart2wasm y elegiría la versión con WebView.
export 'google_maps_embed_stub.dart'
    if (dart.library.js_interop) 'google_maps_embed_web.dart';
