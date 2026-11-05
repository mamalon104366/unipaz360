---
tags: [unipaz360, sistema, bitacora]
---
# Bitácora del repositorio

> Registro fechado de lo que se agrega o se decide en el código. Lo más reciente va arriba. Cada cambio nuevo del código deja una entrada aquí.
>
> **Repositorio real del proyecto:** `C:\Users\mamalon\Pictures\univerrsidadaddadada\unipaz360` (GitHub `mamalon104366/unipaz360`, rama `main`). La carpeta `C:\unipaz360` es solo evidencia.

## 2026-11-05 · Logo de UNIPAZ y barra sin encabezado (commits `77470af` y `8232b8d`)

- **Logo:** el equipo entregó el logo de la universidad (JPG y PNG) y se pasó a vector en `marca/`, con un script que genera lo demás: `node panel/scripts/marca.mjs`. Detalle en [[Marca y logo]].
  - Íconos de Android (adaptativo y monocromo), web y Windows; favicon, entrada y riel del panel; placas QR y parche del nadir.
  - Los colores por defecto pasan a los del logo: azul `#233671` y verde `#0a9640`.
- **Se quitó el encabezado**, a pedido del equipo, tomando como referencia el tour de la Universidad de La Sabana. Desapareció de la configuración (`encabezado`), de la vista previa y de la app.
  - La barra va de borde a borde, con el logo arriba, las secciones con separadores y el nombre al pie.
  - Un botón redondo en el borde la pliega. Sin una página abierta se esconde y el logo se queda sobre la foto, con sombra.
  - La búsqueda pasó a un botón redondo en la esquina contraria, que abre «Cómo llegar».
  - Campo nuevo: `barraLateral.mostrarLogo`. Ancho por defecto: 20 % (mínimo 210 dp).
  - En celular va en modo compacto: caben las seis secciones aun con 360 dp de alto.
  - El vidrio pasó de negro al 35 % al 55 %, porque el texto blanco no se leía sobre paredes claras.
- **Verificación:**
  - 140 pruebas y `flutter analyze` sin problemas; TypeScript y ESLint del panel sin errores. La vista previa en Vercel compiló bien.
  - Compila para web, Windows y Android.
  - Revisado en la ventana de Windows en tamaño de escritorio y de celular, y la vista previa del panel en un servidor local.
- **Sigue pendiente:** promover el panel a producción (con el OK del equipo) y probar en un celular.
- **Documento de grado:** se agregó el numeral 5.4 Marco tecnológico. Ver [[Avance documental (oct-2026)]].

## 2026-11-05 · La app se ve como la plataforma (commits `9a9c965`, `de6e171` y `8888f4d`)

- **La pantalla principal de la app ahora se arma con la configuración del apartado Cliente.** Lo que se ve en la vista previa es lo que se ve en la app, sin internet:
  - El encabezado, la barra (o el riel) y el minimapa en sus tres estados.
  - El botón de inicio y las páginas con pestañas, con el lienzo escalado por `k`.
  - La ficha de los puntos.
  - «Cómo llegar», que en la app funciona con el motor de rutas.
- **Recorrido 360°:**
  - La foto real con la corrección de horizonte, que se arrastra y se acerca.
  - Los puntos 2D (6 formas y 8 animaciones) y las capas 3D, colocadas como en Photo Sphere Viewer.
  - Las flechas a las fotos vecinas y el fundido de 1,1 s al cambiar de foto.
- **Datos:**
  - La app arranca con una **semilla** (`app/assets/paquete/`) armada con el mismo código de «Publicar», sin publicar nada: `panel/scripts/semilla-app.mjs`.
  - La normalización de la apariencia da lo mismo que la del panel: se compara con casos generados por el propio panel.
- **Lo que hizo falta para que sirva en todas las plataformas:**
  - En la web, `sqlite3.wasm`.
  - En Windows, video con `video_player_win` y `app/NuGet.Config`: NuGet no tenía fuentes en el PC y la compilación fallaba.
  - Las fuentes Roboto y Noto Serif (OFL), recortadas al alfabeto latino.
  - Las sombras convertidas de CSS a Flutter.
- **Repositorio:**
  - Se borraron las etiquetas `archivo/p1-plataforma-grafo` y `archivo/p2-plataforma-completa`.
  - Ya está activo el Modo de desarrollador de Windows.
- **Vista previa del panel:** el encabezado y la barra usan Roboto, como la app. Llega a producción cuando se promueva.
- **Verificación:**
  - 120 pruebas (22 nuevas) y `flutter analyze` sin problemas.
  - Compila para web, Android (APK de *release*) y Windows.
  - Revisado en el navegador y en la ventana de Windows.
- **Cómo probarlo:** [[Guía de pruebas - app igual a la plataforma]].

## 2026-11-05 · Flutter listo para empezar (commit `4f041d6`)

- **Revisión antes de la fase B:**
  - `flutter doctor` sin problemas.
  - La app compila para **web** y **Android**.
  - **Windows** necesita activar el Modo de desarrollador del PC (enlaces simbólicos para los plugins).
  - Detalle completo en [[Flutter - listo para empezar]].
- **`app/windows`** creada: nombre UniPaz360, empresa UNIPAZ y ventana de 1280 × 720.
- **Material único:** 3 archivos y una prueba usaban el Material viejo de Flutter. No veían el tema verde (salía el morado por defecto) y el aviso de enlace roto fallaba. Ahora todo importa `material_ui`.
- **Mapa en Windows:** sin WebView, ahora muestra el plano del dron en lugar de romperse. La importación condicional usa `dart.library.js_interop`, que también sirve al compilar a WebAssembly.
- **Español (`es-CO`)** en toda la app. En la web queda `<html lang="es-CO">`, comprobado en el navegador.
- **Manifiesto web:** horizontal (estaba en vertical), nombre, descripción y color. En Android, la etiqueta «UniPaz360».
- **Dependencias:** `cupertino_icons` 2.0.0 y versiones al día dentro de sus rangos.
- **Prueba de la fase B** (proyecto aparte): `sqlite3` 3.9 abre el `datos.sqlite` real en solo lectura, con búsqueda FTS5 sin tildes.
  - Funciona en las pruebas, en Android y en Windows, y compila para la web.
  - Decisión: `sqlite3` directo, sin drift ni `sqlite3_flutter_libs`.
- **Verificación:** `flutter analyze` sin problemas y 98 pruebas en verde.
- **Lo que sigue:** TEC-06 (ordenar `app/lib`) y después la fase B.

## 2026-11-05 · Chatbot que guía sin conexión (fase H1, commit `5b9d3bd`)

- **`app/lib/features/asistente/`** (Dart puro, sin red): el asistente **Paz** entiende «¿cómo llego a la biblio?», «llévame al B2-201 sin escaleras», «de la portería al lab de redes» y «¿hay un baño cerca?».
  - Tolera errores («bilbioteca»), abreviaturas («lab», «biblio», «salón») y códigos escritos de cualquier forma («b2 201»).
  - Si hay varios lugares parecidos, pregunta cuál (por botón o «la segunda»).
  - Si no sabe desde dónde sales, lo pregunta. Si la app lo sabe (foto 360° o QR), da la ruta de una vez.
  - Responde con la ruta paso a paso del motor de rutas y botones: «Ver en el mapa», «Seguir en 360°» y «Sin escaleras».
  - Habla bien: «al Laboratorio de Redes», «a la Biblioteca», «el Aula 101».
- **Nunca inventa:** si un lugar no existe lo dice, y si no hay ruta sin escaleras lo dice y ofrece la otra. Ante una pregunta fuera de tema explica lo que sabe hacer.
- **Pruebas:** 23 diálogos dorados con `datos/ejemplo` y con baños de prueba para «el más cercano». La app entera: **98 pruebas** y `flutter analyze` sin problemas.
- **Producción:** desde el 5 de noviembre corre la plataforma de `b2a912e` (fase A incluida), con el visto bueno del usuario. Este commit es solo de la app y no cambia el panel.
- **Lo que sigue:** H2, el chat en la app. Necesita la fase B (leer `datos.sqlite` del paquete) para usar los datos reales en lugar de los de ejemplo.

## 2026-11-05 · Motor de rutas sin conexión (fase R1, commit `b2a912e`)

- **`app/lib/features/rutas/`** (Dart puro, sin red):
  - El grafo se arma con los nodos y tramos del paquete.
  - A* con la distancia en línea recta como heurística, en perfil **estándar** o **accesible** (solo tramos accesibles y sin escaleras; si no hay camino, lo dice).
  - Indicaciones en español: «Sigue derecho 65 m hasta…», «Gira a la izquierda en…», «Sube por la escalera hasta el piso 1».
  - Tiempo a 1,2 m/s, o 0,8 m/s en el perfil accesible.
- **Regla para que siempre sea la ruta óptima:** ningún tramo cuesta menos que la línea recta entre sus nodos. Una mala medida no engaña a A*.
- **Pruebas:** 11 nuevas con `datos/ejemplo` (la portería al Laboratorio de Redes gira a la izquierda; el Aula 101 solo por escalera, así que sin escaleras no hay ruta) y **2.000 comparaciones contra Dijkstra** en grafos al azar. La app entera: `flutter analyze` sin problemas y 75 pruebas pasan.
- **Rama:** va en `plataforma` porque `main` espera el push forzado de limpieza (`main-limpio`). Llega a `main` con el próximo PR, sin conflictos: `app/` es igual en las dos ramas.
- **Lo que sigue:** H1, el motor del asistente que usa este motor para guiar («¿cómo llego a la biblioteca?»).

## 2026-11-05 · Fase A en el servidor: candado, `version.json` v2 y regla de apariencia (rama `plataforma`)

- **Candado:** publicar y revertir toman `pg_try_advisory_xact_lock`. Si hay otra en curso, responden 409 sin tocar el puntero. Es de transacción porque `DATABASE_URL` usa el pooler de Neon (PgBouncer), donde los de sesión no sirven. Probado con dos conexiones reales: la segunda queda por fuera hasta que la primera termina.
- **`version.json` v2:** agrega `canal` (`estable`), `app_minima` por plataforma (constante en `panel/src/lib/paquete/contrato.ts`) y `resumen` (totales del paquete y cambios desde la publicación anterior, sacados de la auditoría). La app debe tolerar que falten.
- **Regla «apariencia válida»:**
  - `app://` que no viene en la app → error.
  - Imagen o video de otro sitio → aviso (sin conexión no se verá).
  - Enlace a una sección o a una foto 360° que no existe → error.
  - Nodos del minimapa que ya no existen → aviso.
  - 7 casos probados.
- La lista de recursos de la app pasó a `panel/src/lib/recursosApp.ts`, compartida por la vista previa y la validación. La revisión antes de publicar cuenta también las páginas.
- **Docs:** contrato v2 en `docs/datos/formato-paquete.md`.
- **Probado:** `tsc`, `eslint`, `next build` y `scripts/pruebas.mjs`. **No se publicó** una versión real. Commit `b6d8faf`. **En producción** desde el 5 de noviembre, con el visto bueno del usuario: se promovió la vista previa de `b2a912e`. Comprobado: `/ingreso` responde 200, la API sin sesión 401, `/cliente` redirige a ingresar y las imágenes de la app cargan.
- **Sigue pendiente de la fase A** (necesita al usuario): dominio propio para los datos (D11), migrar las URL guardadas y correr el CORS del bucket (`node panel/scripts/configurar-r2.mjs`, con `range` y los encabezados expuestos).

## 2026-11-05 · Plan de actualizaciones a las apps y estructura del logo (solo documentación)

- **Notas nuevas:** [[Flujo de actualización (plataforma → apps)]], [[Plan de trabajo - actualizaciones]] y [[Marca y logo]].
- **Qué queda definido:**
  - Los tres tipos de cambio: el contenido llega por el paquete, sin tiendas; el código necesita una versión nueva de la app.
  - El contrato de versiones: versión del paquete, esquema, versión de la app y `app_minima`. Se compara por «distinta», así una reversión también llega.
  - En el dispositivo: las carpetas, el puntero atómico `actual.json`, la semilla para el primer arranque sin red y la política de medios.
  - Cada plataforma (Android, web y Windows; después macOS e iOS) con sus trampas conocidas, la tabla de fallas previstas y las fases A a G con tareas y pruebas.
- **Hallazgos que quedaron como tareas:**
  - Las apps no deben bajar de `r2.dev`: hace falta un dominio propio.
  - Falta el CORS para la app web.
  - Falta un candado al publicar.
  - El identificador `co.edu.unipaz.dam.unipaz360` hay que decidirlo antes de Google Play.
  - Ya existían HU-09 (descargar datos actualizados) y TEC-07 (API del paquete); el plan se apoya en ellas y propone TEC-13 a TEC-19 y HU-28 a HU-31 (sin crearlas).
- **Decisiones nuevas** D10 a D14 en el [[00 Sistema - Índice]].
- **No se tocó código:** el usuario pidió estructurar primero y construir después. El logo llega pronto.
- **Guía sin conexión con chatbot:** nueva nota [[Plan de trabajo - guía y chatbot]]. Incluye el motor de rutas (R1), el motor del asistente con pruebas doradas (H1), el chat en la app con «Ver en el mapa» y «Seguir en 360°» (H2), y lo editable desde la plataforma (H3 y H4). El asistente nunca usa la red. Se apoya en HU-01, HU-03 a HU-08, HU-11 y HU-12, y propone TEC-20, TEC-21, HU-32 y HU-33.
- **El usuario aprobó empezar** cuando el plan estuviera completo: primero la fase A (servidor) y los motores R1 y H1, que no dependen de nada más.

## 2026-11-04 (noche) · Producción actualizada y por qué no se veía

- **Qué pasó:** en Vercel la rama de producción es `main`. Un push a `plataforma` solo crea una **vista previa**; producción cambia cuando esa vista previa se promueve. Por eso el usuario no veía los cambios.
- **Hecho:** el push forzado de `plataforma` (historia sin coautoría + commit `b019652`) generó la vista previa `fa87z02v8`. Se promovió a producción con `vercel promote`, que creó el despliegue `rmlro8w7n`. Comprobado en https://unipaz360-panel.vercel.app:
  - `/app/imagenes/…` y el video responden 200 (solo existen en la versión nueva).
  - `/ingreso` responde 200.
  - Sin sesión, la API responde 401 y `/cliente` manda a ingresar.
- **PR #35 (plataforma → main):** se fusionó con *squash* (`ff19088`) desde la versión anterior de `plataforma`, y GitHub copió las líneas «Co-Authored-By: Claude» al mensaje. Quedó listo el commit limpio `a855e10` (mismo contenido, autor Marlon) en la rama local `main-limpio`. Para reemplazarlo: `git push --force-with-lease=main:ff19088 origin main-limpio:main`.
- **También con coautoría:** las etiquetas `archivo/p1-plataforma-grafo` y `archivo/p2-plataforma-completa`. Se borran con `git push origin --delete refs/tags/archivo/p1-plataforma-grafo refs/tags/archivo/p2-plataforma-completa`.
- **Pendiente de decidir:** que producción salga sola al fusionar un PR a `main`, o directo de cada push a `plataforma`.

## 2026-11-04 · Páginas tipo Figma, minimapa con nodos y editor 360° pulido (rama `plataforma`)

- **Editor 360°** (lo que "no se guardaba"):
  - Causa del «Ir a»: solo existe una foto 360° (P-002), así que el punto no tenía a dónde llevar y el servidor lo rechazaba. Ahora el editor lo explica y lleva al mapa. Hay tarjetas del destino con su miniatura y el título se llena solo ("Ir a …"). El servidor valida que el destino exista y no sea la misma foto.
  - Cambios sin guardar: el botón de abajo decía «Todo guardado» aunque el punto tuviera cambios. Ahora guarda el punto y los ajustes juntos (también con Ctrl+S). Avisa «Sin guardar» y pregunta antes de salir; al cambiar de punto, lo pendiente se guarda solo.
  - Los puntos se **arrastran** sobre la foto, como en Figma; un toque los selecciona. Atajos: Esc y Supr.
  - **8 formas**: etiqueta, ícono, anillo, pin, tarjeta, miniatura, flecha en el piso y capa dentro de la imagen. Más **color** y **tamaño** por punto.
  - **9 animaciones**: pulso, latido, flotar, rebote, onda, girar, balanceo, parpadeo y ninguna.
  - La flecha se acuesta en el piso sola según su altura.
  - Los puntos quedan pegados a la foto aunque se corrija el horizonte (misma rotación que la esfera, comprobada contra three.js con un error de 1e-12°).
- **Apartado Cliente:**
  - Al tocar una sección de la barra se abre **su página con el contenido que ya tenía la app** (Nosotros con 3 pestañas, Video institucional, Admisiones con 4 pestañas y Ubicación), con las mismas imágenes y el mismo video.
  - Las páginas se editan **como en Figma**:
    - Seleccionar, arrastrar, cambiar el tamaño, girar y escribir con doble clic.
    - Guías inteligentes, selección con recuadro y varios elementos con Mayús.
    - Capas, alinear, duplicar, copiar y pegar, flechas y deshacer o rehacer (Ctrl+Z).
    - Elementos: texto, imagen, botón, forma, video y mapa.
  - Regla para Flutter: lienzo de 1000 unidades, la app escala todo por (ancho del panel / 1000).
  - **Minimapa:** los nodos del recorrido se ubican arrastrándolos sobre la foto del dron. Con 3 o más ubicados, el resto se calcula con un ajuste afín (lat, lon → x, y). El visitante tiene 3 estados (**minimizado, normal y maximizado**) y toca un nodo para ir a esa foto. Se puede seguir al visitante.
  - La vista previa es una pantalla a escala (915 dp en celular, 1440 dp en escritorio) con el recorrido real y sus puntos.
- **Contratos para Flutter:** `docs/datos/apariencia-app.md` y `docs/datos/puntos-360.md`.
- **Recursos de la app en el panel:** `panel/public/app/` es copia de `app/assets` (`node panel/scripts/sincronizar-recursos-app.mjs`). Se escriben como `app://imagenes/…` y `app://videos/…`.
- **Probado:**
  - `tsc`, `eslint`, `next build` y `scripts/pruebas.mjs` pasan.
  - 14 pruebas de `normalizarConfig` pasan: migración de la versión anterior, enlaces `javascript:` y rutas `file://` rechazados, campos por tipo.
  - El ajuste afín es exacto con 3 puntos y rechaza puntos en línea.
  - En el navegador, con datos de ejemplo: arrastrar, redimensionar, girar, deshacer, escribir en el lienzo, agregar y borrar, pestañas, editor de nodos y estados del minimapa, formas y animaciones 360°, arrastre de puntos y descartar cambios.
- **Falta:** probar con la sesión real (guardar en Neon) y hacer push. La rama local `plataforma` tiene la historia sin el trailer de coautoría; el usuario debe correr `git push --force-with-lease origin plataforma informativa`. Luego se promueve a producción.

## 2026-11-04 · Producción, ramas y minimapa del dron

- **Producción pública:** https://unipaz360-panel.vercel.app. Se promovió la rama `plataforma` y todas las variables quedaron en el entorno *Production*. Se entra solo con Google `@unipaz.edu.co` autorizado.
- **Ramas:** quedan solo `main` (app y datos), `plataforma` (panel) e `informativa` (este vault, sin la carpeta `convertido md` por derechos de autor). Las demás se archivaron como etiquetas `archivo/<rama>` y se borraron. El PR #34 se cerró, reemplazado por `plataforma`.
- **Cómo publicar en producción:**
  1. Push a `plataforma`, que crea una vista previa en https://unipaz360-panel-git-plataforma-mamalon104366s-projects.vercel.app
  2. `vercel promote <url de la vista previa>`
- **Cliente:**
  - El minimapa usa la foto del dron del proyecto (`public/marca/mapa-dron.jpg`; en la config se guarda `app://mapa-dron`) o una subida, con zoom, giro, encuadre y opacidad.
  - Hay tamaños ajustables (alto del encabezado, ancho de la barra, tamaño del minimapa, escala de textos).
  - El encabezado, la barra y el minimapa se pueden ocultar con botones, con la opción de que empiecen ocultos.
  - La vista previa usa el visor 360° esférico.
- **URIs de Google a registrar:** localhost:3060, la vista previa de `plataforma` y `https://unipaz360-panel.vercel.app/api/sesion/google/callback`.

## 2026-11-04 · Ingreso con Google, apartado Cliente y navegación por áreas (commit `1e456cb`)

- **Ingreso solo con Google:** OAuth con flujo de código, `state` y `nonce`. Solo entran cuentas `@unipaz.edu.co` verificadas **y** autorizadas en "Cuentas y roles"; por ahora la única es `esteban.merlanoqu@unipaz.edu.co`. Se retiraron las contraseñas.
- **Credenciales:** `GOOGLE_CLIENT_ID` y `GOOGLE_CLIENT_SECRET` están en `~/dev/unipaz360.secretos.env` y en Vercel (Preview). Nunca en el repo.
- **Falta registrar en Google Cloud** (proyecto `hip-arcadia-513721-j7` → Credenciales → cliente OAuth web → URIs de redireccionamiento autorizados):
  - `http://localhost:3060/api/sesion/google/callback`
  - `https://unipaz360-panel-git-p2-plataform-88b764-mamalon104366s-projects.vercel.app/api/sesion/google/callback`
- **Apartado Cliente** (migración 0004 `configuracion_app`): vista previa de la app en celular horizontal y en escritorio, editable como en Figma. Se editan marca y colores, encabezado, barra lateral (secciones, orden, íconos y visibilidad), minimapa y pantalla de inicio. Viaja en el paquete (tabla `configuracion_app`, clave `app`) para que Flutter lo aplique.
- **Navegación:** el riel elige el área (Inicio, Campus, Tour 360°, Cliente, Publicación o Ajustes) y la barra lateral muestra solo lo de esa área. En Tour aparece la lista de panorámicas.

## 2026-11-04 · Puntos 3D en el tour y rama en Vercel (commit `0ce8266`)

- **Migración 0003:** se agrega `punto_informacion.estilo` con forma (etiqueta, ícono, círculo, flecha en el piso o capa 3D), ancho, alto, rotación (yaw, pitch, roll) y animación (pulso, flotar). **Regla compartida con Flutter: ancho angular ≈ ancho/1000 rad.** El esquema del paquete v3 lleva `estilo`.
- **Editor 360°:**
  - Flechas en el piso para ir de nodo en nodo, estilo Unisabana, acostadas con una inclinación de +60°.
  - Capas 3D: imagen, **GIF animado** (se guarda sin convertir), **video con controles dentro de la foto** y tarjetas.
  - Todo con tamaño y giro ajustables y vista en vivo. En la vista del visitante, los puntos son clicables: las flechas navegan y el resto abre una ficha.
- **Mapa:** al tocar un nodo se ve su foto 360° o se sube ahí mismo. Los nodos con foto tienen un anillo azul.
- **Vercel:** se hizo push de la rama `p2-plataforma-completa`. Vista previa protegida: https://unipaz360-panel-git-p2-plataform-88b764-mamalon104366s-projects.vercel.app
- **Pendiente:**
  - ~~Cargar `R2_*` en Vercel~~ ✅ Ya están cargadas como secretos de Preview (con autorización del usuario) y la rama se redesplegó.
  - Configurar el CORS de R2.
  - La contraseña ya la tiene el usuario.

## 2026-11-04 · Plataforma P2 completa (rama `p2-plataforma-completa`, sin commit)

- **Migración 0002** aplicada en Neon (aditiva): contadores para que los identificadores nunca se reutilicen, sesiones, contraseña con scrypt, placas QR con instalación y retiro, ajustes no destructivos de las panorámicas y la tabla `punto_informacion` (hotspots).
- **El esquema del paquete pasa a v3**: `punto_informacion`, flechas con yaw y pitch, y `medio.url`. Las pruebas de `scripts/` siguen pasando.
- **Módulos nuevos del panel** (mismo diseño de la referencia):
  - Inicio de sesión, cuentas y roles (superadmin, editor, lector) y auditoría con exportación a CSV.
  - Espacios y bloques, con foto y nodo de acceso.
  - Anclajes QR, con hoja imprimible de placas (QR con corrección H).
  - **Panorámicas 360°** con Photo Sphere Viewer: puntos de información de 7 tipos, anuncios con vigencia, horizonte, norte, vista inicial, luz y color, difuminado de rostros y parche del nadir con el logo. El original nunca se toca.
  - **Publicar**: mismas reglas del empaquetador; construye `datos.sqlite`, lo sube a R2 y mueve `version.json`. También permite descargar un paquete de prueba.
  - **Historial**, con reversión en segundos.
- **Probado:** `tsc`, `eslint` y `next build` pasan. Se verificó en el navegador el inicio de sesión y el Inicio con datos reales. La subida y el procesado de una 360° real (5376×2688 → rápida 4096 px, 568 KB, en unos 7 s) funcionaron. **Los datos y la cuenta de prueba se borraron.**
- **No probado todavía:** los clics de los editores de Espacios, Anclajes y 360° en el navegador. **Publicar no se ejecutó a propósito** para no mandar una versión a producción.
- **Pendientes del usuario:**
  1. Crear su cuenta de superadministrador en el panel local (`/ingreso`).
  2. Configurar el CORS de R2 (`node scripts/configurar-r2.mjs`); el clasificador bloqueó ese paso.
  3. Cargar `R2_*` en Vercel para que el despliegue pueda subir medios.
  4. Revisar la rama y hacer el commit.

## 2026-11-04 · Panel desplegado en Vercel (vista previa protegida)

- Se creó el proyecto **`unipaz360-panel`** en Vercel, en `mamalon104366's projects` (plan Hobby). Es independiente del proyecto `unipaz360` de la app.
- `DATABASE_URL` quedó cargada como **secreto**, solo para *Preview*.
- **URL de la vista previa:** https://unipaz360-panel-41oqavj9y-mamalon104366s-projects.vercel.app. Está protegida con *Vercel Authentication*: sin sesión responde 302 y manda al inicio de sesión de Vercel.
- **No se despliega en producción** a propósito. En Hobby el dominio de producción queda público, y el panel aún no tiene cuentas ni roles (llegan en P2).
- **Arreglo `aa4d44c`:** la conexión a Neon se crea en la primera consulta. Antes el build fallaba sin credenciales, tanto en Vercel como en el CI. Ya está subido al PR #34.
- El equipo ya cargó datos reales desde el panel: **17 nodos y 19 tramos**, todos por verificar en campo.
- **Conexión con GitHub:** Vercel conectó el proyecto al repo. El primer despliegue desde Git falló porque compilaba desde la raíz, así que se fijó **Root Directory = `panel`**. Ahora cada push a una rama crea su vista previa protegida sola.
- **Commit `853b4b5`:** se agregó `panel/vercel.json` con `deploymentEnabled.main = false`, para que el merge a `main` **no publique** el panel en el dominio público de producción mientras no haya cuentas.

## 2026-11-04 · Plataforma P1: editor del grafo (rama `p1-plataforma-grafo`)

- Se creó `panel/` (Next.js 16, Tailwind 4, MapLibre 6 y `pg` contra Neon) con el diseño de la referencia: riel oscuro, barra lateral con secciones y contadores, y tarjetas suaves.
- Funciona el editor de **nodos y rutas** con atributos de accesibilidad, detección de islas y nodos que se arrastran. Detalle en [[Plataforma P1 - Grafo del campus]].
- Pasan `tsc`, `eslint` y `next build`, y se probó en el navegador. **Commit `fe8a258`**, subido en el [PR #34](https://github.com/mamalon104366/unipaz360/pull/34) hacia `main`.

## 2026-11-04 · Documento v2 y entorno Flutter

- Se generó el **avance documental v2**, con la plataforma de gestión, el nuevo **5.4 Marco tecnológico** y el referente del tour de Unisabana. El detalle está en [[Avance documental (oct-2026)#⭐ Versión 2 (2026-11-04): plataforma de gestión y marco tecnológico]].
- **Entorno verificado:** Flutter 3.47.7 estable, Dart 3.13.5 y `flutter doctor` sin problemas (Android SDK 36, Chrome y Visual Studio Build Tools 2022 para Windows).
- **Decisiones técnicas que salieron de verificar en pub.dev:**
  - Se mantiene el **visor 360° propio**, porque `panorama_viewer` solo soporta Android e iOS.
  - `mobile_scanner` no tiene versión para Windows, así que allí el origen se elige a mano.
  - En web se usa `sqflite_common_ffi_web`.
- **Orden acordado:** primero la **plataforma**, que genera el paquete, y después la app, que lo visualiza.

## 2026-11-04 · Visión consolidada: app + plataforma editora del tour

- Se definió qué hace la **plataforma**: nodos en el mapa, rutas entre nodos, foto 360° por nodo, edición de la imagen dentro del visor (horizonte, nadir con logo, difuminado, luz y color) y contenido encima (información, anuncios con vigencia, imagen, video, enlaces). Ver [[Visión consolidada (nov-2026)]].
- Plataformas de la app: **Android (horizontal), Windows y web** son obligatorias; **iOS y macOS** quedan como límite.
- Diagnóstico del código de `app/`: hay archivos de más de 1.000 líneas, datos simulados, una dependencia de Google Maps y webview, y falta `app/windows`. Se propuso una estructura por funciones.
- Se listaron los ajustes que necesita el `.docx` del avance documental. **Aún no se aplican.**

## 2026-11-04 · Decisión: manda el plan del vault ✅

- La arquitectura objetivo es la de [[Arquitectura general]]: panel **Next.js + MapLibre**, API en **Vercel Functions**, **Neon (PostgreSQL + PostGIS)**, **Cloudflare R2** y el monorepo `app/ panel/ datos/ scripts/ docs/`.
- El repositorio `C:\unipaz360` (Vite + Fastify + ADR 0008 sin servidor) queda como **evidencia del proceso de armado** del proyecto, no como diseño final.
- Si algo del repositorio contradice el vault, gana el vault.

## 2026-11-04 · Revisión general del repositorio

**Estado:** 3 commits en `master`, todos de la Fase 0. No hay remoto configurado.

| Pieza | Estado |
|---|---|
| Documentación (`docs/`, 13 docs + 8 ADR) | ✅ Completa |
| `packages/contracts` (Zod, 37 JSON Schema) | ✅ |
| `infra/` (docker-compose, Caddy) | ✅ |
| `apps/api` (Fastify + Drizzle/Postgres) | 🚧 Falta `src/index.ts`: no arranca |
| `apps/admin` (React + Vite + MapLibre) | 🚧 Falta `src/main.tsx` y no hay páginas |
| `apps/client` (Flutter) | ❌ Solo hay un script que revisa versiones |
| `apps/cli`, `packages/geo`, `packages/ui`, `content/` | ❌ No existen (el README sí los describe) |

**Problemas detectados**
1. La API y el admin no arrancan porque les faltan sus puntos de entrada.
2. La [[#ADR 0008]] (sin servidor) exige que las rutas pasen por la interfaz `ContentStore`. Sin embargo, 7 rutas importan Drizzle/Postgres directamente y ninguna implementación del almacén existe todavía.
3. El README y `docs/10-roadmap.md` están desactualizados (dicen "7 ADR" y marcan como pendiente lo que ya está hecho).
4. Flutter y Docker no están instalados en la máquina.

> [!warning] Divergencia con el plan del vault
> [[Arquitectura general]] y [[Datos y publicación]] describen **Next.js + Vercel Functions + Neon**, con carpetas `app/ panel/ datos/ scripts/`. El repositorio usa **Vite + Fastify + modo sin servidor (SQLite local)** con `apps/ packages/`. **Resuelto:** manda el vault (ver la entrada de arriba).

### ADR 0008
En producción no hay API ni base de datos. El editor trabaja en local (`unipaz dev`), publica *content packs* firmados (Ed25519) como estáticos en Cloudflare R2/Pages o GitHub Releases, y el cliente los descubre por un `releases.json`. El costo es de ~0 USD al mes.

Volver a [[00 Sistema - Índice]] · [[00 UniPaz360 - Índice]]
