import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'mapa_google_config.dart';

/// `webview_flutter` solo existe en Android, iOS y macOS. En Windows (y Linux) no hay
/// WebView: crear el control lanza un error, así que allí se muestra el plano del dron.
bool get mapaEmbebidoDisponible => switch (defaultTargetPlatform) {
  TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.macOS => true,
  _ => false,
};

/// Muestra el marco de Google Maps en Android, iOS y macOS cuando hay internet.
/// Antes de usarlo, revisar [mapaEmbebidoDisponible].
class GoogleMapsEmbed extends StatefulWidget {
  const GoogleMapsEmbed({super.key, this.uri});

  /// Lo que se abre; si falta, la ubicación del Centro de Investigaciones Santa Lucía.
  final Uri? uri;

  @override
  State<GoogleMapsEmbed> createState() => _GoogleMapsEmbedState();
}

class _GoogleMapsEmbedState extends State<GoogleMapsEmbed> {
  late final WebViewController _controlador;

  @override
  void initState() {
    super.initState();
    _controlador = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..loadRequest(widget.uri ?? googleMapsEmbedUri);
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controlador);
}
