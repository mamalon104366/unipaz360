/// El lector de las placas QR del campus (solo en el celular). Se abre con el botón del QR, lee
/// `unipaz360://nodo/<id>` y devuelve el nodo: así la app sabe dónde está la persona. Si no hay
/// una placa cerca o no hay permiso de cámara, deja elegir el lugar a mano.
library;

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/modelo/config_app.dart';
import '../ubicacion/codigo_qr.dart';
import 'estilo_cliente.dart';

/// Lo que devuelve el lector.
sealed class ResultadoQr {
  const ResultadoQr();
}

/// Se leyó la placa de un nodo que existe en el paquete.
class QrDeNodo extends ResultadoQr {
  const QrDeNodo(this.nodoId);

  final String nodoId;
}

/// La persona prefirió elegir el lugar a mano.
class QrALaMano extends ResultadoQr {
  const QrALaMano();
}

/// Abre el lector a pantalla completa. [existe] dice si un nodo está en el paquete.
Future<ResultadoQr?> abrirEscanerQr(
  BuildContext context, {
  required ConfigApp config,
  required bool Function(String nodoId) existe,
}) => Navigator.of(context).push<ResultadoQr>(
  MaterialPageRoute<ResultadoQr>(
    fullscreenDialog: true,
    builder: (_) => PantallaEscanerQr(config: config, existe: existe),
  ),
);

class PantallaEscanerQr extends StatefulWidget {
  const PantallaEscanerQr({
    super.key,
    required this.config,
    required this.existe,
    this.camara,
  });

  final ConfigApp config;
  final bool Function(String nodoId) existe;

  /// La vista de la cámara (las pruebas ponen otra: no hay cámara en ellas).
  final Widget Function(
    BuildContext context,
    Rect ventana,
    void Function(String texto) alLeer,
  )?
  camara;

  @override
  State<PantallaEscanerQr> createState() => PantallaEscanerQrState();
}

class PantallaEscanerQrState extends State<PantallaEscanerQr>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _control;
  late final AnimationController _linea = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  bool _listo = false;
  String? _aviso;
  String? _ultimo;
  Timer? _borrarAviso;

  @override
  void initState() {
    super.initState();
    if (widget.camara == null) {
      _control = MobileScannerController(
        formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
        detectionTimeoutMs: 400,
      );
    }
  }

  @override
  void dispose() {
    _borrarAviso?.cancel();
    _linea.dispose();
    unawaited(_control?.dispose());
    super.dispose();
  }

  /// Un código leído: si es una placa del campus, se cierra con su nodo.
  void leer(String texto) {
    if (_listo || !mounted) return;
    final id = nodoDeCodigo(texto);
    if (id != null && widget.existe(id)) {
      _listo = true;
      unawaited(HapticFeedback.mediumImpact());
      unawaited(_control?.stop());
      Navigator.of(context).pop(QrDeNodo(id));
      return;
    }
    // El mismo código no repite el aviso mientras siga a la vista.
    if (texto == _ultimo && _aviso != null) return;
    _ultimo = texto;
    _avisar(
      id == null ? 'Ese código no es una placa de UniPaz360.' : 'Esa placa es de un punto que no está en esta versión del campus. Actualiza la app.',
    );
  }

  void _avisar(String texto) {
    _borrarAviso?.cancel();
    setState(() => _aviso = texto);
    _borrarAviso = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) setState(() => _aviso = null);
    });
  }

  void _aLaMano() {
    if (_listo) return;
    _listo = true;
    Navigator.of(context).pop(const QrALaMano());
  }

  @override
  Widget build(BuildContext context) {
    final acento = colorHex(widget.config.marca.colorAcento);
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, c) {
          final tam = Size(c.maxWidth, c.maxHeight);
          final vertical = tam.height > tam.width;
          // De pie, la ventana va centrada con el texto debajo; acostado (poca altura), va a la
          // izquierda y el texto y el botón quedan a su lado.
          final lado = (tam.shortestSide * (vertical ? 0.62 : 0.6)).clamp(
            190.0,
            320.0,
          );
          final ventana = Rect.fromCenter(
            center: vertical
                ? Offset(tam.width / 2, tam.height * 0.44)
                : Offset(tam.width * 0.36, tam.height * 0.54),
            width: lado,
            height: lado,
          );
          final aviso = AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _aviso == null
                ? const SizedBox(height: 12)
                : Padding(
                    key: ValueKey<String>(_aviso!),
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xE6B45309),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _aviso!,
                        textAlign: TextAlign.center,
                        style: estiloTexto(
                          tamano: 13.5,
                          peso: 600,
                          color: Colors.white,
                          alto: 1.35,
                        ),
                      ),
                    ),
                  ),
          );
          final pista = Text(
            'Apunta a la placa con el código QR. Se lee sola.',
            textAlign: TextAlign.center,
            style: estiloTexto(
              tamano: 14.5,
              color: const Color(0xE6FFFFFF),
              alto: 1.45,
            ),
          );
          final aLaMano = _BotonTexto(
            icono: LucideIcons.listChecks,
            texto: 'No veo una placa · Elegir el lugar',
            alTocar: _aLaMano,
          );
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (widget.camara != null)
                widget.camara!(context, ventana, leer)
              else
                MobileScanner(
                  controller: _control,
                  scanWindow: ventana,
                  onDetect: (captura) {
                    for (final b in captura.barcodes) {
                      final t = b.rawValue;
                      if (t != null) {
                        leer(t);
                        if (_listo) return;
                      }
                    }
                  },
                  errorBuilder: (context, error) => _SinCamara(
                    permiso:
                        error.errorCode ==
                        MobileScannerErrorCode.permissionDenied,
                    alElegir: _aLaMano,
                  ),
                ),
              // Oscurece todo menos la ventana, y dibuja sus esquinas y la línea que la recorre.
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _linea,
                  builder: (context, _) => CustomPaint(
                    painter: _Marco(
                      ventana: ventana,
                      acento: acento,
                      linea: Curves.easeInOut.transform(_linea.value),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: <Widget>[
                        _BotonRedondo(
                          icono: LucideIcons.x,
                          ayuda: 'Cerrar el lector',
                          alTocar: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Escanea la placa QR',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: estiloTexto(
                              tamano: 18,
                              peso: 700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (_control != null)
                          ValueListenableBuilder<MobileScannerState>(
                            valueListenable: _control!,
                            builder: (context, estado, _) =>
                                estado.torchState == TorchState.unavailable
                                ? const SizedBox.shrink()
                                : _BotonRedondo(
                                    icono: estado.torchState == TorchState.on
                                        ? LucideIcons.flashlightOff
                                        : LucideIcons.flashlight,
                                    ayuda: estado.torchState == TorchState.on
                                        ? 'Apagar la linterna'
                                        : 'Encender la linterna',
                                    alTocar: () =>
                                        unawaited(_control!.toggleTorch()),
                                  ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (vertical) ...<Widget>[
                Positioned(
                  left: 24,
                  right: 24,
                  top: ventana.bottom + 22,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[pista, aviso],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                      child: Center(child: aLaMano),
                    ),
                  ),
                ),
              ] else
                Positioned(
                  left: ventana.right + 32,
                  right: 24,
                  top: ventana.top,
                  bottom: tam.height - ventana.bottom,
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    left: false,
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            pista,
                            aviso,
                            const SizedBox(height: 12),
                            aLaMano,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// El velo oscuro con la ventana del lector, sus esquinas y la línea que la recorre.
class _Marco extends CustomPainter {
  const _Marco({
    required this.ventana,
    required this.acento,
    required this.linea,
  });

  final Rect ventana;
  final Color acento;
  final double linea;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(ventana, const Radius.circular(24));
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(r),
      ),
      Paint()..color = const Color(0x99000000),
    );
    final esquina = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const l = 34.0;
    const rad = 24.0;
    final w = ventana;
    for (final (x, y, sx, sy) in <(double, double, double, double)>[
      (w.left, w.top, 1, 1),
      (w.right, w.top, -1, 1),
      (w.left, w.bottom, 1, -1),
      (w.right, w.bottom, -1, -1),
    ]) {
      final p = Path()
        ..moveTo(x, y + sy * l)
        ..lineTo(x, y + sy * rad)
        ..arcToPoint(
          Offset(x + sx * rad, y),
          radius: const Radius.circular(rad),
          clockwise: sx * sy > 0,
        )
        ..lineTo(x + sx * l, y);
      canvas.drawPath(p, esquina);
    }
    final y = w.top + 18 + (w.height - 36) * linea;
    canvas.drawLine(
      Offset(w.left + 20, y),
      Offset(w.right - 20, y),
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            acento.withValues(alpha: 0),
            acento,
            acento.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(w.left, y - 1, w.width, 2))
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(_Marco viejo) =>
      viejo.linea != linea || viejo.ventana != ventana;
}

class _SinCamara extends StatelessWidget {
  const _SinCamara({required this.permiso, required this.alElegir});

  final bool permiso;
  final VoidCallback alElegir;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF111318),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(LucideIcons.cameraOff, size: 44, color: Colors.white70),
            const SizedBox(height: 16),
            Text(
              permiso
                  ? 'No hay permiso para usar la cámara'
                  : 'No se pudo abrir la cámara',
              textAlign: TextAlign.center,
              style: estiloTexto(tamano: 18, peso: 700, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              permiso
                  ? 'Puedes darlo en los ajustes del celular, o elegir a mano el lugar donde estás.'
                  : 'Puedes elegir a mano el lugar donde estás.',
              textAlign: TextAlign.center,
              style: estiloTexto(
                tamano: 14,
                color: const Color(0xB3FFFFFF),
                alto: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            _BotonTexto(
              icono: LucideIcons.listChecks,
              texto: 'Elegir el lugar',
              alTocar: alElegir,
            ),
          ],
        ),
      ),
    ),
  );
}

class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({
    required this.icono,
    required this.ayuda,
    required this.alTocar,
  });

  final IconData icono;
  final String ayuda;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: ayuda,
    child: Semantics(
      button: true,
      label: ayuda,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: alTocar,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0x66000000),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x40FFFFFF)),
          ),
          child: Icon(icono, size: 20, color: Colors.white),
        ),
      ),
    ),
  );
}

class _BotonTexto extends StatelessWidget {
  const _BotonTexto({
    required this.icono,
    required this.texto,
    required this.alTocar,
  });

  final IconData icono;
  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(999),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: alTocar,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icono, size: 18, color: const Color(0xFF1C1C1F)),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                texto,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: estiloTexto(
                  tamano: 14.5,
                  peso: 600,
                  color: const Color(0xFF1C1C1F),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
