---
tags: [unipaz360, sistema, flutter, preparacion]
fecha: 2026-11-05
estado: vigente
---
# Flutter: listo para empezar

> [!abstract] Para qué es esta nota
> La revisión del **5 de noviembre de 2026**, antes de la fase B del [[Plan de trabajo - actualizaciones]]. Cubre:
> - Las herramientas instaladas.
> - Cómo compila la app hoy en cada plataforma.
> - Una prueba aparte con las dependencias de la fase B (SQLite y compañía).
> - Los errores que aparecieron y cómo quedaron.
> - Lo que falta, separado en dos: lo que tiene que hacer el equipo y lo técnico.

> [!success] En una frase
> Las herramientas están completas, la app compila para **web** y **Android**, y SQLite con búsqueda FTS5 funciona en Android, Windows y las pruebas.
> - Para **Windows** solo falta activar el **Modo de desarrollador** del PC.
> - Los arreglos de esta revisión van en el commit `4f041d6` (rama `plataforma`).

---

## 1. Herramientas (`flutter doctor`)

| Pieza | Versión | Estado |
|---|---|---|
| Flutter / Dart | 3.47.7 / 3.13.5 (estable) | ✅ |
| Android SDK | 36.0.0, licencias aceptadas, Java del JBR de Android Studio | ✅ |
| CMake del SDK de Android | 3.22.1 (se instaló solo la primera vez que hubo código C que compilar) | ✅ |
| Visual Studio Build Tools 2022 | 17.14 con el SDK de Windows 10 (10.0.26100) | ✅ |
| Navegadores | Chrome y Edge | ✅ |

`flutter doctor -v` dice **«No issues found!»**.

---

## 2. Cómo compila la app hoy

| Plataforma | Comando | Resultado |
|---|---|---|
| Web | `flutter build web --release` | ✅ En 1 minuto. También pasa la prueba de WebAssembly (`--wasm`). |
| Android | `flutter build apk --debug` | ✅ |
| Windows | `flutter build windows --release` | ⚠️ Se detiene: *«Building with plugins requires symlink support»*. Hay que activar el **Modo de desarrollador** (sección 6). |
| macOS e iOS | — | Cuando haya un Mac (fase D). |

La carpeta `app/windows` se creó en esta revisión con:
- Nombre «UniPaz360».
- Empresa «UNIPAZ - Instituto Universitario de la Paz».
- Ventana de 1280 × 720.

### Qué plugin funciona en qué plataforma

| Paquete | Android | Web | Windows | Qué pasa donde no hay |
|---|---|---|---|---|
| `url_launcher`, `shared_preferences` | ✅ | ✅ | ✅ | — |
| `video_player` 2.14 | ✅ | ✅ | ❌ | El video institucional muestra «No fue posible cargar el video…» (no se rompe). |
| `webview_flutter` 4.14 | ✅ | ❌ (la web usa su propio `<iframe>`) | ❌ | Ahora muestra el plano del dron (ver 3.2). |
| `sqlite3` (fase B) | ✅ | ✅ con `sqlite3.wasm` | ✅ | — |
| `path_provider` (fase B) | ✅ | No aplica: se usa IndexedDB | ✅ | — |

---

## 3. Errores que aparecieron y cómo quedaron (commit `4f041d6`)

### 3.1 Dos Material mezclados (el más importante)

**Antes:** casi toda la app usa `material_ui`, el Material **oficial** que Flutter separó del SDK (vive en `flutter/packages`). Tres archivos y una prueba seguían con `package:flutter/material.dart`: `contenido_tour.dart`, `seccion_tour.dart` y el mapa embebido. Son **clases distintas**, y una prueba lo confirmó:
- Los widgets del Material viejo **no veían el tema verde** de la app. Salía el morado por defecto (#6750A4), por ejemplo en «Cómo llegar con Google Maps».
- `ScaffoldMessenger.of` **fallaba** con un `FlutterError`. Si un enlace no se podía abrir, el aviso «No se pudo abrir el enlace» rompía la pantalla.

**Ahora:** todo importa `material_ui`, y el README de la app lo deja como regla.

> [!note] Esto resuelve el punto 5 de [[Visión consolidada (nov-2026)]]
> `material_ui` no era un error: es el reemplazo oficial y se queda. El error eran los archivos que no se habían pasado.

### 3.2 El mapa de Google en Windows

**Antes:** en Windows no existe `webview_flutter`. Con internet, crear el mapa embebido lanzaba un error.

**Ahora:**
- Donde no hay WebView se muestra el **plano del dron** con la insignia «Plano del dron».
- «Cómo llegar con Google Maps» sigue abriendo el navegador.
- La importación condicional pasó de `dart.library.html` a `dart.library.js_interop`. La primera **no existe** al compilar a WebAssembly, y la web habría terminado usando la versión con WebView.

### 3.3 Idioma

**Antes:** la app no declaraba idioma. Flutter la anunciaba como inglés: en la web quedaba `<html lang="en-US">`, y los textos del sistema («Back», «Copy») salían en inglés.

**Ahora:** español de Colombia (`es-CO`) con `GlobalMaterialLocalizations`. Se comprobó en el navegador: `lang="es-CO"`. Ayuda a WCAG 2.2 AA (criterio 3.1.1, idioma de la página).

### 3.4 Datos de plantilla

- **Manifiesto web:** tenía la orientación **vertical** (`portrait-primary`), al contrario del modo horizontal de la app. Quedó en horizontal, con nombre «UniPaz360», descripción en español y color #155E49.
- **Android:** el nombre bajo el ícono pasó de «unipaz360» a «UniPaz360».

### 3.5 Dependencias

- Se agregó `cupertino_icons` 2.0.0. Quita el aviso *«Expected to find fonts for CupertinoIcons»* y, con la poda de íconos, pesa 1,4 KB.
- Se subieron versiones dentro de sus rangos: `material_ui` 1.10.0, `cupertino_ui` 1.1.6, `shared_preferences_android` 2.5.4 (ahora usa `jni`) y `web` 1.1.2.

**Verificación:** `flutter analyze` sin problemas, las **98 pruebas** en verde, compilación web y APK. También se revisaron en el navegador el ingreso como invitado, Ubicación y Admisiones.

---

## 4. Prueba de la fase B (proyecto aparte, sin tocar la app)

**Paquetes:** `sqlite3` 3.9.0 + `path_provider` 2.1.6 + `crypto` 3.0.8 + `http` 1.6.0.

**Datos:** el `datos.sqlite` de verdad que arma el empaquetador:

```bash
node scripts/empaquetar.mjs --fuente datos/ejemplo --salida <carpeta>
```

| Qué se probó | Resultado |
|---|---|
| Versión de SQLite que trae el paquete | **3.54.1**, con FTS5, RTREE y funciones matemáticas. |
| Abrir `datos.sqlite` en **solo lectura** (pruebas en Windows) | ✅ `integrity_check = ok` y `esquema_version = 3`. Escribir falla, como debe ser. |
| Búsqueda FTS5 sin tildes | ✅ «coordinacion» → *Coordinación Académica*. «biblio*» → *Biblioteca*. |
| Android | ✅ `libsqlite3.so` (arm64-v8a, armeabi-v7a y x86_64) y `libdartjni.so` dentro del APK. |
| Windows (sin plugins) | ✅ `sqlite3.dll` junto al `.exe`. |
| Web | ✅ Compila con importaciones condicionales (`package:sqlite3/wasm.dart`). Para correr necesita `web/sqlite3.wasm` (sección 7). |

> [!tip] Decisiones que deja la prueba
> - **`sqlite3` directo**, sin drift. La base es de solo lectura y las consultas son pocas, así que no hace falta generar código. El código común usa `package:sqlite3/common.dart`.
> - **Sin `sqlite3_flutter_libs`.** Desde `sqlite3` 3.x el paquete trae SQLite solo, con *hooks* de Dart: descarga los binarios oficiales y revisa su SHA-256.
>   - La **primera** compilación necesita internet (también en el CI).
>   - Si algún día se quiere un espejo propio, existe la opción `url_pattern`.
> - En Android, `path_provider` compila un pedacito de C (`jni`). Por eso el SDK instaló CMake la primera vez.

---

## 5. Cosas del diseño que la fase B tiene que respetar

- **La base del paquete es de solo lectura y se reemplaza entera** en cada actualización. El esquema local trae una tabla `reporte` («cola local»), pero ahí se perdería. La cola de reportes, las vistas recientes y la sesión van en un almacén aparte: `local.sqlite` o `shared_preferences`.
- **`configuracion_app` llega vacía** desde el empaquetador de CSV porque la llena la plataforma. Para la fase F se prueba con un paquete exportado del panel.
- **Prueba fija:** guardar un `datos.sqlite` pequeño generado de `datos/ejemplo` (unos 212 KB) en `app/test/` y un script para regenerarlo. Así las pruebas no dependen de Node.

---

## 6. Lo que tiene que hacer el equipo (no se puede hacer desde aquí)

- [ ] **Activar el Modo de desarrollador de Windows:** Configuración → Sistema → Para programadores → *Modo de desarrollador*, o `start ms-settings:developers`. Es un ajuste del sistema; después de activarlo, `flutter build windows` funciona.
- [ ] **Borrar las 2 etiquetas viejas** del remoto. Su contenido ya está en `plataforma`:
  ```bash
  git push origin --delete refs/tags/archivo/p1-plataforma-grafo refs/tags/archivo/p2-plataforma-completa
  ```
- [ ] **Correr** `node panel/scripts/configurar-r2.mjs` para el CORS con `Range`.
- [ ] **Decisiones D10 a D14.** D12, el identificador de la app, hoy es `co.edu.unipaz.dam.unipaz360` y no se puede cambiar después de publicar en Google Play.
- [ ] **El logo** → [[Marca y logo]]. Los íconos de Android, web y Windows todavía son los de Flutter.

## 7. Pendientes técnicos, en orden

1. [ ] **TEC-06:** ordenar `app/lib` en `core/` y `features/`, y partir los archivos gigantes: `pantalla_dron.dart` (2.084 líneas), `contenido_tour.dart` (1.522) y `pantalla_visor.dart` (1.220). Es el prerrequisito de la fase B.
2. [ ] **Fase B** con las decisiones de la sección 4.
3. [ ] **Web:** poner `sqlite3.wasm` de la misma versión del paquete en `app/web/`. Sale de los *releases* de `simolus3/sqlite3.dart` en GitHub, etiqueta `sqlite3-3.9.0`, y hay que descargarlo con permiso. Además, guardar en IndexedDB.
4. [ ] **Video en Windows:** decidir en la fase D entre `video_player_win` (liviano) y `media_kit` (más pesado, trae su propio reproductor).
5. [ ] **El mapa embebido de Google** depende de internet y de un WebView. La meta sigue siendo el mapa propio con la ortofoto ([[Visión consolidada (nov-2026)]], punto 4).
6. [ ] **Transiciones:** `go_router` 17 solo reconoce el `MaterialApp` viejo, así que con `material_ui` las páginas cambian sin animación. No es un error. Revisarlo con `go_router` 18 (cambio mayor) o con un `pageBuilder` propio durante TEC-06.
7. [ ] **Firma de *release* de Android:** hoy usa la llave de depuración (fase D).

---

Relacionado: [[Plan de trabajo - actualizaciones]] · [[Plan de trabajo - guía y chatbot]] · [[Cliente Flutter]] · [[Flujo de actualización (plataforma → apps)]] · [[Bitácora del repositorio]]

Volver a [[00 Sistema - Índice]] · [[00 UniPaz360 - Índice]]
