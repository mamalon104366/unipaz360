import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'mapa_google_config.dart';

/// En la web el mapa va en un `<iframe>`, así que siempre se puede mostrar.
bool get mapaEmbebidoDisponible => true;

class GoogleMapsEmbed extends StatefulWidget {
  const GoogleMapsEmbed({super.key, this.uri});

  /// Lo que se abre; si falta, la ubicación del Centro de Investigaciones Santa Lucía.
  final Uri? uri;

  @override
  State<GoogleMapsEmbed> createState() => _GoogleMapsEmbedState();
}

class _GoogleMapsEmbedState extends State<GoogleMapsEmbed> {
  static var _siguienteId = 0;
  late final String _tipoVista;

  @override
  void initState() {
    super.initState();
    _tipoVista = 'unipaz-google-map-${_siguienteId++}';
    final url = widget.uri ?? googleMapsEmbedUri;
    ui_web.platformViewRegistry.registerViewFactory(_tipoVista, (viewId) {
      return web.HTMLIFrameElement()
        ..src = url.toString()
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true
        ..referrerPolicy = 'strict-origin-when-cross-origin';
    });
  }

  @override
  Widget build(BuildContext context) => HtmlElementView(viewType: _tipoVista);
}
