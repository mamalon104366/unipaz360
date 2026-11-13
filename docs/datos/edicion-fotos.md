# Edición de las fotos 360° (`ajustes`)

La pestaña **Ajustes** del editor 360° del panel edita cada foto sin tocar el original: lo
elegido se guarda en `panoramica.ajustes` (JSON) y, al guardar, el servidor genera las
versiones publicables (`rapida` de 4096 px, `alta` de hasta 8192 px y `miniatura` de 640 px).

Código: `panel/src/lib/tipos.ts` (`Ajustes`, `AJUSTES_POR_DEFECTO`, `ESTILOS_FOTO`,
`curvaTonos`, `huellaPixeles`), `panel/src/lib/panoramicas.ts` (`normalizarAjustes`: los
rangos) y `panel/src/lib/imagen.ts` (el procesado con `sharp`).

## Campos

| Campo | Rango | Qué hace | Dónde se aplica |
| ----- | ----- | -------- | --------------- |
| `norte` | grados | Dónde queda el norte en la foto (orienta las flechas y el recorrido guiado). | Al mostrar (app y panel) |
| `inclinacion`, `alabeo` | −30 a 30° | Corrigen el horizonte; los puntos se mueven con la foto. | Al mostrar (app y panel) |
| `exposicion` | −1 a 1 | Brillo: ×2^`exposicion`. | Píxeles |
| `contraste` | −1 a 1 | `k = 1 + contraste · 0.6` alrededor del gris medio. | Píxeles |
| `sombras` | −1 a 1 | Aclara (+) u oscurece (−) las zonas oscuras. | Píxeles |
| `luces` | −1 a 1 | Aclara (+) o recupera (−) las zonas claras. | Píxeles |
| `saturacion` | −1 a 1 | −1 es blanco y negro. | Píxeles |
| `temperatura` | −1 a 1 | Rojo ×(1 + 0.12·t), azul ×(1 − 0.12·t). | Píxeles |
| `tinte` | −1 a 1 | Verde ×(1 − 0.12·t): magenta (+) o verde (−). | Píxeles |
| `nitidez` | 0 a 1 | Enfoque (`sharpen`, sigma 0.5 a 1.7). | Píxeles |
| `ruido` | 0 a 1 | Mediana de 3×3 mezclada con la foto en esa proporción (fotos con poca luz). | Píxeles |
| `nadir` | 0 a 40° | Radio del parche que tapa el trípode (0 = sin parche). | Píxeles |
| `nadirTipo` | `logo`, `difuminado`, `color` | El logo de UNIPAZ, el suelo muy desenfocado o un disco liso. | Píxeles |
| `nadirColor` | `#rrggbb` | El color del disco. | Píxeles |
| `difuminados` | hasta 60 | Círculos difuminados (rostros, placas; Ley 1581). | Píxeles |

Lo que falta en un ajuste guardado antes toma su valor por defecto (todo en 0, el parche con el
logo y el color `#233671`).

### Sombras y luces

Las dos van en una sola curva de tonos (0 a 1 → 0 a 1), la misma en el servidor y en la vista
previa:

`y = x + 0.14 · sombras · 6.75 · x(1 − x)² + 0.14 · luces · 6.75 · x²(1 − x)`

Las sombras pesan más en los oscuros (máximo en x = 1/3) y las luces en los claros (x = 2/3).
Con estos pesos la curva siempre sube: no aparecen bandas ni inversiones.

## Orden del procesado

1. Escalar al tamaño de la versión.
2. Reducir ruido (antes de que el contraste o la nitidez lo marquen más).
3. Color. `sharp` aplica estas operaciones en su propio orden fijo, no en el de las llamadas:
   temperatura y tinte (`recomb`), exposición y saturación (`modulate`) y contraste (`linear`).
4. Sombras y luces (tabla de 256 valores sobre los píxeles).
5. Nitidez.
6. Encima: las zonas difuminadas y el parche del suelo (no se afilan).

Si hay sombras, luces, zonas difuminadas o parche, el servidor saca los píxeles después del
paso 3, y así el contraste no toca el parche. Si no hay nada de eso, `sharp` aplica el contraste
después de la nitidez; la diferencia no se nota.

Solo se vuelven a generar las versiones si cambia algo que toca los píxeles (`huellaPixeles`):
el tipo y el color del parche no cuentan si no hay parche.

## Vista previa en el editor

Exposición, saturación y contraste van con filtros CSS; temperatura, tinte, sombras, luces y
nitidez, con un filtro SVG (`feColorMatrix`, `feComponentTransfer` con la misma curva y
`feConvolveMatrix`). La reducción de ruido y el parche del suelo se ven en la **Vista previa**
después de guardar.

## Estilos rápidos

Un toque pone varios ajustes a la vez; después se afinan con los deslizadores. Cada botón
muestra su efecto sobre la misma foto.

| Estilo | Para qué |
| ------ | -------- |
| Natural | Todo en cero. |
| Vivo | Más color, contraste y detalle. |
| Soleado | Cálido y luminoso. |
| Fresco | Frío y limpio. |
| Dramático | Contraste fuerte y cielos recuperados. |
| Interior | Levanta las sombras de un salón o un pasillo. |
| Blanco y negro | Sin color, con contraste. |

## La app

La app recibe las versiones ya procesadas: de `ajustes` solo usa `norte`, `inclinacion` y
`alabeo` (`AjustesPanoramica` en `app/lib/core/modelo/recorrido.dart`).
