---
tags: [unipaz360, proyecto, entregable, evaluacion-de-proyectos]
---
# Formulación y evaluación del proyecto (asignatura 910802)

Entregable de la asignatura **910802 Formulación y Evaluación de Proyectos**, hecho el 2026-10-09 sobre la plantilla del curso **FEP-01-F-01** (se conservaron todos sus títulos, el encabezado y la portada). Población: **comunidad universitaria y visitantes**. Coherente con el [[Avance documental (oct-2026)]]: mismos objetivos, presupuesto conciliado y la misma arquitectura.

## Archivos (carpeta `C:\Users\mamalon\Pictures\univerrsidadaddadada\curso_formulacion\entregables\`)
- `UniPaz360 - Formulación y evaluación del proyecto.docx` / `.pdf`: 83 páginas, 64 tablas y 19 figuras en APA 7, con bibliografía en APA.
- `UniPaz360 - Modelo financiero y de planificación.xlsx`: 20 hojas con fórmulas reales y nombres definidos, cero celdas con error. Las celdas azules son supuestos editables.
- `Diccionario_EDT_UniPaz360.xlsx`: los 18 paquetes de trabajo sobre la plantilla del curso, más una hoja Resumen EDT. El control total − CAPEX da 0.
- `graficos/`: gráficos exportados del Excel. `figuras/`: EDT, UML, BPMN, PERT, Gantt, mapa de riesgos e interesados.

## Cifras clave (pesos de 2026)
| Indicador | Valor |
|---|---|
| CAPEX | $25.787.000 (85 % en especie; desembolso $3.867.000 con imprevistos de $184.000) |
| OPEX anual | $4.148.000 (2,4 SMMLV) |
| VAN social (9 %, DNP) | $23.817.792 |
| TIR social | 38,9 % |
| B/C | 1,57 |
| PRI simple / descontado | 2,16 / 2,48 años |
| VAN financiero (12 %) | −$28.115.740 (bien público; la TIR financiera no existe) |
| CAE / costo por usuario | $10.777.643 / $1.707 por usuario al año |
| Adopción de equilibrio | 37,7 % (prevista: 75 %) |
| PERT | 30,8 semanas; ruta crítica A-C-D-F-H-J-K-L-O-P-Q-R; P(≤ 8 meses) = 99,95 % |
| Riesgos | 0 altos, 7 medios, 3 bajos; VME $1.167.100 (en efectivo $509.600) → reserva de gestión de $325.600 |

**Conciliación con el avance:** $32.807.000 − $25.787.000 = $7.020.000. La diferencia viene de valorar los equipos existentes por su costo de uso ($1.080.000) y no por su precio ($8.100.000), según la regla de costos relevantes de Sapag.

## Cómo regenerarlo
Los scripts están en `curso_formulacion/build/` y todos los datos salen de una sola fuente: `datos.py` (números) y `datos2.py` (textos de MML, riesgos, interesados y requerimientos).
1. `python excel.py`, luego `recalc.ps1 -In <xlsx> -ChartsDir <graficos>`. Este paso recalcula en Excel y exporta los gráficos en alta resolución y el tablero.
2. `python figuras.py`
3. `python word.py`, luego `finalizar.ps1 -Docx <docx>`. Word actualiza la tabla de contenido y exporta el PDF.
4. `python diccionario.py`

Los textos del Word están en `textos1.py` (capítulos 1 a 3), `textos2.py` (capítulos 4 a 6) y `textos3.py` (capítulos 7 a 11).

## Pendientes antes de entregar
- [ ] Nombre del **docente** (resaltado en amarillo en la portada).
- [ ] Revisar la **fecha del encabezado** (09/10/2026).
- [ ] Validar los supuestos de beneficios con datos reales: población 2026, consultas diarias en porterías y visitantes.

Volver a [[00 UniPaz360 - Índice]]
