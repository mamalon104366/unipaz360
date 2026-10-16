# 6 · Chatbot offline y horarios

> «Una IA súper low que haga cosas básicas y funcione sin internet». Traducción correcta: **un motor de intenciones + reglas + búsqueda difusa**, 100 % offline, predecible y testeable. Nada de modelos pesados: para preguntas de campus, las reglas ganan.

## 6.1 Principio de diseño

| Pregunta del estudiante | Sistema que responde |
|---|---|
| «¿Dónde es Cálculo I?» | Horarios + espacios + normalizador |
| «¿Dónde queda el aula 305?» | Buscador (mismo que HU-01) |
| «Llévame a la biblioteca» | Buscador + motor de rutas |
| «¿A qué hora es la próxima clase de Redes?» | Horarios |
| «¿Hay baños cerca?» | POI por categoría + distancia sobre el grafo |
| «No entiendo nada» / otras | Respuesta de reserva + sugerencias («puedo buscar un salón, calcular una ruta, ver tu horario…») |

**Por qué reglas y no un LLM en el teléfono:**
- Funciona sin internet de verdad (sin excepciones).
- Ligero (el motor pesa ~30 KB, no 300 MB).
- Predecible y auditable: si responde mal, se corrige una regla, no se «reentrena».
- Multilenguaje y empaquetado en el propio paquete de datos (editable a futuro desde el panel).

## 6.2 Arquitectura del motor

```
Texto del usuario
   │
   ├─ Normalizar (minúsculas, quitar tildes, expandir abreviaturas: "ulf"→"biblioteca"? no: "lab"→"laboratorio")
   ├─ Detectar intención (reglas + palabras clave ponderadas)
   ├─ Extraer entidades: espacio · materia · día/hora · categoría · lugar
   ├─ Resolver entidades contra la base (FTS5 + difusa): "calculo 1" → materia; "305" → espacio
   ├─ Si falta un dato → pregunta de seguimiento (diálogo de varios turnos)
   └─ Ejecutar acción: responder dato + chips («Ver ficha», «Llevarme», «Ver horario»)
```

**Intenciones v1 (YAML del paquete):**
```yaml
- id: buscar_espacio
  ejemplos: ["dónde es {}", "dónde está {}", "cómo llego a {}", "ubicación de {}"]
- id: ruta_a_espacio
  ejemplos: ["llévame a {}", "cómo llego a {}", "quiero ir a {}"]
- id: horario_materia
  ejemplos: ["a qué hora es {}", "cuándo es {}", "qué salón tiene {}"]
- id: mi_horario
  ejemplos: ["mi horario", "qué clase tengo hoy", "mi próxima clase"]
- id: categoria_cercana
  ejemplos: ["dónde hay {} cerca", "baño más cercano", "cafetería más cercana"]
- id: ayuda
  ejemplos: ["ayuda", "qué puedes hacer", "no entiendo"]
```

- **Palabras clave y sinónimos** por categoría: «baño» = «servicio», «SS»; «aula» = «salón», «salón de clases»; nombres de bloque («B3», «bloque 3», «bloque de informática»).
- **Corrección difusa:** distancia de edición tolerante (1-2 letras). «calculoi» → «Cálculo I».
- **Preguntas de seguimiento:** «¿Cuál cálculo?» (lista de coincidencias con chips), «¿Desde dónde sales?» (lista de QR/referencias).
- **Confianza:** si la mejor coincidencia está por debajo del umbral ⇒ respuesta honesta: «No estoy seguro de a qué te refieres. ¿Es alguno de estos?».
- **Acciones conectadas:** las respuestas pueden traer acciones que abren pantallas (`abrirFicha(id)`, `abrirRuta(de, a)`, `abrirHorario(programa, semestre)`).

## 6.3 Dialogos de ejemplo (pruebas doradas)

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

```text
Usuario: qué clase tengo ahorita
Bot: Si no me has cargado tu horario aún: «Cuéntame tu programa y semestre y te lo muestro».
 (tras configurarlo) → «Ingeniería Informática · VIII: Bases de Datos, B3-401, hasta las 16:00. [Llévame]»
```

## 6.4 Horarios: del Excel de Coordinación al chatbot

**Campos del `HORARIO`** (ver [03-datos](03-datos-y-publicacion.md)):

| Campo | Ejemplo |
|---|---|
| `espacio_id` | B3-305 |
| `dia` | lunes…sábado |
| `hora_inicio` / `hora_fin` | 10:00 / 12:00 |
| `materia` | Cálculo I |
| `programa` / `semestre` / `grupo` | Ing. Informática / 1 / A |
| `docente` (opcional) | Ing. Gómez |

**Flujo:**
1. Coordinación entrega Excel/CSV oficial ⇒ se importa en el panel (con vista previa y detección de choques: mismo salón, mismo día, franjas superpuestas).
2. El panel normaliza nombres de espacios (si un salón del Excel no existe ⇒ fila marcada en rojo para corregir el mapa o el dato).
3. Al publicar, los horarios van en el paquete ⇒ app y chatbot los usan sin conexión.
4. «Mi horario»: el estudiante elige **programa + semestre (+ grupo)** una vez; se guarda localmente. (No hay cuentas personales en la app; opcionalmente se sincroniza con la cuenta institucional si el proyecto crece.)

**Consultas que el chatbot debe resolver (criterios de aceptación):**
- «¿Dónde es la clase de {materia} de {semestre}?» ⇒ espacio + horario + botón de ruta.
- «¿Cuál es mi próxima clase?» ⇒ si hay horario configurado: cuándo, dónde y ruta desde el último QR.
- «¿Qué hay en el salón {id} ahora?» (opcional docente: para saber si puede entrar).
- «¿A qué hora termina {materia}?».

## 6.5 Qué NO hace (para dejarlo claro con los profesores)

- No conversa de temas abiertos (no es ChatGPT; no hay modelo de lenguaje).
- No inventa: si no está en la base, responde que no lo sabe y ofrece reportar el dato faltante.
- No guarda las conversaciones en el paquete (privacidad); estadísticas agregadas solo si se activan.

## 6.6 Evolución opcional (más adelante, todo con bandera de función)

| Nivel | Qué se añade | Cuándo tiene sentido |
|---|---|---|
| v1 (actual) | Reglas + FTS5 + difusa | Ya |
| v2 | Más intenciones y diálogos editables desde el panel | Tras usar v1 con usuarios reales |
| v3 | Embeddings pequeños on-device (cuantizados) para sinónimos y similares | Solo si v1 no alcanza con preguntas reales |
| v4 (en línea, opcional) | Si hay internet y el usuario acepta: LLM con contexto del campus para preguntas abiertas | Cuando haya presupuesto de API |

> Recomendación firme: **construir v1 y medir**. Guardar (local y agregado) las frases que el motor no entendió; ese listado decide si vale la pena subir de nivel. Sin datos, cualquier decisión de «IA» es adivinar.
