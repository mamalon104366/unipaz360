---
tags: [unipaz360, sistema, marca, logo]
fecha: 2026-11-05
estado: integrado
---
# Marca y logo

> [!success] Estado (5 de noviembre de 2026, commit `77470af`)
> El logo de UNIPAZ ya está en la app y en el panel. Llegó como una imagen (JPG de 1042 px y un PNG del símbolo), así que se pasó a vector para que se vea nítido en cualquier tamaño y en todos los íconos.
>
> Si la institución entrega el logo en vector, se reemplazan los maestros y se corre el script: nada más cambia.

---

## 1. Un solo lugar para los archivos maestros

Carpeta `marca/` en la raíz del repositorio (rama `plataforma`). Todo lo demás se **genera** desde aquí, nunca se edita a mano.

```
marca/
├── logo-vertical.svg      ← el logo oficial: símbolo arriba, nombre debajo
├── logo-horizontal.svg    ← derivado: símbolo a la izquierda y el mismo bloque de texto a la derecha
├── isotipo.svg            ← solo el símbolo
├── LEEME.md               ← colores, reglas de uso y qué genera el script
└── fuente/                ← la imagen original y los scripts que la vectorizaron
```

> [!note] Cómo se vectorizó
> `fuente/trazar_logo.py` calcula la cobertura de cada tinta (azul, verde y negro) con la luminancia del JPG, saca el contorno con *marching squares*, afila las esquinas y ajusta curvas de Bézier. Los bordes rectos del rombo quedaron como rectas exactas. Se comparó con el original a 4× de aumento.

---

## 2. Colores de la marca

Se midieron en el logo y reemplazaron a los provisionales (`#163E78` y `#179B55`).

| Uso | Color | Dónde está |
|---|---|---|
| Principal (azul del logo) | `#233671` | `configuracion_app.marca.colorPrimario` |
| Acento (verde del logo) | `#0A9640` | `configuracion_app.marca.colorAcento` |
| Texto del logo | `#1D1D1B` | Solo en el logo |

Los colores se pueden cambiar en el apartado Cliente (Marca y colores) y **llegan a las apps con el paquete**, sin una versión nueva.

---

## 3. Cómo se usa

- **A color:** solo sobre blanco o un fondo muy claro. La paloma es el papel.
- **En blanco:** sobre fondos oscuros y fotos. La tinta se vuelve blanca y la paloma queda del color del fondo. Sobre una foto lleva una sombra suave.
- **Margen libre:** al menos la altura de la U de UNIPAZ.
- **Tamaño mínimo:** 24 px de alto en pantalla y 15 mm impreso. Por debajo, solo el símbolo.
- No deformar, no cambiar los colores y no ponerlo sobre fondos con poco contraste (mínimo 3:1, WCAG 2.2).
- El nombre del producto se escribe **UniPaz360**.

---

## 4. Dónde va y cómo se actualiza

| Lugar | Qué se puso | ¿Versión nueva de la app? |
|---|---|---|
| Barra lateral de la app | Logo horizontal dibujado con sus trazos (`app/lib/core/marca/logo_unipaz.dart`), en blanco o a color según la barra. Plegada, queda sobre la foto con sombra. En el riel, solo el símbolo | **Sí** |
| Pantalla de ingreso de la app | Logo horizontal en blanco | **Sí** |
| Ícono de Android | Adaptativo y vectorial, con versión monocroma (Android 13+) y PNG de respaldo | **Sí** |
| Pantalla de arranque de Android | El símbolo sobre blanco (hasta Android 11). Desde Android 12 el sistema usa el ícono adaptativo | **Sí** |
| Ícono de Windows | `app_icon.ico` de 16 a 256 px | **Sí** |
| Web | Favicon e íconos del manifiesto (normales y *maskable*) | Despliegue de la web |
| Vista previa del Cliente | Los SVG de `panel/public/marca/` | No |
| Panel | Favicon, entrada y riel | No (despliegue del panel) |
| Placas QR impresas | El símbolo a color | No |
| Parche del suelo en las fotos 360° | El símbolo en blanco sobre un disco oscuro | No, pero solo cambia en las fotos que se vuelvan a procesar (guardar de nuevo sus ajustes) |

> [!tip] Cambio respecto al plan inicial
> El plan era un campo `configuracion_app.marca.logo` para cambiar el logo por el paquete. Como es el logo de la institución y cambia muy rara vez, va **dentro de la app, en vector**: se ve nítido, funciona sin red desde el primer arranque y se pinta en blanco o a color según el fondo. `barraLateral.mostrarLogo` permite ocultarlo.

---

## 5. Un comando para generar todo

```bash
node panel/scripts/marca.mjs
```

Lee `marca/*.svg` y, con `sharp`, genera todo lo de la tabla anterior. Lista completa en `marca/LEEME.md`.

---

## 6. Lo que falta

- [ ] **Aprobar con el equipo el logo horizontal.** Es un derivado: se armó con las piezas del logo oficial, con el texto intacto.
- [ ] **Pedir el vector oficial a la institución** y reemplazar los maestros, si lo tienen.
- [ ] **Regenerar las fotos 360° que ya tenían parche** en el nadir, para que tomen el símbolo nuevo.
- [ ] **Promover el panel a producción** para ver el favicon, la entrada y la vista previa nuevos.
- [ ] Íconos de iOS y macOS y mosaicos del MSIX: cuando se empaquete cada plataforma (fase D).

Relacionado: [[Flujo de actualización (plataforma → apps)]] · [[Plan de trabajo - actualizaciones]] · [[Cliente Flutter]] · [[Plataforma de administración]] · [[Guía de pruebas - app igual a la plataforma]]

Volver a [[00 Sistema - Índice]] · [[00 UniPaz360 - Índice]]
