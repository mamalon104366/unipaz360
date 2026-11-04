---
tags: [unipaz360, proyecto, entregable]
---
# Avance documental (octubre de 2026)

Documento para entregar al profesor, generado el 2026-10-03 siguiendo [normasicontec.co](https://normasicontec.co/) y la [[Guía de tesis - Índice|guía aprendida de las 81 tesis]].

- **Archivo:** `C:\Users\mamalon\Pictures\univerrsidadaddadada\avance\UniPaz360 - Avance documental.docx` (y su `.pdf`)
- **Extensión:** 53 páginas · 16 tablas · 4 figuras · 94 notas al pie (ICONTEC, con Ibíd. y Op. cit.) · 63 referencias
- **Formato:** carta, Arial 12, interlineado sencillo, márgenes 3/3/3/2 cm, número de página centrado a 2 cm, títulos de capítulo en página nueva

## Estructura
Cubierta · portada · contenido · listas de tablas y figuras · resumen · abstract → Introducción · 1. Planteamiento (con árbol de problemas y preguntas de sistematización) · 2. Justificación · 3. Objetivos (reformulados según [[Plan de mejora UniPaz360]]) · 4. Alcance y delimitación (riesgos) · 5. Marco referencial (estado del arte con T63039 y T63047, marco teórico de 8 temas, conceptual, legal y contextual) · 6. Diseño metodológico (enfoque mixto, muestra n = 393, 24 participantes en usabilidad, Scrum con 6 sprints, indicadores ISO/IEC 25010 e ISO 9241-11, SUS) · 7. Cronograma · 8. Presupuesto ($32.807.000) · 9. Resultados esperados · Bibliografía · Anexos A–F (matriz de coherencia, cuestionario, entrevista, ficha de levantamiento, protocolo y SUS, consentimiento).

## Pendientes antes de entregar
- [ ] Llenar **director y codirector** (resaltados en amarillo en la portada).
- [ ] Confirmar el segundo apellido "FERNÁNDEZ" (el docx original decía "FRENANDEZ").
- [ ] Pedir a Registro y Control la **población 2026** y recalcular la muestra (hoy usa 5.016, dato de 2024).
- [ ] Revisar los valores del presupuesto y la vigencia de las normas citadas.
- [ ] Si se va a imprimir y empastar, cambiar el margen izquierdo a 4 cm.

## ⭐ Versión 2 (2026-11-04): plataforma de gestión y marco tecnológico

- **Archivo:** `C:\Users\mamalon\Downloads\UniPaz360 - Avance documental (v2).docx`. Tiene 60 páginas, 107 notas al pie y 12 referencias nuevas. El original quedó intacto.
- **Cambios** (alineados con [[Visión consolidada (nov-2026)]]):
  - **Título:** "…aplicación multiplataforma **y una plataforma de gestión de contenidos** para la orientación…" ⚠️ Confirmar con el director si se puede cambiar.
  - **Resumen y abstract:** un párrafo sobre la plataforma y una palabra clave nueva.
  - **Introducción y problema:** la condición de sostenibilidad (el contenido cambia y no debe depender de reprogramar la app).
  - **Pregunta, sistematización, objetivo general, OE2 y OE3:** incluyen la plataforma web que gestiona y publica el contenido.
  - **4.1 Alcance:** son cinco módulos; el quinto es la plataforma de gestión (nodos, tramos, 360°, edición no destructiva y puntos de información). El recorrido virtual toma como referencia la interfaz del tour de Unisabana. El aviso de actualización es [Actualizar ahora] / [Más tarde].
  - **4.2 Delimitación:** Android en horizontal, Windows y web; **iOS y macOS como límite**.
  - **Tabla 1:** se reescribió la fila de iOS y se agregó una fila de riesgo sobre los planes gratuitos en la nube.
  - **5.1.4:** nuevo antecedente, el **tour virtual de la Universidad de La Sabana** (XNOVA360), como referente de interfaz. **Tabla 2:** fila nueva, y UniPaz360 pasa a "Android, Windows y web".
  - **5.2.6:** edición no destructiva y puntos de información guardados como datos aparte (acimut y elevación).
  - **Tabla 3:** términos nuevos (plataforma de gestión, punto de información, publicación).
  - **🆕 5.4 MARCO TECNOLÓGICO** (5.4.1–5.4.8): Flutter 3.47 con Dart 3.13; sqflite 2.4.5, sqflite_common_ffi y sqflite_common_ffi_web 1.2.0; A* y Dijkstra propios; flutter_map 8.3; mobile_scanner 7.5 (en Windows el origen se elige a mano); **visor 360° propio** (panorama_viewer 3.0.0 se descartó porque solo funciona en Android e iOS); plataforma con Next.js, MapLibre GL JS, Photo Sphere Viewer, NeonDB, Cloudflare R2 y Vercel/Hostinger. **Legal pasa a ser el 5.5 y Contextual el 5.6.**
  - **6.5 y Tabla 6:** **8 sprints**. Primero P1 y P2 de la plataforma, luego S1–S6 de la app.
  - **Tablas 5, 7 y 8:** se actualizaron. Indicador nuevo: "Actualización de contenidos sin reinstalar, 100 %".
  - **Tabla 9 (cronograma):** P1–P2 en el mes 4, S1–S6 en los meses 5–7, pruebas funcionales en los meses 7–8 y usabilidad en el mes 8.
  - **Tabla 10 (presupuesto):** salen el iPhone y la cuenta de Apple; entran la nube (8 × $21.000) y el dominio ($50.000). **El total queda en $30.099.000.**
  - **Tabla 11:** producto nuevo, la plataforma. **Anexo A:** la matriz de coherencia quedó alineada.
- **Pendiente:** la **Figura 2** (componentes funcionales) es una imagen y debe redibujarse con el quinto módulo y la flecha plataforma → paquete → app.
- ⚠️ La v2 se editó **directamente sobre el .docx**. Los fuentes `contenido*.js` y `refs.js` de `avance/` **no tienen estos cambios**: si se regenera con `node build.js`, se pierden.

## Cómo regenerarlo
En `avance/`: editar `contenido1.js`, `contenido2.js` o `contenido3.js` (texto) o `refs.js` (referencias) → `node build.js` → `finalizar.ps1` (Word actualiza la tabla de contenido y exporta el PDF).

Volver a [[00 UniPaz360 - Índice]]
