---
tags: [unipaz360, sistema, indice]
---
# Sistema UniPaz360 — Índice

> Punto de entrada del **plan técnico completo**: la app del cliente (Flutter, sin conexión) + la **plataforma web de administración** (mapas, nodos, rutas, edificios, publicación) + los datos (Neon/PostgreSQL y paquetes versionados). El documento extenso vive en el repositorio: `docs/plan/` de `unipaz360`.

El MVP del curso **no cambia**: sigue el backlog y los Hitos del [[00 UniPaz360 - Índice|índice principal]] y de [[Sprint 0 (curso DAM)]]. Este plan ordena la visión completa del proyecto de grado.

## Notas del sistema
| Nota | Qué contiene |
|---|---|
| ⭐ [[Visión consolidada (nov-2026)]] | **Plan vigente**: app cliente + plataforma editora del tour (nodos, rutas, 360°, edición, anuncios), plataformas, diagnóstico del código y cambios al documento |
| 🔄 [[Flujo de actualización (plataforma → apps)]] | Cómo un cambio de la plataforma llega a Android, web y Windows (después macOS e iOS): versiones, motor de la app, cada plataforma y fallas previstas |
| 🗺️ [[Plan de trabajo - actualizaciones]] | Fases A a G con tareas, archivos, pruebas y propuestas para el tablero |
| 💬 [[Plan de trabajo - guía y chatbot]] | La guía sin conexión: motor de rutas y chatbot que te lleva al lugar (fases R1 y H1 a H4) |
| 🎨 [[Marca y logo]] | Archivos maestros del logo, dónde va en cada plataforma y qué hacer cuando llegue |
| ✅ [[Guía de pruebas - app igual a la plataforma]] | Cómo abrir la app en cada plataforma, qué comparar con la vista previa del Cliente y qué diferencias son a propósito |
| 🧰 [[Flutter - listo para empezar]] | Revisión del 5-nov-2026: herramientas, cómo compila la app en Android, web y Windows, prueba de SQLite y lo que falta antes de la fase B |
| [[Ingeniería inversa de Google Maps]] | Cómo funciona Google Maps por dentro (tiles, grafos, rutas, Street View) y su traducción a UniPaz360 con herramientas libres |
| [[Arquitectura general]] | Piezas del sistema, monorepo, tecnologías, entornos, CI/CD y seguridad |
| [[Datos y publicación]] | Modelo de datos en PostgreSQL, paquete offline v2, botón «Enviar a producción», versiones y reversión |
| [[Cliente Flutter]] | Mapa 2D, 360°, dron, tour QR, offline por capas y aviso de actualización |
| [[Plataforma de administración]] | Editor de mapas (MapLibre), medios con LODs, auditoría, respaldos y costos |
| [[Chatbot y horarios]] | Motor de reglas offline, intenciones, horarios de salones |
| [[Hoja de ruta]] | Fases F0–F5, riesgos, faltantes, presupuesto y siguiente paso |
| 🛠️ [[Plataforma P1 - Grafo del campus]] | Primer sprint de la plataforma: diseño, editor de nodos y rutas, accesibilidad, API y pendientes |
| 📓 [[Bitácora del repositorio]] | Registro fechado de lo que se agrega o se decide en el código (repo real en `Pictures\univerrsidadaddadada\unipaz360`) |

## Principios que guían todo

1. **Offline primero:** buscar, calcular rutas, ver el mapa y las fotos funciona en modo avión. La red solo actualiza datos y sirve funciones opcionales.
2. **Sin tocar código para operar:** actualizar el campus (edificios, rutas, fotos, horarios) se hace desde el panel web, no editando archivos ni programas.
3. **Software libre:** nada de dependencias propietarias; MapLibre, OpenStreetMap y herramientas abiertas.
4. **Escalable desde el día 1:** todo lleva `campus_id`; el día que cubra otra sede (u otra universidad), no hay que rehacer nada.
5. **Trazabilidad:** todo lo del panel queda en auditoría; cada versión publicada es inmutable y se puede revertir en segundos.

## Decisión de producto ya tomada ✅

- **Aviso de actualización:** cuando hay versión nueva, el cliente lo notifica **cada vez que abre la app** y la persona decide entre **«Actualizar ahora»** o **«Más tarde»**. Nunca se actualiza en silencio. Ver [[Datos y publicación]] y [[Cliente Flutter]].
- **Acceso (invitado o con cuenta):** el **invitado** ve mapa, búsqueda, rutas, 360°, tour con dron, chatbot y reportes. Iniciar sesión con el correo institucional (`@unipaz.edu.co`) **solo agrega** los horarios de salones y el calendario académico. Ver [[Chatbot y horarios]].

## Decisiones abiertas (D1–D9)

| # | Decisión | Recomendación |
|---|---|---|
| D1 | ¿Reorganizar a monorepo (`app/`, `panel/`, `datos/`, `scripts/`)? | ✅ **Hecho** (rama `tec-01-monorepo`), antes de crear el proyecto Flutter (TEC-01) |
| D2 | Cuentas del panel | Google institucional (`@unipaz.edu.co`) + locales solo para pruebas |
| D3 | Almacenamiento de fotos y paquetes | **Cloudflare R2** (o Vercel Blob al inicio) |
| D4 | Formato del paquete offline | **SQLite preconstruido + manifiesto** |
| D5 | 360° completo offline | Descarga por zonas con LODs: rápida siempre, alta resolución bajo demanda |
| D6 | Horarios de salones | Pedir ya el Excel a Coordinación |
| D7 | Dron | Definir quién vuela y permisos (UAEAC) antes de volar |
| D8 | ¿La app es para invitados o con cuenta? | **Ambas.** El invitado ve mapa, rutas, 360°, chatbot y reportes; el correo institucional (`@unipaz.edu.co`) agrega horarios de salones y calendario. ✅ **Decidido** |
| D9 | ¿Dónde vive el esquema de la base central? | Carpeta `db/` con migraciones versionadas aplicadas a Neon (PostgreSQL + PostGIS). ✅ **Hecho** (migración 0001) |
| D10 | ¿La producción del panel sale al fusionar a `main` o directo de `plataforma`? | Al fusionar a `main` (ver [[Flujo de actualización (plataforma → apps)]]) |
| D11 | Dominio propio para los datos que bajan las apps | `datos.<dominio>` en Cloudflare, antes de publicar las apps |
| D12 | Identificador definitivo de la app (hoy `co.edu.unipaz.dam.unipaz360`) | `co.edu.unipaz.unipaz360`, antes de la primera publicación en Google Play |
| D13 | Distribución en Windows | Microsoft Store o MSIX propio con `.appinstaller` |
| D14 | ¿Canal de pruebas desde el primer día? | Sí |

Volver a [[00 UniPaz360 - Índice]]
