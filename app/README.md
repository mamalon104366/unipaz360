# App UniPaz360 (Flutter)

Aplicación multiplataforma de orientación para el **Centro de Investigaciones Santa Lucía de UNIPAZ**. Encuentra aulas y oficinas y muestra la ruta a pie, incluida una ruta sin escaleras. **Funciona sin conexión.**

- **Proyecto Flutter:** `unipaz360` · organización `co.edu.unipaz.dam` · Flutter 3.47 / Dart 3.13
- **Plataformas:** Android (siempre horizontal), web y Windows. macOS e iOS se agregan cuando haya un Mac: `flutter create --platforms=macos,ios .`
- **Dependencias base:** `material_ui` (el Material oficial, separado de Flutter) · `provider` (estado) · `go_router` (navegación)
- **Idioma:** español de Colombia (`es-CO`) en toda la app.

## Comandos

```bash
flutter pub get
flutter analyze            # el CI lo corre en cada PR
flutter test               # el CI lo corre en cada PR
flutter run -d windows     # también -d chrome o un Android conectado
flutter build web --release
flutter build apk --debug
flutter build windows --release
```

> **Windows:** para compilar con plugins, Flutter necesita enlaces simbólicos. Activa el
> **Modo de desarrollador** una vez (Configuración → Sistema → Para programadores, o
> `start ms-settings:developers`). Sin eso, `flutter build windows` se detiene con
> «Building with plugins requires symlink support».

## Reglas para no romper nada

- Importa siempre `package:material_ui/material_ui.dart`, **nunca** `package:flutter/material.dart`.
  Son clases distintas: un widget del Material viejo no ve el tema verde de la app y
  `ScaffoldMessenger.of` falla.
- Las importaciones condicionales para la web usan `dart.library.js_interop`
  (`dart.library.html` no existe al compilar a WebAssembly).
- `webview_flutter` solo funciona en Android, iOS y macOS: antes de usarlo revisa
  `mapaEmbebidoDisponible` (`lib/ui/visor/google_maps_embed_stub.dart`). En Windows el video lo
  reproduce `video_player_win`.

## Organización de `lib/`

| Carpeta | Contenido |
|---|---|
| `lib/app/` | Arranque, tema, idioma y enrutado (`UniPaz360App`) |
| `lib/domain/` | Entidades y contratos (Dart puro) |
| `lib/data/` | Repositorios (hoy simulado; luego SQLite y el paquete de datos) |
| `lib/core/modelo/` | La apariencia (`ConfigApp`, con las mismas reglas del panel) y el recorrido 360° |
| `lib/core/marca/` | El logo de UNIPAZ dibujado con sus trazos (`LogoUnipaz`); los trazos los genera `node panel/scripts/marca.mjs` desde `marca/` |
| `lib/core/paquete/` | Leer el paquete (`datos.sqlite`) y ubicar cada recurso (semilla o internet) |
| `lib/features/cliente/` | La app del visitante tal como la diseña el apartado Cliente (`vista_cliente.dart`) |
| `lib/features/visor360/` | El recorrido 360°: geometría, puntos 2D y 3D, animaciones y flechas |
| `lib/features/rutas/` | Motor de rutas sin conexión (A* estándar y accesible, paso a paso) |
| `lib/features/asistente/` | Chatbot sin conexión que guía hasta cualquier lugar |
| `lib/ui/` | Pantallas y widgets (ingreso, visor 360°, mapa del dron, recorrido) |

## Datos y recursos

- `assets/paquete/`: la **semilla** (el paquete con el que arranca sin internet). Se rehace desde la
  raíz del repositorio, sin publicar nada:

  ```bash
  node --conditions=react-server --experimental-transform-types panel/scripts/semilla-app.mjs
  ```

- `assets/config/por_defecto.json` y `test/cliente/casos_normalizar.json`: salen del código del panel
  con `panel/scripts/config-app-flutter.mjs` (córrelo si cambia `configApp.ts` o `paginasIniciales.ts`).
- `assets/fuentes/`: Roboto y Noto Serif, las mismas del apartado Cliente (licencia OFL).
- `web/sqlite3.wasm`: SQLite para la web, de la misma versión que el paquete `sqlite3` (3.9.0).
- `NuGet.Config`: fuente de paquetes para compilar en Windows (`video_player_win` baja una biblioteca
  de Microsoft con NuGet; sin fuentes configuradas, la compilación falla).

## Evidencias

Las capturas del Sprint 1 están en [`evidencias/android/`](../evidencias/android/).

El diseño completo está en [`docs/plan/04-cliente-flutter.md`](../docs/plan/04-cliente-flutter.md).
