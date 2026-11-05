---
tags: [unipaz360, sistema, flutter, pruebas]
fecha: 2026-11-05
estado: vigente
---
# Guía de pruebas: ¿la app se ve igual a la plataforma?

> [!abstract] Para qué es esta nota
> Desde el **5 de noviembre de 2026** la app Flutter dibuja la misma configuración que la vista previa del apartado **Cliente** de la plataforma. Esta nota explica:
> - Cómo abrir la app en cada plataforma.
> - De dónde salen sus datos.
> - Qué comparar con la plataforma.
> - Qué diferencias son a propósito.

---

## 1. Cómo abrir la app

| Plataforma | Cómo |
|---|---|
| Windows | `cd app` y `flutter run -d windows`, o abrir `app/build/windows/x64/runner/Release/unipaz360.exe` después de `flutter build windows`. |
| Web | `flutter run -d chrome`, o `flutter build web` y servir la carpeta `app/build/web`. |
| Android | `flutter run` con el celular conectado (opciones de desarrollador y depuración USB), o instalar `app/build/app/outputs/flutter-apk/app-release.apk`. |

> [!tip] Para comparar lado a lado
> Pon la vista previa del panel en **Escritorio** y la ventana de la app en 1440 de ancho, o la vista previa en **Celular** y la app en 915 × 412 (un celular acostado). Así las medidas coinciden.

---

## 2. De dónde salen los datos

- La app arranca con la **semilla** (`app/assets/paquete/`): lo mismo que publicaría la plataforma hoy, armado con `panel/scripts/semilla-app.mjs`. El script **no publica nada**.
- Hoy la base no tiene una apariencia guardada en el Cliente, así que la plataforma y la app muestran la **configuración por defecto**: 6 secciones, sus páginas y el minimapa con la foto del dron.
- Si cambias algo en la plataforma (apariencia, puntos, fotos o nodos) y lo guardas, para verlo en la app:
  1. **Por ahora:** volver a armar la semilla y recompilar. Desde la raíz del repositorio:
     ```bash
     node --conditions=react-server --experimental-transform-types panel/scripts/semilla-app.mjs
     ```
  2. **Cuando esté la fase B completa:** publicar en la plataforma, y la app ofrece actualizar.

---

## 3. Qué comparar

- [ ] **Encabezado:** el logo con las iniciales, el título, el subtítulo, el buscador y el botón de ocultar. Probar los estilos oscuro, claro y vidrio.
- [ ] **Barra:**
  - Las secciones, con la activa en el color principal.
  - Se pliega a riel de íconos.
  - En celular, con una página abierta, queda como riel.
- [ ] **Páginas:**
  - El título en mayúsculas con la barra de color y las pestañas.
  - Los textos con **los mismos saltos de línea**.
  - Las imágenes y las formas.
  - Los botones con sus enlaces: a una sección, a una foto 360° y a la web.
  - El video y el mapa.
- [ ] **Minimapa:**
  - Normal: zoom, giro, desplazamiento y opacidad.
  - Minimizado: el botón redondo.
  - Maximizado: arrastrar, acercar y la leyenda.
  - Los nodos: el actual con su onda, los que tienen foto y los que no, y los nombres.
- [ ] **Recorrido 360°:**
  - El rumbo inicial y la corrección de horizonte.
  - Los puntos: 8 formas, colores, tamaños y 8 animaciones.
  - Las flechas a las fotos vecinas y el fundido al cambiar de foto.
- [ ] **Lo demás:** la ficha de un punto, el botón de inicio y «Cómo llegar».

---

## 4. Diferencias a propósito

- **«Cómo llegar»** funciona de verdad en la app; en la vista previa es solo un ejemplo.
- **Los avisos del editor** no salen en la app: los contornos de selección y el «Ubica los nodos…» del minimapa.
- **El tamaño de letra del sistema** no cambia la app; lo da `interfaz.escala`.
- **El video** de las páginas usa controles propios (tocar para reproducir y la barra de avance), no los del navegador.
- **El mapa de Google embebido** necesita internet y solo se ve en Android, iOS, macOS y la web. En Windows (no hay WebView) y sin internet se ve la imagen del mapa.
- **«Atrás» en Android** cierra primero la ficha, la página o el mapa maximizado.

---

## 5. Estado por plataforma (5 de noviembre de 2026)

| Plataforma | Estado |
|---|---|
| Windows | ✅ Compila. Se revisó la ventana: encabezado, barra, foto 360°, minimapa e inicio. |
| Web | ✅ Probada en el navegador, con la foto 360° real y el punto de video en 3D. |
| Android | ✅ El APK de *release* compila. Falta probarlo en un celular. |
| macOS e iOS | Cuando haya un Mac (fase D). |

---

## 6. Si algo se ve distinto

Anota cuatro cosas:
- La plataforma.
- El tamaño de la ventana.
- La sección y la pestaña.
- Una captura de cada lado.

Las medidas oficiales están en `docs/datos/apariencia-app.md`. La diferencia se corrige en la app, o en la vista previa si la que no refleja la app es la vista previa.

Relacionado: [[Flutter - listo para empezar]] · [[Plan de trabajo - actualizaciones]] · [[Cliente Flutter]] · [[Bitácora del repositorio]]

Volver a [[00 Sistema - Índice]] · [[00 UniPaz360 - Índice]]
