---
tags: [unipaz360, sistema, panel, sprint]
fecha: 2026-11-04
---
# Plataforma · Sprint P1: grafo del campus

> Primer incremento de la plataforma de gestión (ver [[Visión consolidada (nov-2026)]] y [[Plataforma de administración]]). La rama es `p1-plataforma-grafo` en el repo real, dentro de la carpeta `panel/`. **Commit `fe8a258`**, en revisión en el [PR #34](https://github.com/mamalon104366/unipaz360/pull/34).

## Qué quedó funcionando

- **Marco visual** inspirado en la referencia que eligió el equipo:
  - Riel oscuro de íconos dentro de una cápsula clara, con el texto vertical "UNIPAZ360 · PANEL".
  - Barra lateral con perfil y secciones **Campus**, **Estado del grafo** y **Publicación**. Sus contadores se actualizan solos y se resaltan en naranja o verde.
  - Elemento seleccionado "de vidrio", superficies grises con relieve y tipografía grande (Geist).
  - La barra lateral se puede contraer.
- **Inicio:** número grande de nodos, tarjetas de ruta accesible, tramos por verificar, panorámicas y espacios, y la lista "Antes de publicar".
- **Editor de mapa** (MapLibre GL JS 6 sobre satélite de Esri o calles de OSM):
  - Modos **Seleccionar (V)**, **Nodo (N)** y **Ruta (T)**. En Ruta se dibuja encadenado y cada clic une con el anterior.
  - Los nodos se mueven arrastrándolos. PostGIS recalcula la línea y la longitud de sus tramos.
  - Panel de propiedades:
    - **Nodo:** tipo, nombre, piso, coordenadas y el URI del QR `unipaz360://nodo/{id}`.
    - **Tramo:** escaleras, verificado, doble sentido, **apto para la ruta accesible**, superficie, ancho, pendiente y desnivel.
  - **Regla de accesibilidad** del esquema y la NTC 4143: no se puede marcar un tramo accesible si tiene escaleras o no está verificado.
  - Detección de **islas**: los nodos aislados salen en rojo, con el estado "Grafo conectado / N partes separadas".
  - La leyenda distingue rutas accesibles, con escaleras, normales y sin verificar (punteadas).
  - Los filtros de la barra lateral ("por verificar", "aislados", "accesibles") centran el mapa en esos elementos.
- **API:** `GET /api/grafo`, `POST/PATCH/DELETE /api/vertices` y `/api/tramos`, sobre las tablas `vertice` y `tramo` de Neon.
- Los IDs son legibles, como en la ficha de campo (`V-001`, `T-001`).

## Verificación

- `tsc`, `eslint` y `next build` pasan sin errores ni advertencias.
- Se probó en el navegador: se crearon nodos y tramos, se cerró una ruta sobre un nodo existente, se movió un nodo (las longitudes se recalcularon en la base) y se probaron las reglas de accesibilidad. **Los datos de prueba se borraron.**
- La conexión a Neon usa TLS verificado. Las credenciales se leen de `~/dev/unipaz360.secretos.env`, nunca del repo.

## Problemas resueltos por el camino

| Problema | Solución |
|---|---|
| Next 16 trae `cacheComponents` activo, y `export const dynamic` ya no se permite | Los datos se leen con `connection()` dentro de `<Suspense>` |
| MapLibre 6 no carga su *worker* con Turbopack | `scripts/copiar-worker.mjs` lo copia a `public/maplibre/` y se registra con `setWorkerUrl` (URL absoluta) |
| El mapa salía gris en el campus | Esri no tiene imágenes por encima de z18 allí; se fijó `maxzoom: 18` para que amplíe esa capa |
| Se perdía el primer clic sobre un nodo | La detección se hace en píxeles con los datos en memoria, sin depender del render de MapLibre |

## Pendiente (P2)

- Panorámicas por nodo, edición no destructiva y puntos de información.
- Publicar: las 7 reglas, el paquete y R2.
- **Cuentas, roles y auditoría.** Hoy no hay inicio de sesión, así que **no se debe desplegar en público**.
- IDs que nunca se reutilicen (hoy, si se borra el último nodo, su número se vuelve a usar). Hay que resolverlo antes de imprimir los QR.
- Puntos intermedios en los tramos, para seguir las curvas reales del camino.

Volver a [[00 Sistema - Índice]] · [[00 UniPaz360 - Índice]]

## Despliegue

- Vista previa protegida en Vercel (proyecto `unipaz360-panel`): https://unipaz360-panel-41oqavj9y-mamalon104366s-projects.vercel.app. Solo se puede abrir con una sesión de Vercel con acceso al proyecto.
- **Despliegue automático:** cada push a una rama del repo genera su vista previa (Root Directory `panel`). `main` **no se despliega** (`panel/vercel.json`) hasta que P2 tenga inicio de sesión; ese día se quita esa línea.
