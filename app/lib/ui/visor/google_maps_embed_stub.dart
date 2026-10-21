import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'mapa_google_config.dart';

/// Muestra el marco de Google Maps en Android y iOS cuando hay internet.
class GoogleMapsEmbed extends StatefulWidget {
  const GoogleMapsEmbed({super.key});

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
      ..loadRequest(googleMapsEmbedUri);
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controlador);
}
