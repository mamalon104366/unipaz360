# Puntos dentro de las fotos 360°

Cada panorámica puede tener puntos (`punto_informacion` en el paquete): información,
anuncios con fecha, imágenes o GIF, videos, fichas de espacios, accesibilidad y
**«Ir a»** (pasar a otra foto 360°). Este documento dice cómo se dibujan, para que
la app Flutter se vea igual que el editor del panel.

Código de referencia: `panel/src/lib/tipos.ts` (`Estilo`, `estiloPorDefecto`),
`panel/src/components/panoramicas/capas.ts` (dibujo) y `globals.css` (formas y animaciones).

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
| `forma` | `etiqueta`, `icono`, `circulo` (anillo), `pin`, `burbuja` (tarjeta), `miniatura`, `flecha` (en el piso), `capa3d` (dentro de la imagen). |
| `color` | Color de acento `#rrggbb`. El ícono va en negro si la luminancia del color es > 0.6 (la misma de `Color.computeLuminance()`), si no en blanco. |
| `escala` | Tamaño de las formas 2D: 0.5 a 2.5 (1 = 13 dp de letra base). |
| `ancho`, `alto` | Formas 3D: tamaño en "píxeles de esfera"; ancho angular (rad) ≈ `ancho / 1000`. |
| `rotacion` | Formas 3D: `{ yaw, pitch, roll }` en grados, sobre el plano que mira al centro. |
| `animacion` | Ver la tabla de animaciones. |

Color por defecto según el tipo: información `#2563eb`, anuncio `#f59e0b`, imagen
`#7c3aed`, video `#dc2626`, «Ir a» `#ffffff`, espacio `#0d9488`, accesibilidad `#16a34a`.

### Formas

- **Mirando al visitante (2D)**: etiqueta (píldora oscura con ícono y título),
  ícono (círculo de color con borde blanco), anillo (aro blanco con núcleo de color),
  pin (gota de color; su punta toca el punto), tarjeta (blanca con ícono, título y
  hasta 3 líneas de texto; su piquito toca el punto) y miniatura (foto redonda —en un
  «Ir a», la del destino— con el título debajo).
- **Sobre la esfera (3D)**: flecha doble en el piso y capa dentro de la imagen
  (imagen, GIF, video o tarjeta) que se ajusta con tamaño y giro a una pared o pantalla.
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

Con "reducir movimiento" activado en el sistema, las animaciones se apagan.

## «Ir a» otra foto

- El destino (`destino_panoramica_id`) tiene que existir y ser otra panorámica; el
  servidor lo valida. Si todavía no hay otra foto 360°, el editor lo explica y lleva al mapa.
- Además de los «Ir a» puestos a mano, los nodos unidos por un tramo que tienen foto
  se enlazan solos con una flecha (dirección = norte de la foto + rumbo en el mapa;
  la tabla `enlace_panoramica` guarda las que se acomodaron a mano).
- En la vista del visitante, tocar un «Ir a» pasa a la otra foto con un fundido.
