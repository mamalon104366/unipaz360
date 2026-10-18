# Puntos del mapa del dron

La vista del dron es la foto aérea del campus con **puntos marcados encima**. En
la app cada punto abre su ficha y, si tiene recorrido, entra al visor 360°.

Este documento es el contrato de datos: lo que el panel de administración tiene
que entregar para que un punto aparezca en el mapa sin tocar código.

## La imagen

- Es una sola foto del campus (se recomienda JPEG, lado largo ≤ 4096 px).
- La proporción no importa: la app la ajusta a la pantalla sin deformarla.
- Se guarda como archivo del paquete, igual que los panoramas 360°.

## Campos de cada punto

| Campo         | Tipo   | Obligatorio | Qué es                                                        |
| ------------- | ------ | ----------- | ------------------------------------------------------------- |
| `id`          | texto  | sí          | Identificador único dentro del mapa.                          |
| `nombre`      | texto  | sí          | Cómo se llama el lugar ("Cafetería Moka").                    |
| `tipo`        | lista  | sí          | `aulas`, `investigacion`, `servicios`, `deportes`, `salud`, `parqueadero`, `energia`, `acceso`. |
| `x`, `y`      | número | sí          | Posición **relativa**: de 0 a 1 sobre la foto (0,0 = esquina superior izquierda). |
| `zona`        | texto  | no          | Área del campus ("Bloque 2", "Zona deportiva").               |
| `descripcion` | texto  | no          | Dos o tres líneas explicando qué hay ahí.                     |
| `espacio_id`  | texto  | no          | Si el punto tiene recorrido 360°, el id de ese espacio.       |

## Reglas

1. **La posición es relativa, no en píxeles.** Así el mapa funciona igual en un
   celular y en un televisor, y la foto se puede reemplazar por una de más
   resolución sin volver a marcar los puntos.
2. **Sin `espacio_id` el punto igual sirve**: se muestra su ficha y se avisa que
   todavía no hay recorrido 360°.
3. **`tipo` arma la leyenda.** La app explica sola qué significa cada tipo; no
   hay que escribir esa explicación en los datos.
4. **Un punto puede repetir el tipo de otro**: se agrupan y la leyenda muestra
   cuántos hay.

## Dónde vive hoy

- La app lo consume con `MapaDronRepository` (`app/lib/data/`).
- Mientras llega el paquete del campus, los puntos de ejemplo están en
  `MapaDronSimulado`. **Sus posiciones son aproximadas**: se sacaron mirando la
  foto y están para que el cliente las ajuste en el panel.
