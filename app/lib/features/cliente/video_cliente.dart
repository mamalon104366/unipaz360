/// Reproductor de video del lienzo y de las capas 3D: con controles sencillos (tocar para
/// reproducir o pausar y la barra de avance). En Windows lo reproduce `video_player_win`.
library;

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../core/paquete/paquete_local.dart';
import 'estilo_cliente.dart';

class ReproductorVideo extends StatefulWidget {
  const ReproductorVideo({
    super.key,
    required this.fuente,
    this.ajuste = BoxFit.cover,
    this.automatico = false,
    this.bucle = false,
    this.controles = true,
  });

  final FuenteVideo fuente;
  final BoxFit ajuste;

  /// Reproduce solo y sin sonido (como `autoplay muted`).
  final bool automatico;
  final bool bucle;
  final bool controles;

  @override
  State<ReproductorVideo> createState() => _ReproductorVideoState();
}

class _ReproductorVideoState extends State<ReproductorVideo> {
  VideoPlayerController? _c;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _abrir();
  }

  @override
  void didUpdateWidget(ReproductorVideo viejo) {
    super.didUpdateWidget(viejo);
    if (viejo.fuente.asset != widget.fuente.asset ||
        viejo.fuente.url != widget.fuente.url) {
      _c?.dispose();
      _c = null;
      _error = null;
      _abrir();
    }
  }

  void _abrir() {
    final f = widget.fuente;
    final c = f.asset != null
        ? VideoPlayerController.asset(f.asset!)
        : VideoPlayerController.networkUrl(f.url!);
    _c = c;
    c
        .initialize()
        .then((_) async {
          if (!mounted || _c != c) return;
          await c.setLooping(widget.bucle);
          if (widget.automatico) {
            await c.setVolume(0);
            await c.play();
          }
          if (mounted) setState(() {});
        })
        .catchError((Object e) {
          if (mounted && _c == c) setState(() => _error = e);
        });
    c.addListener(_alCambiar);
  }

  void _alCambiar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c?.removeListener(_alCambiar);
    _c?.dispose();
    super.dispose();
  }

  void _alternar() {
    final c = _c;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      if (c.value.position >= c.value.duration &&
          c.value.duration > Duration.zero) {
        c.seekTo(Duration.zero);
      }
      c.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (_error != null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Text(
          'No fue posible cargar el video en este dispositivo.',
          textAlign: TextAlign.center,
          style: estiloTexto(tamano: 13, color: Colors.white70),
        ),
      );
    }
    if (c == null || !c.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    final video = ClipRect(
      child: FittedBox(
        fit: widget.ajuste,
        child: SizedBox(
          width: c.value.size.width,
          height: c.value.size.height,
          child: VideoPlayer(c),
        ),
      ),
    );
    if (!widget.controles) return ColoredBox(color: Colors.black, child: video);
    return ColoredBox(
      color: Colors.black,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _alternar,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            video,
            if (!c.value.isPlaying)
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0x8C000000),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.play,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                c,
                allowScrubbing: true,
                padding: const EdgeInsets.only(top: 6),
                colors: const VideoProgressColors(
                  playedColor: Colors.white,
                  bufferedColor: Color(0x66FFFFFF),
                  backgroundColor: Color(0x33FFFFFF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
