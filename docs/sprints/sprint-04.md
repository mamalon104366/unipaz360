# Sprint 4 · Vertical slice de navegación con bloque piloto

**Objetivo:** conectar origen, cálculo del camino mínimo y plano real alineado para un bloque del Centro Santa Lucía; terminar todas las historias Must de Encontrar/Llegar que tengan datos suficientes.

**Estado/dependencias:** Sprint 3 aceptado; levantamiento INV-01 completo, aprobado y con grafo conexo; TEC-10 plano alineado; identificación de rutas accesibles confirmada si D-01 las elevó. Sin esta base no hay condición para completar ruta real: el equipo puede seguir con fixtures, pero solo contará como prueba técnica.

#### Historias y criterios de aceptación

| Historia | Criterios verificables |
|---|---|
| S4-01 · Elegir origen (HU-03) | **Como estudiante nuevo**, quiero elegir desde dónde salgo, **para** obtener una ruta pertinente. **Prioridad:** Must. **Dependencia:** S3 y vértices piloto. **Prueba:** cambiar origen mantiene destino; inválido e igual al destino se manejan. |
| S4-02 · Calcular camino (HU-04) | **Como estudiante nuevo**, quiero calcular el camino más corto a pie, **para** llegar al espacio. **Prioridad:** Must. **Dependencia:** grafo conexo y métrica acordada. **Prueba:** fixture con ruta conocida, igual origen/destino y sin camino. |
| S4-03 · Ver plano y ruta (HU-05) | **Como estudiante nuevo**, quiero ver el camino sobre el plano del bloque, **para** seguirlo en campus. **Prioridad:** Must. **Dependencia:** TEC-10 calibrado y HU-04. **Prueba:** referencias espaciales conocidas coinciden en Android; no usa línea fija demo. |
| S4-04 · Validar recorrido (INV-01) | **Como visitante**, quiero probar el flujo con datos reales del piloto, **para** confirmar que puedo llegar sin ayuda. **Prioridad:** Must. **Dependencia:** permiso y APK con paquete piloto. **Prueba:** medir tiempo, éxito y ayuda en modo avión; guardar muestra y resultado sin PII. |

#### Tareas técnicas

| ID | Tarea | Descripción técnica | Responsable o perfil | Prioridad | Dependencia | Entregable | Criterio de finalización |
|---|---|---|---|---|---|---|---|
| S4-T01 | Levantar bloque piloto | Completar archivos existentes con IDs/espacios/vértices/tramos/anclajes y horarios confirmados | PO + responsable campus + equipo | Must/bloqueante | Permiso y acceso | Dataset con fuente/fecha | Responsable confirma correspondencia; sin datos inventados |
| S4-T02 | Calibrar plano | Registrar puntos de referencia y transformación coordenada→imagen | Developer 1 + campo | Must | Plano y mediciones | Plano alineado TEC-10 | Referencias medidas coinciden dentro de tolerancia que el equipo documenta |
| S4-T03 | Empaquetar piloto | Ejecutar reglas, corregir bloqueos y generar SQLite/manifest/hash versionado | Developer 2 | Must | T01/T02 | Paquete reproducible | Validador sale sin errores; prueba de paquete verde |
| S4-T04 | Calcular rutas | Conectar selector/origen y algoritmo a datos locales | Developer 1 | Must | S3 y T01 | Servicio de camino mínimo | Casos de ruta conocida, igual origen y sin conexión pasan |
| S4-T05 | Dibujar camino | Convertir geometría del camino a coordenadas de plano y renderizar por nivel/escala | Developer 2 | Must | T02/T04 | Capa de ruta funcional | Puntos de control se alinean en los tamaños de pantalla objetivo |
| S4-T06 | Validar en campo | Recorrer rutas con responsable y registrar discrepancias de paso/obstáculo | Equipo + campus | Must | APK y piloto | Acta de recorrido | Discrepancias críticas corregidas; accesibilidad verificada solo si se inspecciona |

**Entregables:** paquete piloto versionado, validación reproducible, origen, ruta calculada y plano alineado para los destinos de alcance, registro de prueba de campo.

**Validación/evidencia:** pruebas de algoritmo en grafo conocido; prueba de desconectado; validación de paquete; capturas de lista/ficha/origen/ruta (con SHA y dispositivo identificado); ejecución en modo avión y contraste de al menos una ruta en campo.

**Aceptación del sprint:** las rutas aceptadas son derivadas del grafo y verificadas en el campus; ninguna pantalla rotula como “accesible” un tramo no inspeccionado; búsqueda + cálculo se mide; defectos críticos de orientación bloquean aceptación. **DoD Sprint 4:** análisis, tests, CI, revisión de código, APK Android y modo avión; datos en `../../datos/piloto/` con procedencia documentada.

---

Plan derivado de [11-planificacion-sprints.md](../plan/11-planificacion-sprints.md), sección 4. Las actividades aquí descritas son planificadas; no representan trabajo completado.
