---
tags: [unipaz360, sistema, bitacora]
---
# Bitácora del repositorio

> Registro fechado de lo que se agrega o se decide en el código. Lo más reciente va arriba. Cada cambio nuevo del código deja una entrada aquí.
>
> **Repositorio real del proyecto:** `C:\Users\mamalon\Pictures\univerrsidadaddadada\unipaz360` (GitHub `mamalon104366/unipaz360`, rama `main`). La carpeta `C:\unipaz360` es solo evidencia.

## 2026-11-04 · Ingreso con Google, apartado Cliente y navegación por áreas (commit `1e456cb`)

- **Ingreso solo con Google:** OAuth con flujo de código, `state` y `nonce`. Solo entran cuentas `@unipaz.edu.co` verificadas **y** autorizadas en "Cuentas y roles"; por ahora la única es `esteban.merlanoqu@unipaz.edu.co`. Se retiraron las contraseñas.
- **Credenciales:** `GOOGLE_CLIENT_ID` y `GOOGLE_CLIENT_SECRET` están en `~/dev/unipaz360.secretos.env` y en Vercel (Preview). Nunca en el repo.
- **Falta registrar en Google Cloud** (proyecto `hip-arcadia-513721-j7` → Credenciales → cliente OAuth web → URIs de redireccionamiento autorizados):
  - `http://localhost:3060/api/sesion/google/callback`
  - `https://unipaz360-panel-git-p2-plataform-88b764-mamalon104366s-projects.vercel.app/api/sesion/google/callback`
- **Apartado Cliente** (migración 0004 `configuracion_app`): vista previa de la app en celular horizontal y en escritorio, editable como en Figma. Se editan marca y colores, encabezado, barra lateral (secciones, orden, íconos y visibilidad), minimapa y pantalla de inicio. Viaja en el paquete (tabla `configuracion_app`, clave `app`) para que Flutter lo aplique.
- **Navegación:** el riel elige el área (Inicio, Campus, Tour 360°, Cliente, Publicación o Ajustes) y la barra lateral muestra solo lo de esa área. En Tour aparece la lista de panorámicas.

## 2026-11-04 · Puntos 3D en el tour y rama en Vercel (commit `0ce8266`)

- **Migración 0003:** se agrega `punto_informacion.estilo` con forma (etiqueta, ícono, círculo, flecha en el piso o capa 3D), ancho, alto, rotación (yaw, pitch, roll) y animación (pulso, flotar). **Regla compartida con Flutter: ancho angular ≈ ancho/1000 rad.** El esquema del paquete v3 lleva `estilo`.
- **Editor 360°:**
  - Flechas en el piso para ir de nodo en nodo, estilo Unisabana, acostadas con una inclinación de +60°.
  - Capas 3D: imagen, **GIF animado** (se guarda sin convertir), **video con controles dentro de la foto** y tarjetas.
  - Todo con tamaño y giro ajustables y vista en vivo. En la vista del visitante, los puntos son clicables: las flechas navegan y el resto abre una ficha.
- **Mapa:** al tocar un nodo se ve su foto 360° o se sube ahí mismo. Los nodos con foto tienen un anillo azul.
- **Vercel:** se hizo push de la rama `p2-plataforma-completa`. Vista previa protegida: https://unipaz360-panel-git-p2-plataform-88b764-mamalon104366s-projects.vercel.app
- **Pendiente:**
  - ~~Cargar `R2_*` en Vercel~~ ✅ Ya están cargadas como secretos de Preview (con autorización del usuario) y la rama se redesplegó.
  - Configurar el CORS de R2.
  - La contraseña ya la tiene el usuario.

## 2026-11-04 · Plataforma P2 completa (rama `p2-plataforma-completa`, sin commit)

- **Migración 0002** aplicada en Neon (aditiva): contadores para que los identificadores nunca se reutilicen, sesiones, contraseña con scrypt, placas QR con instalación y retiro, ajustes no destructivos de las panorámicas y la tabla `punto_informacion` (hotspots).
- **El esquema del paquete pasa a v3**: `punto_informacion`, flechas con yaw y pitch, y `medio.url`. Las pruebas de `scripts/` siguen pasando.
- **Módulos nuevos del panel** (mismo diseño de la referencia):
  - Inicio de sesión, cuentas y roles (superadmin, editor, lector) y auditoría con exportación a CSV.
  - Espacios y bloques, con foto y nodo de acceso.
  - Anclajes QR, con hoja imprimible de placas (QR con corrección H).
  - **Panorámicas 360°** con Photo Sphere Viewer: puntos de información de 7 tipos, anuncios con vigencia, horizonte, norte, vista inicial, luz y color, difuminado de rostros y parche del nadir con el logo. El original nunca se toca.
  - **Publicar**: mismas reglas del empaquetador; construye `datos.sqlite`, lo sube a R2 y mueve `version.json`. También permite descargar un paquete de prueba.
  - **Historial**, con reversión en segundos.
- **Probado:** `tsc`, `eslint` y `next build` pasan. Se verificó en el navegador el inicio de sesión y el Inicio con datos reales. La subida y el procesado de una 360° real (5376×2688 → rápida 4096 px, 568 KB, en unos 7 s) funcionaron. **Los datos y la cuenta de prueba se borraron.**
- **No probado todavía:** los clics de los editores de Espacios, Anclajes y 360° en el navegador. **Publicar no se ejecutó a propósito** para no mandar una versión a producción.
- **Pendientes del usuario:**
  1. Crear su cuenta de superadministrador en el panel local (`/ingreso`).
  2. Configurar el CORS de R2 (`node scripts/configurar-r2.mjs`); el clasificador bloqueó ese paso.
  3. Cargar `R2_*` en Vercel para que el despliegue pueda subir medios.
  4. Revisar la rama y hacer el commit.

## 2026-11-04 · Panel desplegado en Vercel (vista previa protegida)

- Se creó el proyecto **`unipaz360-panel`** en Vercel, en `mamalon104366's projects` (plan Hobby). Es independiente del proyecto `unipaz360` de la app.
- `DATABASE_URL` quedó cargada como **secreto**, solo para *Preview*.
- **URL de la vista previa:** https://unipaz360-panel-41oqavj9y-mamalon104366s-projects.vercel.app. Está protegida con *Vercel Authentication*: sin sesión responde 302 y manda al inicio de sesión de Vercel.
- **No se despliega en producción** a propósito. En Hobby el dominio de producción queda público, y el panel aún no tiene cuentas ni roles (llegan en P2).
- **Arreglo `aa4d44c`:** la conexión a Neon se crea en la primera consulta. Antes el build fallaba sin credenciales, tanto en Vercel como en el CI. Ya está subido al PR #34.
- El equipo ya cargó datos reales desde el panel: **17 nodos y 19 tramos**, todos por verificar en campo.
- **Conexión con GitHub:** Vercel conectó el proyecto al repo. El primer despliegue desde Git falló porque compilaba desde la raíz, así que se fijó **Root Directory = `panel`**. Ahora cada push a una rama crea su vista previa protegida sola.
- **Commit `853b4b5`:** se agregó `panel/vercel.json` con `deploymentEnabled.main = false`, para que el merge a `main` **no publique** el panel en el dominio público de producción mientras no haya cuentas.

## 2026-11-04 · Plataforma P1: editor del grafo (rama `p1-plataforma-grafo`)

- Se creó `panel/` (Next.js 16, Tailwind 4, MapLibre 6 y `pg` contra Neon) con el diseño de la referencia: riel oscuro, barra lateral con secciones y contadores, y tarjetas suaves.
- Funciona el editor de **nodos y rutas** con atributos de accesibilidad, detección de islas y nodos que se arrastran. Detalle en [[Plataforma P1 - Grafo del campus]].
- Pasan `tsc`, `eslint` y `next build`, y se probó en el navegador. **Commit `fe8a258`**, subido en el [PR #34](https://github.com/mamalon104366/unipaz360/pull/34) hacia `main`.

## 2026-11-04 · Documento v2 y entorno Flutter

- Se generó el **avance documental v2**, con la plataforma de gestión, el nuevo **5.4 Marco tecnológico** y el referente del tour de Unisabana. El detalle está en [[Avance documental (oct-2026)#⭐ Versión 2 (2026-11-04): plataforma de gestión y marco tecnológico]].
- **Entorno verificado:** Flutter 3.47.7 estable, Dart 3.13.5 y `flutter doctor` sin problemas (Android SDK 36, Chrome y Visual Studio Build Tools 2022 para Windows).
- **Decisiones técnicas que salieron de verificar en pub.dev:**
  - Se mantiene el **visor 360° propio**, porque `panorama_viewer` solo soporta Android e iOS.
  - `mobile_scanner` no tiene versión para Windows, así que allí el origen se elige a mano.
  - En web se usa `sqflite_common_ffi_web`.
- **Orden acordado:** primero la **plataforma**, que genera el paquete, y después la app, que lo visualiza.

## 2026-11-04 · Visión consolidada: app + plataforma editora del tour

- Se definió qué hace la **plataforma**: nodos en el mapa, rutas entre nodos, foto 360° por nodo, edición de la imagen dentro del visor (horizonte, nadir con logo, difuminado, luz y color) y contenido encima (información, anuncios con vigencia, imagen, video, enlaces). Ver [[Visión consolidada (nov-2026)]].
- Plataformas de la app: **Android (horizontal), Windows y web** son obligatorias; **iOS y macOS** quedan como límite.
- Diagnóstico del código de `app/`: hay archivos de más de 1.000 líneas, datos simulados, una dependencia de Google Maps y webview, y falta `app/windows`. Se propuso una estructura por funciones.
- Se listaron los ajustes que necesita el `.docx` del avance documental. **Aún no se aplican.**

## 2026-11-04 · Decisión: manda el plan del vault ✅

- La arquitectura objetivo es la de [[Arquitectura general]]: panel **Next.js + MapLibre**, API en **Vercel Functions**, **Neon (PostgreSQL + PostGIS)**, **Cloudflare R2** y el monorepo `app/ panel/ datos/ scripts/ docs/`.
- El repositorio `C:\unipaz360` (Vite + Fastify + ADR 0008 sin servidor) queda como **evidencia del proceso de armado** del proyecto, no como diseño final.
- Si algo del repositorio contradice el vault, gana el vault.

## 2026-11-04 · Revisión general del repositorio

**Estado:** 3 commits en `master`, todos de la Fase 0. No hay remoto configurado.

| Pieza | Estado |
|---|---|
| Documentación (`docs/`, 13 docs + 8 ADR) | ✅ Completa |
| `packages/contracts` (Zod, 37 JSON Schema) | ✅ |
| `infra/` (docker-compose, Caddy) | ✅ |
| `apps/api` (Fastify + Drizzle/Postgres) | 🚧 Falta `src/index.ts`: no arranca |
| `apps/admin` (React + Vite + MapLibre) | 🚧 Falta `src/main.tsx` y no hay páginas |
| `apps/client` (Flutter) | ❌ Solo hay un script que revisa versiones |
| `apps/cli`, `packages/geo`, `packages/ui`, `content/` | ❌ No existen (el README sí los describe) |

**Problemas detectados**
1. La API y el admin no arrancan porque les faltan sus puntos de entrada.
2. La [[#ADR 0008]] (sin servidor) exige que las rutas pasen por la interfaz `ContentStore`. Sin embargo, 7 rutas importan Drizzle/Postgres directamente y ninguna implementación del almacén existe todavía.
3. El README y `docs/10-roadmap.md` están desactualizados (dicen "7 ADR" y marcan como pendiente lo que ya está hecho).
4. Flutter y Docker no están instalados en la máquina.

> [!warning] Divergencia con el plan del vault
> [[Arquitectura general]] y [[Datos y publicación]] describen **Next.js + Vercel Functions + Neon**, con carpetas `app/ panel/ datos/ scripts/`. El repositorio usa **Vite + Fastify + modo sin servidor (SQLite local)** con `apps/ packages/`. **Resuelto:** manda el vault (ver la entrada de arriba).

### ADR 0008
En producción no hay API ni base de datos. El editor trabaja en local (`unipaz dev`), publica *content packs* firmados (Ed25519) como estáticos en Cloudflare R2/Pages o GitHub Releases, y el cliente los descubre por un `releases.json`. El costo es de ~0 USD al mes.

Volver a [[00 Sistema - Índice]] · [[00 UniPaz360 - Índice]]
