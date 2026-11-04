---
tags: [unipaz360, sistema, datos]
---
# Datos y publicación

> El corazón del sistema: cómo se guardan los datos, cómo se empaquetan y cómo llegan al teléfono sin conexión. Detalle extenso: `docs/plan/03-datos-y-publicacion.md`.

## Las dos bases de datos

| | Base central (Neon/PostgreSQL) | Base local (SQLite en el dispositivo) |
|---|---|---|
| Rol | Fuente de la verdad, la editan administradores | Réplica de solo lectura que usa la app |
| Cuándo | Siempre en línea | Siempre offline |
| Esquema | Completo (usuarios, auditoría, borradores) | Solo lo que la app necesita (`db/esquema-local.sql`) |

El **paquete de datos** es una exportación de la base central al esquema local. El empaquetador (TEC-05) se vuelve la pieza clave: valida en el servidor lo mismo que la app exige en el dispositivo.

**Implementado (TEC-05):** el pipeline vive en `scripts/` y no tiene dependencias (usa `node:sqlite` de Node 24): `validar.mjs` aplica las 7 reglas, `empaquetar.mjs` produce `datos.sqlite` + `manifest.json` + `version.json` (y sube a R2 con `--subir`). El esquema local v2 está en `db/esquema-local.sql`. Se prueba de punta a punta con `datos/ejemplo/` en el CI.

## Modelo ampliado (evolución de TEC-04)

Entidades nuevas o ampliadas respecto al modelo actual (ver [[Grafo del campus]]):

| Entidad | Qué agrega |
|---|---|
| **CAMPUS** | `campus_id` en todo: futuro multi-sede desde el día 1 |
| **BLOQUE** | Polígono (footprint), altura, nombre |
| **NIVEL** | Plano de piso (imagen georreferenciada), elevación |
| **ESPACIO** | `nivel_id` + polígono del salón (dibujado, no solo punto) |
| **TRAMO** | Geometría de la línea (pasillo real) + longitud calculada |
| **PANORAMICA** | Rumbo inicial y niveles de detalle (LOD) — estilo Street View |
| **MEDIO** | Fotos, videos de dron, ortomosaico (con LODs y licencia) |
| **HORARIO** | Espacio, día, franjas, materia, programa, semestre, grupo — ver [[Chatbot y horarios]] |
| **CALENDARIO_ACADEMICO** | Festivos, inicio/fin de semestre, exámenes — «¿hay clase el 20 de julio?» |
| **USUARIO / PERFIL_ESTUDIANTE / AUDITORIA / PUBLICACION** | Panel y app: roles, programa del estudiante, trazabilidad y versiones |
| **REPORTE** | + estado (nuevo/en proceso/resuelto) |

**Implementado:** el esquema central completo ya vive en `db/migraciones/0001_esquema_inicial.sql`
y está aplicado en Neon (PostgreSQL 18 + PostGIS 3.6), con migrador propio (`db/migrar.mjs`)
y prueba de humo (`db/pruebas.mjs`). Documentado en `docs/datos/modelo-central.md`.

## Las 7 validaciones antes de publicar

1. **Grafo conexo** (BFS): islas ⇒ se bloquea la publicación.
2. Todo espacio tiene su vértice de acceso.
3. Accesibilidad coherente: `accesible` ⇒ sin escaleras y verificado en campo.
4. ¿Existe ruta sin escaleras desde la portería principal? ⇒ aviso si no.
5. Medios referenciados existen con su hash.
6. **QR estables:** los `uri` de anclajes publicados nunca cambian ni se reutilizan — ¡están impresos en placas físicas!
7. Horarios sin choques (mismo salón, franjas superpuestas).

**Implementado:** las 7 reglas están en `scripts/lib/reglas.mjs` y se ejecutan con `node scripts/validar.mjs`. Los errores bloquean la publicación; los avisos (accesibilidad, medios, QR) no.

## Paquete offline v2 (decisión D4)

**Cambio recomendado:** en vez de JSON que la app convierte a SQLite, **el servidor construye directamente el `datos.sqlite`** (con FTS5). La app solo descarga → verifica hash → cambia. Menos código en la app, mismos índices y CHECK en desarrollo y producción.

```
unipaz360-2026.11.1/
├── manifest.json      ← archivos, tamaños, SHA-256, versión de esquema
├── datos.sqlite       ← base lista
├── medios/            ← fotos, 360 (LOD 0/1), dron (tiles)
└── version.json       ← puntero a la última
```

En el teléfono: `paquete-actual/` + `paquete-anterior/` (reversión) + `descargas/` (en curso).

## El botón «Enviar a producción»

```
Panel: Publicar (v2026.11.2, notas) → fila en PUBLICACION
   → GitHub Action: exporta de Neon → valida (7 reglas) → construye datos.sqlite
      → genera LODs → sube a R2 (inmutable) → actualiza version.json → purga CDN
   → PUBLICACION=publicada
   → App: consulta version.json al abrir → AVISO al usuario:
        [Actualizar ahora] [Más tarde]   ← decisión tomada ✅
```

- **Nunca se actualiza en silencio:** si eligen «Más tarde», se vuelve a preguntar en la próxima apertura (ver [[Cliente Flutter]]).
- **Reversión:** cambiar el puntero de `version.json` a la anterior. En segundos, sin reempaquetar.
- **Borradores:** el panel edita borradores; solo lo aprobado llega a los teléfonos.
- **Versionado de esquema:** `manifest.esquema_version` — app vieja avisa «actualiza la app» si no soporta el esquema nuevo.

## Reportes de usuarios (HU-13)

```
App (offline) → reporte local → al haber red POST /api/reportes → Neon
   → bandeja del panel: estado + comentarios → se corrige → nueva publicación
```

Los reportes con foto valen oro para validar el levantamiento. Cada reporte se ve **sobre el mapa** en el panel.

Volver a [[00 Sistema - Índice]] · [[00 UniPaz360 - Índice]]
