# 4 · Cliente Flutter (multiplataforma, offline primero)

> Objetivo: la experiencia de Google Maps, pero para el campus y sin internet. Android, iOS, web y escritorio con el mismo código.

## 4.1 Pantallas de la app

```
┌───────────────────────────────┐  1. Inicio / Buscar: buscador, categorías,
│  UniPaz360        [⌕] [🔔]    │     «cerca de mí» (mi última ubicación QR),
│ ┌───────────────────────────┐ │     acceso al tour y al chat.
│ │                           │ │
│ │        MAPA 2D            │ │  2. Mapa: 2D con capas (edificios, planos,
│ │   (plano + edificios)     │ │     rutas); a la derecha abajo los botones
│ │                           │ │
│ │                           │ │      [ 360° ]  → recorrido virtual
│ │          [360] [2D] [🛰]  │ │      [ 2D  ]  → plano clásico
│ │          [🚁] [🎮]        │ │      [ 🛰 ]  → vista de dron
│ └───────────────────────────┘ │      [ 🚁 ]  → vista aérea 3D/ortophoto
│ ┌───────────────────────────┐ │      [ 🎮 ]  → tour y logros
│ │ ▶ Ruta al Aula 101 · 3 min│ │
│ └───────────────────────────┘ │  3. Ficha de espacio · 4. Ruta a pie
└───────────────────────────────┘     (con opción sin escaleras)
┌───────────────────────────────┐
│  💬 Chat (offline)            │  5. Chat: «¿dónde es Cálculo I?»,
│  «¿dónde es Cálculo I?»       │     «llévame a mi próxima clase».
│  ¡Bloque 3, piso 2, Aula 305! │
└───────────────────────────────┘  6. Tour QR · 7. Mi horario · 8. Ajustes
```

### Navegación (go_router)
- `/` mapa · `/buscar` · `/espacio/:id` · `/ruta?destino=…&origen=…`
- `/360?panorama=…` · `/dron` · `/tour` · `/chat` · `/horario` · `/ajustes`
- Deep links para compartir: `https://unipaz360.app/ruta?de=PORTERIA&a=B3-305` (web y móvil).

## 4.2 Mapa 2D (la base de todo)

**Motor:** `flutter_map` con capas, en este orden:

| Capa | Contenido | Fuente |
|---|---|---|
| 1. Fondo | Ortophoto de dron por zoom (o plano ilustrado del campus) | paquete `medios/dron/*.mbtiles` |
| 2. Planos de piso | Plano interior del bloque activo (imagen georreferenciada del `NIVEL`) | `medios/planos/` |
| 3. Edificios | Polígonos de bloques y salones (contorno + relleno por categoría) | `datos.sqlite` (GeoJSON) |
| 4. Red peatonal | Tramos (solo en modo «explorar» o depuración) | `datos.sqlite` |
| 5. Ruta activa | Polilínea resaltada + marcadores origen/destino + waypoints numerados | cálculo local |
| 6. Puntos de interés | QR/anclajes, puntos de referencia, baños, cafetería | `datos.sqlite` |
| 7. Yo | Última ubicación conocida (fijada por QR), con su hora | local |

**Comportamientos clave:**
- Selector de piso: al cambiar de nivel, animación y filtrado de espacios por `nivel`.
- «Pellizco» para zoom; doble toque para acercar; rotación **desactivada** por defecto (mapas de campus se leen mejor al norte) con ajuste opcional.
- Etiquetas de espacios según zoom (LOD de etiquetas: código a poco zoom, nombre completo al acercar).
- Modo alto contraste para baja visión (HU-14) y tamaño de texto del sistema respetado.

**Actualización de la posición fijada por QR:** escanear una placa la guarda como «estoy aquí» con una marca de tiempo; caduca a las N horas (ajustable) para no mentir cuando el usuario ya se movió.

## 4.3 Cálculo de rutas (dominio)

Ya definido en [formato-paquete.md](../datos/formato-paquete.md): **A\*** con heurística en línea recta, Dijkstra como oráculo en pruebas. Se amplía:

- **Tres perfiles de costo:** estándar (distancia), accesible (excluye escaleras/no verificado), paso preferente (evita zonas de servicio/peligrosas si se marcan).
- **Rutas con varios pisos:** al cambiar de nivel, la ruta indica «sube por la escalera X» o «usa el ascensor Y» (HU-11).
- **Extremos:** el destino es el vértice de acceso del espacio, con el último tramo «entra por la puerta principal».
- **Rendimiento:** grafo de un campus ≈ < 2 000 vértices ⇒ cálculo < 5 ms en un móvil de gama media; sin necesidad de algoritmos jerárquicos.
- **Sin camino:** mensaje + botón de reporte (ya en criterios HU-04).

## 4.4 Vista de dron (🚁)

Etapas, de simple a complejo (no bloquear la primera por la última):

1. **Ortophoto interactiva:** el ortomosaico del vuelo como capa de fondo del mapa 2D (ya en el paquete). Zoom hasta ~5 cm/px en el bloque piloto.
2. **Recorrido aéreo guiado:** video del dron con puntos de interés sincronizados («mira el Bloque 2»), reproducido offline.
3. **Modelo 3D (futuro):** malla del campus (fotogrametría) con visor glTF. Solo si el proyecto crece; requiere equipo y tiempo de procesamiento (OpenDroneMap / WebODM).
4. **Permisos:** vuelo según normativa UAEAC (RAC 100), con piloto autorizado y locaciones autorizadas. **Sin personas identificables** en el material publicado.

> Mientras no haya dron, esta pestaña muestra la **vista satelital libre del campus** (imagen satelital de OpenStreetMap/Esri con atribución) o se oculta con una bandera de función.

## 4.5 Recorrido 360° (🛰)

**Formato:** una foto esférica equirectangular por vértice-panorámica; dos niveles de detalle (LOD 0 rápida ~1-2 MB, LOD 1 alta ~6-8 MB); orientación inicial (rumbo) para que abra mirando hacia el camino.

**Viewer dentro de Flutter:** paquete de panorama mantenido para móvil/escritorio (comprobar candidato actual en pub.dev al implementar; si la calidad no conviene, shader propio con `flutter_gpu`/`Impeller`). **Web:** el mismo widget de Flutter Web o un `HtmlElementView` con **Photo Sphere Viewer** local (JS empaquetado en los activos, sin CDN ⇒ también offline).

**Navegación entre panorámicas:** grafo `ENLACE_PANORAMICA` ⇒ flechas flotantes (adelante/atrás) y mini-mapa con puntos de otras panorámicas. Mismo patrón que Street View.

**Rendimiento:** cargar LOD 0 inmediato y LOD 1 en segundo plano; precargar las panorámicas vecinas (las «que vienen en camino»).

## 4.6 Tour QR: «Descubre UniPaz» (🎮)

Minijuego de inducción para estudiantes nuevos, 100 % offline:

- **Checkpoints:** cada anclaje QR publicado se puede marcar como punto del tour (`TOUR_CHECKPOINT`: anclaje, título, reto, insignia).
- **Mecánica:** escanear el QR desbloquea la ficha del lugar + pregunta corta («¿qué servicio ofrece este punto?») + insignia. Mapa con efecto «niebla» que se va revelando: los bloques no visitados se ven difuminados.
- **Progreso:** guardado local y opcionalmente sincronizado con la cuenta institucional (para que Coordinación vea avance de inducción… si algún día lo piden).
- **Logros:** «Visitó los 5 bloques», «Encontró la biblioteca», «Completó el tour en un día».
- **Beneficio doble:** enseña el campus y **valida los QR reales** (si un QR del tour no escanea, está mal puesto).

Inspiración: mecánicas de Pokémon GO / geocaching, sin rastreo continuo ni ubicación en vivo.

## 4.7 Chatbot (💬)

Detalle completo en [06-chatbot-y-horarios](06-chatbot-y-horarios.md). Resumen: motor de reglas + búsqueda difusa **100 % offline**, intenciones en YAML dentro del paquete (editable desde el panel más adelante), respuestas con acción («abrir ruta», «abrir ficha», «ver horario»).

## 4.8 Horarios (📅)

- «Mi horario»: el estudiante elige programa + semestre (o grupo) y ve su semana; se guarda local.
- «Próxima clase»: tarjeta en inicio con cuenta regresiva y botón «Cómo llegar» (ruta desde el último QR escaneado).
- El chatbot responde «¿dónde es X materia?» y «¿a qué hora termina la clase actual?».

## 4.9 Sin conexión: qué significa exactamente

| Función | Sin internet | Con internet |
|---|---|---|
| Buscar, ficha, mapa 2D, rutas, chatbot, horario, tour | ✅ todo local | ✅ igual |
| 360 LOD 0 | ✅ si se descargó la zona | ✅ |
| 360 LOD 1 | ⏳ solo zonas descargadas | ✅ descarga bajo demanda |
| Ortophoto completa | ✅ si se descargó | ✅ |
| Enviar reporte | se encola | se envía |
| Comprobar actualización | ❌ (avisa «sin conexión») | ✅ |
| Compartir ruta | ❌ (o por QR local) | ✅ enlace |

**Aviso de actualización (decidido):** cuando hay una versión nueva, la app lo notifica **al abrir**, con dos botones: **Actualizar ahora** y **Más tarde**. «Más tarde» vuelve a preguntar en la siguiente apertura; la app jamás se actualiza en silencio. El aviso explica qué cambió («2 bloques nuevos», «fotos del Bloque 3», «horarios actualizados»).

**Ajustes de datos:** «Descargar todo (Wi-Fi)», «Solo datos básicos», «Borrar medios»; barra de progreso con tamaño total (se muestra el peso antes de descargar).

## 4.10 Arquitectura interna (capas)

```
ui/          pantallas y widgets (mapa, 360, chat, tour…)
dominio/     casos de uso: BuscarEspacio, CalcularRuta, RespuestaChatbot…
   └─ entidades puras + interfaces (repositorios)
datos/       implementación: drift (SQLite), lector de paquete, sincronizador
   └─ repositorios que cumplen las interfaces del dominio
plataforma/  adaptadores: rutas de archivos, conectividad, cámara QR, share
```

- **Estado:** Riverpod (providers por caso de uso).
- **Pruebas:** unitarias del dominio (A\* vs Dijkstra, chatbot con conversaciones doradas), de widgets para pantallas clave, de integración con paquete de ejemplo.
- **i18n:** español desde el día 1 con archivos ARB (preparado para inglés).

## 4.11 Calidad y accesibilidad

- Objetivo WCAG 2.2 AA: contraste, tamaños táctiles, textos alternativos en fotos, lector de pantalla en mapa y chat (Semantics).
- Modo claro/oscuro; respetar `prefers-reduced-motion` en web.
- La ruta accesible no es «una opción escondida»: aparece como filtro visible al pedir ruta.
