# Modelo entidad-relación de la base de datos local (TEC-04)

**Borrador para revisar en equipo.** La base vive en el teléfono (SQLite) y se llena con el paquete de datos del campus; el formato del paquete está en [formato-paquete.md](formato-paquete.md). El script SQL equivalente está en [esquema.sql](esquema.sql).

```mermaid
erDiagram
    METADATOS {
        TEXT version PK
        TEXT generado
        TEXT campus
        TEXT sha256
        TEXT instalado_en
    }
    VERTICE {
        TEXT id PK
        REAL lat
        REAL lon
        INTEGER nivel
        TEXT tipo
        TEXT descripcion
    }
    ESPACIO {
        TEXT id PK
        TEXT nombre
        TEXT codigo UK
        TEXT categoria
        TEXT bloque
        INTEGER nivel
        TEXT vertice_id FK
        TEXT horario
        TEXT servicios
        TEXT foto
    }
    TRAMO {
        TEXT id PK
        TEXT origen_id FK
        TEXT destino_id FK
        REAL longitud_m
        REAL desnivel_m
        REAL pendiente_pct
        INTEGER escaleras
        TEXT superficie
        REAL ancho_m
        INTEGER accesible
        INTEGER bidireccional
        INTEGER verificado
    }
    ANCLAJE {
        TEXT id PK
        TEXT uri UK
        TEXT vertice_id FK
        TEXT ubicacion
    }
    PANORAMICA {
        TEXT id PK
        TEXT archivo
        TEXT vertice_id FK
    }
    ENLACE_PANORAMICA {
        TEXT origen_id PK, FK
        TEXT destino_id PK, FK
    }
    REPORTE {
        INTEGER id PK
        TEXT tipo
        TEXT referencia
        TEXT descripcion
        TEXT creado_en
        INTEGER enviado
    }

    VERTICE ||--o{ ESPACIO : "es el acceso de"
    VERTICE ||--o{ TRAMO : "es origen de"
    VERTICE ||--o{ TRAMO : "es destino de"
    VERTICE ||--o{ ANCLAJE : "se fija con"
    VERTICE ||--o{ PANORAMICA : "se ve en"
    PANORAMICA ||--o{ ENLACE_PANORAMICA : "enlaza a"
    PANORAMICA ||--o{ ENLACE_PANORAMICA : "es enlazada por"
```

## Diccionario de datos

| Entidad | Para qué sirve | Historias que la usan |
|---|---|---|
| **METADATOS** | Versión, fecha y hash del paquete instalado. Permite saber si hay una actualización. | HU-09, TEC-07 |
| **VERTICE** | Punto de la red peatonal: puerta, cruce, escalera, rampa, acceso o referencia. | HU-03, HU-04, HU-05 |
| **ESPACIO** | Aula, oficina, laboratorio u otro lugar que se busca. Se llega a él por su vértice de acceso. | HU-01, HU-02 |
| **TRAMO** | Trozo de camino entre dos vértices, con los atributos que deciden si es accesible. | HU-04, HU-07, HU-08 |
| **ANCLAJE** | Placa QR: su URI se traduce al vértice de origen. | HU-06 |
| **PANORAMICA** | Foto 360° tomada en un vértice. | HU-10 |
| **ENLACE_PANORAMICA** | Relación muchos a muchos entre panorámicas, para saltar de una a otra. | HU-10, HU-12 |
| **REPORTE** | Reporte de error escrito sin conexión. Se guarda y se envía a la API cuando hay red (`enviado = 1`). | HU-13 |

## Reglas que verifica la base
- `ESPACIO.codigo` y `ANCLAJE.uri` son únicos.
- Un tramo no puede unir un vértice consigo mismo (`origen_id <> destino_id`).
- `accesible = 1` exige `escaleras = 0` y `verificado = 1`. Se verifica con una restricción CHECK y también en el script de empaquetado (TEC-05).
- Los campos booleanos son `INTEGER` con valor 0 o 1, porque SQLite no tiene tipo booleano.
- Hay índices por `TRAMO(origen_id)`, `TRAMO(destino_id)` y `ESPACIO(nombre)` para que la búsqueda y la carga del grafo sean rápidas.

## Decisiones abiertas para el equipo
- Guardar `servicios` como texto separado por comas o crear una tabla `SERVICIO` (normalizar).
- Si `PANORAMICA` debe guardar la orientación inicial de la foto (rumbo) para que el visor 360° abra mirando hacia el camino.
