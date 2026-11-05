---
tags: [unipaz360, sistema, cliente, flutter]
---
# Cliente Flutter

> La experiencia de Google Maps para el campus, multiplataforma y sin internet: Android, iOS, web y escritorio con el mismo código. Detalle extenso: `docs/plan/04-cliente-flutter.md`.

## Pantallas

1. **Inicio / Buscar** — buscador, categorías, «cerca de mí» (último QR), acceso al tour y al chat.
2. **Mapa** — 2D con capas; abajo a la derecha los botones **[360] [2D] [🛰 dron] [🎮 tour]**.
3. **Ficha de espacio** — nombre, código, bloque, piso, horario, servicios, foto, botón «Cómo llegar».
4. **Ruta a pie** — estándar o sin escaleras, con distancia y tiempo.
5. **Chat** (offline) — ver [[Chatbot y horarios]] · plan: [[Plan de trabajo - guía y chatbot]].
6. **Tour QR** — minijuego «Descubre UniPaz» (abajo).
7. **Mi horario** · 8. **Ajustes**.

Navegación con `go_router` y **deep links** compartibles: `https://unipaz360.app/ruta?de=PORTERIA&a=B3-305`.

## Mapa 2D (capas, de abajo hacia arriba)

| Capa | Contenido |
|---|---|
| 1. Fondo | Ortophoto de dron por zoom o plano ilustrado |
| 2. Planos de piso | Plano interior del bloque activo (imagen georreferenciada) |
| 3. Edificios | Polígonos de bloques y salones por categoría |
| 4. Red peatonal | Tramos (modo explorar/depuración) — ver [[Grafo del campus]] |
| 5. Ruta activa | Polilínea + marcadores + waypoints |
| 6. Puntos de interés | QR/anclajes, baños, cafetería, referencias — ver [[Origen por código QR]] |
| 7. Yo | Última ubicación fijada por QR, con su hora |

- Selector de piso con animación; etiquetas según zoom (LOD).
- «Estoy aquí» por QR **caduca** a las N horas (no mentir si ya se movió).
- Modo alto contraste y textos del sistema (HU-14) — ver [[Normativa de accesibilidad]].

## Rutas (dominio)

- **Tres perfiles:** estándar (distancia), **accesible** (sin escaleras ni desnivel) y paso preferente.
- Multi-piso: «sube por la escalera X» / «usa el ascensor» (HU-11).
- A\* con heurística en línea recta, Dijkstra como oráculo en pruebas. < 5 ms en gama media.
- Sin camino ⇒ mensaje + reporte (HU-04) — ver [[Ruta accesible]] y [[Rutas sin conexión]].

## Vista de dron (🚁)

1. **Ortophoto interactiva** sobre el mapa 2D (fase 1, sin dron: imagen satelital libre temporal).
2. **Recorrido aéreo guiado** por video con puntos de interés (offline).
3. **Modelo 3D** (futuro, fotogrametría).
4. Permisos UAEAC (RAC 100), sin personas identificables. Ver [[Centro de Investigaciones Santa Lucía]].

## Recorrido 360° (🛰)

- Esférica equirectangular por panorámica; **2 LODs** (rápida ~1-2 MB / alta ~6-8 MB); rumbo inicial.
- Viewer Flutter en móvil/escritorio; en web, **Photo Sphere Viewer** local (sin CDN ⇒ también offline).
- Navegación por grafo de enlaces (`ENLACE_PANORAMICA`) con flechas estilo Street View + mini-mapa.
- Precarga de panorámicas vecinas. Ver [[Recorrido virtual]] y el antecedente [[T63039 - Tour virtual 360° Centro de Investigaciones Santa Lucía|T63039]].

## Tour QR «Descubre UniPaz» (🎮)

- **Checkpoints** en anclajes QR: escanear desbloquea la ficha del lugar + reto + insignia.
- **Niebla en el mapa:** los bloques no visitados se ven difuminados; se revelan al visitarlos.
- Progreso local (sin rastreo continuo); logros tipo «Visitó los 5 bloques».
- **Doble beneficio:** enseña el campus y valida que los QR físicos funcionen.

## Sin conexión: qué funciona

| Función                                            | Sin internet             | Con internet   |
| -------------------------------------------------- | ------------------------ | -------------- |
| Buscar, ficha, mapa 2D, rutas, chat, horario, tour | ✅ local                  | ✅              |
| 360 LOD 0                                          | ✅ si se descargó         | ✅              |
| 360 LOD 1                                          | ⏳ solo zonas descargadas | ✅ bajo demanda |
| Enviar reporte                                     | se encola                | se envía       |
| Comprobar actualización                            | ❌ avisa «sin conexión»   | ✅              |
| Compartir ruta                                     | ❌ (QR local)             | ✅ enlace       |

## ⭐ Aviso de actualización (decisión tomada)

- Al **abrir la app** con red, consulta `version.json`.
- Si hay versión nueva: **notificación cada vez que abre** con **[Actualizar ahora]** / **[Más tarde]**.
- «Más tarde» ⇒ se vuelve a preguntar en la próxima apertura. **Jamás se actualiza en silencio.**
- El aviso dice qué cambió («2 bloques nuevos», «fotos del Bloque 3»).
- Ajustes: «Descargar todo (Wi-Fi)», «Solo datos básicos», «Borrar medios», con tamaños a la vista.
- Diseño completo del motor (carpetas, verificación y cada plataforma): [[Flujo de actualización (plataforma → apps)]] · plan: [[Plan de trabajo - actualizaciones]].

## Arquitectura interna

```
ui/          pantallas (mapa, 360, chat, tour…)
dominio/     casos de uso: BuscarEspacio, CalcularRuta, RespuestaChatbot… (puro Dart)
datos/       drift/SQLite · lector de paquete · sincronizador
plataforma/  archivos, conectividad, cámara, compartir
```

- Estado: **Riverpod**. Pruebas: dominio (A\* vs Dijkstra, conversaciones doradas), widgets, integración con paquete de ejemplo.
- i18n desde el día 1 (español; preparado para inglés).
- Meta de accesibilidad WCAG 2.2 AA — ver [[Evaluación de usabilidad]].

Volver a [[00 Sistema - Índice]] · [[00 UniPaz360 - Índice]]

## Apariencia y páginas que manda el panel (contrato)

- La app lee `configuracion_app` (clave `app`) del paquete y dibuja con eso el encabezado, la barra lateral, el minimapa (nodos y estados minimizado, normal y maximizado) y **las páginas de cada sección**.
- Las páginas son un lienzo de 1000 unidades de ancho: todo se multiplica por (ancho del panel / 1000). Fuentes: Roboto y Noto Serif, empaquetadas en la app.
- Recursos `app://imagenes/…` y `app://videos/…` = `assets/` de la app; lo `https://` se descarga del paquete para verse sin conexión.
- Puntos del 360°: 8 formas, color, tamaño y 9 animaciones. Las posiciones van en el marco de la foto, con la misma corrección de horizonte que la esfera.
- Detalle: `docs/datos/apariencia-app.md` y `docs/datos/puntos-360.md` del repositorio. Ver [[Bitácora del repositorio]].
