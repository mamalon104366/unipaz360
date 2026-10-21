import 'dart:async';

import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import 'barra_tour.dart';
import 'google_maps_embed.dart';
import 'seccion_tour.dart';

const _azulUnipaz = Color(0xFF163E78);
const _verdeUnipaz = Color(0xFF179B55);
const _grisTexto = Color(0xFF526071);

/// Panel claro que acompaña al tour, dejando visible el panorama y la barra.
class ContenidoTour extends StatelessWidget {
  const ContenidoTour({
    required this.seccion,
    required this.menuAbierto,
    required this.escritorio,
    required this.subseccionAdmisiones,
    required this.alCerrar,
    super.key,
  });

  final SeccionTour seccion;
  final bool menuAbierto;
  final bool escritorio;
  final SeccionAdmisiones subseccionAdmisiones;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final alto = MediaQuery.sizeOf(context).height;
    final margenIzquierdo = menuAbierto
        ? anchoBarraTour(ancho, escritorio: escritorio)
        : 56.0;

    return Positioned(
      left: margenIzquierdo,
      right: 0,
      top: 0,
      bottom: 0,
      child: Material(
        color: const Color(0xFFFAFAF8),
        child: _PanelSeccion(
          seccion: seccion,
          alto: alto,
          subseccionAdmisiones: subseccionAdmisiones,
          alCerrar: alCerrar,
        ),
      ),
    );
  }
}

class _PanelSeccion extends StatelessWidget {
  const _PanelSeccion({
    required this.seccion,
    required this.alto,
    required this.subseccionAdmisiones,
    required this.alCerrar,
  });

  final SeccionTour seccion;
  final double alto;
  final SeccionAdmisiones subseccionAdmisiones;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    final compacto = alto < 560;
    return Column(
      children: [
        Container(
          height: compacto ? 76 : 96,
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(compacto ? 24 : 50, 14, 22, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 74,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _azulUnipaz,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      seccion.etiqueta.toUpperCase(),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: compacto ? 21 : 29,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.35,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: _azulUnipaz.withValues(alpha: 0.84),
                child: InkWell(
                  onTap: alCerrar,
                  child: SizedBox(
                    width: 46,
                    height: 40,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 29,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: switch (seccion) {
            SeccionTour.nosotros => const _Nosotros(),
            SeccionTour.videoInstitucional => const _VideoInstitucional(),
            SeccionTour.admisiones => _Admisiones(
              subseccion: subseccionAdmisiones,
            ),
            SeccionTour.ubicacion => const _Ubicacion(),
            SeccionTour.recorrido => const _VistaRecorrido(),
          },
        ),
      ],
    );
  }
}

class _Nosotros extends StatefulWidget {
  const _Nosotros();

  @override
  State<_Nosotros> createState() => _NosotrosState();
}

class _NosotrosState extends State<_Nosotros> {
  int _pestana = 0;
  static const _titulos = ['Nuestra historia', 'Trayectoria', 'Identidad'];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compacto = constraints.maxWidth < 720;
        return Column(
          children: [
            Container(
              height: 58,
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: compacto ? 18 : 50),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _titulos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 30),
                itemBuilder: (context, index) {
                  final activa = index == _pestana;
                  return InkWell(
                    onTap: () => setState(() => _pestana = index),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: activa ? _azulUnipaz : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        _titulos[index].toUpperCase(),
                        style: TextStyle(
                          color: _azulUnipaz,
                          fontSize: 11,
                          fontWeight: activa
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  compacto ? 20 : 50,
                  compacto ? 18 : 32,
                  compacto ? 20 : 50,
                  30,
                ),
                child: _pestana == 1
                    ? _LineaDeTiempo(compacto: compacto)
                    : _ContenidoHistoria(
                        compacto: compacto,
                        identidad: _pestana == 2,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ContenidoHistoria extends StatelessWidget {
  const _ContenidoHistoria({required this.compacto, required this.identidad});

  final bool compacto;
  final bool identidad;

  @override
  Widget build(BuildContext context) {
    final foto = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: AspectRatio(
        aspectRatio: compacto ? 1.9 : 1.28,
        child: Image.asset(
          'assets/imagenes/portada-campus.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          identidad
              ? 'Educación pública con raíces en el territorio'
              : 'Una historia construida en el Magdalena Medio',
          style: const TextStyle(
            color: _azulUnipaz,
            fontFamily: 'Georgia',
            fontSize: 30,
            fontStyle: FontStyle.italic,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 17),
        Text(
          identidad
              ? 'UNIPAZ es una institución pública de educación superior del orden departamental. Integra la ciencia, la cultura y los saberes de las comunidades, con una misión comprometida con el desarrollo humano del Magdalena Medio y del país.'
              : 'UNIPAZ nació de la iniciativa de comunidades e instituciones del Magdalena Medio que buscaban acercar la educación superior pública a la región. El Decreto Ordenanzal 0331 del 19 de noviembre de 1987 creó el Instituto Universitario de la Paz, con sede principal en Barrancabermeja.',
          style: const TextStyle(color: _grisTexto, fontSize: 15, height: 1.65),
        ),
        if (!identidad) ...[
          const SizedBox(height: 13),
          const Text(
            'El primer rector se posesionó el 1 de enero de 1988. Ese mismo año, Medicina Veterinaria y Zootecnia abrió sus aulas a 50 estudiantes. Desde entonces, UNIPAZ ha extendido su oferta académica, la investigación y la proyección social, en diálogo con las necesidades productivas, culturales y ambientales del Magdalena Medio.',
            style: TextStyle(color: _grisTexto, fontSize: 15, height: 1.65),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.tonalIcon(
          onPressed: () => _abrirEnlace(
            context,
            'https://unipaz.edu.co/transparencia/mision-vision-e-historia/',
          ),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('Historia institucional completa'),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compacto)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [foto, const SizedBox(height: 20), texto],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 11, child: foto),
              const SizedBox(width: 42),
              Expanded(flex: 9, child: texto),
            ],
          ),
        const SizedBox(height: 34),
        const Text(
          'Un campus vivo, conectado con su región',
          style: TextStyle(
            color: _azulUnipaz,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        _GaleriaInstitucional(compacto: compacto),
        const SizedBox(height: 20),
        const Text(
          'Desde el Centro de Investigaciones Santa Lucía, la formación se encuentra con el paisaje, la producción y las comunidades del Magdalena Medio. Esa relación entre conocimiento y territorio define el carácter público y regional de UNIPAZ.',
          style: TextStyle(color: _grisTexto, fontSize: 14, height: 1.65),
        ),
      ],
    );
  }
}

class _GaleriaInstitucional extends StatelessWidget {
  const _GaleriaInstitucional({required this.compacto});

  final bool compacto;

  static const _fotos = [
    (
      'assets/imagenes/unipaz-campus.jpg',
      'Campus Santa Lucía',
      'Espacios para aprender y compartir.',
    ),
    (
      'assets/imagenes/origenes-trayectoria.jpg',
      'Vida universitaria',
      'La comunidad construye el campus.',
    ),
    (
      'assets/imagenes/historia-tradicion.jpg',
      'Historia y tradición',
      'Una trayectoria al servicio de la región.',
    ),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columnas = compacto ? 1 : 3;
      const espacio = 14.0;
      final ancho =
          (constraints.maxWidth - espacio * (columnas - 1)) / columnas;
      return Wrap(
        spacing: espacio,
        runSpacing: espacio,
        children: [
          for (final item in _fotos)
            SizedBox(
              width: ancho,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1.72,
                      child: Image.asset(item.$1, fit: BoxFit.cover),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(11, 9, 8, 3),
                      child: Text(
                        item.$2,
                        style: const TextStyle(
                          color: _azulUnipaz,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(11, 0, 8, 11),
                      child: Text(
                        item.$3,
                        style: const TextStyle(color: _grisTexto, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _LineaDeTiempo extends StatelessWidget {
  const _LineaDeTiempo({required this.compacto});

  final bool compacto;

  static const _hitos = [
    (
      '1987',
      'Creación de UNIPAZ',
      'El Decreto Ordenanzal 0331 formaliza el Instituto Universitario de la Paz.',
    ),
    (
      '1988',
      'Primer programa',
      'Medicina Veterinaria y Zootecnia inicia clases con 50 estudiantes.',
    ),
    (
      '1990',
      'Nuevos campos',
      'Se autoriza la Facultad de Ingeniería Agronómica.',
    ),
    (
      '1994',
      'Crecimiento académico',
      'El programa agroindustrial adopta el nombre de Ingeniería Agroindustrial.',
    ),
    (
      'Hoy',
      'Compromiso regional',
      'Docencia, investigación y proyección social al servicio del Magdalena Medio.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Más de tres décadas junto al territorio',
          style: TextStyle(
            color: _azulUnipaz,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < _hitos.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: compacto ? 58 : 82,
                  child: Text(
                    _hitos[i].$1,
                    style: const TextStyle(
                      color: _verdeUnipaz,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(width: 2, height: 52, color: const Color(0xFFD9E6DD)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hitos[i].$2,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _hitos[i].$3,
                        style: const TextStyle(color: _grisTexto, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _VideoInstitucional extends StatefulWidget {
  const _VideoInstitucional();

  @override
  State<_VideoInstitucional> createState() => _VideoInstitucionalState();
}

class _VideoInstitucionalState extends State<_VideoInstitucional> {
  late final VideoPlayerController _controlador;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _controlador =
        VideoPlayerController.asset('assets/videos/BienvenidosUNIPAZ.mp4')
          ..initialize()
              .then((_) {
                if (mounted) setState(() {});
              })
              .catchError((Object error) {
                if (mounted) setState(() => _error = error);
              });
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    return Container(
      color: const Color(0xFF101112),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ancho < 1000 ? 1100 : 1380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _error != null
                ? const Center(
                    child: Text(
                      'No fue posible cargar el video institucional en este dispositivo.',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  )
                : !_controlador.value.isInitialized
                ? const AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: AspectRatio(
                          aspectRatio: _controlador.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(_controlador),
                              IconButton.filled(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                  fixedSize: const Size(68, 68),
                                ),
                                onPressed: () => setState(() {
                                  _controlador.value.isPlaying
                                      ? _controlador.pause()
                                      : _controlador.play();
                                }),
                                icon: Icon(
                                  _controlador.value.isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow,
                                  size: 38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      VideoProgressIndicator(
                        _controlador,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: _verdeUnipaz,
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Bienvenidos a UNIPAZ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
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

class _Admisiones extends StatelessWidget {
  const _Admisiones({required this.subseccion});

  final SeccionAdmisiones subseccion;

  static const _urlProceso =
      'https://unipaz.edu.co/proceso-de-inscripcion-admision-y-matricula-semestre-2027a/';
  static const _urlPregrado = 'https://unipaz.edu.co/programas-de-pregrado/';
  static const _urlPosgrado = 'https://unipaz.edu.co/programas-de-posgrado/';
  static const _urlCalendario = 'https://unipaz.edu.co/calendario-academico/';

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final compacto = ancho < 920;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        compacto ? 20 : 50,
        22,
        compacto ? 20 : 50,
        35,
      ),
      child: switch (subseccion) {
        SeccionAdmisiones.pasos => const _PasosAdmision(),
        SeccionAdmisiones.pregrado => _OfertaProgramas(
          compacto: compacto,
          posgrado: false,
        ),
        SeccionAdmisiones.posgrado => _OfertaProgramas(
          compacto: compacto,
          posgrado: true,
        ),
        SeccionAdmisiones.calendario => const _CalendarioAdmision(),
      },
    );
  }
}

class _PasosAdmision extends StatelessWidget {
  const _PasosAdmision();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: AspectRatio(
          aspectRatio: 3.08,
          child: Semantics(
            label: 'Banner oficial de inscripciones UNIPAZ 2027-A',
            child: Image.asset(
              'assets/imagenes/banner-admisiones-2027a.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      const SizedBox(height: 13),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 14,
        runSpacing: 8,
        children: [
          const _EtiquetaEstado(texto: 'Convocatoria 2027-A anunciada'),
          const Text(
            'Publicación oficial: 13 de octubre de 2026',
            style: TextStyle(color: _grisTexto, fontSize: 12),
          ),
          TextButton.icon(
            onPressed: () =>
                _abrirEnlace(context, 'https://unipaz.edu.co/?p=40578'),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Ver anuncio'),
          ),
        ],
      ),
      const SizedBox(height: 20),
      const Text(
        'Tu ingreso, paso a paso',
        style: TextStyle(
          color: _azulUnipaz,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'El proceso 2027-A ya tiene una página e instructivo institucional. Sigue la secuencia y revisa allí los plazos, requisitos y documentos del programa al que te postulas.',
        style: TextStyle(color: _grisTexto, height: 1.5),
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final columnas = constraints.maxWidth > 920
              ? 3
              : constraints.maxWidth > 570
              ? 2
              : 1;
          const gap = 14.0;
          final cardWidth =
              (constraints.maxWidth - gap * (columnas - 1)) / columnas;
          final pasos = [
            (
              '01',
              'Elige programa y sede',
              'Revisa la oferta de pregrado o posgrado y define si te postulas en Barrancabermeja o por UNIPAZ en tu Territorio.',
              'assets/imagenes/programas-pregrado-oficial.jpg',
              'https://unipaz.edu.co/soy-aspirante/',
            ),
            (
              '02',
              'Diligencia la inscripción',
              'Entra al proceso 2027-A, completa los datos solicitados, selecciona el programa y confirma la información.',
              'assets/imagenes/aspirantes-inscripcion.webp',
              _Admisiones._urlProceso,
            ),
            (
              '03',
              'Genera y paga el recibo',
              'Descarga la carta de pago y sigue las instrucciones oficiales. La inscripción queda válida cuando el sistema registra el pago.',
              'assets/imagenes/aspirantes-documentos.jpg',
              _Admisiones._urlProceso,
            ),
            (
              '04',
              'Carga los documentos',
              'Sube los soportes requeridos para tu nivel y programa en la plataforma indicada por Registro y Control.',
              'assets/imagenes/aspirantes-documentos.jpg',
              _Admisiones._urlProceso,
            ),
            (
              '05',
              'Consulta resultados y matrícula',
              'Revisa la publicación de admitidos y, si eres seleccionado, completa la matrícula dentro del plazo oficial.',
              'assets/imagenes/aspirantes-inscripcion.webp',
              _Admisiones._urlCalendario,
            ),
          ];
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final paso in pasos)
                SizedBox(
                  width: cardWidth,
                  child: _PasoAdmision(
                    numero: paso.$1,
                    titulo: paso.$2,
                    texto: paso.$3,
                    imagen: paso.$4,
                    url: paso.$5,
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 18),
      const _NotaOficial(
        texto: 'El anuncio 2027-A que consultamos no publica fecha límite de inscripción en su nota. Por eso esta guía no la inventa: verifica fechas, documentos y cualquier cambio en el proceso oficial antes de pagar o cargar archivos.',
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: () => _abrirEnlace(context, _Admisiones._urlProceso),
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('Abrir proceso 2027-A'),
          ),
          OutlinedButton.icon(
            onPressed: () => _abrirEnlace(context, _Admisiones._urlCalendario),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Consultar calendario'),
          ),
        ],
      ),
      const SizedBox(height: 20),
      const _DocumentosIngreso(),
    ],
  );
}

class _DocumentosIngreso extends StatelessWidget {
  const _DocumentosIngreso();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F5F2),
      border: Border(left: BorderSide(color: _verdeUnipaz, width: 4)),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prepara tus soportes',
          style: TextStyle(
            color: _azulUnipaz,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Para pregrado, la institución indica documentos como Saber 11 e identificación, además de los soportes que correspondan a tu situación socioeconómica. Para posgrado, solicita identificación, hoja de vida y título o acta del nivel previo. La lista y el formato de cada soporte pueden cambiar por convocatoria; consulta el instructivo 2027-A antes de cargar.',
          style: TextStyle(color: _grisTexto, height: 1.5),
        ),
      ],
    ),
  );
}

class _OfertaProgramas extends StatelessWidget {
  const _OfertaProgramas({required this.compacto, required this.posgrado});

  final bool compacto;
  final bool posgrado;

  static const _pregrado = <(String, List<String>)>[
    (
      'Escuela de Ciencias',
      [
        'Administración de Negocios Internacionales',
        'Ingeniería Informática',
        'Licenciatura en Artes',
        'Química',
      ],
    ),
    (
      'Escuela de Ciencias Sociales y de las Comunicaciones',
      ['Comunicación Social', 'Trabajo Social', 'Derecho'],
    ),
    (
      'Escuela de Ingeniería Agroindustrial',
      [
        'Técnico Profesional en Operación del Recurso Energético',
        'Tecnología en Procesamiento de Alimentos',
        'Ingeniería Agroindustrial',
        'Profesional en Turismo',
      ],
    ),
    ('Escuela de Ingeniería Agronómica', ['Ingeniería Agronómica']),
    (
      'Escuela de Ingeniería Ambiental y de Saneamiento',
      [
        'Ingeniería Civil',
        'Tecnología en Obras Civiles',
        'Ingeniería Ambiental y de Saneamiento',
      ],
    ),
    (
      'Escuela de Ingeniería de Producción',
      [
        'Tecnología en Operación de Sistemas Electromecánicos',
        'Tecnología en Seguridad y Salud en el Trabajo',
        'Ingeniería de Producción',
        'Ingeniería en Seguridad y Salud en el Trabajo',
      ],
    ),
    (
      'Escuela de Medicina Veterinaria y Zootecnia',
      ['Medicina Veterinaria y Zootecnia'],
    ),
    (
      'Escuela de Ciencias de la Salud',
      ['Tecnología en Gestión Deportiva y Actividad Física'],
    ),
  ];

  static const _posgrado = <(String, List<String>)>[
    (
      'Escuela de Ciencias',
      [
        'Especialización en Big Data e Inteligencia de Negocios',
        'Especialización en Gerencia de Proyectos Culturales',
        'Maestría en Educación',
      ],
    ),
    (
      'Escuela de Ingeniería Agroindustrial',
      [
        'Especialización Tecnológica en Control de Calidad de Biocombustibles Líquidos',
        'Especialización en Agronegocios',
        'Especialización en Aseguramiento de la Calidad e Inocuidad Agroalimentaria',
        'Especialización en Mercadeo Global Empresarial',
        'Maestría en Logística y Cadena de Suministro',
      ],
    ),
    (
      'Escuela de Ingeniería Ambiental y de Saneamiento',
      ['Especialización en Gestión Ambiental'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final oferta = posgrado ? _posgrado : _pregrado;
    final url = posgrado ? _Admisiones._urlPosgrado : _Admisiones._urlPregrado;
    final fotos = posgrado
        ? 'assets/imagenes/programas-pregrado-oficial.jpg'
        : 'assets/imagenes/unipaz-campus.jpg';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: compacto ? 170 : 220,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(fotos, fit: BoxFit.cover),
                ColoredBox(color: Colors.black.withValues(alpha: .40)),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      posgrado
                          ? 'Especializaciones y maestrías'
                          : 'Encuentra el camino que quieres construir',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          posgrado
              ? 'Oferta de posgrado publicada por UNIPAZ'
              : 'Programas de pregrado publicados por UNIPAZ',
          style: const TextStyle(
            color: _azulUnipaz,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'La disponibilidad, modalidad y sede pueden variar por periodo. Abre la ficha oficial para confirmar si el programa está ofertado en la convocatoria vigente.',
          style: TextStyle(color: _grisTexto, height: 1.5),
        ),
        const SizedBox(height: 14),
        for (final escuela in oferta)
          _GrupoProgramas(
            titulo: escuela.$1,
            programas: escuela.$2,
            posgrado: posgrado,
          ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => _abrirEnlace(context, url),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Ver oferta oficial completa'),
        ),
      ],
    );
  }
}

class _GrupoProgramas extends StatefulWidget {
  const _GrupoProgramas({
    required this.titulo,
    required this.programas,
    required this.posgrado,
  });

  final String titulo;
  final List<String> programas;
  final bool posgrado;

  @override
  State<_GrupoProgramas> createState() => _GrupoProgramasState();
}

class _GrupoProgramasState extends State<_GrupoProgramas> {
  bool _abierto = false;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFDDE5E2)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      children: [
        InkWell(
          onTap: () => setState(() => _abierto = !_abierto),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(
                  widget.posgrado
                      ? Icons.workspace_premium_outlined
                      : Icons.school_outlined,
                  color: _verdeUnipaz,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.titulo,
                        style: const TextStyle(
                          color: _azulUnipaz,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.programas.length} '
                        '${widget.programas.length == 1 ? 'programa listado' : 'programas listados'}',
                      ),
                    ],
                  ),
                ),
                Icon(
                  _abierto ? Icons.expand_less : Icons.expand_more,
                  color: _azulUnipaz,
                ),
              ],
            ),
          ),
        ),
        if (_abierto)
          for (final programa in widget.programas)
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 0, 17, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_right, color: _verdeUnipaz, size: 20),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      programa,
                      style: const TextStyle(color: _grisTexto, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
      ],
    ),
  );
}

class _CalendarioAdmision extends StatelessWidget {
  const _CalendarioAdmision();

  static const _fechas = [
    ('14 nov 2026', 'Finalización de clases · semestre B-2026'),
    ('17–23 nov 2026', 'Exámenes finales · semestre B-2026'),
    ('24–28 nov 2026', 'Registro digital de notas · semestre B-2026'),
    ('3–5 dic 2026', 'Habilitaciones · semestre B-2026'),
    ('11 dic 2026', 'Ceremonia de grados · semestre B-2026'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Fechas académicas publicadas',
        style: TextStyle(
          color: _azulUnipaz,
          fontSize: 23,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'El calendario institucional disponible corresponde al semestre B-2026. Estas son sus siguientes fechas; la convocatoria de admisiones 2027-A se anuncia por separado.',
        style: TextStyle(color: _grisTexto, height: 1.5),
      ),
      const SizedBox(height: 17),
      for (final fecha in _fechas)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 126,
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 9,
                ),
                color: const Color(0xFFE7F0EB),
                child: Text(
                  fecha.$1,
                  style: const TextStyle(
                    color: _azulUnipaz,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    fecha.$2,
                    style: const TextStyle(color: _grisTexto, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 10),
      const _NotaOficial(
        texto: 'El calendario B-2026 no reemplaza las fechas de inscripción y matrícula de 2027-A. La página del proceso 2027-A y el portal de calendario son las fuentes para cualquier actualización o prórroga.',
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: () => _abrirEnlace(
              context,
              'https://unipaz.edu.co/calendario-academico/',
            ),
            icon: const Icon(Icons.calendar_month_outlined),
            label: const Text('Abrir calendario oficial'),
          ),
          OutlinedButton.icon(
            onPressed: () => _abrirEnlace(
              context,
              'https://unipaz.edu.co/proceso-de-inscripcion-admision-y-matricula-semestre-2027a/',
            ),
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('Ver proceso 2027-A'),
          ),
        ],
      ),
    ],
  );
}

class _EtiquetaEstado extends StatelessWidget {
  const _EtiquetaEstado({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFE5F4E9),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.campaign_outlined, color: _verdeUnipaz, size: 16),
          const SizedBox(width: 6),
          Text(
            texto,
            style: const TextStyle(
              color: _azulUnipaz,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _NotaOficial extends StatelessWidget {
  const _NotaOficial({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: const BoxDecoration(
      color: Color(0xFFF3F5F4),
      border: Border(left: BorderSide(color: _azulUnipaz, width: 3)),
    ),
    child: Text(
      texto,
      style: const TextStyle(color: _grisTexto, fontSize: 12, height: 1.5),
    ),
  );
}

class _PasoAdmision extends StatelessWidget {
  const _PasoAdmision({
    required this.numero,
    required this.titulo,
    required this.texto,
    required this.imagen,
    required this.url,
  });

  final String numero;
  final String titulo;
  final String texto;
  final String imagen;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirEnlace(context, url),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              SizedBox(
                width: 84,
                height: 74,
                child: Image.asset(imagen, fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$numero · $titulo',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _azulUnipaz,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      texto,
                      style: const TextStyle(
                        color: _grisTexto,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: _verdeUnipaz, size: 19),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ubicacion extends StatefulWidget {
  const _Ubicacion();

  @override
  State<_Ubicacion> createState() => _UbicacionState();
}

class _UbicacionState extends State<_Ubicacion> {
  static const _coordenadas = '7.066153703270713, -73.74487959820672';
  static const _urlGoogle =
      'https://www.google.com/maps/dir/?api=1&destination=7.066153703270713%2C-73.74487959820672';

  bool _hayInternet = false;
  late final StreamSubscription<InternetStatus> _estadoInternet;

  @override
  void initState() {
    super.initState();
    InternetConnection().hasInternetAccess
        .then((estado) {
          if (mounted) setState(() => _hayInternet = estado);
        })
        .catchError((Object _) {});
    _estadoInternet = InternetConnection().onStatusChange.listen((estado) {
      if (mounted) {
        setState(() => _hayInternet = estado == InternetStatus.connected);
      }
    });
  }

  @override
  void dispose() {
    _estadoInternet.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final anchoTarjeta = constraints.maxWidth > 430
            ? 390.0
            : constraints.maxWidth - 36;
        return Stack(
          fit: StackFit.expand,
          children: [
            // Con conexión, Google Maps ocupa todo el espacio bajo el título.
            // La imagen del dron queda como plano de respaldo sin conexión.
            Positioned.fill(
              child: _hayInternet ? const GoogleMapsEmbed() : _MapaAereo(),
            ),
            Positioned(
              top: 18,
              right: 18,
              child: _InsigniaEstadoMapa(enLinea: _hayInternet),
            ),
            Positioned(
              left: 18,
              bottom: 18,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: anchoTarjeta),
                child: _TarjetaUbicacion(
                  enLinea: _hayInternet,
                  alPedirRuta: () => _abrirEnlace(context, _urlGoogle),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InsigniaEstadoMapa extends StatelessWidget {
  const _InsigniaEstadoMapa({required this.enLinea});

  final bool enLinea;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x26000000),
          blurRadius: 14,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            enLinea ? Icons.wifi : Icons.wifi_off_outlined,
            color: enLinea ? _verdeUnipaz : _grisTexto,
            size: 17,
          ),
          const SizedBox(width: 7),
          Text(
            enLinea ? 'Google Maps en línea' : 'Plano del dron sin conexión',
            style: const TextStyle(
              color: _azulUnipaz,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TarjetaUbicacion extends StatelessWidget {
  const _TarjetaUbicacion({required this.enLinea, required this.alPedirRuta});

  final bool enLinea;
  final VoidCallback alPedirRuta;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .96),
    elevation: 8,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: _verdeUnipaz, size: 23),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Centro de Investigaciones Santa Lucía',
                      style: TextStyle(
                        color: _azulUnipaz,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Km 14 vía Barrancabermeja – Bucaramanga, Santander',
                      style: TextStyle(color: _grisTexto, fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    SelectableText(
                      _UbicacionState._coordenadas,
                      style: TextStyle(color: _grisTexto, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: enLinea ? alPedirRuta : null,
            icon: const Icon(Icons.directions),
            label: const Text('Cómo llegar con Google Maps'),
          ),
        ],
      ),
    ),
  );
}

class _MapaAereo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset('assets/imagenes/mapa-dron.jpg', fit: BoxFit.cover),
      Center(
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .25),
                blurRadius: 14,
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on,
            color: Color(0xFFD94343),
            size: 36,
          ),
        ),
      ),
    ],
  );
}

class _VistaRecorrido extends StatelessWidget {
  const _VistaRecorrido();

  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      'El recorrido 360° está listo en el fondo. Cierra este panel para seguir explorando.',
    ),
  );
}

Future<void> _abrirEnlace(BuildContext context, String url) async {
  final ok = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo abrir el enlace.')),
    );
  }
}
