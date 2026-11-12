import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app/unipaz360_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // En el celular la app ocupa toda la pantalla: la barra de estado y los botones del
  // sistema se recogen, y vuelven al deslizar desde el borde. La orientación no se fuerza:
  // la decide la persona (ver «Tu experiencia»).
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
  }
  runApp(const UniPaz360App());
}
