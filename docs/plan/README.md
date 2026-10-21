# Plan técnico de UniPaz360 — sistema completo

> Este plan es la **visión ampliada** del proyecto: la app del cliente (Flutter, sin conexión) + la **plataforma web de administración** (mapas, nodos, rutas, edificios, publicación) + el ecosistema de datos (Neon/PostgreSQL y paquetes versionados).
> El MVP del curso sigue siendo el de [docs/sprints](../sprints) y el backlog del [README](../../README.md); este plan ordena todo lo demás y dice **qué, cómo y en qué orden**.

## Documentos

| # | Documento | Qué contiene |
|---|---|---|
| 1 | [Ingeniería inversa de Google Maps](01-ingenieria-inversa-google-maps.md) | Cómo funciona Google Maps por dentro (tiles, grafos, rutas, Street View, POI) y cómo se traduce a UniPaz360 con herramientas libres |
| 2 | [Arquitectura general](02-arquitectura-general.md) | Mapa del sistema completo, monorepo, tecnologías, entornos, CI/CD y seguridad |
| 3 | [Datos y publicación](03-datos-y-publicacion.md) | Modelo de datos en PostgreSQL, paquete offline v2, pipeline de publicación («Enviar a producción»), versiones y reversión |
| 4 | [Cliente Flutter](04-cliente-flutter.md) | Mapa 2D, recorrido 360°, vista de dron, tour QR (minijuego), chatbot y horarios; estrategia offline por capas |
| 5 | [Plataforma de administración](05-plataforma-admin.md) | Panel web: editor de mapas y grafos, subida de edificios/fotos, auditoría, respaldos y botón de publicar |
| 6 | [Chatbot y horarios](06-chatbot-y-horarios.md) | Intenciones, motor de reglas offline, integración con horarios de salones |
| 7 | [Hoja de ruta](07-hoja-de-ruta.md) | Fases, cruce con los sprints e Hitos del curso, riesgos, costos y decisiones abiertas |
| 8 | [Análisis funcional de Google Maps y arquitectura cartográfica](08-analisis-funcional-y-arquitectura-cartografica.md) | Ingeniería inversa de funciones observables, equivalentes libres, arquitectura recomendada y brechas del repositorio actual |

## Principios que guían todo el plan

1. **Offline primero:** todo lo esencial (buscar, calcular rutas, ver el mapa y las fotos) funciona en modo avión. La red solo se usa para actualizar datos y para funciones opcionales.
2. **Sin tocar código para operar:** después de entregar el proyecto, actualizar el campus (edificios, rutas, fotos, horarios) se hace **desde el panel web**, no editando archivos ni programas.
3. **Software libre:** nada de dependencias propietarias (nada de Google Maps de pago); todo con MapLibre, OpenStreetMap y herramientas abiertas.
4. **Escalable desde el día 1:** cada tabla y cada paquete llevan `campus_id`; el día que UniPaz360 cubra otra sede (o hasta otra universidad), no hay que rehacer nada.
5. **Trazabilidad:** todo lo que se hace en el panel queda en auditoría; cada versión publicada es inmutable y se puede revertir.

## Decisiones abiertas (para discutir con el equipo)

| # | Decisión | Recomendación |
|---|---|---|
| D1 | ¿Reorganizar el repositorio a monorepo (`app/`, `panel/`, `datos/`, `scripts/`)? | ✅ **Hecho** (rama `tec-01-monorepo`) |
| D2 | Cuentas del panel: ¿solo Google institucional o también cuentas locales? | Google Workspace institucional (`@unipaz.edu.co`) + cuentas locales solo para pruebas |
| D3 | Almacenamiento de fotos y paquetes | **Cloudflare R2** (S3-compatible, egreso gratis). Alternativa: Vercel Blob para empezar |
| D4 | Formato del paquete offline | **SQLite preconstruido + manifiesto** (el servidor arma la base; la app solo la descarga y la cambia) |
| D5 | 360° completo offline | Descarga por zonas con niveles de detalle (LOD): vista rápida siempre, alta resolución bajo demanda |
| D6 | Horarios de salones | Pedir a Coordinación la fuente oficial (Excel/CSV); mientras tanto, carga manual desde el panel |
| D7 | Dron | Definir quién vuela y permisos (UAEAC, RAC 100) **antes** de comprar/comprar vuelos |
| D8 | Acceso en la app: ¿invitado o con cuenta? | **Ambos.** El invitado ve mapa, rutas, 360°, chatbot y reportes; el correo institucional (`@unipaz.edu.co`) agrega **horarios de salones** y calendario académico. ✅ **Decidido** |
| D9 | ¿Dónde vive el esquema de la base central? | Carpeta `db/` con migraciones versionadas aplicadas a **Neon** (PostgreSQL + PostGIS). ✅ **Hecho** |
