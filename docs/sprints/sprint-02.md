# Sprint 2 · Requisitos, actores, eventos, flujos y arquitectura

**Objetivo:** dejar requisitos y arquitectura del MVP trazables y validados, resolver contradicciones de alcance y preparar trabajo implementable para el Sprint 3. El sprint no se acepta por crear más documentos: requiere revisión del PO y al menos una validación con usuario/representante disponible.

**Estado/dependencias:** los documentos `../plan/` y `./sprint-01.md` aportan base; el último describe Sprint 1 como investigación/prototipo, mientras que la rama `examen/sprint1-tecnico` contiene INV-04 técnico. Confirmar con docente cuál es la secuencia oficial de sprints. Depende de sincronizar el clon y de confirmar los Must del README. Depende del responsable del campus para datos del piloto; si no está disponible, registrar bloqueo y no fabricar ubicaciones.

#### Historias y criterios de aceptación

| Historia | Criterios verificables |
|---|---|
| S2-01 · Alcance (HU-S2-01) | **Como PO**, quiero fijar qué entra en la entrega y aclarar las diferencias entre examen, README y `main`, **para** que el equipo construya la versión que evaluará el curso. **Prioridad:** alta. **Dependencia:** revisión del docente/equipo. **Prueba:** acta que resuelve/eleva D-01 (HU-07), D-02 (sesión) y numeración de sprint; ninguna contradicción se oculta. |
| S2-02 · Criterios del recorrido (HU-S2-02) | **Como estudiante nuevo**, quiero que búsqueda, ficha, origen y ruta tengan resultados y errores definidos, **para** saber qué esperar al orientarme. **Prioridad:** alta. **Dependencia:** criterios Must vigentes. **Prueba:** revisión guiada que demuestra criterios de éxito, vacío, error, offline y Atrás para HU-01…05. |
| S2-03 · Contratos y eventos (HU-S2-03) | **Como desarrollador**, quiero conocer entradas, estados, salidas y errores de cada capa, **para** integrar UI, repositorio local y paquete sin acoplarlos. **Prioridad:** alta. **Dependencia:** HU-S2-02. **Prueba:** revisión por otro integrante de la tabla de eventos y contratos; cada error tiene respuesta observable. |
| S2-04 · Arquitectura actual/objetivo (HU-S2-04) | **Como equipo**, queremos separar lo existente de lo propuesto en frontend, dominio, persistencia y pipeline, **para** tomar decisiones técnicas justificadas. **Prioridad:** alta. **Dependencia:** auditoría de `main`. **Prueba:** diagramas revisados contra rutas/clases; no hay integración dibujada como terminada si no está probada. |
| S2-05 · Preparar piloto (HU-S2-05) | **Como visitante**, quiero que los nombres, ubicación y barreras de los espacios estén confirmados, **para** seguir indicaciones fiables. **Prioridad:** alta. **Dependencia:** permiso y responsable del campus. **Prueba:** plan de levantamiento aprobado o bloqueo explícito; nunca reemplazar datos reales por ubicaciones inventadas. |

#### Tareas técnicas

| ID | Tarea | Descripción técnica | Responsable o perfil | Prioridad | Dependencia | Entregable | Criterio de finalización |
|---|---|---|---|---|---|---|---|
| S2-T01 | Alinear clon | Comparar SHA local/remoto, historial y diferencias; preservar archivos no rastreados y crear rama desde base acordada | SM + revisor | Alta | Acceso GitHub | Registro de baseline y rama | Base/commit se acuerdan y evidencia previa permanece intacta |
| S2-T02 | Conciliar fuentes | Comparar README, tablero, docs de sprints/examen y registrar numeración/alcance oficial | PO | Alta | T01 | Acta de decisiones | Se anotan acuerdos, responsables y preguntas pendientes |
| S2-T03 | Definir requisitos | Refinar HU-01…05, actores, eventos y escenarios alternos | PO + developer | Alta | T02 | Historias trazables | Cada historia tiene criterio de aceptación y prueba |
| S2-T04 | Auditar navegación | Recorrer rutas Flutter y distinguir widget existente de flujo accesible integrado | Developer 1 | Alta | T01 | Informe con capturas/checks | Lista de rutas confirmada en código y en ejecución o marcada sin verificar |
| S2-T05 | Validar arquitectura | Documentar capas actuales/objetivo, paquete local, pipeline y CI; separar realidad de propuesta | Developer 2 | Alta | T03/T04 | `docs/arquitectura.md` | Revisión técnica y diagramas coherentes con el repo |
| S2-T06 | Resolver piloto/accesibilidad | Confirmar permiso de campo, responsable, límites de zona y decisión HU-07 | PO + equipo | Bloqueante para S4 | Campus/docente | D-01 y plan de campo o bloqueo | No se afirma ruta accesible ni datos reales sin validación |

**Entregables:** decisión de alcance; historias HU-01…05 listas y criterios; actores/eventos/flujos; arquitectura con límites actuales y propuestos; plan de levantamiento de piloto; tablero actualizado con dependencias.

**Validación/evidencia:** revisión PO; recorrido de prototipo con al menos estudiante nuevo/visitante si se puede convocar; minuta con observaciones sin identificadores personales; links de issues/PR; diagramas versionados. Si no se logra convocar usuario o campus, registrarlo como impedimento, no como prueba completada.

**Aceptación del sprint:** criterios y diagramas revisados por equipo; D-01 decidido o bloqueado con fecha/rol de resolución; no quedan historias Must sin definición de offline/errores; alcance oficial de Sprint 2 confirmado. **DoD Sprint 2:** artefactos fusionados por PR revisado, links coherentes, sin duplicar ni reemplazar evidencia previa, tablero refleja decisiones y bloqueos.

---

Plan derivado de [11-planificacion-sprints.md](../plan/11-planificacion-sprints.md), sección 4. Las actividades aquí descritas son planificadas; no representan trabajo completado.
