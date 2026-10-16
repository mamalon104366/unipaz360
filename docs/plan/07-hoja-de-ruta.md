# 7 · Hoja de ruta

> Cómo pasar de «docs del curso» a «sistema completo» sin ahogarse: fases pequeñas, cada una utilizable, mapeadas a los sprints del curso.

## 7.1 Resumen de fases

| Fase | Cuándo | Qué queda funcionando | Alcance |
|---|---|---|---|
| **F0 · Cimientos** | Sprints 2–3 (curso) | Monorepo, `app/` Flutter creado, modelo ER v2 con `campus_id`, pipeline de empaquetado con validaciones | TEC-01, 04, 05, 06 |
| **F1 · MVP app** | Sprints 4–6 (curso) | Buscar, ficha, origen, ruta normal y accesible, mapa 2D offline, SQLite real (Hito 2) | HU-01…05, 07, TEC-02, 10, INV-01 |
| **F2 · Experiencia completa** | Sprints 7–9 (curso) | QR real, 360° multipanorámica, dimensiones/tiempos, APK distribuido (Hito 3) | HU-06, 08, 10, 12, TEC-03, INV-02 |
| **F3 · Panel de administración MVP** | Semestre siguiente (grado) | Login institucional, CRUD de nodos/tramos/espacios/medios, editor MapLibre, publicar + versiones + auditoría | Nuevo |
| **F4 · Chatbot, horarios y tour** | Semestre siguiente | Chatbot reglas, importador de horarios, minijuego QR y logros | Nuevo + HU-13, 14 |
| **F5 · Dron y escala** | Después | Ortomosaico en el mapa, recorrido aéreo, multi-sede, integraciones | Nuevo |

> **Regla de oro del avance:** ninguna fase nueva empieza sin que la anterior esté *usable y probada con usuarios reales*. El sueño completo es correcto, pero el error clásico es construir el panel del año 2 antes del mapa del año 1.

## 7.2 F0–F2 en detalle (lo que toca YA en el curso)

**F0 (sprints 2–3):**
1. ✅ Reorganizar a monorepo (`app/`, `panel/` y `scripts/`; `datos/` y `docs/` permanecen en la raíz) y actualizar el CI — decisión D1 (rama `tec-01-monorepo`).
2. `TEC-01`: crear `app/` Flutter (Android + web + escritorio desde el inicio).
3. `TEC-04`: actualizar modelo ER a v2 (campus, bloque, nivel, medio, horario) — *borrador ya en [03-datos](03-datos-y-publicacion.md) §3.2*.
4. `TEC-06`: `docs/plan` ya contiene el resumen; `docs/arquitectura.md` nace de [04-cliente](04-cliente-flutter.md) §4.10.
5. `TEC-05`: empaquetador con las 7 validaciones (§3.2) — primero local (Python/Node), luego en GitHub Action.

**F1 (sprints 4–6):** el corazón ya definido en el backlog; añadir:
- Capa de medios LOD en el paquete (para que F2 no requiera rediseño).
- «Mi ubicación por QR» con caducidad.
- Pruebas del sincronizador (descarga feliz, hash corrupto, sin espacio, reversión).

**F2 (sprints 7–9):**
- Visor 360 multipanorámica + precarga de vecinas.
- Tour QR en versión mínima: checkpoints por anclaje + mapa con niebla + 3 insignias.
- Distribución del APK (Firebase App Distribution, TEC-03) con canal `pruebas`.

## 7.3 F3–F5 en detalle (grado / después)

**F3 (el panel):** por módulos, en este orden: usuarios/roles y auditoría → espacios/tramos (CRUD sobre mapa) → medios (subida y LODs) → panorámicas → publicar/versiones → reportes. Cada módulo entra con pruebas y con su parte de auditoría desde el día 1.
**F4:** chatbot v1 completo + importador de horarios + tour extendido.
**F5:** dron (requiere permisos) + ortomosaico + 3D opcional + preparación multi-sede (todo ya lleva `campus_id`).

## 7.4 Qué falta en el panorama (auto-revisión)

Cosas que no estaban en tu lista y que el sistema NECESITA tarde o temprano:

| # | Faltante | Por qué importa | Fase |
|---|---|---|---|
| 1 | **Estabilidad de IDs y QR impresos** | Un QR impreso no se puede «republicar»: `ANCLAJE.uri` inmutable; retirar ≠ reutilizar | F0 (regla de pipeline) |
| 2 | **Borradores vs publicado** | Editar el mapa no debe romper la app de nadie | F0 (modelo) |
| 3 | **Reversión de versiones** | Un mal dato publicado se quita en segundos | F0 (pipeline) |
| 4 | **Procesado de medios (LODs/tiles)** | El 360 y el dron sin procesar pesan demasiado para el teléfono | F0 (script) → F3 (automático) |
| 5 | **Bandeja de reportes** | Cierra el ciclo: usuarios encuentran errores, el panel los corrige | F3 |
| 6 | **Telemetría agregada opcional** | Saber qué se busca y qué no se encuentra (sin datos personales) | F4 |
| 7 | **Política de tratamiento de datos** | Auditoría y cuentas institucionales = datos personales (Ley 1581) | F3, antes de producción |
| 8 | **Documentación para el heredero** | «No tocaremos código»: manual del panel + docs en el repo + video | F3 |
| 9 | **Plan de contingencia de guías impresas** | La app no puede ser la ÚNICA señalética del campus | F2 (comunicación) |
| 10 | **Pruebas de accesibilidad reales** | HU-14 y ruta accesible deben probarse con quien usa silla/ bastón, no en simulación | F2 y F4 |
| 11 | **Analítica de producto** | Qué rutas y espacios más se buscan ⇐ prioriza mejoras | F4 |
| 12 | **Presupuesto de impresión de QR** | Placas resistentes exteriores: es un costo real que no aparece en el backlog | F2/F3 |

## 7.5 Riesgos y mitigaciones

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| Alcance desbordado (panel + app + dron + IA) | Alta | Alto | Fases y «definición de terminado» por fase; el curso manda |
| Medios 360° demasiado pesados para datos móviles | Media | Medio | LODs, descarga Wi-Fi, «solo datos básicos» |
| QR impresos que dejan de resolver | Baja | **Crítico** | URIs inmutables + resolución de anclaje en la app + pruebas de compatibilidad |
| Sin acceso a horarios oficiales | Media | Medio | Carga manual temporal; el importador se prueba con datos simulados |
| Permisos de dron/tiempo de vuelo | Media | Medio | Empezar con ortophoto satelital libre; dron como fase independiente |
| Pérdida de datos (Neon/servicios) | Baja | Alto | PITR + respaldos diarios a R2 + paquetes inmutables |
| Tres personas + curso + grado | Alta | Alto | Automatizar todo lo automatizable (pipeline, CI); no manual en producción |
| Vercel/Neon límites gratuitos | Baja | Bajo | Medios en R2; monitorear consumo; plan de migración documentado |
| Privacidad en fotos/videos (personas) | Media | Alto | Regla de publicación: difuminar personas; dron sin identificar |

## 7.6 Presupuesto global estimado (proyecto completo)

| Rubro | Estimado |
|---|---|
| Servicios (Vercel, Neon, R2) | 0–5 USD/mes al inicio |
| Dominio (opcional) | ~12 USD/año |
| Placas QR (100 uds aprox.) | 100–300 USD según material |
| Dron (vuelos/permisos o servicio externo) | 150–800 USD por jornada/permiso |
| Impresión / presentación | según curso |

## 7.7 Decisiones abiertas

Véanse D1–D7 en el [índice del plan](README.md). Las tres que bloquean el arranque:

1. **D1 (monorepo):** decidir en la próxima reunión — sin esto no se puede crear `app/`.
2. **D4 (paquete SQLite preconstruido):** confirmar con el equipo para redactar bien TEC-04/TEC-05.
3. **D6 (horarios):** pedir el Excel a Coordinación desde ya (tiene tiempos burocráticos).

## 7.8 Siguiente paso inmediato (sugerido)

1. Presentar este plan al equipo (2 páginas: [índice](README.md) + esta hoja de ruta).
2. Hacer D1: PR de reorganización del repo (yo puedo prepararlo).
3. Arrancar F0: TEC-01 (proyecto Flutter) + TEC-04 v2 + primera versión del empaquetador.
4. Gerencia: solicitar el Excel de horarios y cotización de placas QR.
