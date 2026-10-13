# Levantamiento del bloque piloto (INV-01)

Llenar estos cuatro archivos en el campus. Se pueden abrir con Excel; el separador es `;`.

| Archivo | Qué va | Una fila por |
|---|---|---|
| `espacios.csv` | Aulas, oficinas, laboratorios, baños… del bloque piloto | espacio |
| `vertices.csv` | Puertas, cruces de pasillos, escaleras, rampas y accesos | punto de la red |
| `tramos.csv` | Cada trozo de camino entre dos vértices | tramo |
| `anclajes.csv` | Lugares propuestos para las placas QR | placa |

Las reglas de cada columna están en [docs/datos/formato-paquete.md](../../docs/datos/formato-paquete.md).

## Recorrido sugerido (equipo de 3)
1. **Persona A:** espacios. Nombre y código oficial de cada espacio (pedirlos a Planta física), además de horario, servicios y una foto.
2. **Persona B:** vértices. Marcar cada puerta, cruce, escalera y rampa en QGIS o en Google Maps y anotar las coordenadas.
3. **Persona C:** tramos. Medir longitud y desnivel, y anotar escalones, superficie y ancho. Marcar `verificado = true` solo si se recorrió.
4. **Al final:** los tres revisan juntos que el grafo esté conexo y que todo espacio tenga su vértice.
