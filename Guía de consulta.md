---
tags: [unipaz360, indice, guia]
---
# Guía de consulta

Cómo está organizada esta base y cómo usarla (también la uso yo, Claude, para no olvidar nada del proyecto).

## Carpetas
| Carpeta | Qué hay |
|---|---|
| `Proyecto/` | Notas del documento de UniPaz360 + [[Documento original (docx)]] completo |
| `Conceptos/` | Funciones, decisiones técnicas y contexto (Flutter, grafo, QR, accesibilidad…) |
| `Antecedentes/` | Los 9 trabajos del [[Estado del arte]] |
| `Tesis ejemplo/Fichas/` | 1 ficha por tesis de ejemplo de UNIPAZ (81) |
| `Tesis ejemplo/{Directores, Temas, Modalidades, Tecnologías y métodos}/` | Nodos que conectan las fichas entre sí |
| `convertido md/` | Texto completo de cada tesis (convertido del PDF con MarkItDown) |

| `Guía de tesis/` | Cómo se escribe cada sección de una tesis UNIPAZ (estudio de las 81) + [[Plan de mejora UniPaz360]] |
| `Sistema/` | Plan técnico completo del sistema: cliente Flutter + plataforma de administración + datos (empieza en [[00 Sistema - Índice|Sistema — Índice]]) |

## Preguntas frecuentes → dónde mirar
- ¿Cómo se escribe la sección X? → [[Guía de tesis - Índice]]
- ¿Qué le falta a nuestro documento y en qué orden? → [[Plan de mejora UniPaz360]]
- ¿Qué secciones me faltan? → [[Estructura típica de tesis UNIPAZ]] · [[Pendientes y observaciones]]
- ¿Quién ha hecho algo parecido en UNIPAZ? → [[Tesis ejemplo - Índice]] (sección ⭐) · [[Sistemas para UNIPAZ]]
- ¿Qué directores dirigen apps? → [[Aplicaciones móviles]] y luego el director de cada ficha
- ¿Cómo redactan el marco legal, la metodología, etc.? → abrir el texto completo de una ficha modelo ([[T63073]], [[T63039]], [[T63035]])
- ¿Quién usó Flutter, Scrum o encuestas? → [[Flutter]] · [[Scrum]] · [[Encuesta]]
- ¿Cómo será el sistema completo (app, panel, publicación, chatbot)? → [[00 Sistema - Índice|Sistema — Índice]]

## Vista de grafo
Abrir con `Ctrl + G`. Colores: proyecto (rojo), guía de tesis (verde azulado), conceptos (naranja), antecedentes (amarillo), fichas de tesis (azul), directores (verde), temas/modalidades/tecnologías (morado). Los textos completos de `convertido md` se ocultan del grafo para que no lo saturen.

## Regenerar (si llegan más PDF)
En `C:\Users\mamalon\Pictures\univerrsidadaddadada`:
1. Poner los PDF en `ejemplos/`
2. `.venv\Scripts\python.exe convertir_pdfs.py` → `convertido md/`
3. `.venv\Scripts\python.exe extraer_metadatos.py` y `.venv\Scripts\python.exe tecnologias.py`
4. Clasificar las nuevas en `generar_obsidian.py` (diccionario `T`) y ejecutarlo

Volver a [[00 UniPaz360 - Índice]]
