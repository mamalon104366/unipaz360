import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/marca/logo_unipaz.dart';
import '../../domain/sesion.dart';
import 'sesion_viewmodel.dart';

/// La hoja de la cuenta: entrar con Google (cuenta institucional) o ver quién entró y salir.
///
/// La app nunca la muestra sola: se abre con el botón redondo de cuenta. Sin cuenta todo lo
/// demás funciona igual.
Future<void> mostrarDialogoCuenta(BuildContext context) {
  final sesion = context.read<SesionViewModel>();
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x99000000),
    builder: (context) => ChangeNotifierProvider<SesionViewModel>.value(
      value: sesion,
      child: const _HojaCuenta(),
    ),
  ).whenComplete(() {
    // Cerrar la hoja con un aviso de error a la vista lo borra; un ingreso en curso sigue.
    if (sesion.estadoIngreso == EstadoIngreso.fallo) sesion.cancelarIngreso();
  });
}

const Color _fondo = Color(0xF71B1F27);
const Color _tenue = Color(0xB3FFFFFF);
const Color _linea = Color(0x29FFFFFF);
const String _fuente = 'Roboto';

TextStyle _texto(double tamano, {int peso = 400, Color color = Colors.white}) =>
    TextStyle(
      fontFamily: _fuente,
      fontSize: tamano,
      height: 1.45,
      color: color,
      fontVariations: <FontVariation>[FontVariation('wght', peso.toDouble())],
      fontWeight: FontWeight.values[(peso ~/ 100) - 1],
      decoration: TextDecoration.none,
    );

class _HojaCuenta extends StatelessWidget {
  const _HojaCuenta();

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<SesionViewModel>();
    final Widget cuerpo = sesion.esInstitucional
        ? _Dentro(sesion: sesion)
        : switch (sesion.estadoIngreso) {
            EstadoIngreso.esperando => _Esperando(sesion: sesion),
            EstadoIngreso.fallo => _Entrar(
              sesion: sesion,
              error: sesion.mensajeIngreso,
            ),
            EstadoIngreso.reposo => _Entrar(sesion: sesion),
          };
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
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
          child: Stack(
            children: <Widget>[
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: cuerpo,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(LucideIcons.x, size: 20, color: _tenue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sin cuenta: la invitación a entrar con Google.
class _Entrar extends StatelessWidget {
  const _Entrar({required this.sesion, this.error});

  final SesionViewModel sesion;
  final String? error;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const Center(child: LogoUnipaz(tinta: TintaLogo.blanco, ancho: 170)),
      const SizedBox(height: 24),
      Text(
        'Tu cuenta institucional',
        textAlign: TextAlign.center,
        style: _texto(21, peso: 700),
      ),
      const SizedBox(height: 8),
      Text(
        'Entra con tu correo @${Sesion.dominioInstitucional} para ver también lo que es '
        'solo para la comunidad UNIPAZ. Sin cuenta puedes seguir recorriendo el campus.',
        textAlign: TextAlign.center,
        style: _texto(14, color: _tenue),
      ),
      if (error != null) ...<Widget>[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0x33F59E0B),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x66F59E0B)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  LucideIcons.triangleAlert,
                  size: 16,
                  color: Color(0xFFFCD34D),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(error!, style: _texto(13.5))),
            ],
          ),
        ),
      ],
      const SizedBox(height: 22),
      _BotonGoogle(
        texto: error == null ? 'Continuar con Google' : 'Intentar de nuevo',
        alTocar: sesion.iniciarConGoogle,
      ),
      const SizedBox(height: 16),
      Text(
        'Al entrar, la plataforma guarda tu correo, tu nombre y cuántas veces abres la app. '
        'Nada más.',
        textAlign: TextAlign.center,
        style: _texto(12, color: const Color(0x8CFFFFFF)),
      ),
    ],
  );
}

/// Google está abierto en el navegador: se espera a que la persona termine.
class _Esperando extends StatelessWidget {
  const _Esperando({required this.sesion});

  final SesionViewModel sesion;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const SizedBox(height: 10),
      const Center(
        child: SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
        ),
      ),
      const SizedBox(height: 24),
      Text(
        'Termina de entrar en el navegador',
        textAlign: TextAlign.center,
        style: _texto(20, peso: 700),
      ),
      const SizedBox(height: 8),
      Text(
        'Se abrió Google para que elijas tu cuenta @${Sesion.dominioInstitucional}. '
        'Cuando termines, vuelve aquí: la app entra sola.',
        textAlign: TextAlign.center,
        style: _texto(14, color: _tenue),
      ),
      const SizedBox(height: 22),
      _BotonLinea(
        texto: 'Abrir Google otra vez',
        alTocar: sesion.reabrirNavegador,
      ),
      const SizedBox(height: 6),
      TextButton(
        onPressed: sesion.cancelarIngreso,
        child: Text('Cancelar', style: _texto(14, peso: 600, color: _tenue)),
      ),
    ],
  );
}

/// Con la cuenta institucional: quién entró y cómo salir.
class _Dentro extends StatelessWidget {
  const _Dentro({required this.sesion});

  final SesionViewModel sesion;

  @override
  Widget build(BuildContext context) {
    final s = sesion.sesion!;
    final nombre = s.etiqueta;
    final inicial = nombre.trim().isEmpty
        ? '?'
        : nombre.trim()[0].toUpperCase();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Container(
            width: 68,
            height: 68,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF233671),
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(color: Color(0x59FFFFFF), width: 2),
              ),
            ),
            child: Text(inicial, style: _texto(28, peso: 700)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          nombre,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _texto(20, peso: 700),
        ),
        if (s.correo != null && s.correo != nombre) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            s.correo!,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _texto(13.5, color: _tenue),
          ),
        ],
        const SizedBox(height: 14),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x330A9640),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x660A9640)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  LucideIcons.graduationCap,
                  size: 15,
                  color: Color(0xFF86EFAC),
                ),
                const SizedBox(width: 7),
                Text(
                  'Cuenta institucional',
                  style: _texto(
                    12.5,
                    peso: 600,
                    color: const Color(0xFFBBF7D0),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Ya ves lo que es solo para la comunidad UNIPAZ.',
          textAlign: TextAlign.center,
          style: _texto(14, color: _tenue),
        ),
        const SizedBox(height: 22),
        _BotonLinea(
          icono: LucideIcons.logOut,
          texto: 'Cerrar sesión',
          alTocar: () {
            Navigator.of(context).pop();
            sesion.salir();
          },
        ),
      ],
    );
  }
}

class _BotonGoogle extends StatelessWidget {
  const _BotonGoogle({required this.texto, required this.alTocar});

  final String texto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: alTocar,
      child: SizedBox(
        height: 54,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // La «G» oficial de Google, del paquete de recursos que Google publica para
            // los botones de ingreso (signin-assets.zip, tema claro).
            const Image(
              image: AssetImage('assets/marca/google-g.png'),
              width: 20,
              height: 20,
              filterQuality: FilterQuality.medium,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: 12),
            Text(
              texto,
              style: _texto(15, peso: 600, color: const Color(0xFF3C4043)),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BotonLinea extends StatelessWidget {
  const _BotonLinea({required this.texto, required this.alTocar, this.icono});

  final String texto;
  final IconData? icono;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: const BorderSide(color: Color(0x66FFFFFF)),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: alTocar,
      child: SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icono != null) ...<Widget>[
              Icon(icono, size: 17, color: Colors.white),
              const SizedBox(width: 9),
            ],
            Text(texto, style: _texto(14.5, peso: 600)),
          ],
        ),
      ),
    ),
  );
}
