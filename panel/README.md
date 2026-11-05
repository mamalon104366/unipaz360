# Plataforma de gestión UniPaz360 (`panel/`)

Aplicación web donde el equipo arma el campus que luego ve la app: **nodos sobre el mapa, rutas entre
nodos, accesibilidad de cada tramo** y, en los siguientes sprints, panorámicas 360°, contenidos y
publicación del paquete de datos.

> La app del visitante (`app/`) nunca consulta esta plataforma: solo descarga el paquete publicado.

## Estado: Sprint P1 (grafo del campus)

| Módulo | Estado |
|---|---|
| Inicio: contadores y revisiones antes de publicar | ✅ |
| **Mapa y rutas**: poner, mover y borrar nodos; trazar rutas encadenadas; atributos de accesibilidad; detección de islas | ✅ |
| Panorámicas 360°, Espacios, Anclajes QR, Publicar, Ajustes | ⏳ P2 (pantallas de "próximamente") |

## Cómo se usa el editor de mapa

| Tecla | Modo | Qué hace |
|---|---|---|
| `V` | Seleccionar | Clic en un nodo o tramo para editarlo; arrastra un nodo para moverlo |
| `N` | Nodo | Clic en el mapa para poner un nodo |
| `T` | Ruta | Clic, clic, clic…: cada clic une con el anterior (si cae en el vacío, crea el nodo) |
| `Esc` | — | Termina la ruta o quita la selección |
| `Supr` | — | Elimina lo seleccionado |

Reglas que se aplican al guardar (las mismas del esquema en `db/`):

- Un tramo **accesible** no puede tener escaleras y debe estar **verificado en campo**.
- Un tramo no puede unir un nodo consigo mismo ni duplicar otro tramo.
- Al mover un nodo se recalculan la línea y la longitud de sus tramos (PostGIS).
- Los identificadores siguen la ficha de campo: `V-001`, `T-001`…

## Tecnología

Next.js 16 (App Router, `cacheComponents`) · TypeScript · Tailwind CSS 4 · MapLibre GL JS 6 ·
`pg` contra Neon (PostgreSQL + PostGIS) · íconos `lucide-react`.

Fondo del mapa: imágenes satelitales de Esri (hasta z18; desde ahí se amplían) o calles de
OpenStreetMap, ambas con su atribución.

## Desarrollo

```bash
cd panel
npm install          # copia también el worker de MapLibre a public/maplibre/
npm run dev          # http://localhost:3000
npm run lint
npm run build
```

La conexión a la base se lee de `DATABASE_URL`. Si no está en el entorno, se carga de
`~/dev/unipaz360.secretos.env` (el mismo archivo que usa `db/`). **Las credenciales nunca se suben
al repositorio.**

## Estructura

```
src/
├─ app/
│  ├─ page.tsx               Inicio
│  ├─ mapa/page.tsx          Editor de mapa
│  ├─ api/grafo              GET grafo completo
│  ├─ api/vertices[/id]      POST · PATCH · DELETE nodos
│  └─ api/tramos[/id]        POST · PATCH · DELETE tramos
├─ components/
│  ├─ marco/                 Riel de íconos, barra lateral y marco general
│  ├─ mapa/                  EditorMapa, PanelPropiedades, avisos
│  └─ ui/                    Encabezado, pantallas de "próximamente"
└─ lib/
   ├─ db.ts                  Conexión a Neon (solo servidor)
   ├─ grafo.ts               Consultas y reglas del grafo (solo servidor)
   ├─ geo.ts                 Distancias y componentes conexas
   └─ tipos.ts               Modelo compartido
```

## Pendiente para P2

- Panorámicas por nodo con edición no destructiva y puntos de información.
- Publicación: validar las 7 reglas (`scripts/`), construir el paquete y subirlo a R2.
- Cuentas `@unipaz.edu.co`, roles y auditoría (hoy el panel no tiene inicio de sesión: **no desplegarlo
  en público todavía**).
- Identificadores que nunca se reutilicen: hoy, si se borra el último nodo, su número se vuelve a usar.
  Antes de imprimir QR hay que pasar a una secuencia.
