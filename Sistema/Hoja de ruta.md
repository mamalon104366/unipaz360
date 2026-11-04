---
tags: [unipaz360, sistema, roadmap]
---
# Hoja de ruta

> Cómo pasar de «docs del curso» a «sistema completo» sin ahogarse: fases pequeñas, cada una utilizable, mapeadas a los sprints del curso. Detalle extenso: `docs/plan/07-hoja-de-ruta.md`.

## Fases

| Fase | Cuándo | Qué queda funcionando |
|---|---|---|
| **F0 · Cimientos** | Sprints 2–3 (curso) | Monorepo, `app/` Flutter creado, modelo ER v2 con `campus_id`, empaquetador con validaciones (TEC-01/04/05/06) |
| **F1 · MVP app** | Sprints 4–6 (curso) | Buscar, ficha, origen, ruta normal y accesible, mapa 2D offline (Hito 2) |
| **F2 · Experiencia completa** | Sprints 7–9 (curso) | QR real, 360° multipanorámica, tiempos/distancia, APK distribuido (Hito 3) + tour QR mínimo |
| **F3 · Panel MVP** | Semestre siguiente (grado) | Login institucional, CRUD sobre mapa, medios, panorámicas, publicar/versiones, auditoría, reportes |
| **F4 · Chatbot, horarios y tour** | Semestre siguiente | Chatbot v1, importador de horarios, tour extendido |
| **F5 · Dron y escala** | Después | Ortomosaico, recorrido aéreo, multi-sede, integraciones |

> **Regla de oro:** ninguna fase nueva empieza sin que la anterior esté *usable y probada con usuarios reales*. El error clásico es construir el panel del año 2 antes del mapa del año 1.

## F0–F2 en el curso (lo que toca ya)

- **F0:** ✅ reorganizar monorepo (D1) → TEC-01 (`app/` Flutter con Android + web + escritorio) → TEC-04 v2 → empaquetador con las 7 validaciones.
- **F1:** lo ya definido en el backlog, más: capa de medios LOD en el paquete, «mi ubicación por QR» con caducidad, pruebas del sincronizador (hash corrupto, sin espacio, reversión).
- **F2:** visor 360 multipanorámica + precarga de vecinas; tour QR mínimo (checkpoints + niebla + 3 insignias); APK por Firebase App Distribution (TEC-03) en canal `pruebas`.

## Lo que faltaba en el panorama (auto-revisión)

| # | Faltante | Por qué importa | Fase |
|---|---|---|---|
| 1 | **IDs estables y QR impresos** | Un QR impreso no se puede «republicar»; retirar ≠ reutilizar | F0 |
| 2 | **Borradores vs publicado** | Editar el mapa no debe romper la app de nadie | F0 |
| 3 | **Reversión de versiones** | Un mal dato se quita en segundos | F0 |
| 4 | **Procesado de medios (LODs/tiles)** | El 360 y el dron sin procesar pesan demasiado | F0 → F3 |
| 5 | **Bandeja de reportes** | Cierra el ciclo de mejora | F3 |
| 6 | **Telemetría agregada opcional** | Saber qué se busca y qué no se encuentra | F4 |
| 7 | **Política de tratamiento de datos** | Auditoría + cuentas = datos personales (Ley 1581) | F3 |
| 8 | **Documentación para el heredero** | «No tocaremos código»: manual + docs + video | F3 |
| 9 | **Plan de contingencia de guías impresas** | La app no puede ser la única señalética | F2 |
| 10 | **Pruebas de accesibilidad reales** | Con usuarios de silla/bastón, no en simulación | F2/F4 |
| 11 | **Analítica de producto** | Qué rutas/espacios más se buscan | F4 |
| 12 | **Presupuesto de impresión de QR** | Placas resistentes: costo real fuera del backlog | F2/F3 |

## Riesgos principales

| Riesgo | Mitigación |
|---|---|
| **Alcance desbordado** (el #1) | Fases y «definido» por fase; el curso manda |
| Medios 360° pesados para datos móviles | LODs, descarga Wi-Fi, «solo datos básicos» |
| QR impresos que dejan de resolver | URIs inmutables + pruebas de compatibilidad |
| Sin acceso a horarios oficiales | Carga manual temporal; importador probado con datos simulados |
| Permisos de dron | Empezar con ortomosaico satelital libre; dron como fase aparte |
| Pérdida de datos | PITR + respaldos diarios + paquetes inmutables |
| Privacidad (personas en fotos/videos) | Difuminar personas; regla de publicación |

## Presupuesto global estimado

| Rubro | Estimado |
|---|---|
| Servicios (Vercel, Neon, R2) | 0-5 USD/mes |
| Dominio | ~12 USD/año |
| Placas QR (100 uds) | 100-300 USD |
| Dron (vuelos/permisos) | 150-800 USD por jornada/permiso |

## Siguiente paso inmediato

1. Presentar el plan al equipo ([[00 Sistema - Índice]] + esta nota).
2. **D1:** ✅ PR de reorganización del repo (monorepo).
3. Arrancar F0: TEC-01 (Flutter) + TEC-04 v2 + empaquetador.
4. Gerencia: pedir el Excel de horarios y cotizar placas QR.

Volver a [[00 Sistema - Índice]] · [[00 UniPaz360 - Índice]]
