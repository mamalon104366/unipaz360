---
tags: [guia-tesis]
---
# Cómo escribir - Diseño metodológico

Es el capítulo **más largo y más evaluado**: mediana ≈1.540 palabras en los proyectos de grado. Estructura típica (casi todos citan a Hernández Sampieri para enfoque, tipo y alcance):

| Apartado | Qué poner | Lo que hacen las tesis |
|---|---|---|
| Enfoque | Cuantitativo, cualitativo o **mixto**, justificado | Cuantitativo 16 · cualitativo 11 · mixto 8. [[T63047 - App GPS transporte UNIPAZ (GPAZ)|T63047]] justifica bien el mixto: encuestas para la necesidad, entrevistas para la aceptación |
| Tipo de investigación | **Aplicada / desarrollo tecnológico** | Aplicada 12 · descriptiva 9 · tecnológica 8 |
| Alcance | Descriptivo (a veces exploratorio) | Casi siempre "descriptivo según Hernández Sampieri" |
| Población | Quiénes y cuántos, **con fuente** | [[T63039 - Tour virtual 360° Centro de Investigaciones Santa Lucía|T63039]]: 5.016 personas en 2024 (4.686 estudiantes y 330 docentes/administrativos), según Registro y Control Académico |
| Muestra | Tamaño y forma de selección | 15 de 23 usan la fórmula para poblaciones finitas |
| Técnicas e instrumentos | Encuesta, entrevista, observación, pruebas | Encuesta 17 · entrevista 13 · observación 11 |
| Fuentes | Primarias y secundarias | [[T63007 - App web semilleros de investigación UNIPAZ|T63007]] lo resume en una **"Ficha técnica del estudio"** (tabla): idea excelente |
| Metodología de desarrollo | Scrum, cascada, Design Thinking, IWeb, Galvis Panqueva, RUP… con sus fases | [[T63073 - App Saber Pro UNIPRO (UNIPAZ)|T63073]] usa **Scrum adaptado a un equipo de 2 personas**, justificado |
| Fases y actividades | Qué se hace en cada fase **para cada objetivo** | [[T63039 - Tour virtual 360° Centro de Investigaciones Santa Lucía|T63039]]: análisis → diseño → programación → pruebas → entrega |
| Materiales y recursos | Humanos, físicos y técnicos | T63039, tabla 14 |

## La fórmula de la muestra (poblaciones finitas)
n = N·Z²·p·q / [e²·(N−1) + Z²·p·q], con Z = 1,96 (95 %), p = q = 0,5 y e = 0,05.
Para N = 5.016 da n ≈ 357, igual que T63039.

⚠️ **Coherencia:** si se usa la fórmula (muestreo probabilístico), la selección debe ser **aleatoria** (simple o estratificada por semestre o programa). T63039 calculó 357 y luego dice que eligió "de manera estratégica"; eso es una contradicción que un jurado señala. Si no se puede sortear, hay que declarar **muestreo no probabilístico por conveniencia** y no presentar la fórmula como si definiera la selección.

## Evaluación de usabilidad: el hueco de todas las tesis
- **Ninguna de las 81 tesis usa SUS** (System Usability Scale, Brooke 1996: 10 ítems Likert, puntaje de 0 a 100, 68 es el promedio de referencia).
- Las pruebas de usabilidad no necesitan cientos de personas:
  - Para encontrar problemas basta con grupos pequeños (Nielsen y Landauer, 1993).
  - Para estimar el puntaje SUS con estabilidad se recomiendan unos 12–14 usuarios o más (Tullis y Stetson, 2004).
- Se combina con **tareas de orientación cronometradas**: tasa de éxito, tiempo y errores. Es lo mismo que midieron [[Tahir y Krogstie 2023 - Wayfinding en campus]] y conecta con el estado del arte.

## Plan de análisis de datos (casi nadie lo escribe y suma puntos)
- Estadística descriptiva: frecuencias, porcentajes, media y desviación estándar.
- Puntaje SUS, tasa de éxito por tarea y tiempo medio.
- Si hay comparación (con app / sin app): prueba t o Wilcoxon, como hizo [[T63029 - Software educativo con RA sistema óseo|T63029]] con la t de Student (p < 0,05).

## Ética
- Consentimiento informado por la Ley 1581 de 2012: el formato va como anexo.
- Validación de los instrumentos por **juicio de expertos** (2–3 docentes) más una **prueba piloto**.

## Aplicación a UniPaz360
Hoy el documento **no tiene diseño metodológico** y es lo que más pesa. La propuesta completa (enfoque mixto, investigación aplicada, población, dos muestras, instrumentos, Scrum por fases y tabla Fase–Objetivo–Instrumento–Entregable) está en [[Plan de mejora UniPaz360]].

Volver a [[Guía de tesis - Índice]]
