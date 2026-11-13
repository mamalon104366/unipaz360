/// Las insignias del recorrido guiado: la hoja con los lugares ganados y por ganar, y el aviso
/// que sale al ganar una. Ver `domain/insignias.dart`.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/modelo/config_app.dart';
import '../../domain/insignias.dart';
import '../asistente/asistente.dart' show Lugar;
import 'estilo_cliente.dart';

const Color _oro = Color(0xFFF5B301);
const Color _oroClaro = Color(0xFFFFE08A);

/// El ícono de la insignia de un lugar, según su categoría.
IconData iconoLugar(Lugar l) => switch (l.categoria) {
  'biblioteca' => LucideIcons.bookOpen,
  'laboratorio' => LucideIcons.flaskConical,
  'aula' => LucideIcons.school,
  'oficina' => LucideIcons.briefcase,
  'auditorio' => LucideIcons.theater,
  'cafeteria' => LucideIcons.coffee,
  'deportivo' => LucideIcons.trophy,
  'bano' => LucideIcons.droplets,
  'parqueadero' => LucideIcons.car,
  'porteria' => LucideIcons.doorOpen,
  _ => LucideIcons.mapPin,
};

Future<void> mostrarInsignias(
  BuildContext context, {
  required ConfigApp config,
  required List<Lugar> lugares,
  required Insignias insignias,
}) => showDialog<void>(
  context: context,
  barrierColor: const Color(0x99000000),
  builder: (_) => HojaInsignias(config: config, lugares: lugares, insignias: insignias),
);

class HojaInsignias extends StatelessWidget {
  const HojaInsignias({super.key, required this.config, required this.lugares, required this.insignias});

  final ConfigApp config;
  final List<Lugar> lugares;
  final Insignias insignias;

  @override
  Widget build(BuildContext context) {
    final primario = colorHex(config.marca.colorPrimario);
    // Las ganadas primero (las más recientes arriba); luego las que faltan.
    final ganadas = lugares.where((l) => insignias.tiene(l.id)).toList()
      ..sort((a, b) => insignias.lugares[b.id]!.compareTo(insignias.lugares[a.id]!));
    final faltan = lugares.where((l) => !insignias.tiene(l.id)).toList();
    final total = lugares.length;
    final avance = total == 0 ? 0.0 : ganadas.length / total;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    // Los dos colores de la marca, como Paz y el recorrido guiado.
                    colors: <Color>[primario, colorHex(config.marca.colorAcento, porDefecto: const Color(0xFF0A9640))],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: avance,
                              strokeWidth: 6,
                              color: _oro,
                              backgroundColor: const Color(0x33FFFFFF),
                            ),
                          ),
                          Text(
                            '${ganadas.length}/$total',
                            style: estiloTexto(tamano: 15, peso: 800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Tus insignias', style: estiloTexto(tamano: 20, peso: 800, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(
                            'Gana una por cada lugar al que llegues con el recorrido guiado. Se guardan en este dispositivo.',
                            style: estiloTexto(tamano: 12.5, color: const Color(0xD9FFFFFF), alto: 1.4),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(LucideIcons.x, size: 20, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: total == 0
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Todavía no hay lugares con nombre para coleccionar.',
                          textAlign: TextAlign.center,
                          style: estiloTexto(tamano: 14, color: const Color(0xFF5F6B7A)),
                        ),
                      )
                    : GridView.extent(
                        shrinkWrap: true,
                        maxCrossAxisExtent: 128,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.82,
                        padding: const EdgeInsets.all(16),
                        children: <Widget>[
                          for (final l in ganadas) _Medalla(lugar: l, ganada: true),
                          for (final l in faltan) _Medalla(lugar: l, ganada: false),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Medalla extends StatelessWidget {
  const _Medalla({required this.lugar, required this.ganada});

  final Lugar lugar;
  final bool ganada;

  @override
  Widget build(BuildContext context) => Semantics(
    label: ganada ? 'Insignia ganada: ${lugar.nombre}' : 'Insignia por ganar: ${lugar.nombre}',
    excludeSemantics: true,
    child: Column(
      children: <Widget>[
        MedallaLugar(lugar: lugar, ganada: ganada, lado: 64),
        const SizedBox(height: 8),
        Text(
          lugar.nombre,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: estiloTexto(
            tamano: 12.5,
            peso: ganada ? 700 : 500,
            color: ganada ? const Color(0xFF1C1C1F) : const Color(0xFF8A94A3),
            alto: 1.25,
          ),
        ),
      ],
    ),
  );
}

/// La medalla de un lugar: dorada si se ganó, gris con candado si falta.
class MedallaLugar extends StatelessWidget {
  const MedallaLugar({super.key, required this.lugar, required this.ganada, this.lado = 64});

  final Lugar lugar;
  final bool ganada;
  final double lado;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: lado,
    height: lado,
    child: Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: ganada
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[_oroClaro, _oro, Color(0xFFC98A00)],
                  )
                : null,
            color: ganada ? null : const Color(0xFFE7EAEE),
            border: Border.all(color: ganada ? const Color(0xFFFFF3C4) : const Color(0xFFD5DAE1), width: lado * 0.05),
            boxShadow: ganada
                ? <BoxShadow>[BoxShadow(color: _oro.withValues(alpha: 0.45), blurRadius: lado * 0.25, offset: Offset(0, lado * 0.06))]
                : null,
          ),
          child: Center(
            child: Icon(iconoLugar(lugar), size: lado * 0.42, color: ganada ? const Color(0xFF5A3D00) : const Color(0xFFB3BBC6)),
          ),
        ),
        if (!ganada)
          Positioned(
            right: -lado * 0.02,
            bottom: -lado * 0.02,
            child: Container(
              width: lado * 0.34,
              height: lado * 0.34,
              decoration: const BoxDecoration(color: Color(0xFF8A94A3), shape: BoxShape.circle),
              child: Icon(LucideIcons.lock, size: lado * 0.18, color: Colors.white),
            ),
          ),
      ],
    ),
  );
}

/// El aviso «Nueva insignia» que baja desde arriba y se va solo.
class AvisoInsignia extends StatefulWidget {
  const AvisoInsignia({super.key, required this.lugar, required this.alTerminar, this.alTocar});

  final Lugar lugar;
  final VoidCallback alTerminar;
  final VoidCallback? alTocar;

  @override
  State<AvisoInsignia> createState() => _AvisoInsigniaState();
}

class _AvisoInsigniaState extends State<AvisoInsignia> with SingleTickerProviderStateMixin {
  late final AnimationController _brillo = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _reloj = Timer(const Duration(milliseconds: 3600), widget.alTerminar);
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _brillo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(begin: 0, end: 1),
    duration: const Duration(milliseconds: 520),
    curve: Curves.elasticOut,
    builder: (context, v, hijo) => Transform.scale(scale: 0.6 + 0.4 * v, child: Opacity(opacity: v.clamp(0.0, 1.0), child: hijo)),
    child: Semantics(
      liveRegion: true,
      label: 'Nueva insignia: ${widget.lugar.nombre}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.alTocar,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
          decoration: BoxDecoration(
            color: const Color(0xF21C1C1F),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x55FFE08A)),
            boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x80000000), blurRadius: 18, offset: Offset(0, 8))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedBuilder(
                animation: _brillo,
                builder: (context, hijo) => Transform.rotate(
                  angle: math.sin(_brillo.value * 2 * math.pi) * 0.12,
                  child: hijo,
                ),
                child: MedallaLugar(lugar: widget.lugar, ganada: true, lado: 40),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('¡Nueva insignia!', style: estiloTexto(tamano: 11.5, peso: 800, color: _oroClaro, espaciado: 0.06)),
                    Text(
                      widget.lugar.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: estiloTexto(tamano: 15, peso: 700, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
