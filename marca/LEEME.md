# Marca: logo de UNIPAZ

Aquí están los **maestros vectoriales** del logo del Instituto Universitario de la Paz. Todo lo
demás (variantes, íconos, trazos para la app) se **genera** desde aquí y no se edita a mano:

```bash
node panel/scripts/marca.mjs
```

## Archivos

| Archivo | Qué es |
| ------- | ------ |
| `logo-vertical.svg` | El logo oficial: el símbolo arriba, UNIPAZ y el nombre debajo. |
| `logo-horizontal.svg` | El mismo símbolo a la izquierda y el bloque de texto a la derecha, con las proporciones del texto intactas. Es el que usa la barra lateral de la app. |
| `isotipo.svg` | Solo el símbolo: ícono de la app, favicon, riel de íconos y parche del nadir. |
| `fuente/logo-unipaz.jpg` | La imagen de la que salieron los maestros. |
| `fuente/trazar_logo.py` | Convierte esa imagen en trazos (cobertura por tinta, marching squares y curvas de Bézier). |
| `fuente/componer_marca.py` | Arma los tres SVG a partir de los trazos. |

Los SVG tienen tres capas (`azul`, `verde` y `negro`) con relleno par-impar, y solo usan los
comandos absolutos `M`, `L`, `C` y `Z`, que es lo que entienden el script y la app.

> Si la institución entrega el logo en vector, se reemplazan estos maestros y se vuelve a correr
> el script. Nada más cambia.

## Colores

| Tinta | Color | Dónde más se usa |
| ----- | ----- | ---------------- |
| Azul | `#233671` | Color principal de la app (`marca.colorPrimario`) |
| Verde | `#0a9640` | Color de acento de la app (`marca.colorAcento`) |
| Negro | `#1d1d1b` | Solo en el texto del logo |

## Cómo se usa

- **Sobre fondo claro:** a color. La paloma es el papel: el logo a color siempre va sobre blanco
  o un fondo muy claro.
- **Sobre fondo oscuro o una foto:** en blanco. La tinta se vuelve blanca y la paloma queda del
  color del fondo, como en un logo a una tinta. Sobre una foto lleva una sombra suave.
- **Margen libre:** al menos la altura de la letra principal (la U de UNIPAZ).
- **Tamaño mínimo:** 24 px de alto en pantalla y 15 mm impreso. Por debajo de eso, solo el símbolo.
- No deformar, no cambiar los colores ni ponerlo sobre fondos con poco contraste (mínimo 3:1, WCAG 2.2).
- El nombre del producto se escribe **UniPaz360**.

## Qué genera el script

| Destino | Qué |
| ------- | --- |
| `panel/public/marca/` | Los tres logos, a color y en blanco. |
| `panel/src/app/` | `icon.svg`, `favicon.ico` y `apple-icon.png`. |
| `panel/src/lib/marca.generado.ts` | El tamaño de cada logo y el parche del nadir. |
| `app/lib/core/marca/logo_unipaz_trazos.dart` | Los trazos con los que la app dibuja el logo (`LogoUnipaz`), sin imágenes. |
| `app/android/app/src/main/res/` | Ícono adaptativo vectorial con versión monocroma (Android 13+) y PNG de respaldo. |
| `app/web/` | Favicon e íconos del manifiesto, normales y *maskable*. |
| `app/windows/runner/resources/app_icon.ico` | De 16 a 256 px. |

## Cuándo llega cada cambio

- **Panel:** al desplegar.
- **Dentro de la app y sus íconos:** con la siguiente versión de la app, porque van compilados.
- **Parche del nadir:** solo en las fotos que se vuelvan a procesar (guardar de nuevo sus ajustes).
