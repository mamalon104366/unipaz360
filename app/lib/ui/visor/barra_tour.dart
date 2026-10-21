import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import 'seccion_tour.dart';

double anchoBarraTour(double anchoPantalla, {required bool escritorio}) =>
    escritorio ? 300 : (anchoPantalla * 0.32).clamp(220.0, 250.0);

/// Navegación superpuesta al recorrido, inspirada en el tour institucional.
class BarraTour extends StatelessWidget {
  const BarraTour({
    required this.abierta,
    required this.escritorio,
    required this.alternar,
    required this.seleccionada,
    required this.alSeleccionar,
    required this.admisionesSeleccionada,
    required this.alSeleccionarAdmisiones,
    super.key,
  });

  final bool abierta;
  final bool escritorio;
  final VoidCallback alternar;
  final SeccionTour seleccionada;
  final ValueChanged<SeccionTour> alSeleccionar;
  final SeccionAdmisiones admisionesSeleccionada;
  final ValueChanged<SeccionAdmisiones> alSeleccionarAdmisiones;

  @override
  Widget build(BuildContext context) {
    final anchoPantalla = MediaQuery.sizeOf(context).width;
    final altoPantalla = MediaQuery.sizeOf(context).height;
    final ancho = anchoBarraTour(anchoPantalla, escritorio: escritorio);

    return Stack(
      children: [
        if (abierta)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: ancho,
            child: ClipRect(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 11, sigmaY: 11),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xD91A2925),
                    border: Border(
                      right: BorderSide(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            escritorio ? 24 : 16,
                            altoPantalla < 520 ? 14 : 26,
                            escritorio ? 20 : 14,
                            altoPantalla < 520 ? 16 : 27,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: escritorio ? 44 : 38,
                                height: escritorio ? 44 : 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5A9D72),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.explore_outlined,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                              SizedBox(width: escritorio ? 12 : 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'UNIPAZ 360',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: escritorio ? 18 : 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Centro de Investigaciones\nSanta Lucía',
                                      style: TextStyle(
                                        color: Color(0xD9FFFFFF),
                                        fontSize: escritorio ? 12 : 10,
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 20, 10),
                          child: Text(
                            'EXPLORA EL CAMPUS',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.68),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              for (final seccion in SeccionTour.values) ...[
                                _OpcionTour(
                                  icono: seccion.icono,
                                  etiqueta: seccion.etiqueta,
                                  activa: seleccionada == seccion,
                                  alPresionar: () => alSeleccionar(seccion),
                                ),
                                if (seccion == SeccionTour.admisiones &&
                                    seleccionada == SeccionTour.admisiones)
                                  for (final subseccion
                                      in SeccionAdmisiones.values)
                                    _SubOpcionTour(
                                      icono: subseccion.icono,
                                      etiqueta: subseccion.etiqueta,
                                      activa:
                                          admisionesSeleccionada == subseccion,
                                      alPresionar: () =>
                                          alSeleccionarAdmisiones(subseccion),
                                    ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: abierta ? ancho - 21 : 14,
          top: altoPantalla / 2 - 21,
          child: Material(
            color: Colors.white,
            elevation: 5,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: alternar,
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(
                  abierta ? Icons.chevron_left : Icons.chevron_right,
                  color: const Color(0xFF214734),
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubOpcionTour extends StatelessWidget {
  const _SubOpcionTour({
    required this.icono,
    required this.etiqueta,
    required this.activa,
    required this.alPresionar,
  });

  final IconData icono;
  final String etiqueta;
  final bool activa;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 45, right: 18, top: 1, bottom: 1),
    child: Material(
      color: activa ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: alPresionar,
        borderRadius: BorderRadius.circular(7),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              Icon(icono, color: Colors.white70, size: 17),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  etiqueta,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .94),
                    fontSize: 12,
                    fontWeight: activa ? FontWeight.w700 : FontWeight.w500,
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

class _OpcionTour extends StatelessWidget {
  const _OpcionTour({
    required this.icono,
    required this.etiqueta,
    required this.alPresionar,
    this.activa = false,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback alPresionar;
  final bool activa;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
      child: Material(
        color: activa
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: alPresionar,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icono, color: Colors.white, size: 21),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    etiqueta,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: activa ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (activa)
                  Container(
                    width: 5,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9BD29F),
                      borderRadius: BorderRadius.circular(3),
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
