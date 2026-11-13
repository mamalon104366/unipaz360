# Puntos dentro de las fotos 360°

Cada panorámica puede tener puntos (`punto_informacion` en el paquete): información,
anuncios con fecha, imágenes o GIF, videos, fichas de espacios, accesibilidad y
**«Ir a»** (pasar a otra foto 360°). Este documento dice cómo se dibujan, para que
la app Flutter se vea igual que el editor del panel.

Código de referencia: `panel/src/lib/tipos.ts` (`Estilo`, `estiloPorDefecto`),
`panel/src/lib/estiloPunto.ts` (`limpiarEstilo`: los rangos de cada campo),
`panel/src/components/panoramicas/capas.ts` (dibujo) y `globals.css` (formas y animaciones).
En la app: `app/lib/core/modelo/recorrido.dart` (`EstiloPunto.de`) y `app/lib/features/visor360/`.

La app lee el estilo con las mismas reglas que el panel. Lo comprueba
`app/test/visor360/estilo_punto_test.dart` con casos sacados del código del panel; se
regeneran, junto con la lista de íconos, con:

```
node --conditions=react-server --experimental-transform-types panel/scripts/puntos-flutter.mjs
```

## Posición

- `yaw` y `pitch` en grados, **en el marco de la foto** (pegados a la imagen).
- El visor gira la esfera con la corrección de horizonte de los ajustes
  (`inclinacion`, `alabeo`). A los puntos, al norte y a las flechas se les aplica la
  misma rotación: `R = Rx(inclinación) · Rz(alabeo)` (Euler `YXZ` sin giro horizontal),
  con el vector `v = (−cos p · sen y, sen p, cos p · cos y)`. Así, si después se
  corrige el horizonte, los puntos se mueven junto con la foto.
  Implementación: `correccion.ts` (`aVista` y `aFoto`, la inversa es la transpuesta).

## Estilo (`estilo`, JSON)

| Campo | Qué es |
| ----- | ------ |
| `forma` | `etiqueta`, `icono`, `circulo` (anillo), `pin`, `burbuja` (tarjeta), `miniatura`, `recorte` (imagen sin marco), `flecha` (en el piso), `capa3d` (dentro de la imagen). |
| `color` | Color de acento `#rrggbb`. El ícono va en negro si la luminancia del color es > 0.6 (la misma de `Color.computeLuminance()`), si no en blanco. |
| `escala` | Tamaño de las formas 2D: 0.5 a 2.5 (1 = 13 dp de letra base). |
| `ancho`, `alto` | Formas 3D: tamaño en "píxeles de esfera"; ancho angular (rad) ≈ `ancho / 1000`. |
| `rotacion` | Formas 3D: `{ yaw, pitch, roll }` en grados, sobre el plano que mira al centro. |
| `animacion` | Ver la tabla de animaciones. |
| `velocidad` | De 0.5 a 2 (1 = normal): la duración de la animación se divide por este número. |
| `icono` | Uno de los íconos de la lista (abajo) o `''`: el del tipo de punto. |
| `fondo` | `oscuro`, `claro`, `color` (el de acento) o `''`: el de la forma. Ver «Fondos». |
| `rotulo` | `true`: el título queda siempre visible debajo del ícono, el anillo, el pin o la imagen sin marco. |
| `opacidad` | De 0.2 a 1, sobre todo el punto. |
| `esquinas` | Capa dentro de la imagen: radio de las esquinas en px de la capa (por defecto 14). Nunca pasa de la mitad del lado corto: con un valor grande queda redonda. |
| `marco` | Capa dentro de la imagen: grosor del marco, del color de acento, de 0 a 60 px (0 = sin marco). |

Un campo que falta, que no es del tipo esperado o que no está en su lista toma su valor
por defecto; un número fuera de rango se lleva al límite. Lo que no es del estilo se descarta.

Color por defecto según el tipo: información `#2563eb`, anuncio `#f59e0b`, imagen
`#7c3aed`, video `#dc2626`, «Ir a» `#ffffff`, espacio `#0d9488`, accesibilidad `#16a34a`.

### Íconos

Son de Lucide, los mismos en el panel (`lucide-react`) y en la app (`lucide_icons_flutter`).
El catálogo (188 íconos en 9 grupos: Lugares, Académico, Servicios, Transporte, Salud y
deporte, Cultura, Naturaleza y campo, Señales y seguridad, Información) sale de
`panel/scripts/puntos-flutter.mjs` y está en `panel/src/lib/iconosPunto.generado.ts`, con la
etiqueta y el grupo de cada uno. El editor lo muestra con buscador y pestañas por grupo
(`components/ui/SelectorIconos.tsx`); las secciones del menú de la app usan el mismo catálogo.

Las claves ya guardadas no cambian nunca: lo nuevo se agrega al final de la lista. Las 44
primeras: `info`, `anuncio`, `imagen`, `video`, `ir`, `edificio`, `accesibilidad`,
`biblioteca`, `aula`, `graduacion`, `laboratorio`, `microscopio`, `computo`, `cafeteria`,
`restaurante`, `gimnasio`, `deportes`, `musica`, `arte`, `teatro`, `salud`, `enfermeria`,
`banos`, `parqueadero`, `bus`, `bicicletas`, `wifi`, `entrada`, `ubicacion`, `calendario`,
`horario`, `telefono`, `correo`, `seguridad`, `precaucion`, `ayuda`, `naturaleza`,
`destacado`, `favorito`, `foto`, `idea`, `personas`, `tienda`, `historia`. Las 144 del 13 de
noviembre de 2026 van del campus (`auditorio`, `capilla`, `canchas`, `piscina`, `cajero`,
`impresion`, `extintor`, `salida`, `encuentro`…) al campo (`cultivos`, `maquinaria`,
`piscicultura`, `avicultura`, `vivero`, `riego`…).

Sin ícono elegido, cada tipo usa el suyo: información `info`, anuncio `anuncio`, imagen
`imagen`, video `video`, «Ir a» `ir`, espacio `edificio`, accesibilidad `accesibilidad`.
El anillo y la flecha no llevan ícono; la miniatura y la capa lo muestran cuando no hay foto.

### Fondos

El fondo cambia la etiqueta, la tarjeta, el rótulo (el de la miniatura y el del ícono, el
anillo y el pin) y la capa dentro de la imagen cuando lleva texto. Sin elegir, la tarjeta va
en claro y lo demás en oscuro.

| Fondo | Etiqueta y rótulo | Tarjeta | Capa con texto |
| ----- | ----------------- | ------- | -------------- |
| `oscuro` | `rgb(24 24 27 / 0.82)`, letra blanca | `rgb(24 24 27 / 0.92)`, título blanco, texto `rgb(255 255 255 / 0.72)` | `rgb(28 28 31 / 0.88)`, título blanco, texto `rgb(255 255 255 / 0.75)` |
| `claro` | `rgb(255 255 255 / 0.94)`, letra `#1c1c1f` | `rgb(255 255 255 / 0.97)`, título `#1c1c1f`, texto `#55555c` | `rgb(255 255 255 / 0.94)`, título `#1c1c1f`, texto `#55555c` |
| `color` | el color de acento, letra en su tinta | el color de acento, título en su tinta, texto en su tinta al 80 % | igual que la tarjeta |

Con el fondo `color`, el círculo del ícono se aclara (`rgb(255 255 255 / 0.22)` encima del
acento) para que no se pierda. La etiqueta clara lleva un borde `rgb(0 0 0 / 0.08)` y una
sombra más suave (`0.6` en lugar de `0.75`).

### Rótulo

El título va en una píldora 0.8 em debajo de la forma, sin moverla (el ancla del punto no
cambia): a 3.4 em del borde de arriba en el ícono, a 3.86 em en el anillo y a 4.7 em en el
pin; en la miniatura, a 5.4 em. Letra de 0.9 em, peso 500. Con el rótulo puesto no se muestra
el globo con el título al pasar el mouse.

### Formas

- **Mirando al visitante (2D)**: etiqueta (píldora oscura con ícono y título),
  ícono (círculo de color con borde blanco), anillo (aro blanco con núcleo de color),
  pin (gota de color; su punta toca el punto), tarjeta (blanca con ícono, título y
  hasta 3 líneas de texto; su piquito toca el punto), miniatura (foto redonda —en un
  «Ir a», la del destino— con el título debajo) e **imagen sin marco** (`recorte`, solo en
  los puntos de imagen): la imagen entera en un cuadro de 7 em, sin caja ni círculo, con una
  sombra que sigue su silueta (`drop-shadow(0 0.35em 0.5em rgb(0 0 0 / 0.55))`). Con un PNG
  de fondo transparente (un logo, una señal) queda recortada sobre la foto. Sin imagen,
  muestra el ícono. El rótulo va a 7.8 em.
- **Sobre la esfera (3D)**: flecha doble en el piso y capa dentro de la imagen
  (imagen, GIF, video o tarjeta) que se ajusta con tamaño y giro a una pared o pantalla.
  La capa puede llevar esquinas redondeadas y un marco del color de acento; el contenido
  se recorta con el radio de adentro (el de afuera menos el marco), como en CSS.
- **Flecha acostada en el piso**: su `rotacion.pitch` sale de qué tan abajo está el
  punto, `clamp(−pitch + 35, 45, 85)` si `pitch < 0` (cerca del horizonte un plano
  horizontal se vería de canto, por eso se levanta un poco).

### Animaciones (bucle infinito)

| Nombre | Duración | Movimiento |
| ------ | -------- | ---------- |
| `pulso` | 1.6 s | escala 1 → 1.12 → 1 |
| `latido` | 1.3 s | escala 1.18 (14 %), 1 (28 %), 1.12 (42 %), 1 (70 %) |
| `flotar` | 2.4 s | sube 0.6 em y baja |
| `rebote` | 1.6 s | sube 1 em (40 %), baja, rebota 0.45 em (70 %) y 0.1 em (85 %) |
| `brillo` (onda) | 1.8 s | aro del color de acento que crece a 1.9× y se desvanece |
| `girar` | 3 s | el ícono gira sobre su eje vertical (el pin y las capas 3D giran completos) |
| `balanceo` | 2 s | gira de −7° a 7° desde la base |
| `parpadeo` | 1.4 s | opacidad 1 → 0.35 → 1 |

Con "reducir movimiento" activado en el sistema, las animaciones se apagan. La duración
real es la de la tabla dividida por `velocidad` (en una capa 3D, `girar` parte de 4 s).

## El editor (panel)

El formulario del punto tiene seis apartados que se pliegan (el navegador recuerda cuáles
quedaron abiertos): **Contenido**, **Forma y tamaño**, **Color e ícono**, **Animación**,
**Posición** y **Visibilidad**. Además:

- **Deshacer y rehacer** (Ctrl+Z, Ctrl+Y o Ctrl+Mayús+Z) sobre el punto abierto. Arrastrar
  un deslizador o escribir seguido cuenta como un solo paso.
- **Duplicar** (Ctrl+D): crea una copia 8° a la derecha y la abre.
- **Copiar y pegar estilo**, también entre fotos, y **aplicar el estilo a todos** los puntos
  del mismo tipo de la foto. Se copia la apariencia; el ícono, el tamaño y el giro son de
  cada punto y se conservan.
- **Posición exacta**: los grados se pueden escribir; «Al centro» lleva el punto al centro de
  la vista y «Mirarlo» gira la vista hasta él.
- **Guías**: el horizonte (ya corregido), una cuadrícula cada 30° y una mira en el centro.
  Solo se ven en el editor.
- **Buscador** en la lista cuando la foto tiene más de cinco puntos.

## Quién lo ve (`audiencia`)

`todos` (por defecto) o `institucional`: el punto solo se dibuja para quien entró con la cuenta
`@unipaz.edu.co`. Es una columna de la migración `0005_audiencia.sql`. Mientras la base no la tenga, el
panel la guarda dentro de `estilo` (`estilo.audiencia`) y la lee de ahí; la migración la pasa a la
columna. En el paquete siempre va en la columna. Detalle y límites en `apariencia-app.md`, «Quién lo ve».

## «Ir a» otra foto

- El destino (`destino_panoramica_id`) tiene que existir y ser otra panorámica; el
  servidor lo valida. Si todavía no hay otra foto 360°, el editor lo explica y lleva al mapa.
- Además de los «Ir a» puestos a mano, los nodos unidos por un tramo que tienen foto
  se enlazan solos con una flecha (dirección = norte de la foto + rumbo en el mapa;
  la tabla `enlace_panoramica` guarda las que se acomodaron a mano).
- En la vista del visitante, tocar un «Ir a» pasa a la otra foto con un fundido.
