/// «Tu experiencia»: lo que cada persona ajusta a su gusto (aspecto, cómo abre la app, los
/// botones que se atenúan y la orientación). Se guarda en su dispositivo. Se abre con el botón
/// redondo del engranaje.
library;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/modelo/config_app.dart';
import '../../domain/preferencias.dart';
import '../../ui/preferencias/preferencias_viewmodel.dart';
import 'estilo_cliente.dart';

/// Abre la hoja. [plataforma] es la configuración publicada: de ahí sale lo que vale cada
/// cosa mientras la persona no la cambie.
Future<void> mostrarAjustesCliente(
  BuildContext context, {
  required ConfigApp plataforma,
}) {
  final vm = context.read<PreferenciasViewModel>();
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x99000000),
    builder: (context) => ChangeNotifierProvider<PreferenciasViewModel>.value(
      value: vm,
      child: _HojaAjustes(plataforma: plataforma),
    ),
  );
}

const Color _fondo = Color(0xF71B1F27);
const Color _tenue = Color(0xB3FFFFFF);
const Color _linea = Color(0x24FFFFFF);

TextStyle _t(double tamano, {int peso = 400, Color color = Colors.white}) =>
    estiloTexto(tamano: tamano, peso: peso, color: color, alto: 1.4);

class _HojaAjustes extends StatelessWidget {
  const _HojaAjustes({required this.plataforma});

  final ConfigApp plataforma;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PreferenciasViewModel>();
    final p = vm.valor;
    final acento = colorHex(plataforma.marca.colorAcento);
    final estilo = p.estilo ?? plataforma.barraLateral.estilo;
    final atenuar = p.atenuar ?? plataforma.atenuar;
    final opacidad = p.atenuarOpacidad ?? plataforma.atenuarOpacidad;
    final mapa =
        p.mapaAbierto ?? plataforma.minimapa.estadoInicial != 'minimizado';
    final menu = p.menuAbierto ?? !plataforma.barraLateral.iniciaPlegada;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _fondo,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: _linea),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 40,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 8, 10),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0x1FFFFFFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.slidersHorizontal,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Tu experiencia', style: _t(18, peso: 700)),
                            Text(
                              'Se guarda en este dispositivo',
                              style: _t(12, color: _tenue),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          LucideIcons.x,
                          size: 20,
                          color: _tenue,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: _linea),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const _Titulo('Aspecto'),
                        Row(
                          children: <Widget>[
                            for (final e in estilosInterfaz) ...<Widget>[
                              if (e != estilosInterfaz.first)
                                const SizedBox(width: 10),
                              Expanded(
                                child: _TarjetaEstilo(
                                  estilo: e,
                                  elegido: e == estilo,
                                  acento: acento,
                                  alTocar: () => vm.cambiar(p.con(estilo: e)),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 20),
                        const _Titulo('Al abrir la app'),
                        _Interruptor(
                          icono: LucideIcons.sparkles,
                          texto: 'Animación de bienvenida',
                          valor: p.bienvenida,
                          acento: acento,
                          alCambiar: (v) => vm.cambiar(p.con(bienvenida: v)),
                        ),
                        _Interruptor(
                          icono: LucideIcons.map,
                          texto: 'Minimapa a la vista',
                          valor: mapa,
                          acento: acento,
                          alCambiar: (v) => vm.cambiar(p.con(mapaAbierto: v)),
                        ),
                        _Interruptor(
                          icono: LucideIcons.panelLeft,
                          texto: 'Menú lateral a la vista',
                          nota: 'En vertical el menú va abajo',
                          valor: menu,
                          acento: acento,
                          alCambiar: (v) => vm.cambiar(p.con(menuAbierto: v)),
                        ),
                        const SizedBox(height: 14),
                        const _Titulo('Botones'),
                        _Interruptor(
                          icono: LucideIcons.eyeOff,
                          texto: 'Atenuarlos si no los uso',
                          nota: 'Para ver mejor la foto 360°',
                          valor: atenuar,
                          acento: acento,
                          alCambiar: (v) => vm.cambiar(p.con(atenuar: v)),
                        ),
                        if (atenuar)
                          Padding(
                            padding: const EdgeInsets.only(left: 34, top: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        'Qué tanto se ven',
                                        style: _t(13.5, color: _tenue),
                                      ),
                                    ),
                                    Text(
                                      '${(opacidad * 100).round()} %',
                                      style: _t(13.5, peso: 600),
                                    ),
                                  ],
                                ),
                                SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 4,
                                    activeTrackColor: acento,
                                    inactiveTrackColor: const Color(0x33FFFFFF),
                                    thumbColor: Colors.white,
                                    overlayColor: const Color(0x1FFFFFFF),
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 9,
                                    ),
                                  ),
                                  child: Slider(
                                    value: opacidad.clamp(0.2, 0.9),
                                    min: 0.2,
                                    max: 0.9,
                                    divisions: 14,
                                    semanticFormatterCallback: (v) =>
                                        '${(v * 100).round()} por ciento',
                                    onChanged: (v) => vm.cambiar(
                                      p.con(
                                        atenuarOpacidad: (v * 20).round() / 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (PreferenciasViewModel.puedeGirar) ...<Widget>[
                          const SizedBox(height: 14),
                          const _Titulo('Pantalla'),
                          _Segmentos<Orientacion>(
                            valor: p.orientacion,
                            acento: acento,
                            opciones: const <(Orientacion, IconData, String)>[
                              (
                                Orientacion.automatica,
                                Icons.screen_rotation,
                                'Automática',
                              ),
                              (
                                Orientacion.horizontal,
                                Icons.stay_current_landscape,
                                'Horizontal',
                              ),
                              (
                                Orientacion.vertical,
                                Icons.stay_current_portrait,
                                'Vertical',
                              ),
                            ],
                            alCambiar: (o) => vm.cambiar(p.con(orientacion: o)),
                          ),
                        ],
                        if (p.personalizada) ...<Widget>[
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton.icon(
                              onPressed: vm.restablecer,
                              icon: const Icon(
                                LucideIcons.rotateCcw,
                                size: 15,
                                color: _tenue,
                              ),
                              label: Text(
                                'Volver a como viene la app',
                                style: _t(13.5, peso: 600, color: _tenue),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      texto.toUpperCase(),
      style: estiloTexto(
        tamano: 11,
        peso: 700,
        color: const Color(0x99FFFFFF),
        espaciado: 0.12,
      ),
    ),
  );
}

/// Una tarjeta con una miniatura de cómo se ve la app en ese estilo.
class _TarjetaEstilo extends StatelessWidget {
  const _TarjetaEstilo({
    required this.estilo,
    required this.elegido,
    required this.acento,
    required this.alTocar,
  });

  final String estilo;
  final bool elegido;
  final Color acento;
  final VoidCallback alTocar;

  static const Map<String, String> _nombres = <String, String>{
    'vidrio': 'Vidrio',
    'oscuro': 'Oscuro',
    'claro': 'Claro',
  };

  @override
  Widget build(BuildContext context) {
    final sup = Superficie.de(estilo);
    final nombre = _nombres[estilo] ?? estilo;
    return Semantics(
      button: true,
      selected: elegido,
      label: 'Aspecto $nombre',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: alTocar,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: elegido
                  ? const Color(0x1FFFFFFF)
                  : const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: elegido ? acento : _linea,
                width: elegido ? 2 : 1,
              ),
            ),
            child: Column(
              children: <Widget>[
                // La miniatura: un cielo con la barra y un botón en ese estilo.
                AspectRatio(
                  aspectRatio: 1.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Color(0xFF6DB3E8),
                                Color(0xFFBFE3F5),
                                Color(0xFF4E8F5A),
                              ],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: 0.36,
                            heightFactor: 1,
                            child: ColoredBox(
                              color: sup.fondo,
                              child: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    for (final w in const <double>[
                                      0.9,
                                      0.6,
                                      0.75,
                                    ])
                                      FractionallySizedBox(
                                        widthFactor: w,
                                        child: Container(
                                          height: 3,
                                          margin: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: sup.tinta.withValues(
                                              alpha: 0.75,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: const Alignment(0.88, -0.8),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: sup.fondo,
                              shape: BoxShape.circle,
                              border: sup.borde == null
                                  ? null
                                  : Border.all(color: sup.borde!, width: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (elegido) ...<Widget>[
                      Icon(LucideIcons.check, size: 13, color: acento),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      nombre,
                      style: _t(
                        13,
                        peso: elegido ? 700 : 500,
                        color: elegido ? Colors.white : _tenue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Interruptor extends StatelessWidget {
  const _Interruptor({
    required this.icono,
    required this.texto,
    required this.valor,
    required this.acento,
    required this.alCambiar,
    this.nota,
  });

  final IconData icono;
  final String texto;
  final String? nota;
  final bool valor;
  final Color acento;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: InkWell(
      onTap: () => alCambiar(!valor),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            Icon(icono, size: 18, color: _tenue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(texto, style: _t(14.5, peso: 500)),
                  if (nota != null) Text(nota!, style: _t(12, color: _tenue)),
                ],
              ),
            ),
            Switch(
              value: valor,
              onChanged: alCambiar,
              activeThumbColor: Colors.white,
              activeTrackColor: acento,
              inactiveThumbColor: const Color(0xFFCBD5E1),
              inactiveTrackColor: const Color(0x33FFFFFF),
              trackOutlineColor: const WidgetStatePropertyAll<Color>(
                Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Segmentos<T> extends StatelessWidget {
  const _Segmentos({
    required this.valor,
    required this.opciones,
    required this.acento,
    required this.alCambiar,
  });

  final T valor;
  final List<(T, IconData, String)> opciones;
  final Color acento;
  final ValueChanged<T> alCambiar;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0x14FFFFFF),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: <Widget>[
        for (final (v, icono, texto) in opciones)
          Expanded(
            child: Semantics(
              button: true,
              selected: v == valor,
              label: texto,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => alCambiar(v),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: v == valor ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: <Widget>[
                      Icon(
                        icono,
                        size: 18,
                        color: v == valor ? const Color(0xFF1C1C1F) : _tenue,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        texto,
                        style: _t(
                          12,
                          peso: 600,
                          color: v == valor ? const Color(0xFF1C1C1F) : _tenue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
