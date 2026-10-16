# `db/` — Base central de UniPaz360

Esquema, migraciones y semilla de la **base central** (Neon · PostgreSQL 18 + PostGIS 3.6).
Es la fuente de la verdad del campus: el panel la edita y el pipeline (TEC-05) la
empaqueta para la app. La app **no** consulta esta base directamente.

## Contenido

| Ruta | Para qué |
|---|---|
| `migraciones/` | Cambios del esquema, en orden. Se aplican **una sola vez** y quedan registrados. |
| `semilla/` | Datos base idempotentes (p. ej. el campus). Se pueden re-ejecutar. |
| `lib/conexion.mjs` | Conexión a Neon (usa `DIRECT_URL`; si no, `DATABASE_URL`). |
| `migrar.mjs` | Aplica las migraciones pendientes. |
| `sembrar.mjs` | Aplica la semilla. |
| `pruebas.mjs` | Prueba de humo del esquema (transacción + ROLLBACK). |

## Cómo se usa

```bash
cd db
npm install

# con la cadena de conexión en el entorno (DIRECT_URL o DATABASE_URL):
node migrar.mjs     # aplica migraciones pendientes
node sembrar.mjs    # inserta el campus base
node pruebas.mjs    # verifica el esquema (no deja datos)
```

Las credenciales **nunca** viven en el repositorio: van en variables de entorno
o en el archivo de secretos local (`~/dev/unipaz360.secretos.env`).

## Reglas del esquema

- Identificadores de catálogo en `TEXT` (legibles, fáciles de editar en el panel);
  claves transaccionales en `BIGSERIAL` o `UUID`.
- Geometría en **SRID 4326** con índice GIST. `vertice` guarda además `lat`/`lon`
  planos para consultas rápidas.
- Un tramo no puede unir un vértice consigo mismo.
- Un tramo `accesible` **no puede** tener escaleras y **debe** estar verificado.
- El código de un espacio es único por campus.
- `actualizado_en` se mantiene con un disparador en cada `UPDATE`.

## Entidades

`campus`, `bloque`, `nivel`, `espacio`, `vertice`, `tramo`, `anclaje`, `medio`,
`panoramica`, `enlace_panoramica`, `horario`, `calendario_academico`, `usuario`,
`perfil_estudiante`, `auditoria`, `publicacion`, `reporte`.

El modelo completo está documentado en [`docs/datos/modelo-central.md`](../docs/datos/modelo-central.md).
