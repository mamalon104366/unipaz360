# Datos de ejemplo

Campus **ficticio y mínimo** que sirve para tres cosas:

1. **Probar el pipeline** sin depender del levantamiento real: `scripts/validar.mjs` y `scripts/empaquetar.mjs`.
2. **Probar la app** con un paquete real (espacios, rutas, horarios, calendario).
3. **Correr en el CI** de forma determinista.

> Las coordenadas, materias y docentes son inventados. El campus real se levanta
> en `datos/piloto/` (INV-01).

## Archivos

| Archivo | Filas |
|---|---|
| `campus.csv` | 1 campus |
| `vertices.csv` | 7 vértices (portería, cruces, puertas, escalera) |
| `tramos.csv` | 6 tramos (uno con escaleras, no accesible) |
| `espacios.csv` | 6 espacios (aulas, laboratorio, oficina, biblioteca, portería) |
| `anclajes.csv` | 3 placas QR |
| `horarios.csv` | 4 franjas de clase |
| `calendario.csv` | 3 fechas clave |
| `panoramicas.csv` | 2 panorámicas enlazadas |

## Qué demuestra

- El **Aula 101 y el Aula 102** están en el piso 1 y solo se llega por escaleras:
  el validador lo reporta como **aviso** («sin ruta accesible desde la portería»),
  que es justo lo que debe avisar el sistema.
- Los otros espacios sí tienen ruta sin escaleras desde la portería.
- Hay **horarios** (con salón, materia, programa, semestre y grupo) y **calendario**,
  para que el chatbot tenga de dónde responder.

## Uso

```bash
cd scripts
node validar.mjs --fuente ../datos/ejemplo
node empaquetar.mjs --fuente ../datos/ejemplo --salida ../dist
```
