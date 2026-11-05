# Apariencia y contenido de la app

El apartado **Cliente** del panel edita cómo se ve la app del visitante: colores,
encabezado, barra lateral, minimapa y **las páginas de cada sección**. Todo se
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
| Encabezado | Alto `encabezado.alto`, arriba, de lado a lado; esquinas de 16 dp. |
| Barra lateral | Debajo del encabezado hasta 12 dp del borde inferior; ancho `barraLateral.ancho` % de la pantalla. |
| Riel de íconos | 56 dp de ancho. Se usa cuando la barra está plegada y, **en celular, siempre que hay una página abierta** (así la página tiene más espacio). |
| Minimapa normal | Ancho `minimapa.tamano` % de la pantalla, proporción 4:3, en la esquina `minimapa.posicion`. |
| Minimapa minimizado | Botón redondo de 46 dp con el ícono de mapa. |
| Minimapa maximizado | Ocupa el área libre (al lado de la barra) con 12 dp de margen; muestra la foto completa y los nombres. |
| Botón de inicio | Abajo al centro, a 14 dp del borde. |

Con una página abierta el encabezado se oculta y la barra (o el riel) sube hasta arriba.

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
- **Sombra**: `BoxShadow(offset: (0, 8k), blurRadius: 24k, spreadRadius: −10k, color: negro 25 %)`.
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
