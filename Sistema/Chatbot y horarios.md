---
tags: [unipaz360, sistema, chatbot]
---
# Chatbot y horarios

> [!todo] Plan para construirlo (noviembre de 2026)
> El paso a paso del motor de rutas, el asistente y su conexión con la plataforma está en [[Plan de trabajo - guía y chatbot]]. El chatbot **nunca usa la red**.

> «Una IA súper low que haga cosas básicas y funcione sin internet». Traducción correcta: **motor de intenciones + reglas + búsqueda difusa**, 100 % offline, predecible y testeable. Detalle extenso: `docs/plan/06-chatbot-y-horarios.md`.

## Principio de diseño

| Pregunta del estudiante | Sistema que responde |
|---|---|
| «¿Dónde es Cálculo I?» | Horarios + espacios + normalizador |
| «¿Dónde queda el aula 305?» | Buscador (HU-01) |
| «Llévame a la biblioteca» | Buscador + motor de rutas |
| «¿A qué hora es la próxima clase de Redes?» | Horarios |
| «¿Hay baños cerca?» | POI por categoría + distancia sobre el grafo |
| Otras | Reserva + sugerencias de lo que sí sabe hacer |

**Por qué reglas y no un LLM en el teléfono:**
- Funciona sin internet de verdad (sin excepciones).
- Ligero (~30 KB, no 300 MB).
- Predecible y auditable: se corrige una regla, no se «reentrena».
- Empaquetado en el paquete de datos ⇒ editable a futuro desde el panel.

## Arquitectura del motor

```
Texto → Normalizar (tildes, abreviaturas) → Intención (reglas + palabras clave)
      → Entidades: espacio · materia · día/hora · categoría
      → Resolver contra la base (FTS5 + difusa): "calculo 1" → materia; "305" → espacio
      → ¿Falta un dato? → pregunta de seguimiento
      → Respuesta + chips: [Ver ficha] [Llévame] [Ver horario]
```

- **Intenciones v1:** buscar espacio · ruta a espacio · horario de materia · mi horario · categoría cercana · ayuda (en YAML dentro del paquete).
- **Sinónimos:** «baño»=«servicio», «aula»=«salón», bloques («B3», «bloque 3», «bloque de informática»).
- **Difusa:** tolera 1-2 errores de escritura («calculoi» → «Cálculo I»).
- **Umbral de confianza:** si no está seguro ⇒ «¿Es alguno de estos?» (chips), nunca inventa.

## Diálogo de ejemplo (prueba dorada)

```text
Usuario: ¿dónde es cálculo?
Bot: Veo dos: «Cálculo I» (Ing. Informática, B3-305) y «Cálculo II» (Electrónica, B2-201). ¿Cuál buscas?
Usuario: cálculo 1
Bot: Cálculo I es en el Bloque 3, piso 2, Aula 305. Hoy: 10:00–12:00.
     [Ver ficha] [Llévame] [Ver horario]
Usuario: llévame
Bot: ¿Desde dónde sales?
Usuario: [portería principal]
Bot: Ruta lista: 4 min (280 m) ✓ sin escaleras disponible. [Abrir mapa]
```

## Horarios: del Excel de Coordinación al chatbot

Campos del `HORARIO`: espacio · día · hora inicio/fin · materia · programa · semestre · grupo · docente (opcional).

1. Coordinación entrega Excel/CSV ⇒ se importa en el panel (vista previa + detección de choques).
2. Salones del Excel que no existen en el mapa ⇒ fila en rojo para corregir.
3. Al publicar, los horarios van en el paquete ⇒ app y chatbot los usan sin conexión.
4. «Mi horario»: el estudiante elige **programa + semestre (+ grupo)** una vez; se guarda local.

> **Quién ve los horarios (decidido):** los horarios de salones y el calendario académico se muestran **solo con sesión institucional** (`@unipaz.edu.co`). El invitado usa el resto de la app (mapa, rutas, 360°, chatbot de rutas) sin cuenta. Ver [[Cliente Flutter]] y [[Datos y publicación]].

**Consultas que debe resolver:**
- «¿Dónde es la clase de {materia} de {semestre}?» ⇒ espacio + horario + botón ruta.
- «¿Cuál es mi próxima clase?» ⇒ cuándo, dónde y ruta desde el último QR.
- «¿A qué hora termina {materia}?».
- «¿Hay clase el {fecha}?» ⇒ calendario académico (festivos, fin de semestre).

## Qué NO hace (para dejarlo claro)

- No conversa de temas abiertos (no es ChatGPT; no hay modelo de lenguaje).
- No inventa: si no está en la base ⇒ lo dice y ofrece reportar.
- No guarda conversaciones (privacidad).

## Evolución (con bandera de función)

| Nivel | Qué añade | Cuándo |
|---|---|---|
| v1 | Reglas + FTS5 + difusa | Ya |
| v2 | Más intenciones editables desde el panel | Tras usarla con usuarios reales |
| v3 | Embeddings pequeños on-device | Solo si v1 no alcanza |
| v4 | LLM en línea (opcional, con permiso) | Con presupuesto de API |

> **Firme:** construir v1 y medir. Guardar las frases no entendidas; esos datos deciden si vale subir de nivel.

Volver a [[00 Sistema - Índice]] · [[00 UniPaz360 - Índice]]
