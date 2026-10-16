# App UniPaz360 (Flutter)

Aplicación multiplataforma de orientación para el **Centro de Investigaciones Santa Lucía de UNIPAZ**. Encuentra aulas y oficinas y muestra la ruta a pie, incluida una ruta sin escaleras. **Funciona sin conexión.**

- **Proyecto Flutter:** `unipaz360` · organización `co.edu.unipaz.dam`
- **Plataformas:** Android (hoy). Web, Windows e iOS se agregan con `flutter create --platforms`.
- **Dependencias base:** `provider` (estado) · `go_router` (navegación)

## Comandos

```bash
flutter pub get
flutter analyze            # el CI lo corre en cada PR
flutter test               # el CI lo corre en cada PR
flutter run -d windows     # también -d chrome o un Android conectado
```

## Organización de `lib/`

| Carpeta | Contenido |
|---|---|
| `lib/app/` | Arranque y enrutado (`UniPaz360App`) |
| `lib/domain/` | Entidades y contratos (Dart puro) |
| `lib/data/` | Repositorios (hoy simulado; luego SQLite y el paquete de datos) |
| `lib/ui/` | Pantallas y widgets (espacios, detalle, estados) |

## Evidencias

Las capturas del Sprint 1 están en [`evidencias/android/`](../evidencias/android/).

## Plataformas pendientes

```bash
cd app
flutter create --platforms web,windows,ios .
```

El diseño completo está en [`docs/plan/04-cliente-flutter.md`](../docs/plan/04-cliente-flutter.md).
