---
tags: [unipaz360, sistema, google-maps]
---
# Ingeniería inversa de Google Maps

> Cómo está construido un sistema de mapas tipo Google Maps, para copiar su arquitectura (no su escala) con herramientas libres. Detalle extenso: `docs/plan/01-ingenieria-inversa-google-maps.md`.

## Cómo funciona por dentro

Google Maps son **cuatro sistemas que se alimentan de una misma base de datos**, más el cliente que pinta:

```
CAPTURA:      satélite · Street View · dron/avión · aportes de usuarios · tráfico en vivo
PROCESAMIENTO: costura de imágenes · ortorectificación · 3D/ fotogrametría ·
               grafo de vías · geocodificación · índice de lugares · corte en TILES
SERVIDORES:   tiles z/x/y desde CDN · motor de rutas (grafo) · ETA/tráfico · Street View
CLIENTE:      WebGL · pide solo los tiles visibles · precarga lo que viene · dibuja encima
```

## Los 7 trucos → su equivalente en UniPaz360

| # | Truco | En qué consiste | Equivalente en UniPaz360 |
|---|---|---|---|
| 1 | **Pirámide de tiles** | Cuadritos de 256 px por nivel de zoom (4^z); el cliente pide solo lo visible y lo cachea | Igual con `flutter_map`; el campus cabe entero |
| 2 | **Niveles de detalle (LOD)** | Nunca se descarga más resolución de la que se ve | Miniatura primero, alta resolución al abrir |
| 3 | **Vectorización** | Calles y edificios son vectores, no fotos: pesan poco | Edificios, salones y rutas como GeoJSON (mismo archivo sirve a panel, app y plano) |
| 4 | **Grafo + algoritmos jerárquicos** | Precalcula atajos (Contraction Hierarchies) para rutas instantáneas | Nuestro grafo es diminuto: **A\* puro basta** (ya decidido en [[Grafo del campus]]) |
| 5 | **Street View = mosaicos** | Esférica cortada en cubos por zoom; saltos por enlaces predefinidos | Ya en el modelo: `PANORAMICA` + `ENLACE_PANORAMICA`; se agregan LODs y rumbo inicial — ver [[Recorrido virtual]] |
| 6 | **Geocoder + POI** | Índice de lugares con sinónimos y errores | SQLite FTS5 + normalizar tildes + sinónimos (HU-01) — ver [[Localización de espacios]] |
| 7 | **Precarga** | Baja lo que viene en camino antes de que haga falta | El paquete completo se descarga y se actualiza por versiones — ver [[Rutas sin conexión]] |

## Qué NO copiar

- Tráfico en vivo, ETA con machine learning, navegación por GPS paso a paso: fuera de alcance.
- Servidores de tiles nacionales: el campus entero cabe en un teléfono.
- Edición colaborativa abierta: aquí hay un panel con roles.

## Traducción a la pila libre

| Pieza de Google | Nuestra pieza | Herramienta |
|---|---|---|
| Motor de mapas | Editor del panel | **MapLibre GL JS** |
| Mapas del cliente | Mapa 2D de la app | **flutter_map** |
| Satélite | Ortomosaico de dron + planos | Tiles raster propios |
| Street View | Recorrido 360° | Esféricas equirectangulares + Photo Sphere Viewer |
| Grafo de vías | Red peatonal (`VERTICE`+`TRAMO`) | Propio, en SQLite |
| Motor de rutas | A\* | Propio en Dart (Dijkstra como oráculo) |
| Geocoder | Buscador de espacios | FTS5 |
| Servidor de tiles | Paquete offline versionado | Cloudflare R2 |
| Nube de Google | Base central | **Neon (PostgreSQL)** |

## Conclusión

**La arquitectura de Google Maps cabe en una caja de zapatos** si el territorio es un campus: no hacen falta algoritmos jerárquicos ni infraestructura de tiles. El 90 % del trabajo es un panel que produzca datos limpios y una app que los reproduzca offline.

Volver a [[00 Sistema - Índice]] · [[00 UniPaz360 - Índice]]
