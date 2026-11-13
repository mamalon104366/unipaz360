/// Dónde está la persona. En el celular lo dice el QR de una placa; en el computador y en la
/// web (y en el celular si no hay placa cerca) se elige en esta hoja: un lugar con nombre, una
/// foto 360° o un punto del mapa. Al saberlo, la app avisa «Estás en…».
library;

import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/modelo/config_app.dart';
import '../../core/paquete/datos_paquete.dart';
import '../asistente/texto.dart' show normalizar, palabras;
import 'estilo_cliente.dart';

/// Un sitio donde puede estar la persona.
class SitioUbicable {
  const SitioUbicable({
    required this.nodoId,
    required this.nombre,
    this.detalle,
    this.foto = false,
  });

  final String nodoId;
  final String nombre;

  /// «Bloque 2, planta baja», «Foto 360°»…
  final String? detalle;

  /// Tiene foto 360°: al elegirlo, la app la abre.
  final bool foto;
}

/// Cómo se nombra el sitio de un nodo: su lugar con nombre, su foto 360° o «el punto V-001».
String nombreDelNodo(DatosPaquete datos, String nodoId) {
  final lugar = datos.guia.lugarDelNodo(nodoId);
  if (lugar != null && !lugar.nombre.startsWith('el punto ')) {
    return lugar.nombreConCodigo;
  }
  final foto = datos.panoramicaPorVertice[nodoId];
  if (foto != null && foto.titulo.trim().isNotEmpty && foto.titulo != nodoId) {
    return foto.titulo;
  }
  return 'el punto $nodoId';
}

/// Los sitios para elegir: primero los lugares con nombre, luego las fotos 360° de los demás nodos.
List<SitioUbicable> sitiosUbicables(DatosPaquete datos) {
  final vistos = <String>{};
  final sitios = <SitioUbicable>[];
  for (final l in datos.guia.lugares) {
    if (!vistos.add('${l.nodoId}|${l.nombreConCodigo}')) continue;
    sitios.add(
      SitioUbicable(
        nodoId: l.nodoId,
        nombre: l.nombreConCodigo,
        detalle: l.ubicacion.isEmpty ? null : l.ubicacion,
        foto: datos.panoramicaPorVertice.containsKey(l.nodoId),
      ),
    );
  }
  final conNombre = <String>{for (final s in sitios) s.nodoId};
  for (final p in datos.panoramicas) {
    if (conNombre.contains(p.verticeId) || !vistos.add('foto|${p.verticeId}')) {
      continue;
    }
    sitios.add(
      SitioUbicable(
        nodoId: p.verticeId,
        nombre: nombreDelNodo(datos, p.verticeId),
        detalle: 'Foto 360°',
        foto: true,
      ),
    );
  }
  return sitios;
}

/// Lo que se elige en la hoja: un nodo o «elegir en el mapa».
sealed class EleccionUbicacion {
  const EleccionUbicacion();
}

class UbicacionEnNodo extends EleccionUbicacion {
  const UbicacionEnNodo(this.nodoId);

  final String nodoId;
}

class UbicacionEnMapa extends EleccionUbicacion {
  const UbicacionEnMapa();
}

/// Abre la hoja «¿Dónde estás?».
Future<EleccionUbicacion?> elegirUbicacion(
  BuildContext context, {
  required ConfigApp config,
  required List<SitioUbicable> sitios,
  required bool enCelular,
  required bool hayMapa,
}) => showDialog<EleccionUbicacion>(
  context: context,
  barrierColor: const Color(0x99000000),
  builder: (_) => HojaUbicacion(
    config: config,
    sitios: sitios,
    enCelular: enCelular,
    hayMapa: hayMapa,
  ),
);

class HojaUbicacion extends StatefulWidget {
  const HojaUbicacion({
    super.key,
    required this.config,
    required this.sitios,
    required this.enCelular,
    required this.hayMapa,
  });

  final ConfigApp config;
  final List<SitioUbicable> sitios;

  /// En el celular el QR se lee con la app; aquí solo se elige a mano.
  final bool enCelular;
  final bool hayMapa;

  @override
  State<HojaUbicacion> createState() => _HojaUbicacionState();
}

class _HojaUbicacionState extends State<HojaUbicacion> {
  final TextEditingController _buscar = TextEditingController();

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  List<SitioUbicable> get _filtrados {
    final t = palabras(normalizar(_buscar.text));
    if (t.isEmpty) return widget.sitios;
    return <SitioUbicable>[
      for (final s in widget.sitios)
        if (t.every(
          normalizar('${s.nombre} ${s.detalle ?? ''} ${s.nodoId}').contains,
        ))
          s,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final primario = colorHex(widget.config.marca.colorPrimario);
    final lista = _filtrados;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 620),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                color: primario,
                padding: const EdgeInsets.fromLTRB(20, 18, 8, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: tintaSobre(primario).withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.locateFixed,
                        size: 20,
                        color: tintaSobre(primario),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '¿Dónde estás?',
                            style: estiloTexto(
                              tamano: 19,
                              peso: 700,
                              color: tintaSobre(primario),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.enCelular
                                ? 'Elige el lugar donde estás. Si ves una placa con código QR, escanéala y es más rápido.'
                                : 'En el campus hay placas con código QR: escanéalas con la app UniPaz360 en tu celular '
                                      'para ubicarte al instante. Aquí puedes elegir el lugar a mano.',
                            style: estiloTexto(
                              tamano: 13,
                              color: tintaSobre(primario)
                                  .withValues(alpha: 0.82),
                              alto: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        LucideIcons.x,
                        size: 20,
                        color: tintaSobre(primario),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.sitios.length > 5)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: TextField(
                    controller: _buscar,
                    onChanged: (_) => setState(() {}),
                    style: estiloTexto(
                      tamano: 14.5,
                      color: const Color(0xFF1C1C1F),
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      hintText: 'Buscar un lugar',
                      filled: true,
                      fillColor: const Color(0xFFF1F3F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              Flexible(
                child: widget.sitios.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Todavía no hay lugares con nombre ni fotos 360° para elegir. '
                          'Se agregan desde la plataforma de gestión.',
                          textAlign: TextAlign.center,
                          style: estiloTexto(
                            tamano: 14,
                            color: const Color(0xFF5F6B7A),
                            alto: 1.45,
                          ),
                        ),
                      )
                    : lista.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No encontré ese lugar.',
                          textAlign: TextAlign.center,
                          style: estiloTexto(
                            tamano: 14,
                            color: const Color(0xFF5F6B7A),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        itemCount: lista.length,
                        separatorBuilder: (context, i) =>
                            const SizedBox(height: 2),
                        itemBuilder: (context, i) {
                          final s = lista[i];
                          return Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () =>
                                  Navigator.of(context)
                                      .pop(UbicacionEnNodo(s.nodoId)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: primario.withValues(alpha: 0.10),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        s.foto
                                            ? LucideIcons.orbit
                                            : LucideIcons.mapPin,
                                        size: 18,
                                        color: primario,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            s.nombre,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: estiloTexto(
                                              tamano: 15,
                                              peso: 600,
                                              color: const Color(0xFF1C1C1F),
                                            ),
                                          ),
                                          if (s.detalle != null)
                                            Text(
                                              s.detalle!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: estiloTexto(
                                                tamano: 12.5,
                                                color: const Color(0xFF6B7684),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      LucideIcons.chevronRight,
                                      size: 18,
                                      color: primario.withValues(alpha: 0.7),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (widget.hayMapa)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(const UbicacionEnMapa()),
                    icon: const Icon(LucideIcons.map, size: 18),
                    label: const Text('Elegir en el mapa'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      foregroundColor: primario,
                      side: BorderSide(color: primario.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// El aviso «Estás en…» que aparece arriba al ubicarse. Se va solo a los 10 segundos.
class AvisoUbicacion extends StatefulWidget {
  const AvisoUbicacion({
    super.key,
    required this.config,
    required this.nombre,
    required this.porQr,
    required this.alCerrar,
    this.alPreguntar,
  });

  final ConfigApp config;
  final String nombre;
  final bool porQr;
  final VoidCallback alCerrar;

  /// «¿A dónde vas?»: abre el asistente.
  final VoidCallback? alPreguntar;

  @override
  State<AvisoUbicacion> createState() => _AvisoUbicacionState();
}

class _AvisoUbicacionState extends State<AvisoUbicacion> {
  Timer? _reloj;

  @override
  void initState() {
    super.initState();
    _reloj = Timer(const Duration(seconds: 10), widget.alCerrar);
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acento = colorHex(widget.config.marca.colorAcento);
    final primario = colorHex(widget.config.marca.colorPrimario);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (context, v, hijo) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, -24 * (1 - v)),
          child: hijo,
        ),
      ),
      child: Semantics(
        liveRegion: true,
        label: 'Estás en ${widget.nombre}',
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            color: Colors.white,
            elevation: 10,
            shadowColor: const Color(0x66000000),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              // Angosto (un celular acostado con el menú abierto), «¿A dónde vas?» baja a su
              // propia línea para que el texto no se apriete.
              child: LayoutBuilder(
                builder: (context, restr) {
                  final angosto = restr.maxWidth < 360;
                  final preguntar = widget.alPreguntar == null
                      ? null
                      : TextButton(
                          onPressed: widget.alPreguntar,
                          style: TextButton.styleFrom(
                            foregroundColor: primario,
                          ),
                          child: Text(
                            '¿A dónde vas?',
                            style: estiloTexto(
                              tamano: 13.5,
                              peso: 700,
                              color: primario,
                            ),
                          ),
                        );
                  final fila = Row(
                    children: <Widget>[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: acento,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.porQr
                              ? LucideIcons.scanQrCode
                              : LucideIcons.mapPinCheck,
                          size: 19,
                          color: tintaSobre(acento),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              widget.porQr
                                  ? 'Placa leída'
                                  : 'Ubicación elegida',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: estiloTexto(
                                tamano: 11.5,
                                peso: 600,
                                color: const Color(0xFF6B7684),
                                espaciado: 0.04,
                              ),
                            ),
                            Text(
                              'Estás en ${widget.nombre}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: estiloTexto(
                                tamano: 15,
                                peso: 700,
                                color: const Color(0xFF1C1C1F),
                                alto: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (preguntar != null && !angosto) preguntar,
                      IconButton(
                        tooltip: 'Cerrar el aviso',
                        onPressed: widget.alCerrar,
                        icon: const Icon(
                          LucideIcons.x,
                          size: 18,
                          color: Color(0xFF6B7684),
                        ),
                      ),
                    ],
                  );
                  if (preguntar == null || !angosto) return fila;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[fila, preguntar],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Las formas de ubicarse que ofrece el botón del QR.
enum FormaDeUbicarse {
  /// Leer la placa del lugar con la cámara (solo en el celular).
  qr,

  /// Tocar en el mapa el punto donde se está (o, si el mapa no tiene puntos, la lista).
  mapa,

  /// Buscar el lugar en la lista.
  lista,
}

/// Abre «¿Dónde estás?» con las dos formas de ubicarse: escanear el QR de una placa o elegir
/// en el mapa. [puedeEscanear] es `false` en el computador y en la web: ahí el QR se ve, pero
/// apagado, con la nota de que se usa desde la app del celular.
Future<FormaDeUbicarse?> elegirComoUbicarse(
  BuildContext context, {
  required ConfigApp config,
  required bool puedeEscanear,
  required bool mapaConPuntos,
}) => showDialog<FormaDeUbicarse>(
  context: context,
  barrierColor: const Color(0x99000000),
  builder: (_) => HojaComoUbicarse(
    config: config,
    puedeEscanear: puedeEscanear,
    mapaConPuntos: mapaConPuntos,
  ),
);

class HojaComoUbicarse extends StatelessWidget {
  const HojaComoUbicarse({
    super.key,
    required this.config,
    required this.puedeEscanear,
    required this.mapaConPuntos,
  });

  final ConfigApp config;
  final bool puedeEscanear;

  /// El minimapa tiene puntos ubicados (si no, «el mapa» es la lista de lugares).
  final bool mapaConPuntos;

  @override
  Widget build(BuildContext context) {
    final primario = colorHex(config.marca.colorPrimario);
    final acento = colorHex(config.marca.colorAcento);
    void elegir(FormaDeUbicarse f) => Navigator.of(context).pop(f);
    final qr = _OpcionUbicarse(
      icono: LucideIcons.scanQrCode,
      titulo: 'Escanear el QR',
      texto: puedeEscanear
          ? 'Apunta la cámara a la placa del lugar.'
          : 'Desde la app UniPaz360 en tu celular.',
      nota: puedeEscanear ? null : 'Solo en el celular',
      color: primario,
      alTocar: puedeEscanear ? () => elegir(FormaDeUbicarse.qr) : null,
    );
    final mapa = _OpcionUbicarse(
      icono: mapaConPuntos ? LucideIcons.map : LucideIcons.listChecks,
      titulo: mapaConPuntos ? 'Elegir en el mapa' : 'Elegir el lugar',
      texto: mapaConPuntos
          ? 'Toca en el mapa el punto donde estás.'
          : 'Busca en la lista el lugar donde estás.',
      color: acento,
      alTocar: () => elegir(FormaDeUbicarse.mapa),
    );
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '¿Dónde estás?',
                              style: estiloTexto(
                                tamano: 20,
                                peso: 800,
                                color: const Color(0xFF1C1C1F),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Escoge cómo ubicarte en el campus.',
                              style: estiloTexto(
                                tamano: 13.5,
                                color: const Color(0xFF6B7684),
                              ),
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
                          color: Color(0xFF6B7684),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    // Dos tarjetas: lado a lado si caben; si no, una encima de la otra.
                    child: LayoutBuilder(
                      builder: (context, restr) => restr.maxWidth >= 380
                          ? IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Expanded(child: qr),
                                  const SizedBox(width: 12),
                                  Expanded(child: mapa),
                                ],
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                qr,
                                const SizedBox(height: 10),
                                mapa,
                              ],
                            ),
                    ),
                  ),
                  if (mapaConPuntos)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: 8),
                      child: Center(
                        child: TextButton.icon(
                          onPressed: () => elegir(FormaDeUbicarse.lista),
                          icon: const Icon(LucideIcons.list, size: 16),
                          label: const Text('Prefiero buscarlo en una lista'),
                          style: TextButton.styleFrom(
                            foregroundColor: primario,
                            textStyle: estiloTexto(tamano: 13.5, peso: 600),
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
    );
  }
}

/// Una de las dos formas de ubicarse: una tarjeta grande con su ícono.
class _OpcionUbicarse extends StatelessWidget {
  const _OpcionUbicarse({
    required this.icono,
    required this.titulo,
    required this.texto,
    required this.color,
    required this.alTocar,
    this.nota,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final Color color;

  /// `null`: apagada (el QR en el computador).
  final VoidCallback? alTocar;

  /// Una etiqueta pequeña arriba a la derecha («Solo en el celular»).
  final String? nota;

  @override
  Widget build(BuildContext context) {
    final activa = alTocar != null;
    final tono = activa ? color : const Color(0xFF9CA3AF);
    return Semantics(
      button: true,
      enabled: activa,
      label: nota == null ? '$titulo. $texto' : '$titulo. $texto ($nota)',
      excludeSemantics: true,
      child: Material(
        color: tono.withValues(alpha: activa ? 0.07 : 0.06),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alTocar,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: tono.withValues(alpha: activa ? 0.35 : 0.25),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: tono,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: activa
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: tono.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(icono, size: 26, color: tintaSobre(tono)),
                    ),
                    const SizedBox(width: 8),
                    // La nota se encoge si no cabe (nunca empuja el ícono).
                    Expanded(
                      child: nota == null
                          ? const SizedBox.shrink()
                          : Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5E7EB),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  nota!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: estiloTexto(
                                    tamano: 11,
                                    peso: 700,
                                    color: const Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  titulo,
                  style: estiloTexto(
                    tamano: 16,
                    peso: 800,
                    color: activa
                        ? const Color(0xFF1C1C1F)
                        : const Color(0xFF6B7684),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  texto,
                  style: estiloTexto(
                    tamano: 13,
                    color: const Color(0xFF6B7684),
                    alto: 1.35,
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
