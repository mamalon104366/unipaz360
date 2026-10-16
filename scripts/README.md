# Scripts del pipeline de datos

Herramientas que convierten el levantamiento (`datos/`) en el **paquete offline** que descarga la app: validan, empaquetan y calculan hashes.

> Reservado en el monorepo; se implementa en **TEC-05** y evoluciona en F0/F3.

## Qué irá aquí

| Script | Qué hace |
|---|---|
| `validar.mjs` | Comprueba las reglas antes de publicar (grafo conexo, accesibilidad, medios, QR estables, horarios…) |
| `empaquetar.mjs` | Construye `datos.sqlite` + `manifest.json` + `version.json` |
| `procesar-medios.mjs` | Genera miniaturas y LODs de fotos, 360° y ortomosaicos |

Reglas y formato en [`docs/plan/03-datos-y-publicacion.md`](../docs/plan/03-datos-y-publicacion.md) y [`docs/datos/formato-paquete.md`](../docs/datos/formato-paquete.md).

## Estado

Pendiente (TEC-05). El CI detecta `scripts/validar.mjs` y lo ejecuta en cuanto exista.
