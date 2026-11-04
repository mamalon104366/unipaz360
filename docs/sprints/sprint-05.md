# Sprint 5 · Sprint final: estabilización, aceptación y demostración

**Objetivo:** entregar un APK y paquete versionado reproducibles, integrar únicamente alcance aprobado que ya tenga dependencias resueltas, corregir bloqueadores y demostrar el MVP con usuarios. Este es el último sprint de este plan; no se abre otro sprint implícito.

**Estado/dependencias:** Sprint 4 cumple su aceptación y los casos Must funcionan con piloto. Si el grafo/plano o lista/ficha no han alcanzado ese punto, PO debe reducir alcance con docente o redefinir la entrega; no se marca “final” con mock.

#### Historias y criterios de aceptación

| Historia | Criterios verificables |
|---|---|
| S5-01 · Versión final en Android (HU-S5-01) | **Como equipo**, queremos instalar el APK con su paquete versionado y usarlo sin red, **para** demostrar el MVP. **Prioridad:** bloqueante. **Dependencia:** S4 aceptado. **Prueba:** flujo Must en modo avión en el dispositivo objetivo. |
| S5-02 · Recuperación (HU-S5-02) | **Como usuario**, quiero mensajes claros ante paquete ausente/corrupto o destino desconectado, **para** recuperarme sin indicaciones falsas. **Prioridad:** alta. **Dependencia:** S3/S4. **Prueba:** casos de daño y sin camino permiten corregir o salir sin cierre inesperado. |
| S5-03 · Aceptación (HU-S5-03) | **Como PO**, quiero medir tareas y tiempo con usuarios representativos, **para** conocer si se alcanza el objetivo de producto. **Prioridad:** alta. **Dependencia:** APK/piloto y consentimiento. **Prueba:** informar n, éxitos, necesidad de ayuda, tiempos y resultado ante 90 %/60 s. |
| S5-04 · Evidencia de entrega (HU-S5-04) | **Como docente/evaluador**, quiero localizar el APK, SHA, documentación y resultados, **para** reproducir la demostración. **Prioridad:** alta. **Dependencia:** checks finales. **Prueba:** checklist de demo completo y enlaces resuelven a artefactos reales. |

#### Tareas técnicas

| ID | Tarea | Descripción técnica | Responsable o perfil | Prioridad | Dependencia | Entregable | Criterio de finalización |
|---|---|---|---|---|---|---|---|
| S5-T01 | Congelar alcance | Resolver HU-07, sesión/login y Should; documentar exclusiones | PO + docente | Bloqueante | Evidencia de S4 | Acta de alcance | No quedan Must ambiguos ni Should presentados como terminados |
| S5-T02 | Estabilizar Android | Revisar permisos, lifecycle, Atrás, tamaños/semántica básica y errores offline | Developer 1 | Alta | S4 aceptado | APK candidato | Instala y completa casos de prueba sin defectos bloqueantes |
| S5-T03 | Congelar paquete | Regenerar desde fuente versionada y probar integridad/recuperación | Developer 2 | Alta | T01 y paquete piloto | Versión + manifest/hash | Hash/versiones coherentes; restauración/carga comprobada |
| S5-T04 | Verificar calidad | Ejecutar analyzer, tests, scripts, build Android y workflow del SHA final | SM + revisor | Bloqueante | T02/T03 | Registro de CI y salidas | Todo pasa; si hay falla queda corregida o entrega no se acepta |
| S5-T05 | Aceptar en dispositivo | Usar Android físico en modo avión para recorrer casos Must y alternos | Equipo | Bloqueante | APK/paquete final | Matriz de resultados y capturas autorizadas | Resultados registrados en el mismo SHA/version y sin red |
| S5-T06 | Preparar demo | Ensayar flujo, recuperación, restricciones y alternativa sin servicio externo | PO + equipo | Alta | T04/T05 | Guion, README y checklist | Demo se repite desde estado limpio y explica limitaciones |

**Entregables:** APK de demostración, commit/tag o release aprobado por el equipo, paquete con hashes, documentación, reporte de pruebas y checklist de demo.

**Validación/evidencia:** resultado CI asociado al SHA, salida `flutter analyze`, salida `flutter test`, salida de scripts, build APK, prueba real en modo avión, fotos/capturas de app con datos autorizados y tabla de resultados de usuario. No se publican rostros, nombres ni ubicaciones sensibles sin consentimiento.

**Aceptación final:** todas las Must que el PO haya mantenido en alcance pasan sus criterios; APK no depende de servicios en red para navegación; paquete reproduce la misma experiencia; objetivos de 90 %/60 s se reportan con muestra y limitaciones. Si objetivo no se cumple, declarar incumplimiento y causa; no afirmar que pasó.

**DoD final:** código fusionado por PR revisado; CI verde en commit de entrega; análisis y tests verdes; APK instalado físicamente y probado offline; datos piloto aprobados y rastreables; errores conocidos documentados; material de demo y evidencias vinculados; aceptación explícita PO/docente.

---

Plan derivado de [11-planificacion-sprints.md](../plan/11-planificacion-sprints.md), sección 4. Las actividades aquí descritas son planificadas; no representan trabajo completado.
