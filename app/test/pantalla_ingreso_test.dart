import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:unipaz360/data/sesion_repositorio.dart';
import 'package:unipaz360/domain/sesion.dart';
import 'package:unipaz360/ui/sesion/pantalla_ingreso.dart';
import 'package:unipaz360/ui/sesion/sesion_viewmodel.dart';

void main() {
  Future<SesionViewModel> montar(
    WidgetTester tester, [
    SesionRepository? repo,
  ]) async {
    final sesion = SesionViewModel(repo ?? SesionEnMemoria());
    await tester.pumpWidget(
      ChangeNotifierProvider<SesionViewModel>.value(
        value: sesion,
        child: const MaterialApp(home: PantallaIngreso()),
      ),
    );
    await tester.pumpAndSettle();
    return sesion;
  }

  testWidgets('ofrece las dos formas de entrar', (tester) async {
    await montar(tester);

    expect(find.text('UniPaz360'), findsOneWidget);
    expect(find.text('Continuar con Google'), findsOneWidget);
    expect(find.text('Iniciar como invitado'), findsOneWidget);
    // Deja claro qué desbloquea cada nivel.
    expect(find.textContaining('@unipaz.edu.co'), findsOneWidget);
  });

  testWidgets('entrar como invitado guarda la sesión', (tester) async {
    final repositorio = SesionEnMemoria();
    final sesion = await montar(tester, repositorio);

    await tester.tap(find.text('Iniciar como invitado'));
    await tester.pumpAndSettle();

    expect(sesion.esInvitado, isTrue);
    expect(repositorio.sesion?.tipo, TipoSesion.invitado);
  });

  testWidgets('Google avisa que faltan las credenciales del proyecto', (
    tester,
  ) async {
    final sesion = await montar(tester);

    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();

    expect(find.text('Cuenta institucional'), findsOneWidget);
    expect(find.text('Probar con mi correo'), findsOneWidget);
    expect(sesion.haySesion, isFalse);
  });

  testWidgets('la entrada temporal pide el correo institucional', (
    tester,
  ) async {
    final sesion = await montar(tester);

    await tester.tap(find.text('Continuar con Google'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Probar con mi correo'));
    await tester.pumpAndSettle();

    // Un correo ajeno no pasa.
    await tester.enterText(find.byType(TextField), 'ana@gmail.com');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('no es de la UNIPAZ'), findsOneWidget);
    expect(sesion.haySesion, isFalse);

    // El correo de la institución sí.
    await tester.enterText(find.byType(TextField), 'ana@unipaz.edu.co');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(sesion.esInstitucional, isTrue);
    expect(sesion.sesion?.correo, 'ana@unipaz.edu.co');
  });
}
