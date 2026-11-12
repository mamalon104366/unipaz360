# Apariencia y contenido de la app

El apartado **Cliente** del panel edita cómo se ve la app del visitante: colores,
barra lateral con el logo, minimapa y **las páginas de cada sección**. Todo se
guarda en un solo objeto JSON que viaja en el paquete, en la tabla
`configuracion_app` (clave `'app'`). La app Flutter lo aplica tal cual, así que lo
que se ve en la vista previa del panel es lo que verá el visitante.

Tipos y validación: `panel/src/lib/configApp.ts` (`normalizarConfig`). El panel
nunca guarda algo que la app no entienda: lo inválido vuelve al valor por defecto.

## Medidas de la pantalla

Todo lo superpuesto al recorrido se mide en **dp** (píxeles lógicos de Flutter) y
se multiplica por `interfaz.escala` (0.7 a 1.5).

| Pieza | Regla |
| ----- | ----- |
| Margen general | 12 dp por cada lado. |
| Barra lateral | De arriba abajo, pegada al borde, sin esquinas y con una línea solo del lado de la foto. Ancho `barraLateral.ancho` % de la pantalla, nunca menos de 210 dp ni más del 45 %. |
| Logo | Horizontal, en la esquina superior de la barra. Ancho hasta 200 dp (150 en celular), sin pasarse del ancho de la barra. Ver «El logo». |
| Secciones | Ícono de 16 dp y título (0.8 em, peso 500; la abierta, 700), con una línea entre filas. La abierta lleva fondo tenue y una barrita de 3 dp del color de acento en el borde. |
| Pie de la barra | `marca.nombre` en mayúsculas (0.7 em, peso 700) y `marca.subtitulo` (0.62 em, hasta 2 líneas; en celular, 1). |
| Botón de plegar | Redondo y blanco, de 34 dp, a media altura y montado sobre el borde de la barra. Con la barra oculta, a 12 dp del borde de la pantalla. Solo si `barraLateral.plegable`. |
| Riel de íconos | 56 dp de ancho, con el símbolo arriba. Se usa con una página abierta: en celular siempre (así la página tiene más espacio) y en escritorio si se pliega la barra. |
| Botones de arriba | Redondos, de 40 dp, a 12 dp de la esquina superior del lado contrario a la barra y con 8 dp entre ellos: en la esquina el de cuenta, luego el de «Tu experiencia» (controles deslizantes) y, hacia el centro, el del asistente. Se ocultan con una página abierta o el mapa maximizado. |
| Minimapa normal | Ancho `minimapa.tamano` % de la pantalla (nunca menos de 112 dp, para que quepan su rótulo y sus botones), proporción 4:3, en la esquina `minimapa.posicion`. Arriba a la derecha baja para no tapar los botones de arriba. |
| Minimapa minimizado | Botón redondo de 46 dp con el ícono de mapa. |
| Minimapa maximizado | Ocupa el área libre (al lado de la barra) con 12 dp de margen; muestra la foto completa y los nombres. |
| Botón de inicio | Redondo, de 46 dp y del color principal, con una casa: igual al minimapa minimizado. Va abajo, a 12 dp del borde y a 8 dp del minimapa, del lado del centro de la pantalla. Con el minimapa arriba (o sin minimapa) queda en la esquina de abajo de ese lado. Su nombre (`inicio.textoBoton`) se lee al dejar el dedo o el mouse encima. Se oculta con una página abierta o el mapa maximizado. |

**Plegar la barra:** sin una página abierta, la barra se corre fuera de la pantalla en 280 ms
(`easeOutCubic`) y quedan el logo y el botón para abrirla. El minimapa y lo demás usan el espacio.
Si `barraLateral.plegable` es falso, la barra nunca se esconde, aunque `iniciaPlegada` esté activo:
el visitante no tendría cómo abrirla.

**En celular** (lado corto de menos de 600 dp) la pantalla es baja: filas de 8 dp de relleno
vertical en vez de 11, relleno superior de 14 en vez de 20, y menos espacio junto al logo y al pie.
Así caben las seis secciones aun en un celular de 360 dp de alto.

### El logo

El logo de UNIPAZ viene dentro de la app y del panel, en vector (ver `marca/LEEME.md`): no se sube
ni viaja en el paquete. `barraLateral.mostrarLogo` lo muestra u oculta.

| Dónde | Versión |
| ----- | ------- |
| Barra de vidrio u oscura | Horizontal, en blanco. |
| Barra clara | Horizontal, a color. |
| Barra oculta, sobre la foto | Horizontal, en blanco y con sombra (`0 1px 6px`, negro al 65 %), siempre. Se queda en el mismo lugar. |
| Riel de íconos | Solo el símbolo, de 30 dp: en blanco, o a color sobre un riel claro. |

### Superficies

`barraLateral.estilo` da la superficie de la barra y del botón de cuenta.

| Estilo | Fondo | Línea |
| ------ | ----- | ----- |
| `vidrio` | Negro al 55 % con desenfoque de 12 px detrás. Antes era 35 %, pero el texto blanco no se leía sobre paredes y cielos claros. | Blanco al 20 % |
| `oscuro` | `#1c1c1f` al 92 % | Ninguna |
| `claro` | Blanco al 95 % | Negro al 10 % |

## Secciones

`barraLateral.secciones[]`: `id`, `titulo`, `icono`, `visible`, `tipo`.

| `tipo` | Al tocarla |
| ------ | ---------- |
| `pagina` | Abre su página (ver abajo), en el panel que va del borde de la barra al borde derecho. |
| `recorrido` | Cierra la página abierta y deja el recorrido 360°. |

El tipo `rutas` (la sección «Cómo llegar», con su botón redondo de buscar) **ya no existe**: guiar
hasta un lugar es trabajo del asistente. Una configuración que todavía traiga secciones de ese tipo
las pierde al normalizarse, en el panel y en la app.

Íconos: `info`, `video`, `escuela`, `orbita`, `mapa`, `ruta`, `calendario`, `estrella`.

## Páginas: un lienzo libre, como en Figma

`paginas[idSeccion].pestanas[]`. Cada pestaña es un lienzo de **1000 unidades de
ancho** (`ANCHO_PAGINA`) y `alto` unidades de alto, con color de `fondo`.

**Regla de escala:** `k = ancho real del panel / 1000`. La app multiplica por `k`
posiciones, tamaños, tamaños de letra, radios y grosores, y pone el lienzo dentro
de un desplazamiento vertical. Como todo escala igual, los saltos de línea son los
mismos en el celular, en Windows y en la web.

Encabezado del panel: barra de 4 × 56 dp en el color principal, título en
mayúsculas (21 dp, extra negrita) y botón de cerrar de 40 × 36 dp. Con 2 o más
pestañas aparece la fila de pestañas (44 dp, títulos de 11 dp en mayúsculas,
subrayado de 3 dp en la activa); con una sola, no.

### Elementos (`elementos[]`, el último se dibuja encima)

Campos comunes: `id`, `tipo`, `nombre`, `x`, `y`, `ancho`, `alto` (unidades de
diseño), `rotacion` (grados, alrededor del centro), `opacidad` (0–1),
`bloqueado` (solo para el editor), `oculto` (no se dibuja) y `audiencia` (`todos` o `institucional`,
ver «Quién lo ve»).

| `tipo` | Campos propios |
| ------ | -------------- |
| `texto` | `texto`, `fuente` (`sans` = Roboto, `serif` = Noto Serif), `tamano`, `peso` (400–800), `cursiva`, `mayusculas`, `color`, `alineacion` (`izquierda`, `centro`, `derecha`), `interlineado`. |
| `boton` | Los de texto, más `relleno`, `radio`, `borde`, `grosorBorde`, `sombra`, `enlace`. Texto centrado verticalmente, relleno lateral 14·k. |
| `imagen` | `src`, `ajuste` (`cubrir` recorta / `contener` completa), `radio`, `borde`, `grosorBorde`, `sombra`, `enlace`. |
| `video` | `src`, `ajuste`, `radio`, `automatico` (reproduce solo y sin sonido). Con controles. |
| `forma` | `figura` (`rectangulo`, `elipse`, `linea`), `relleno`, `radio`, `borde`, `grosorBorde`, `sombra`, `enlace`. La línea es horizontal, centrada en la caja, de grosor `grosorBorde` y color `borde`. |
| `mapa` | `lat`, `lon`, `zoomMapa`, `radio`, `src`. Con internet: Google Maps (`https://www.google.com/maps?q=lat,lon&z=zoom&output=embed&hl=es`); sin conexión: la imagen `src`. |

- **Colores**: `#rrggbb`. En `relleno` y `borde`, la cadena vacía significa "sin color".
- **Sombra**: en CSS `0 8k 24k −10k` negro al 25 %. En Flutter el desenfoque no es el mismo número: CSS usa
  sigma = desenfoque / 2 y Flutter sigma = blurRadius · 0.57735 + 0.5, así que la app lo convierte
  (`desenfoqueCss()` en `app/lib/features/visor360/animacion_punto.dart`). Vale para todas las sombras.
- **Recursos (`src`)**: `app://imagenes/<archivo>` y `app://videos/<archivo>` vienen
  dentro de la app (`app/assets/imagenes`, `app/assets/videos`); lo demás es `https://`
  (medios subidos a R2, que el paquete lista en `medio` para descargarlos y verlos sin conexión).
- **Enlaces (`enlace`)**: `''` (nada), `https://…` (abre el navegador), `seccion:<id>`
  (abre esa sección) o `panoramica:<id>` (cierra la página y va a esa foto 360°).

El contenido inicial de las páginas es el que ya tenía la app (Nosotros, Video
institucional, Admisiones y Ubicación): `panel/src/lib/paginasIniciales.ts`.

## Quién lo ve: todos o solo con la cuenta institucional

Cada elemento de las páginas (`audiencia`) y cada punto de las fotos 360°
(`punto_informacion.audiencia`) dice quién lo ve en la app:

| Valor | En la app |
| ----- | --------- |
| `todos` (por defecto) | Lo ven todos, también los invitados. |
| `institucional` | Solo quien entró con su correo `@unipaz.edu.co`. A los invitados no se les dibuja. |

Lo que no se reconoce es `todos`. Las reglas están en `panel/src/lib/audiencia.ts` y, en la app, en
`visibleEnApp()` (`lienzo_pagina.dart`) y `PuntoPanoramica.visiblePara()` (`recorrido.dart`).

- **En el panel**: el control «Quién lo ve en la app» está en las propiedades de cada elemento y en
  el formulario de cada punto. Los institucionales llevan un birrete en el lienzo, en la lista de capas
  y en la lista de puntos.
- **Vista previa**: el selector «Ver como» (Invitado o Cuenta institucional) muestra lo que ve cada
  quien. Al editar, lo institucional se atenúa en vez de esconderse, para poder seleccionarlo.
- **Botón de cuenta**: redondo, de 40 dp, en la esquina superior del lado contrario a la barra.
  En la app abre la cuenta (entrar con Google o salir); con la cuenta institucional muestra un
  birrete. Se oculta con una página abierta o el mapa maximizado.

### La app abre sin pedir cuenta

No hay pantalla de ingreso: la app abre directo en el recorrido y quien no entra es invitado. La
cuenta institucional es opcional y se abre con el botón de cuenta:

1. La app inventa un secreto, calcula su SHA-256 (el «reto») y abre en el navegador
   `<plataforma>/api/sesion/google?app=<reto>`.
2. La persona entra con Google. La plataforma solo acepta cuentas verificadas `@unipaz.edu.co`
   y deja el ingreso confirmado para ese reto. No se abre sesión en la plataforma.
3. La app pregunta cada 2,5 s con el secreto (`POST /api/app/ingreso`) y recibe el correo, el
   nombre y una **ficha**, una sola vez. Un ingreso sin terminar vence a los 15 minutos.
4. Con la ficha, la app avisa cada vez que se abre (`POST /api/app/uso`): así se cuentan las
   aperturas (como mucho una por minuto y por dispositivo). Al cerrar sesión la ficha se anula
   (`POST /api/app/salir`).

El secreto y la ficha solo viven en el dispositivo; la base guarda sus SHA-256 (tablas
`usuario_app` y `sesion_app`, migración `0006`). Las rutas `/api/app/*` no usan cookies y
aceptan cualquier origen (la web de la app está en otro dominio). Quién entró y cuántas veces
abrió la app lo ve el superadministrador en **Ajustes → Usuarios de la app** (con exportación a
CSV). Quien usa la app sin cuenta no deja ningún registro.

Código: `panel/src/lib/usuariosApp.ts`, `app/lib/data/cuenta_servicio.dart` y
`app/lib/ui/sesion/`. La dirección de la plataforma se puede cambiar al compilar la app con
`--dart-define=PANEL_URL=https://…`.

### La bienvenida

Al abrir, la app muestra una bienvenida animada (`bienvenida_cliente.dart`): el logo entra
dentro de una órbita con un punto que la recorre, `inicio.bienvenida` sube y la foto queda
detrás, desenfocada.

- **Celular de pie** (lado corto menor de 600 dp y más alto que ancho): se queda hasta que la
  persona elige. «Girar la pantalla» deja la app en horizontal aunque el giro automático esté
  apagado, y así se recuerda (Android y iPhone; en la web solo se invita). «Seguir en vertical»
  entra en el modo vertical. Si la persona gira el celular, deja de pedirlo.
- **Lo demás** (horizontal, tableta, escritorio): se va sola a los 3,2 s, o al tocar.

La app **no fuerza la orientación**: la decide la persona. En el celular ocupa toda la pantalla
(la barra de estado y los botones del sistema se recogen y vuelven al deslizar desde el borde).

### Modo vertical (celular de pie)

En un celular de pie no hay barra lateral (`vertical_cliente.dart`):

| Pieza | Cómo es |
| ----- | ------- |
| Logo | Arriba a la izquierda, en blanco y con sombra, de 150 dp. |
| Botones redondos | En columna, arriba a la derecha: asistente, cuenta y «Tu experiencia». |
| Barra de abajo | Flotante y centrada, de 58 dp de alto, a 14 dp del borde, con la superficie de `barraLateral.estilo`: **Menú**, **Inicio** y **Mapa**. El que está abierto se pinta del color principal y muestra su nombre. |
| Menú | Una hoja que sube desde abajo con el nombre de la app y las secciones visibles. Tocar afuera la cierra. |
| Página | Ocupa toda la pantalla. |
| Mapa | Solo abierto (a lo ancho, entre el logo y la barra de abajo) o guardado en la barra. |
| Chat | Ocupa la pantalla con 12 dp de margen. |

Una tableta de pie usa el diseño de siempre. La vista previa de la plataforma muestra el
horizontal; el modo vertical se arma solo con la misma configuración.

### Tu experiencia (preferencias de cada persona)

El botón de los controles deslizantes abre «Tu experiencia» (`ajustes_cliente.dart`). Lo que
ahí se elige vale solo para esa persona y se guarda en su dispositivo (`localStorage` en la
web, preferencias nativas en Android y Windows; clave `unipaz360.preferencias`). No viaja a la
plataforma. Mientras no cambie algo, vale lo que dice la configuración publicada.

| Preferencia | Qué cambia |
| ----------- | ---------- |
| Aspecto | `vidrio`, `oscuro` o `claro`: reemplaza `barraLateral.estilo`. |
| Animación de bienvenida | Verla o no al abrir. |
| Minimapa a la vista | Abrir con el minimapa normal o recogido en su botón. |
| Menú lateral a la vista | Abrir con la barra lateral desplegada o plegada. |
| Atenuar los botones | Reemplaza `interfaz.atenuar` y `interfaz.atenuarOpacidad` (los segundos los pone la plataforma). |
| Pantalla | Automática, horizontal o vertical (solo en celulares y tabletas). |

«Volver a como viene la app» borra todo lo guardado. Código: `domain/preferencias.dart`,
`data/preferencias_repositorio.dart` y `ui/preferencias/`.

### La web siempre muestra lo último publicado

Android y Windows arrancan con la semilla y ofrecen las versiones nuevas (`actualizador.dart`).
La **web** está siempre en internet, así que cada vez que se abre lee el puntero
`version.json` de la plataforma, baja el manifiesto y `datos.sqlite` de esa versión
(comprobando sus huellas y que vengan del almacenamiento de la plataforma) y abre con eso: no
hay que volver a subir la página para ver un cambio. Las fotos y los videos del recorrido no
vienen en la página: se piden por su dirección cuando hacen falta.

Si la plataforma no contesta, o lo que llega no pasa las comprobaciones, la web abre con la base
de respaldo que trae (`PaqueteLocal.cargar`, `paquete_local.dart`).

Para publicar la web, desde `app/`: `flutter build web --release` y después
`node tool/web_ligera.mjs`, que quita de `build/web` los medios de la semilla y avisa si la
página pasa de 100 MB.

### Botones que se atenúan (`interfaz.atenuar*`)

| Campo | Qué es |
| ----- | ------ |
| `atenuar` | Si se atenúan. Por defecto, sí. |
| `atenuarTras` | Segundos sin tocar ningún botón (2 a 60, entero). Por defecto 5. |
| `atenuarOpacidad` | Con qué opacidad quedan (0.2 a 0.9). Por defecto 0.5. |

Se atenúan el botón de plegar, los de arriba, el de inicio y el minimapa (no la barra ni el logo).
Mover la foto no cuenta como usar un botón; tocar cualquier otra cosa los devuelve completos y la
cuenta empieza de nuevo. Con el mouse basta pasar por encima. Con una página, el chat, una ficha o
el mapa maximizado abiertos no se atenúan. Se ajusta en la capa «Marca y colores»; después cada
persona lo puede cambiar para sí misma en «Tu experiencia».

> [!WARNING]
> **No es secreto.** El contenido institucional viaja en el paquete de datos, que se descarga sin
> iniciar sesión: la app solo lo oculta a los invitados. Sirve para ordenar lo que ve cada quien, no
> para información confidencial. Además, mientras no esté el ingreso con Google, la app acepta la
> entrada temporal con un correo `@unipaz.edu.co` sin verificarlo.

**Compatibilidad**: la columna es aditiva (no sube el esquema). La app la lee solo si el paquete la
trae. Una app anterior a este cambio que reciba un paquete nuevo mostraría todo a todos: hoy no hay
apps publicadas, pero si se publica una antes, hay que subir `app_minima`.

## Minimapa

| Campo | Qué hace |
| ----- | -------- |
| `imagen` | `app://imagenes/mapa-dron.jpg` (viene en la app) o una URL `https://`. |
| `nodos[]` | `{ vertice_id, x, y }`: posición del nodo **de 0 a 1 sobre la imagen** (0,0 = arriba a la izquierda), igual que en `puntos-mapa.md`. |
| `zoom`, `rotacion`, `desplazamientoX/Y`, `opacidad` | Encuadre del estado normal: la lámina (imagen + nodos) se escala, se gira y se traslada en % de su tamaño. |
| `centrarEnActual` | En estado normal, el encuadre se traslada para dejar en el centro el nodo donde está el visitante (con `zoom` > 1). |
| `estadoInicial` | `minimizado`, `normal` o `maximizado` al abrir la app. |
| `permitirMinimizar`, `permitirMaximizar` | Botones que ve el visitante. |
| `mostrarNombres` | Nombres también en estado normal (al maximizar siempre se ven). |

Dibujo de los nodos: el nodo actual en el color de acento (14 dp, con una onda),
los que tienen foto 360° en el color principal (10 dp) y los demás en gris
(7 dp, no se pueden tocar). Tocar un nodo con foto lleva a su panorámica; desde el
estado maximizado, además, vuelve al estado normal. Los marcadores no se giran ni
se agrandan con el encuadre (se dibujan con la rotación y la escala inversas).

En el panel, **Ubicar nodos en el mapa** permite arrastrarlos sobre la foto. Con 3
o más ubicados, el resto se calcula con un ajuste afín por mínimos cuadrados de
(lat, lon) a (x, y).

## Cómo lo hace la app Flutter

La vista del visitante está en `app/lib/features/cliente/` (`vista_cliente.dart` arma todo) y el
recorrido en `app/lib/features/visor360/`.

- **Normalización**: `app/lib/core/modelo/normalizar_config.dart` aplica las mismas reglas que
  `normalizarConfig`. La prueba `app/test/cliente/normalizar_config_test.dart` compara su resultado con
  casos que se generan corriendo el código del panel:
  `node --conditions=react-server --experimental-transform-types panel/scripts/config-app-flutter.mjs`.
  El mismo script escribe `app/assets/config/por_defecto.json` (la configuración por defecto con las
  páginas iniciales), que la app usa si un paquete no trae apariencia.
- **Fuentes**: Roboto y Noto Serif (normal e itálica) variables, recortadas al alfabeto latino de Google
  Fonts, en `app/assets/fuentes/` con sus licencias OFL. Cada peso apunta al mismo archivo y el grosor
  real lo pone el eje `wght`, así Flutter no inventa negritas. Roboto no trae itálica: igual que el
  navegador, la cursiva se inclina sola.
- **Interfaz de la vista previa**: la barra y la ficha también usan Roboto en el panel, para que se vean
  como en la app.
- **Logo**: `app/lib/core/marca/logo_unipaz.dart` lo dibuja con sus trazos (`Canvas.drawPath`, par-impar), sin
  imágenes ni paquetes, así se ve nítido a cualquier tamaño. En el panel son los SVG de `panel/public/marca/`.
- **Celular**: la app se considera celular cuando el lado corto de la pantalla mide menos de 600 dp.
- **Tamaño del texto**: la vista no sigue el tamaño de letra del sistema (el lienzo es fijo y se rompería);
  el tamaño lo da `interfaz.escala`.
- **Lo que solo es del editor** no aparece en la app: los contornos de selección y el aviso «Ubica los
  nodos…» del minimapa sin nodos.
- **Botón de inicio**: vuelve a la primera panorámica (o al encuadre inicial si ya está en ella).
- **Atrás (Android)**: cierra primero la bienvenida, el menú, el chat, la ficha, la página o el mapa maximizado.

## Asistente (`asistente`)

El chat que guía hasta un lugar, sin internet. Capa «Asistente» del apartado Cliente.

| Campo | Qué es |
| ----- | ------ |
| `visible` | Si se muestra el botón redondo del asistente (junto a los de cuenta y «Tu experiencia»). Por defecto, sí. |
| `nombre` | Cómo se llama (hasta 24 letras). Por defecto «Paz». |
| `saludo` | El primer mensaje (hasta 200 letras). Vacío: el saludo de siempre, con el nombre. |
| `sinonimos` | Hasta 60 pares `{ palabra, significa }`, una palabra en cada lado y sin repetir `palabra`: «biblio» significa «biblioteca». Se suman a los que la app ya trae. |
| `respuestas` | Hasta 30 pares `{ pregunta, respuesta }`. Si lo que escribe la persona trae todas las palabras clave de `pregunta`, el asistente contesta `respuesta`; entre varias gana la de más palabras. |

La app compara sin tildes ni mayúsculas. Lo que no está escrito no se inventa: responde que no
entendió y ofrece lo que sí sabe hacer. Código: `panel/src/lib/configApp.ts`
(`normalizarAsistente`), `app/lib/core/modelo/normalizar_config.dart` y
`app/lib/features/asistente/`.
