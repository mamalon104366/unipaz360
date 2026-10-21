import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../domain/sesion.dart';
import 'ingreso_institucional.dart';
import 'sesion_viewmodel.dart';

/// Primera pantalla: entrar como invitado o con la cuenta institucional,
/// sobre la foto del campus.
class PantallaIngreso extends StatelessWidget {
  const PantallaIngreso({super.key});

  /// Foto del campus que sirve de fondo.
  static const String fotoCampus = 'assets/imagenes/portada-campus.jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF20242B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(fotoCampus, fit: BoxFit.cover),
          // Oscurece la foto para que el texto se lea sobre cualquier parte.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Color(0xCC000000)],
              ),
            ),
          ),
          const SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: _TarjetaIngreso(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta oscura con las dos formas de entrar.
class _TarjetaIngreso extends StatelessWidget {
  const _TarjetaIngreso();

  @override
  Widget build(BuildContext context) {
    final sesion = context.read<SesionViewModel>();

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
        decoration: BoxDecoration(
          color: const Color(0xF21B1F27),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x33FFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 30,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Encabezado(),
            const SizedBox(height: 26),
            _BotonGoogle(alPresionar: () => _entrarConGoogle(context, sesion)),
            const SizedBox(height: 12),
            _BotonInvitado(alPresionar: () => sesion.entrarComoInvitado()),
            const SizedBox(height: 22),
            const Text(
              'Como invitado ves el mapa, las rutas, los recorridos 360°, el '
              'dron y el chatbot. Con tu correo @${Sesion.dominioInstitucional} '
              'también ves los horarios de clase y el calendario académico.',
              style: TextStyle(
                color: Color(0xB3FFFFFF),
                fontSize: 12.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _entrarConGoogle(
    BuildContext context,
    SesionViewModel sesion,
  ) async {
    final resultado = await sesion.iniciarConGoogle();
    if (resultado == ResultadoGoogle.entro) return;
    if (!context.mounted) return;
    await explicarIngresoInstitucional(context, sesion);
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0x1FFFFFFF),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: const Icon(
            Icons.school_outlined,
            size: 30,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'UniPaz360',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Recorre el campus de la UNIPAZ en 360°',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 13.5),
        ),
      ],
    );
  }
}

class _BotonGoogle extends StatelessWidget {
  const _BotonGoogle({required this.alPresionar});

  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: alPresionar,
        borderRadius: BorderRadius.circular(14),
        child: const SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // La marca oficial de Google se agrega cuando la institución
              // registre el proyecto; por ahora va la "G" de la casa.
              Text(
                'G',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4285F4),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Continuar con Google',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3C4043),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonInvitado extends StatelessWidget {
  const _BotonInvitado({required this.alPresionar});

  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: alPresionar,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        side: const BorderSide(color: Color(0x66FFFFFF)),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text(
        'Iniciar como invitado',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}
