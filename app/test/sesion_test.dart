import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unipaz360/data/cuenta_servicio.dart';
import 'package:unipaz360/data/sesion_repositorio.dart';
import 'package:unipaz360/domain/sesion.dart';
import 'package:unipaz360/ui/sesion/sesion_viewmodel.dart';

/// La plataforma de mentira: contesta lo que se le ponga en [respuestas], en orden.
class _Plataforma implements ServicioCuenta {
  _Plataforma([this.respuestas = const <Object>[]]);

  final List<Object> respuestas;
  final List<String> secretos = <String>[];
  final List<String> usos = <String>[];
  final List<String> salidas = <String>[];
  String? reto;
  bool? valeLaFicha = true;

  @override
  Uri urlIngreso(String r) {
    reto = r;
    return Uri.parse('https://plataforma.prueba/api/sesion/google?app=$r');
  }

  @override
  Future<RespuestaIngreso> recoger(String secreto) async {
    secretos.add(secreto);
    final r = respuestas[(secretos.length - 1).clamp(0, respuestas.length - 1)];
    if (r is RespuestaIngreso) return r;
    throw r;
  }

  @override
  Future<bool?> registrarUso(String ficha) async {
    usos.add(ficha);
    return valeLaFicha;
  }

  @override
  Future<void> salir(String ficha) async => salidas.add(ficha);
}

const Duration _ya = Duration(milliseconds: 1);

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

    test('recupera la cuenta guardada y avisa que la app se abrió', () async {
      final plataforma = _Plataforma();
      final vm = SesionViewModel(
        SesionEnMemoria(
          const Sesion(
            tipo: TipoSesion.institucional,
            correo: 'ana@unipaz.edu.co',
            ficha: 'ficha-de-ana',
          ),
        ),
        servicio: plataforma,
      );

      await vm.cargar();
      await Future<void>.delayed(_ya);

      expect(vm.esInstitucional, isTrue);
      expect(vm.sesion?.correo, 'ana@unipaz.edu.co');
      expect(plataforma.usos, <String>['ficha-de-ana']);
    });

    test('sin cuenta no se le avisa nada a la plataforma', () async {
      final plataforma = _Plataforma();
      final vm = SesionViewModel(SesionEnMemoria(), servicio: plataforma);
      await vm.cargar();
      await Future<void>.delayed(_ya);
      expect(vm.esInvitado, isTrue);
      expect(plataforma.usos, isEmpty);
    });

    test(
      'si la plataforma dice que la sesión ya no vale, queda de invitado',
      () async {
        final repositorio = SesionEnMemoria(
          const Sesion(
            tipo: TipoSesion.institucional,
            correo: 'ana@unipaz.edu.co',
            ficha: 'vieja',
          ),
        );
        final vm = SesionViewModel(
          repositorio,
          servicio: _Plataforma()..valeLaFicha = false,
        );
        await vm.cargar();
        await Future<void>.delayed(_ya);
        expect(vm.esInvitado, isTrue);
        expect(repositorio.sesion, isNull);
      },
    );

    test('sin internet la cuenta guardada se conserva', () async {
      final vm = SesionViewModel(
        SesionEnMemoria(
          const Sesion(
            tipo: TipoSesion.institucional,
            correo: 'ana@unipaz.edu.co',
            ficha: 'f',
          ),
        ),
        servicio: _Plataforma()..valeLaFicha = null,
      );
      await vm.cargar();
      await Future<void>.delayed(_ya);
      expect(vm.esInstitucional, isTrue);
    });

    test('una cuenta institucional sin ficha (la entrada de prueba de antes) no vale', () async {
      final repositorio = SesionEnMemoria(
        const Sesion(
          tipo: TipoSesion.institucional,
          correo: 'ana@unipaz.edu.co',
        ),
      );
      final vm = SesionViewModel(repositorio, servicio: _Plataforma());
      await vm.cargar();
      expect(vm.esInvitado, isTrue);
      expect(repositorio.sesion, isNull);
    });

    test('entrar con Google: abre el navegador, espera y guarda la cuenta', () async {
      final plataforma = _Plataforma(<Object>[
        const IngresoPendiente(),
        Exception('sin red un momento'),
        const IngresoListo(
          correo: 'Ana@Unipaz.edu.co',
          nombre: ' Ana Pérez ',
          ficha: 'ficha-nueva',
        ),
      ]);
      final abiertas = <Uri>[];
      final repositorio = SesionEnMemoria();
      final vm = SesionViewModel(
        repositorio,
        servicio: plataforma,
        abrir: (u) async {
          abiertas.add(u);
          return true;
        },
        pausa: _ya,
      );
      final estados = <EstadoIngreso>[];
      vm.addListener(() => estados.add(vm.estadoIngreso));

      await vm.iniciarConGoogle();

      expect(abiertas, hasLength(1));
      expect(abiertas.single.queryParameters['app'], plataforma.reto);
      expect(plataforma.reto, matches(RegExp(r'^[0-9a-f]{64}$')));
      // Siempre el mismo secreto, que nunca viaja en la dirección que se abre.
      expect(plataforma.secretos.toSet(), hasLength(1));
      expect(
        plataforma.secretos.first,
        matches(RegExp(r'^[A-Za-z0-9_-]{43}$')),
      );
      expect('${abiertas.single}', isNot(contains(plataforma.secretos.first)));
      expect(estados.first, EstadoIngreso.esperando);
      expect(vm.estadoIngreso, EstadoIngreso.reposo);
      expect(vm.esInstitucional, isTrue);
      expect(vm.sesion?.correo, 'ana@unipaz.edu.co');
      expect(vm.sesion?.nombre, 'Ana Pérez');
      expect(repositorio.sesion?.ficha, 'ficha-nueva');
    });

    test('cada intento usa un secreto distinto', () async {
      final plataforma = _Plataforma(<Object>[const ErrorCuenta('no')]);
      final vm = SesionViewModel(
        SesionEnMemoria(),
        servicio: plataforma,
        abrir: (_) async => true,
        pausa: _ya,
      );
      await vm.iniciarConGoogle();
      await vm.iniciarConGoogle();
      expect(plataforma.secretos.toSet(), hasLength(2));
    });

    test(
      'si la plataforma dice que no, se muestra el motivo y no entra',
      () async {
        final vm = SesionViewModel(
          SesionEnMemoria(),
          servicio: _Plataforma(<Object>[
            const IngresoPendiente(),
            const ErrorCuenta('Este ingreso ya venció.'),
          ]),
          abrir: (_) async => true,
          pausa: _ya,
        );
        await vm.iniciarConGoogle();
        expect(vm.estadoIngreso, EstadoIngreso.fallo);
        expect(vm.mensajeIngreso, 'Este ingreso ya venció.');
        expect(vm.esInvitado, isTrue);
        vm.cancelarIngreso();
        expect(vm.estadoIngreso, EstadoIngreso.reposo);
        expect(vm.mensajeIngreso, isNull);
      },
    );

    test('un correo que no es de la institución no entra aunque la plataforma lo mande', () async {
      final vm = SesionViewModel(
        SesionEnMemoria(),
        servicio: _Plataforma(<Object>[
          const IngresoListo(correo: 'ana@gmail.com', ficha: 'x'),
        ]),
        abrir: (_) async => true,
        pausa: _ya,
      );
      await vm.iniciarConGoogle();
      expect(vm.estadoIngreso, EstadoIngreso.fallo);
      expect(vm.esInvitado, isTrue);
    });

    test('si el navegador no abre, lo dice', () async {
      final plataforma = _Plataforma(<Object>[const IngresoPendiente()]);
      final vm = SesionViewModel(
        SesionEnMemoria(),
        servicio: plataforma,
        abrir: (_) async => false,
        pausa: _ya,
      );
      await vm.iniciarConGoogle();
      expect(vm.estadoIngreso, EstadoIngreso.fallo);
      expect(plataforma.secretos, isEmpty);
    });

    test('cancelar deja de preguntar', () async {
      final plataforma = _Plataforma(<Object>[const IngresoPendiente()]);
      final vm = SesionViewModel(
        SesionEnMemoria(),
        servicio: plataforma,
        abrir: (_) async => true,
        pausa: const Duration(milliseconds: 5),
      );
      final espera = vm.iniciarConGoogle();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      vm.cancelarIngreso();
      await espera;
      final hechas = plataforma.secretos.length;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(plataforma.secretos.length, hechas);
      expect(vm.estadoIngreso, EstadoIngreso.reposo);
      expect(vm.esInvitado, isTrue);
    });

    test('se acaba el tiempo si la persona nunca termina', () async {
      final vm = SesionViewModel(
        SesionEnMemoria(),
        servicio: _Plataforma(<Object>[const IngresoPendiente()]),
        abrir: (_) async => true,
        pausa: _ya,
        limite: const Duration(milliseconds: 20),
      );
      await vm.iniciarConGoogle();
      expect(vm.estadoIngreso, EstadoIngreso.fallo);
    });

    test('cerrar sesión borra la cuenta y anula la ficha', () async {
      final plataforma = _Plataforma();
      final repositorio = SesionEnMemoria(
        const Sesion(
          tipo: TipoSesion.institucional,
          correo: 'ana@unipaz.edu.co',
          ficha: 'f1',
        ),
      );
      final vm = SesionViewModel(repositorio, servicio: plataforma);
      await vm.cargar();

      await vm.salir();
      await Future<void>.delayed(_ya);

      expect(vm.esInvitado, isTrue);
      expect(vm.haySesion, isFalse);
      expect(repositorio.sesion, isNull);
      expect(plataforma.salidas, <String>['f1']);
    });

    test('la ficha se guarda y se lee con la sesión', () {
      const s = Sesion(
        tipo: TipoSesion.institucional,
        correo: 'ana@unipaz.edu.co',
        ficha: 'abc',
      );
      expect(Sesion.desdeJson(s.aJson())?.ficha, 'abc');
      expect(
        Sesion.desdeJson(const <String, Object?>{
          'tipo': 'institucional',
          'ficha': 7,
        })?.ficha,
        isNull,
      );
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
