---
tags: [unipaz360, sistema, arquitectura]
---
# Arquitectura general

> Mapa del sistema completo: cliente, panel, API, base de datos, almacenamiento y pipeline. Detalle extenso: `docs/plan/02-arquitectura-general.md`.

## Vista de pájaro

```
                 NEON (PostgreSQL + PostGIS): campus · bloques · niveles · espacios ·
                 vértices · tramos · panorámicas · horarios · usuarios · auditoría
                          ▲                                   ▲
        PANEL DE ADMINISTRACIÓN                  API v1 (Vercel Functions)
        Next.js · MapLibre · PSV                 version.json · reportes
                          ▲                                   ▲
                    navegador                       CLOUDFLARE R2 / CDN
                                                     paquetes · medios
                                                              ▲
        CLIENTE FLUTTER (Android · iOS · Web · Escritorio)
        mapa 2D · 360° · dron · chat · tour  ←  SQLite local  ←  descarga paquetes
```

**Regla de oro:** la app **nunca** depende de la red para funcionar. La red solo: consulta versiones nuevas, descarga el paquete y envía reportes opcionales.

## Piezas

| Pieza | Qué es | Tecnología |
|---|---|---|
| **Cliente** | App de orientación multiplataforma | Flutter + Dart — ver [[Cliente Flutter]] |
| **Panel** | Consola de mapeo y publicación | Next.js + TypeScript + MapLibre GL JS — ver [[Plataforma de administración]] |
| **API** | Versión, paquete, reportes | Vercel Functions (TypeScript) |
| **Base central** | Fuente de la verdad | **Neon (PostgreSQL + PostGIS)** |
| **Objetos** | Paquetes, fotos, videos, tiles | **Cloudflare R2 + CDN** |
| **Pipeline** | Valida, empaqueta y publica | La plataforma (función de Vercel) desde noviembre de 2026; GitHub Actions queda para compilar la app |
| **Repo** | Código + datos fuente + docs | Monorepo — ver [[Datos y publicación]] |

## Monorepo propuesto (decisión D1)

```
unipaz360/
├── app/        ← Flutter (TEC-01 lo crea aquí)
├── panel/      ← Next.js del panel
├── datos/      ← CSV del levantamiento
├── scripts/    ← validador y empaquetador (TEC-05)
└── docs/       ← docs/plan/ (este plan) + docs/arquitectura.md (TEC-06)
```

Mover carpetas **antes** de que exista código cuesta minutos; después cuesta días. El CI (`ci.yml`) se actualiza en el mismo PR.

## Tecnologías y por qué (resumen)

- **Cliente:** `flutter_map` (4 plataformas), `drift`/SQLite + FTS5, Riverpod, go_router (deep links), `mobile_scanner` (QR).
- **Panel:** Next.js (pantallas + API en un proyecto), **MapLibre GL JS** (libre, sin claves ni tarifas), Photo Sphere Viewer, Tailwind + shadcn/ui.
- **Infra:** Vercel (panel y API, nunca medios pesados), R2 (medios, egreso gratis), GitHub Actions (publicación), Neon (ramas por entorno).

## Entornos

| Entorno | Base | Panel | Paquete |
|---|---|---|---|
| Local | Neon rama `dev` | `next dev` | generación local |
| Preview | rama por PR | deploy automático Vercel | sin publicar |
| Producción | `main` | Vercel prod | público en R2 |

> [!note] Producción del panel (noviembre de 2026)
> Hoy sale al promover la vista previa de `plataforma`. La decisión D10 define si pasa a salir sola al fusionar a `main`. Ver [[Flujo de actualización (plataforma → apps)]].

## La regla que evita sorpresas

**Los medios pesados nunca pasan por Vercel.** Paquetes, fotos y tiles siempre por R2. Ver [[Plataforma de administración]].

## Seguridad (resumen)

- Ingreso con cuenta institucional Google restringida al dominio; roles en la tabla `usuario`.
- **Auditoría completa:** quién entró, quién cambió qué y cuándo (antes/después), exportable — ver [[Plataforma de administración]].
- Paquetes públicos sin datos personales; medios con URL firmadas para subir.

## CI/CD

| Cambio toca… | Corre |
|---|---|
| `app/` | `flutter analyze` + pruebas (como hoy) |
| `panel/` | `tsc`, lint, build de Next |
| `datos/` o `scripts/` | Validación del grafo y del formato |
| Botón Publicar | La plataforma valida, empaqueta, sube a R2 y mueve `version.json` (sin workflow) |
| Tag `app-vX.Y.Z` | APK/AAB firmado + builds de web/escritorio |

Volver a [[00 Sistema - Índice]] · [[00 UniPaz360 - Índice]]
