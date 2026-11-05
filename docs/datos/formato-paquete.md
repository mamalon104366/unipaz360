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

### `version.json` v2 (lo publica la plataforma desde noviembre de 2026)

La plataforma (`panel/src/lib/publicacion.ts`) publica el paquete en `paquetes/<versión>/`
y mueve el puntero `version.json` **de último**. A los campos de arriba agrega:

```json
{
  "canal": "estable",
  "app_minima": { "android": "1.0.0", "web": "1.0.0", "windows": "1.0.0", "macos": "1.0.0", "ios": "1.0.0" },
  "resumen": {
    "totales": { "nodos": 17, "tramos": 19, "espacios": 0, "panoramicas": 1, "puntos": 0, "paginas": 9 },
    "cambios": { "vertice": { "crear": 3 }, "panoramica": { "actualizar": 1 } }
  }
}
```

| Campo | Qué es |
|---|---|
| `canal` | `estable` por ahora; el canal de pruebas llega después |
| `app_minima` | Versión mínima de la app, por plataforma, que entiende este paquete (`panel/src/lib/paquete/contrato.ts`). Si la app es más vieja, **no descarga**: sigue con su paquete y pide actualizar la app |
| `resumen.totales` | Cuántos elementos trae el paquete |
| `resumen.cambios` | Cambios desde la publicación anterior, por entidad (`vertice`, `tramo`, `espacio`, `bloque`, `anclaje`, `panoramica`, `punto`, `configuracion_app`, `horario`) y acción (`crear`, `actualizar`, `borrar`) |

**Reglas para la app:**

1. Comparar la versión por **distinta**, no por mayor. Si la plataforma revierte, el puntero apunta a una versión más vieja y la app la ofrece igual.
2. `esquema_version` viaja como texto (`"3"`): aceptar texto o número.
3. Tolerar que falten `canal`, `app_minima` y `resumen` (paquetes publicados antes, o reversiones a ellos).
4. Ignorar los campos que no conozca.

**Una publicación a la vez:** publicar y revertir toman un candado de transacción en
Neon (`pg_try_advisory_xact_lock`). Si hay otra en curso, responden 409 y no tocan el puntero.

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

## Semilla de la app (el paquete con el que arranca sin internet)

La app trae un paquete dentro (`app/assets/paquete/`): con él abre la primera vez, sin red. Se arma con
el mismo exportador y el mismo constructor de `datos.sqlite` que el botón «Publicar», así que trae
exactamente lo que vería con una publicación, pero **no publica nada** (no sube a R2, no mueve
`version.json` y solo lee la base):

```bash
node --conditions=react-server --experimental-transform-types panel/scripts/semilla-app.mjs
```

- Deja `datos.sqlite`, `manifest.json`, `version.json` y `medios/<archivo>` (cada medio se baja de R2 y se
  verifica con su SHA-256). Si la plataforma no dejaría publicar (hay errores), el script tampoco arma la semilla.
- La versión es `semilla-AAAA.MM.DD-HHMM`: cuando haya una publicación real, la app la verá distinta y
  ofrecerá actualizar.
- La app abre `datos.sqlite` en memoria y solo para leer (`app/lib/core/paquete/`). En Android, Windows,
  macOS e iOS usa la biblioteca nativa del paquete `sqlite3`; en la web, `app/web/sqlite3.wasm` (de la
  misma versión del paquete).
- La prueba `app/test/cliente/paquete_semilla_test.dart` exige que cada foto 360° y cada medio citado
  estén dentro de la app.
