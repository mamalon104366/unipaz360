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
| Botón de buscar | Redondo, de 40 dp, a 12 dp de la esquina superior del lado contrario a la barra. Abre la sección de tipo `rutas`; si no hay una visible, no aparece. Se oculta con una página abierta o el mapa maximizado. |
| Minimapa normal | Ancho `minimapa.tamano` % de la pantalla, proporción 4:3, en la esquina `minimapa.posicion`. Arriba a la derecha baja para no tapar el botón de buscar. |
| Minimapa minimizado | Botón redondo de 46 dp con el ícono de mapa. |
| Minimapa maximizado | Ocupa el área libre (al lado de la barra) con 12 dp de margen; muestra la foto completa y los nombres. |
| Botón de inicio | Abajo al centro de la pantalla, a 14 dp del borde. |

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

`barraLateral.estilo` da la superficie de la barra y del botón de buscar.

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
| `rutas` | Abre el buscador de rutas de la app (sale del mapa y de los espacios; no se edita aquí). |

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
`bloqueado` (solo para el editor) y `oculto` (no se dibuja).

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
- **Sección `rutas`**: en la vista previa es un ejemplo; en la app funciona de verdad y sin internet
  (busca entre los espacios y los nodos con nombre del paquete y arma la ruta con el motor de rutas).
- **Botón de inicio**: vuelve a la primera panorámica (o al encuadre inicial si ya está en ella).
- **Atrás (Android)**: cierra primero la ficha, la página o el mapa maximizado.
