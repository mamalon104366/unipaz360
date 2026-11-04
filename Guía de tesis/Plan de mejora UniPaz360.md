---
tags: [unipaz360, guia-tesis, pendiente]
---
# Plan de mejora UniPaz360

Diagnóstico del [[Documento original (docx)]] comparado con las 81 tesis de ejemplo ([[Guía de tesis - Índice]]).

## 1. Diagnóstico por sección
| Sección | Estado | Frente a las tesis de ejemplo | Acción | Prioridad |
|---|---|---|---|---|
| Portada y preliminares | Incompleta | — | Corregir "FRENANDEZ", llenar director y codirector; luego resumen y abstract | 🔴 |
| Planteamiento | ✅ Bueno | Mejor que la mayoría (4 limitaciones técnicas) | Añadir contexto macro con cifra, evidencia propia y árbol de problemas | 🟡 |
| Pregunta | ✅ Buena | Sigue la fórmula correcta | Ajustar si cambian los objetivos | 🟢 |
| Justificación | ✅ Buena | Buen argumento, pero sin datos | Añadir datos, misión de UNIPAZ y línea de investigación | 🟡 |
| Objetivos | ✅ Bien encaminados | Patrón diagnóstico → diseño → desarrollo → evaluación | Agregar "mediante…" y la ruta accesible (ver §2) | 🟡 |
| Estado del arte | ⭐ Excelente | **Superior al 90 % de las tesis** | Citar T63039 (y T63047) y reformular la constatación 4 | 🔴 |
| Marco teórico | ❌ Falta | Lo tiene el 82 % | Escribirlo con los temas de [[Cómo escribir - Marco referencial]] | 🔴 |
| Marco conceptual | ❌ Falta | 82 % | Glosario de 15–20 términos citados | 🟡 |
| Marco legal | ❌ Falta | 86 % | Tabla Norma \| Descripción \| Pertinencia | 🟡 |
| Marco contextual | ❌ Falta | — | Ubicación y mapa de Santa Lucía, área, bloques | 🟢 |
| **Diseño metodológico** | ❌ **Falta** | **91 %; es el capítulo más evaluado** | Ver §3 | 🔴🔴 |
| Cronograma y presupuesto | ❌ Faltan | Los anteproyectos recientes los traen | Ver [[Cómo escribir - Cronograma y presupuesto]] | 🟡 |
| Citas y bibliografía | ✅ ICONTEC correcto | 14 referencias (mediana de los PG: 23) | Subir a 30 o más con libros y artículos recientes | 🟡 |
| Tabla de contenido | ⚠️ Desactualizada | — | Regenerarla | 🔴 (5 minutos) |

## 2. Objetivos: propuesta de redacción (para discutir con el director)
**General:** Desarrollar una aplicación multiplataforma en Flutter que permita localizar espacios, calcular rutas peatonales —incluidas rutas accesibles para personas con movilidad reducida— sin conexión a internet y realizar recorridos virtuales, con el fin de facilitar la orientación y el reconocimiento de las instalaciones del Centro de Investigaciones Santa Lucía de UNIPAZ.

**Específicos:**
1. **Diagnosticar** las necesidades de orientación de estudiantes, docentes, personal administrativo y visitantes, y **caracterizar** los espacios, accesos y tramos del Centro de Investigaciones Santa Lucía, mediante encuestas, entrevistas y levantamiento en campo, para establecer los requerimientos funcionales y no funcionales de la aplicación.
2. **Diseñar** la arquitectura, el modelo de datos del grafo del campus y la interfaz de la aplicación mediante prototipos en Figma, para organizar la consulta de espacios, rutas y recorridos virtuales.
3. **Desarrollar** la aplicación en Flutter con la metodología ágil Scrum, integrando la búsqueda de espacios, el cálculo de rutas sin conexión sobre el grafo del campus (Dijkstra o A\*), el modo de ruta accesible, la lectura de códigos QR como punto de origen y el recorrido virtual.
4. **Evaluar** la aplicación mediante pruebas funcionales y pruebas de usabilidad con estudiantes y visitantes (tareas de orientación cronometradas y cuestionario SUS), para verificar el cumplimiento de los requerimientos establecidos.

## 3. Propuesta de diseño metodológico
- **Enfoque mixto.** Cuantitativo: encuesta diagnóstica, puntaje SUS, tiempos y tasas de éxito. Cualitativo: entrevistas a portería, secretarías y Bienestar, y observación. Se justifica igual que en [[T63047 - App GPS transporte UNIPAZ (GPAZ)|T63047]].
- **Tipo:** investigación aplicada de desarrollo tecnológico. **Alcance:** descriptivo.
- **Población:** comunidad que usa el campus Santa Lucía. Dato de referencia: **5.016 personas en 2024** (4.686 estudiantes y 330 docentes/administrativos, según Registro y Control Académico, citado en [[T63039 - Tour virtual 360° Centro de Investigaciones Santa Lucía|T63039]]). ➜ **Pedir el dato actualizado de 2026.** Los visitantes y aspirantes son una población no cuantificable.
- **Muestra 1, diagnóstico:** fórmula de poblaciones finitas (95 %, e = 5 %), que para N = 5.016 da ≈ 357, con **selección aleatoria estratificada** (por semestre o programa). Alternativa honesta: muestreo por conveniencia declarado como tal.
- **Muestra 2, usabilidad:** 15–20 participantes (estudiantes de primer semestre y visitantes) por conveniencia, justificado con Nielsen y Landauer (1993) y Tullis y Stetson (2004).
- **Técnicas e instrumentos** (validados por juicio de 3 expertos y una prueba piloto; con consentimiento informado por la Ley 1581 de 2012):
  - Cuestionario Likert diagnóstico.
  - Guía de entrevista semiestructurada.
  - **Ficha de levantamiento de espacios y tramos** (nodo, tipo, piso, coordenadas, escalera o rampa, pendiente, iluminación).
  - Matriz de casos de prueba.
  - Protocolo de tareas de orientación (por ejemplo: "desde portería, llegar al laboratorio X").
  - **Cuestionario SUS.**
- **Ficha técnica del estudio** en tabla, como en [[T63007 - App web semilleros de investigación UNIPAZ|T63007]].
- **Metodología de desarrollo:** **Scrum adaptado a un equipo de 2 personas**, justificado como en [[T63073 - App Saber Pro UNIPRO (UNIPAZ)|T63073]]. El director o un representante de UNIPAZ hace de *Product Owner*, el rol de *Scrum Master* rota entre los dos y hay sprints de 2 semanas.

| Fase | Objetivo | Actividades | Técnica / instrumento | Entregable |
|---|---|---|---|---|
| 1. Diagnóstico | OE1 | Encuesta, entrevistas, recorrido de campo y levantamiento de nodos y tramos | Cuestionario, guía de entrevista, ficha de levantamiento | Requerimientos (ISO/IEC/IEEE 29148), inventario de espacios, grafo preliminar |
| 2. Diseño | OE2 | Arquitectura *offline-first*, modelo de datos, prototipo y validación rápida con 5 usuarios | Figma, prueba de prototipo | Documento de diseño, prototipo navegable |
| 3. Desarrollo | OE3 | Sprints: S1 mapa y búsqueda · S2 grafo y algoritmo de rutas · S3 ruta accesible · S4 códigos QR · S5 recorrido virtual · S6 estabilización en Android, iOS y escritorio | Product backlog, sprint reviews | Incrementos funcionales, repositorio Git, instaladores |
| 4. Evaluación | OE4 | Pruebas funcionales; tareas de orientación en el campus; SUS | Matriz de casos de prueba, protocolo de tareas, SUS | Informe de pruebas, puntaje SUS, tiempos y tasas de éxito |

- **Análisis de datos:** estadística descriptiva; puntaje SUS (umbral de 68); tiempo medio y tasa de éxito por tarea. Opcional: comparar **con app vs. sin app** (prueba t o Wilcoxon), lo que daría el nivel de rigor de [[T63029 - Software educativo con RA sistema óseo|T63029]].

## 4. Orden de trabajo sugerido
1. Arreglos rápidos: tabla de contenido, "FRENANDEZ", director y codirector.
2. Citar T63039 y T63047 en el estado del arte y ajustar la síntesis del vacío.
3. **Escribir el diseño metodológico** (§3) y la matriz de coherencia (anexo).
4. Escribir los marcos teórico, conceptual, legal y contextual.
5. Hacer el cronograma y el presupuesto.
6. Aplicar la encuesta diagnóstica y meter sus datos en el planteamiento y la justificación.
7. Al final: introducción, resumen y abstract, y revisar contra [[Errores que el jurado detecta]].

Volver a [[Guía de tesis - Índice]] · [[Pendientes y observaciones]]
