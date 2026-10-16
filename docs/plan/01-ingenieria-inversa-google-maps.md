# 1 · Ingeniería inversa de Google Maps → UniPaz360

> Objetivo: entender **cómo está construido un sistema de mapas tipo Google Maps** para copiar su arquitectura (no su escala) con herramientas libres, y saber qué piezas necesitamos en UniPaz360.

## 1.1 Cómo funciona Google Maps por dentro

Google Maps se entiende como **cuatro sistemas que se alimentan de una misma base de datos**, más el cliente que los pinta:

```
┌──────────────────────────── CAPTURA DE DATOS ────────────────────────────┐
│ Satélite · Street View (autos) · vuelos de dron/avión · aportes de       │
│ usuarios · datos de tráfico en vivo (celulares) · socios comerciales     │
└───────────────────────────────────┬──────────────────────────────────────┘
                                    ▼
┌──────────────────────── PROCESAMIENTO (pipeline) ────────────────────────┐
│ Costura de imágenes · ortorectificación · nubes de puntos y 3D ·         │
│ construcción del GRAFO de vías · geocodificación · índice de lugares ·   │
│ corte de imágenes en TILES (pirámide de niveles de zoom) · cálculo de    │
│ tiempos (ETA) con machine learning · clasificación de negocios            │
└───────────────────────────────────┬──────────────────────────────────────┘
                                    ▼
┌──────────────────────── SERVIDORES (lo que sirve) ───────────────────────┐
│  Tiles z/x/y (raster y vectoriales)      Motor de rutas (grafo +          │
│  desde CDN                                algoritmos jerárquicos)         │
│  Geocoder (texto → lugar)                 Tiempos/ETA · tráfico           │
│  Búsqueda de sitios (POI)                 Street View (panoramas 360°)    │
└───────────────────────────────────┬──────────────────────────────────────┘
                                    ▼
┌──────────────────────── CLIENTE (lo que se ve) ──────────────────────────┐
│ Render WebGL · pide solo los tiles visibles en cada zoom · precarga lo   │
│ que viene en camino · dibuja la ruta ENCIMA del mapa · capas por         │
│ encima (tráfico, lugares, 360°)                                          │
└───────────────────────────────────────────────────────────────────────────┘
```

### Los 7 trucos que hacen que Google Maps se sienta «mágico»

| # | Truco | En qué consiste | Equivalente en UniPaz360 |
|---|---|---|---|
| 1 | **Pirámide de tiles** | El mapa se corta en cuadritos de 256 px; el zoom `z` decide cuántos cuadritos hay (4^z). El cliente pide **solo los visibles** y los reutiliza desde caché. | Igual: `flutter_map` pide solo lo visible y lo guarda en caché local. Nuestro campus es pequeño: con la ortophoto en MBTiles o tiles precalculados basta. |
| 2 | **Niveles de detalle (LOD)** | A cada zoom le toca una resolución distinta: nunca se descarga más de lo que se ve. | Lo mismo para el 360° y las fotos: miniatura primero, alta resolución solo al abrir. |
| 3 | **Vectorización** | Calles, ríos y edificios no son fotos: son **vectores** (líneas y polígonos) que el cliente pinta. Pesan poco y se estilan al vuelo. | Edificios, salones y rutas se guardan como **GeoJSON** en la base: el mismo archivo sirve para el panel, la app y la impresión. |
| 4 | **Grafo de vías + algoritmos jerárquicos** | Las vías son un grafo; para calcular rápido, Google precalcula atajos (Contraction Hierarchies) y despacha en milisegundos. | Nuestro grafo peatonal es diminuto (cientos de vértices): **A\* puro basta y sobra** (ya está decidido en `formato-paquete.md`). No necesitamos jerarquías. |
| 5 | **Street View = panoramas en mosaico** | La cámara toma una esférica; el servidor la corta en cubos/tiles por zoom; saltar a la panorámica de al lado se hace con enlaces predefinidos. | Ya existe en el modelo (`PANORAMICA`, `ENLACE_PANORAMICA`). Agregar: **cortar cada esférica en tiles** (o al menos 2-3 LOD) y guardar la orientación inicial. |
| 6 | **Geocodificación y POI** | «aula 101» → índice de lugares con sinónimos, errores y ranking. | SQLite **FTS5** + normalización de tildes/mayúsculas + sinónimos por categoría (ya pedido en HU-01). |
| 7 | **Precarga inteligente** | Mientras caminas, el cliente ya bajó lo que viene. Sin señal, sigue funcionando con lo cacheado. | La app descarga **el paquete completo** del campus y actualiza por versiones; «precarga» = descargar de una todo lo del campus piloto. |

### Qué NO copiar (no aplica a nuestra escala)

- Tráfico en vivo, ETA con ML, navegación paso a paso por GPS: fuera de alcance.
- Servidores de tiles propios de todo un país: el campus cabe entero en memoria.
- Edición colaborativa en vivo tipo «Local Guides»: tenemos un panel con roles.

## 1.2 Traducción a la pila libre de UniPaz360

| Pieza de Google Maps | Nuestra pieza | Herramienta libre |
|---|---|---|
| Motor de mapas del navegador | Editor del panel web | **MapLibre GL JS** |
| Motor de mapas del cliente | Mapa 2D de la app | **flutter_map** (Dart, funciona en Android, web y escritorio) |
| Tiles satelitales | Ortomosaico de dron + planos | Tiles raster o imagen georreferenciada (GeoJSON/tiles) |
| Street View | Recorrido 360° | Foto esférica equirectangular; viewer web: **Photo Sphere Viewer** (panel) y viewer embebido en Flutter |
| Grafo de vías | Red peatonal (`VERTICE` + `TRAMO`) | Propio, en SQLite embebido |
| Motor de rutas | A\* sobre el grafo | Propio en Dart (ya definido) |
| Geocoder | Buscador de espacios | SQLite FTS5 + normalizador |
| Guardado/servidor de tiles | Paquete offline versionado | **Cloudflare R2** (o Vercel Blob al inicio) |
| Google Cloud (base de datos global) | Base central | **Neon (PostgreSQL + PostGIS)** |
| Panel de negocios (Google Business) | **Panel de administración UniPaz360** | Next.js en **Vercel** |

## 1.3 El ciclo de vida del dato (igual que Google, en pequeño)

```
Levantamiento en campo (CSV) ──► PostgreSQL (Neon) ──► Panel edita/valida
        ▲                                                    │
        │                                   botón «Enviar a producción»
        │                                                    ▼
   Reportes de usuarios ◄── App descarga ◄── paquete versionado en R2/CDN
```

1. **Captura:** CSV del levantamiento (`datos/piloto/`), fotos 360° de la cámara, vuelos de dron, datos de Coordinación (horarios).
2. **Procesamiento:** scripts que normalizan, validan (grafo conexo, accesibilidad) y generan el paquete (equivalente al `TEC-05` actual, pero en servidor).
3. **Servir:** el paquete vive en R2 con `version.json`; el panel es la consola de operación.
4. **Cliente:** la app consulta la versión, descarga e instala; sin red, usa la última instalada. Reportes de error vuelven por la API.

> Conclusión del análisis: **la arquitectura de Google Maps cabe en una caja de zapatos** si el territorio es un campus. No necesitamos buscar usuarios geoespaciales avanzados; necesitamos un panel que produzca datos limpios y una app que los reproduzca offline. Ese es el 90 % del trabajo.
