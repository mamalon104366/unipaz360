# Formato del paquete de datos del campus

La app guarda en el teléfono un **paquete de datos**, que se convierte a SQLite al instalarla o al actualizarla. El paquete se genera a partir de los CSV de `datos/` y tiene esta forma:

```json
{
  "version": "2026.10.1",
  "generado": "2026-10-13",
  "campus": "Centro de Investigaciones Santa Lucía",
  "espacios":   [{ "id": "B1-101", "nombre": "Aula 101", "codigo": "B1-101", "categoria": "aula", "bloque": "B1", "nivel": 1, "vertice": "V012", "horario": "L–V 6:00–22:00", "servicios": ["videobeam"], "foto": "fotos/b1-101.jpg" }],
  "vertices":   [{ "id": "V012", "lat": 7.0000000, "lon": -73.0000000, "nivel": 1, "tipo": "puerta", "descripcion": "Puerta del aula 101" }],
  "tramos":     [{ "id": "T001", "origen": "V001", "destino": "V002", "longitud_m": 12.5, "desnivel_m": 0.0, "pendiente_pct": 0.0, "escaleras": false, "accesible": true, "bidireccional": true, "verificado": true }],
  "anclajes":   [{ "id": "A01", "uri": "unipaz360://a/A01", "vertice": "V001" }],
  "panoramicas":[{ "id": "P01", "archivo": "360/p01.jpg", "vertice": "V001", "enlaces": ["P02"] }],
  "sha256": "<hash del contenido, lo calcula el script de empaquetado>"
}
```

Los valores del ejemplo son ilustrativos (las coordenadas no son las del campus).

## Reglas
| Elemento | Regla |
|---|---|
| `id` | Único. Espacios con su código oficial (`B1-101`); vértices `V###`; tramos `T###`; anclajes `A##`; panorámicas `P##`. |
| `categoria` | `aula`, `laboratorio`, `oficina`, `auditorio`, `biblioteca`, `bano`, `cafeteria`, `deportivo`, `porteria`, `parqueadero` u `otro`. |
| `nivel` | 0 para la planta baja, 1 para el primer piso alto, y así sucesivamente. |
| `lat`, `lon` | Grados decimales (WGS84), tomados en QGIS o en Google Maps sobre la imagen satelital, no con el GPS del teléfono bajo techo. |
| `tipo` de vértice | `puerta`, `cruce`, `escalera`, `rampa`, `ascensor`, `acceso` (entrada al campus o a un bloque) o `referencia`. |
| `longitud_m` | Se mide con cinta o con QGIS. Si se deja vacía, la app la calcula con las coordenadas. |
| `escaleras` | `true` si el tramo tiene al menos un escalón. |
| `accesible` | `true` solo si **no** tiene escaleras ni escalones y su pendiente está dentro del límite de la NTC 4143 para su longitud. **Debe verificarse en campo** (`verificado = true`). |
| `bidireccional` | `false` solo si el tramo se recorre en un único sentido. |
| Grafo | Debe ser **conexo**: desde cualquier vértice se llega a cualquier otro. |

## Cómo usa la app estos datos
- **Ruta estándar:** A\* sobre todos los tramos, con costo igual a `longitud_m`. La heurística es la distancia en línea recta.
- **Ruta accesible:** A\* solo sobre los tramos con `accesible = true`.
- **Pruebas:** Dijkstra sirve como oráculo; las dos rutas deben coincidir en todos los casos de prueba.
- **Origen por QR:** la placa contiene la URI del anclaje, y la app la traduce al vértice de origen.
- **Actualización (HU-09):** la app consulta `version.json` en la API. Si hay una versión nueva, descarga el paquete, verifica el `sha256` y reemplaza la base local.
