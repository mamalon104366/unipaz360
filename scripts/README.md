# Scripts del pipeline de datos (TEC-05)

Convierten el levantamiento (`datos/`) en el **paquete offline** que descarga la app:
validan, construyen la base SQLite y calculan los hashes. **Sin dependencias externas:**
usan módulos integrados de Node 24 (`node:sqlite`, `node:crypto`).

## Herramientas

| Script | Qué hace |
|---|---|
| `validar.mjs` | Aplica los controles antes de publicar y deja un informe (los errores bloquean; los avisos no) |
| `empaquetar.mjs` | Construye `datos.sqlite` + `manifest.json` + `version.json`; sube a R2 con `--subir` |
| `pruebas.mjs` | Empaqueta `datos/ejemplo` y comprueba el resultado (tablas, FTS5, manifiesto). Lo corre el CI |
| `lib/csv.mjs` | Lector de CSV (separador `;`, comillas dobles, comentarios con `#`) |
| `lib/datos.mjs` | Carga y normaliza el levantamiento |
| `lib/reglas.mjs` | Las reglas de validación |

## Uso

Las rutas se resuelven **desde la raíz del repositorio**.

```bash
# con el ejemplo (no requiere el levantamiento real)
node scripts/validar.mjs --fuente datos/ejemplo
node scripts/empaquetar.mjs --fuente datos/ejemplo --salida dist

# con el levantamiento real (INV-01)
node scripts/validar.mjs --fuente datos/piloto
node scripts/empaquetar.mjs --fuente datos/piloto --version 2026.11.1

# publicar en R2 (requiere las variables R2_* y @aws-sdk/client-s3)
node scripts/empaquetar.mjs --fuente datos/piloto --subir
```

Banderas de `empaquetar.mjs`: `--fuente`, `--salida`, `--version`, `--subir`, `--forzar`.

## Reglas que se validan

1. Identificadores únicos y **grafo conexo** (BFS).
2. Todo espacio tiene su vértice de acceso, y el vértice existe.
3. Accesibilidad coherente: `accesible` ⇒ sin escaleras y verificado en campo.
4. Aviso si algún espacio queda sin ruta sin escaleras desde la portería.
5. Los medios referenciados existen (si no, aviso).
6. URI de placas QR únicas y estables (¡están impresas en placas físicas!).
7. Horarios sin choques (mismo salón y día) y calendario con formato válido.

## Salida

El paquete queda en `dist/paquete-<versión>/`:

```
datos.sqlite    base lista para la app (con búsqueda FTS5)
manifest.json   archivos, tamaños y SHA-256
version.json    puntero a la última versión (lo consulta la app)
medios/         fotos, 360°, ortomosaicos (si los hay)
```

`dist/` está en `.gitignore`: los paquetes son artefactos, no código.

Formato y reglas en [`docs/plan/03-datos-y-publicacion.md`](../docs/plan/03-datos-y-publicacion.md)
y [`docs/datos/formato-paquete.md`](../docs/datos/formato-paquete.md). El esquema local
que produce el empaquetador vive en [`db/esquema-local.sql`](../db/esquema-local.sql).
