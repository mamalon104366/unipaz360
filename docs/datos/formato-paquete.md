# Formato del paquete de datos (v2)

La app guarda en el teléfono un **paquete de datos** que se descarga y se reemplaza
completo cuando hay una versión nueva (decisión **D4**: base SQLite preconstruida).

Lo genera **[`scripts/empaquetar.mjs`](../../scripts/empaquetar.mjs)** a partir del
levantamiento de `datos/` (CSV) —y, más adelante, de lo que publique el panel desde
la base central—, después de validarlo con **[`scripts/validar.mjs`](../../scripts/validar.mjs)**.

## Estructura del paquete

```
paquete-2026.11.1/
├── datos.sqlite     base lista para la app (con búsqueda FTS5)
├── manifest.json    archivos, tamaños, SHA-256, versión de esquema
├── version.json     puntero a la última versión (lo consulta la app)
└── medios/          fotos de fichas, 360° (LOD 0/1), ortomosaicos
```

### `manifest.json`

```json
{
  "version": "2026.11.1",
  "campus": "Centro de Investigaciones Santa Lucía",
  "campus_id": "santa-lucia",
  "generado": "2026-11-03T14:20:00.000Z",
  "esquema_version": "2",
  "contenido_sha256": "<hash del contenido, independiente del archivo>",
  "archivos": [
    { "ruta": "datos.sqlite", "bytes": 192512, "sha256": "<hash del archivo>", "mime": "application/octet-stream" }
  ]
}
```

### `version.json`

```json
{
  "version": "2026.11.1",
  "campus": "Centro de Investigaciones Santa Lucía",
  "campus_id": "santa-lucia",
  "generado": "2026-11-03T14:20:00.000Z",
  "esquema_version": "2",
  "contenido_sha256": "<hash del contenido>",
  "manifiesto": "manifest.json",
  "sha256": "<hash del manifest.json>",
  "tamano_bytes": 192512,
  "archivos": 1
}
```

La app consulta `version.json` al abrir. Si la versión cambia, avisa al usuario
(**[Actualizar ahora] / [Más tarde]**) y **nunca** se actualiza en silencio.

## Base local (`datos.sqlite`)

El esquema vive en **[`db/esquema-local.sql`](../../db/esquema-local.sql)** (v2). Tablas:

`metadatos`, `campus`, `medio`, `vertice`, `tramo`, `espacio`, `anclaje`,
`panoramica`, `enlace_panoramica`, `horario`, `calendario_academico`, `reporte`,
y las tablas de búsqueda `espacio_fts` y `materia_fts` (FTS5).

## Columnas de los CSV (`datos/`)

Separador `;`. Los encabezados y su significado:

| Archivo | Columnas |
|---|---|
| `campus.csv` | `id`, `nombre`, `centro_lat`, `centro_lon`, `zoom` |
| `vertices.csv` | `id`, `lat`, `lon`, `nivel`, `tipo`, `descripcion` |
| `tramos.csv` | `id`, `origen`, `destino`, `longitud_m`, `desnivel_m`, `pendiente_pct`, `escaleras`, `superficie`, `ancho_m`, `accesible`, `bidireccional`, `verificado`, `notas` |
| `espacios.csv` | `id`, `nombre`, `codigo`, `categoria`, `bloque`, `nivel`, `vertice`, `horario`, `servicios`, `foto`, `notas` |
| `anclajes.csv` | `id`, `vertice`, `ubicacion`, `autorizado_por`, `instalada`, `notas` |
| `horarios.csv` | `id`, `espacio`, `dia`, `hora_inicio`, `hora_fin`, `materia`, `programa`, `semestre`, `grupo`, `docente` |
| `calendario.csv` | `fecha`, `tipo`, `descripcion` |
| `panoramicas.csv` | `id`, `vertice`, `archivo`, `rumbo_inicial`, `enlaces` |

## Reglas

| Elemento | Regla |
|---|---|
| `id` | Único. Espacios con su código oficial (`B1-101`); vértices `V###`; tramos `T###`; anclajes `A##`; panorámicas `P##`. |
| `categoria` | `aula`, `laboratorio`, `oficina`, `auditorio`, `biblioteca`, `bano`, `cafeteria`, `deportivo`, `porteria`, `parqueadero` u `otro`. |
| `nivel` | 0 para la planta baja, 1 para el primer piso alto, y así sucesivamente. |
| `lat`, `lon` | Grados decimales (WGS84), tomados en QGIS o sobre la imagen satelital, no con el GPS del teléfono bajo techo. |
| `tipo` de vértice | `puerta`, `cruce`, `escalera`, `rampa`, `ascensor`, `acceso` (entrada al campus o a un bloque) o `referencia`. |
| `dia` | 1 = lunes … 7 = domingo (ISO). |
| `longitud_m` | Se mide con cinta o con QGIS. Si se deja vacía, la app la calcula con las coordenadas. |
| `escaleras` | `true` si el tramo tiene al menos un escalón. |
| `accesible` | `true` solo si **no** tiene escaleras ni escalones y su pendiente está dentro del límite de la NTC 4143 para su longitud. **Debe verificarse en campo** (`verificado = true`). |
| `bidireccional` | `false` solo si el tramo se recorre en un único sentido. |
| `espacio` (horarios) | Puede ser el `id` del espacio (`E01`) o su `codigo` (`B1-101`). |
| Grafo | Debe ser **conexo**: desde cualquier vértice se llega a cualquier otro. |
| Horarios | Sin choques: un mismo salón no puede tener dos franjas superpuestas el mismo día. |

## Cómo usa la app estos datos

- **Ruta estándar:** A\* sobre todos los tramos, con costo igual a `longitud_m`. La heurística es la distancia en línea recta.
- **Ruta accesible:** A\* solo sobre los tramos con `accesible = true`.
- **Pruebas:** Dijkstra sirve como oráculo; las dos rutas deben coincidir en todos los casos de prueba.
- **Origen por QR:** la placa contiene la URI del anclaje, y la app la traduce al vértice de origen.
- **Búsqueda y chatbot:** `espacio_fts` y `materia_fts` permiten buscar sin conexión con tolerancia a tildes y errores.
- **Actualización (HU-09):** la app consulta `version.json`; si hay una versión nueva, descarga el paquete, verifica el `sha256` y reemplaza la base local.
