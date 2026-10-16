# 2 · Arquitectura general del sistema

## 2.1 Vista de pájaro

```
                     ┌─────────────────────────────────────────────────────┐
                     │                    NEON (PostgreSQL + PostGIS)      │
                     │  campus · bloques · niveles · espacios · vértices   │
                     │  tramos · panorámicas · horarios · usuarios         │
                     │  auditoría · versiones publicadas · reportes        │
                     └────────────▲────────────────────────▲───────────────┘
                                  │                        │
        (API para operar)         │                        │  (API pública)
                     ┌────────────┴──────────┐   ┌─────────┴────────────────┐
                     │  PANEL DE             │   │  API v1 (Vercel        │
                     │  ADMINISTRACIÓN       │   │  Functions)            │
                     │  Next.js · MapLibre   │   │  · version.json        │
                     │  Photo Sphere Viewer  │   │  · descarga de paquete │
                     │  auditoría · publicar │   │  · reportes entrantes   │
                     └────────────▲──────────┘   └─────────▲────────────────┘
                                  │                        │
      navegador del equipo    ───┘                        │      ┌──────────────────────┐
      de mapeo                                           └──────│  CLOUDFLARE R2 / CDN │
                                                                 │  paquetes · medios   │
        ┌──────────────────────────────────────────────────┐     └──────────▲───────────┘
        │                  CLIENTE FLUTTER                  │                │
        │  Android · iOS · Web · Escritorio                 │                │
        │  ┌───────────┐ ┌───────────┐ ┌─────────────────┐  │   descarga paquetes
        │  │  Mapa 2D  │ │ 360°/dron │ │ Chatbot + tour  │  │◄─────── y medios
        │  ├───────────┴─┴───────────┴─┴─────────────────┤  │
        │  │        SQLite local (datos + FTS5)          │  │
        │  └─────────────────────────────────────────────┘  │
        └──────────────────────────────────────────────────┘
```

**Regla de oro:** la app **nunca** depende de la red para funcionar. La red solo (a) consulta si hay versión nueva, (b) descarga el paquete, (c) envía reportes/telemetría opcional.

## 2.2 Piezas del sistema

| Pieza | Qué es | Dónde vive | Tecnología |
|---|---|---|---|
| **Cliente** | App de orientación multiplataforma | Android, iOS, web, escritorio | Flutter + Dart |
| **Panel** | Consola de mapeo y publicación | Web (Vercel) | Next.js + TypeScript + MapLibre GL JS |
| **API** | Lectura pública (versión, paquete, reportes) y operación del panel | Vercel Functions | TypeScript (mismo repo del panel) |
| **Base central** | Fuente de la verdad | Neon | PostgreSQL + PostGIS |
| **Objetos** | Paquetes versionados, fotos, videos, tiles | Cloudflare R2 + CDN | S3-compatible |
| **Pipeline** | Valida, empaqueta y publica | GitHub Actions | Node.js (scripts en `scripts/`) |
| **Repo** | Código + datos fuente + documentación | GitHub | Monorepo |

## 2.3 Monorepo propuesto (decisión D1)

```
unipaz360/
├── app/                  ← proyecto Flutter
│   ├── lib/
│   │   ├── app/          (arranque y enrutado)
│   │   ├── data/         (SQLite/drift, paquete, sincronización)
│   │   ├── domain/       (grafo, A*, búsqueda, chatbot, horarios)
│   │   └── ui/           (mapa, 360, dron, tour, chat)
│   └── test/
├── db/                   ← base central: esquema y migraciones (Neon · PostgreSQL + PostGIS)
│   ├── migraciones/      (cambios del esquema, en orden)
│   └── semilla/          (datos base, p. ej. el campus)
├── panel/                ← Next.js del panel de administración
│   ├── app/  (rutas y API)
│   └── components/
├── datos/                ← CSV fuente + (más adelante) ortophotos fuente
│   └── piloto/
├── scripts/              ← validar.py / empaquetar.mjs (pipeline TEC-05)
├── docs/
│   ├── plan/             ← este plan
│   ├── datos/            ← modelo ER, formato de paquete
│   ├── historias/  sprints/
│   └── arquitectura.md   ← (TEC-06) resumen para la app, enlaza a este plan
└── .github/workflows/    ← CI: Flutter + panel + pipeline
```

Por qué **ahora**: mover carpetas antes de que exista código cuesta minutos; después de TEC-01/02 cuesta días. El CI (`ci.yml`) se actualiza en el mismo PR con rutas `app/` y un job nuevo para `panel/`.

## 2.4 Tecnologías y por qué

### Cliente (Flutter)
| Necesidad | Elección | Por qué |
|---|---|---|
| Mapa 2D | `flutter_map` | Maduro, funciona en las 4 plataformas, raster + vectores, caché offline |
| Capas vectoriales | GeoJSON propio (Polígono/Línea/Marcador) | Los datos del campus son pequeños; no hace falta servidor de tiles vectoriales |
| Ortophoto de fondo | Tiles raster o imagen georreferenciada | Vuelo de dron → ortomosaico → tiles por zoom |
| 360° | Viewer propio o paquete de panorama mantenido; **capa de compatibilidad** para web | Ver [04-cliente-flutter](04-cliente-flutter.md) §4.5 |
| Base local | `drift` (SQLite) + FTS5 | Tipado, migraciones, búsqueda con tildes |
| Estado | Riverpod | Simple, testeable, sin `BuildContext` |
| Rutas de navegación | `go_router` | Deep links (compartir una ruta por enlace) |
| QR | `mobile_scanner` | Multiplataforma, offline |

### Panel (Vercel)
| Necesidad | Elección | Por qué |
|---|---|---|
| Framework | **Next.js (App Router)** | Un solo proyecto = pantallas + API; despliegue nativo en Vercel |
| Editor de mapas | **MapLibre GL JS** | Libre (sin claves ni tarifas), vectorial, editable con plugins de dibujo (terra-draw o similar) |
| Vista previa 360° | **Photo Sphere Viewer** | Libre, con mosaicos multinivel estilo Street View |
| Base de datos | Neon (PostgreSQL) + **PostGIS** | Consultas espaciales (intersecciones, distancias), soporte directo en Neon |
| ORM | Drizzle o Prisma | Tipado con TypeScript; migraciones versionadas |
| UI | Tailwind + shadcn/ui | Rápido de armar, accesible |
| Autenticación | Auth institucional Google (`@unipaz.edu.co`) + sesiones con rol | Ver §2.6 |

### Infraestructura
- **Vercel:** panel y API. *Nunca* sirve medios pesados (límites de banda ancha).
- **Cloudflare R2:** paquetes, fotos, videos, tiles. Egreso gratis; URL firmadas para subir.
- **GitHub Actions:** CI del código + job de publicación (validar → empaquetar → subir → actualizar `version.json`).
- **Neon:** ramas de base de datos por entorno (dev/preview/prod) — ideal para probar migraciones sin miedo.

## 2.5 Flujo de datos en dos direcciones

**Hacia la app (descarga):**
```
Panel edita (borrador) → Publicar → GitHub Action:
  valida datos → construye paquete (DB SQLite + medios) → sube a R2
  → actualiza version.json → app lo detecta y actualiza
```

**Hacia el panel (retorno):**
```
App guarda sin conexión: reportes de error · telemetría agregada (opcional)
  → al haber red, los envía a la API → bandeja del panel → se corrige → nueva versión
```

## 2.6 Seguridad y auditoría (resumen)

- **Autenticación:** Google Workspace institucional restringido al dominio de UNIPAZ; rol asignado en la tabla `usuario` (superadmin, editor, lector). Sesiones cortas + refresco.
- **Autorización:** cada mutación pasa por API con rol verificado; los lectores solo consultan.
- **Auditoría (HU nueva del panel):** toda acción de escritura y todo inicio/cierre de sesión se registra en `auditoria` (quién, qué, cuándo, valor antes/después, IP y agente). Consultable y exportable solo por superadmin.
- **Medios:** subida con URL firmada; descarga pública de paquetes (no contienen datos personales).
- **Legal:** datos de auditoría = datos personales → política de tratamiento (Ley 1581 de Colombia), retención definida (p. ej. 12 meses) y acceso restringido.

## 2.7 Entornos

| Entorno | Base | Panel | Paquete |
|---|---|---|---|
| **Local** | Neon rama `dev` | `next dev` | generación local de paquete |
| **Preview** | rama de Neon por PR | deploy automático de Vercel | paquete de pruebas sin publicar |
| **Producción** | rama `main` de Neon | Vercel producción | paquete público en R2 |

Nada llega a producción sin pasar por el botón **Publicar** del panel (con validaciones). Los paquetes publicados son **inmutables**: si algo sale mal, se apunta `version.json` a la versión anterior (reversión en segundos).

## 2.8 CI/CD

| Disparador | Qué corre |
|---|---|
| PR (toca `app/`) | `flutter analyze` + `flutter test` (como hoy) |
| PR (toca `panel/`) | `tsc`, lint, pruebas, build de Next.js |
| PR (toca `datos/` o `scripts/`) | Validación del grafo y del formato del paquete |
| Botón Publicar | workflow `publicar.yml`: valida → empaqueta → sube a R2 → actualiza versión |
| Tag `app-vX.Y.Z` | compila APK/AAB firmado (y web/build de escritorio) |

> Este esquema conserva lo que ya exige el curso (todo por PR, CI verde, APK en modo avión) y le suma la capa de infraestructura sin romper ninguna regla existente.
