import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unipaz360/data/sesion_repositorio.dart';
import 'package:unipaz360/domain/sesion.dart';
import 'package:unipaz360/ui/sesion/sesion_viewmodel.dart';

void main() {
  group('Sesion', () {
    test('reconoce los correos de la institución', () {
      expect(Sesion.esCorreoInstitucional('ana@unipaz.edu.co'), isTrue);
      expect(
        Sesion.esCorreoInstitucional('  Ana.Perez@UNIPAZ.EDU.CO  '),
        isTrue,
      );
      expect(Sesion.esCorreoInstitucional('ana@gmail.com'), isFalse);
      expect(
        Sesion.esCorreoInstitucional('ana@unipaz.edu.co.evil.com'),
        isFalse,
      );
      expect(Sesion.esCorreoInstitucional('@unipaz.edu.co'), isFalse);
    });

    test(
      'el invitado se muestra como "Invitado" y la cuenta con su nombre',
      () {
        const invitado = Sesion(tipo: TipoSesion.invitado);
        expect(invitado.etiqueta, 'Invitado');

        const institucional = Sesion(
          tipo: TipoSesion.institucional,
          correo: 'ana@unipaz.edu.co',
          nombre: 'Ana Pérez',
        );
        expect(institucional.etiqueta, 'Ana Pérez');

        const sinNombre = Sesion(
          tipo: TipoSesion.institucional,
          correo: 'ana@unipaz.edu.co',
        );
        expect(sinNombre.etiqueta, 'ana@unipaz.edu.co');
      },
    );

    test('ida y vuelta por JSON', () {
      const original = Sesion(
        tipo: TipoSesion.institucional,
        correo: 'ana@unipaz.edu.co',
        nombre: 'Ana',
      );
      final copia = Sesion.desdeJson(original.aJson());
      expect(copia?.tipo, TipoSesion.institucional);
      expect(copia?.correo, 'ana@unipaz.edu.co');
      expect(copia?.nombre, 'Ana');
    });

    test('un JSON roto no rompe la aplicación', () {
      expect(Sesion.desdeJson(const {}), isNull);
      expect(Sesion.desdeJson(const {'tipo': 'inventado'}), isNull);
    });
  });

  group('SesionViewModel', () {
    test('arranca sin sesión y queda listo tras cargar', () async {
      final vm = SesionViewModel(SesionEnMemoria());
      expect(vm.haySesion, isFalse);
      expect(vm.listo, isFalse);

      await vm.cargar();

      expect(vm.listo, isTrue);
      expect(vm.haySesion, isFalse);
    });

    test('entrar como invitado se guarda en el dispositivo', () async {
      final repositorio = SesionEnMemoria();
      final vm = SesionViewModel(repositorio);

      await vm.entrarComoInvitado();

      expect(vm.esInvitado, isTrue);
      expect(vm.esInstitucional, isFalse);
      expect(repositorio.sesion?.tipo, TipoSesion.invitado);
    });

    test('recupera la sesión guardada al abrir la app', () async {
      final vm = SesionViewModel(
        SesionEnMemoria(
          const Sesion(
            tipo: TipoSesion.institucional,
            correo: 'ana@unipaz.edu.co',
          ),
        ),
      );

      await vm.cargar();

      expect(vm.esInstitucional, isTrue);
      expect(vm.sesion?.correo, 'ana@unipaz.edu.co');
    });

    test('solo acepta el correo institucional', () async {
      final repositorio = SesionEnMemoria();
      final vm = SesionViewModel(repositorio);

      final ajeno = await vm.entrarConCorreoInstitucional('ana@gmail.com');
      expect(ajeno, isFalse);
      expect(vm.haySesion, isFalse);
      expect(repositorio.sesion, isNull);

      final propio = await vm.entrarConCorreoInstitucional(
        'Ana@Unipaz.edu.co',
        nombre: '  Ana Pérez  ',
      );
      expect(propio, isTrue);
      expect(vm.esInstitucional, isTrue);
      expect(vm.sesion?.correo, 'ana@unipaz.edu.co');
      expect(vm.sesion?.nombre, 'Ana Pérez');
    });

    test('cerrar sesión vuelve al ingreso', () async {
      final repositorio = SesionEnMemoria();
      final vm = SesionViewModel(repositorio);

      await vm.entrarComoInvitado();
      await vm.salir();

      expect(vm.haySesion, isFalse);
      expect(repositorio.sesion, isNull);
    });

    test('sin cliente OAuth, Google avisa que faltan credenciales', () async {
      final vm = SesionViewModel(SesionEnMemoria());

      expect(vm.googleConfigurado, isFalse);
      expect(await vm.iniciarConGoogle(), ResultadoGoogle.faltanCredenciales);
      expect(vm.haySesion, isFalse);
    });

    test('la sesión guardada sobrevive al cierre de la app', () async {
      SharedPreferences.setMockInitialValues({});
      final dispositivo = SesionEnDispositivo();

      await dispositivo.guardar(const Sesion(tipo: TipoSesion.invitado));
      final leida = await SesionEnDispositivo().cargar();

      expect(leida?.tipo, TipoSesion.invitado);
    });

    test('un dato guardado corrupto se ignora', () async {
      SharedPreferences.setMockInitialValues({
        'unipaz360.sesion': 'no es json',
      });

      expect(await SesionEnDispositivo().cargar(), isNull);
    });
  });
}
