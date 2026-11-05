---
tags: [unipaz360, sistema, marca, logo]
fecha: 2026-11-05
estado: esperando el logo definitivo
---
# Marca y logo

> [!info] Estado
> Estructura lista para cuando llegue el logo de UniPaz360. **Todavía no se ha cambiado nada**:
> - En el panel, el parche del suelo de las fotos 360° usa un logo provisional (`panel/src/lib/imagen.ts`).
> - En la app, el encabezado muestra las iniciales «UN».
> - Los íconos de Android, la web y el panel son los que traen Flutter y Next.js por defecto.

---

## 1. Un solo lugar para los archivos maestros

Carpeta `marca/` en la raíz del repositorio. Todo lo demás se **genera** desde aquí, nunca se edita a mano.

```
marca/
├── logo.svg            ← maestro vectorial a color (horizontal, con el nombre)
├── logo-blanco.svg     ← para fondos oscuros
├── logo-negro.svg      ← para impresión a una tinta
├── isotipo.svg         ← solo el símbolo: ícono de la app y favicon
├── isotipo-fondo.svg   ← el símbolo sobre su color (para íconos sin transparencia)
├── nadir.svg           ← versión circular para tapar el trípode en las fotos 360°
└── LEEME.md            ← colores, márgenes, tamaños mínimos y usos
```

> [!warning] Requisitos del maestro
> - **SVG** con `viewBox`, los textos convertidos a trazos, sin imágenes incrustadas y con el fondo transparente.
> - Si solo hay PNG: mínimo 2048 × 2048 px, con transparencia.

---

## 2. Colores de la marca

| Uso | Color | Dónde está hoy |
|---|---|---|
| Principal (azul UNIPAZ) | `#163E78` | Por defecto en `configuracion_app.marca.colorPrimario` |
| Acento (verde UNIPAZ) | `#179B55` | Por defecto en `configuracion_app.marca.colorAcento` |
| Texto secundario | `#526071` | Páginas iniciales del apartado Cliente |

Si el logo trae otros tonos, se ajustan aquí y en el apartado Cliente (Marca y colores): eso **llega a las apps con el paquete**, sin una versión nueva.

---

## 3. Dónde va y cómo se actualiza

| Lugar | Archivo y tamaño | Cómo se genera | ¿Versión nueva de la app? |
|---|---|---|---|
| Ícono de Android | Adaptativo: primer plano de 432 × 432 px con zona segura del 66 %, fondo de color y versión monocroma (Android 13+) | `flutter_launcher_icons` desde `isotipo.svg` | **Sí** |
| Ícono de iOS | 1024 × 1024 px, sin transparencia | `flutter_launcher_icons` | **Sí** |
| Ícono de macOS | `.icns` | `flutter_launcher_icons` | **Sí** |
| Ícono de Windows | `app_icon.ico` (16 a 256 px) y mosaicos del MSIX | Script + paquete `msix` | **Sí** |
| Web | Favicon de 16 y 32 px, íconos de 192 y 512 px (también *maskable*) y `apple-touch-icon` de 180 px | Script | Despliegue de la web |
| Pantalla de arranque | Logo centrado sobre el azul. En Android 12+: ícono de 288 dp con círculo seguro de 192 dp | `flutter_native_splash` | **Sí** |
| Logo dentro de la app (encabezado y páginas) | PNG o SVG | **Por el paquete**: campo nuevo `configuracion_app.marca.logo` (`app://imagenes/logo.png` o https) | **No** |
| Panel (favicon, riel, ingreso) | SVG y PNG | Copia en `panel/public/marca/` | No (despliegue del panel) |
| Parche del suelo en las fotos 360° | `nadir.svg` (circular) | El panel lo usa al generar las versiones de cada foto | No, pero hay que **regenerar** las fotos ya editadas (guardar de nuevo sus ajustes) |
| Placas QR impresas | SVG | Hoja imprimible del panel | No |
| Documento de grado y presentaciones | PNG y SVG | — | — |

> [!tip] Lo que se puede cambiar sin tiendas
> El logo **dentro** de la app y los colores van en el paquete: se publican desde la plataforma y llegan con el aviso de siempre.
> El **ícono** y la pantalla de arranque están dentro del instalador: cambian con la siguiente versión de la app. Ver [[Flujo de actualización (plataforma → apps)]].

---

## 4. Un comando para generar todo (por hacer)

`node scripts/marca.mjs` leerá `marca/*.svg` y, con `sharp`, generará:

- `app/assets/marca/` (logo para la app y para la semilla del paquete);
- `app/web/icons/*` y `app/web/favicon.png`;
- `panel/public/marca/*` y `panel/src/app/favicon.ico`;
- el parche del nadir que usa el panel.

Después:

```bash
dart run flutter_launcher_icons
```

```bash
dart run flutter_native_splash:create
```

Esos dos comandos hacen los íconos y la pantalla de arranque de cada plataforma, con la configuración guardada en `app/pubspec.yaml`.

---

## 5. Reglas de uso

- **Margen libre** alrededor del logo: al menos la altura de la letra principal.
- **Tamaño mínimo:** 24 px de alto en pantalla y 15 mm impreso.
- No deformar, no cambiar los colores y no ponerlo sobre fondos que bajen el contraste (mínimo 3:1, WCAG 2.2).
- El nombre se escribe **UniPaz360**. Hoy dicen `unipaz360` el `android:label` de Android y el `manifest.json` de la web: se corrigen junto con el logo.

---

## 6. Checklist cuando llegue el logo

1. Guardar el maestro en `marca/` y revisar que el SVG esté limpio (viewBox, trazos y transparencia).
2. Sacar las variantes (blanco, negro, isotipo y circular para el nadir) y aprobarlas con el equipo.
3. Crear y correr `scripts/marca.mjs`.
4. **Panel:** favicon, riel, ingreso y parche del nadir → desplegar → regenerar las fotos 360° que ya tenían parche.
5. **Apariencia:** subir el logo y ponerlo en `configuracion_app.marca.logo` → publicar. Llega a las apps **sin** versión nueva.
6. **App:** íconos y pantalla de arranque de cada plataforma → salen con la siguiente versión de la app.
7. Corregir el nombre visible (**UniPaz360**) en Android, web, Windows y las tiendas.

Relacionado: [[Flujo de actualización (plataforma → apps)]] · [[Plan de trabajo - actualizaciones]] · [[Cliente Flutter]] · [[Plataforma de administración]]

Volver a [[00 Sistema - Índice]] · [[00 UniPaz360 - Índice]]
