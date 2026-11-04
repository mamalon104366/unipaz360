---
tags: [unipaz360, sistema, admin, panel]
---
# Plataforma de administración

> El «Google Business + editor» de UniPaz360: crear el mapa, dibujar rutas, subir edificios y fotos, y **publicar al teléfono de todos sin escribir código**. Detalle extenso: `docs/plan/05-plataforma-admin.md`.

## Módulos del panel

| Módulo | Qué se hace |
|---|---|
| **Mapa y estructuras** | Dibujar bloques (polígonos), planos de piso, salones y contornos |
| **Red peatonal (grafo)** | Colocar vértices, trazar tramos, marcar accesibilidad — ver [[Grafo del campus]] |
| **Espacios** | Ficha completa: código, nombre, categoría, horario, servicios, fotos |
| **Anclajes QR** | Registrar placas, asignarlas a vértices, **generar PDF imprimible** |
| **Panorámicas** | Subir la esférica, ubicarla, fijar orientación, enlazar con otras |
| **Medios** | Fotos, videos de dron, ortomosaicos (con procesado automático a LODs/tiles) |
| **Horarios** | Importar CSV/Excel de Coordinación; editor; detección de choques |
| **Tour** | Checkpoints del minijuego, insignias, textos |
| **Reportes** | Bandeja de reportes de usuarios sobre el mapa |
| **Publicar** | Validar, empaquetar, poner en producción, historial y reversión |
| **Auditoría** | Quién entró, quién cambió qué y cuándo; exportable |
| **Usuarios y roles** | Altas/bajas y permisos |

## El editor de mapas (todo visual, sin código)

**MapLibre GL JS + capa de dibujo** (estilo terra-draw). Flujo típico:

1. **Bloques:** polígonos encima del ortomosaico o del mapa base.
2. **Planos de piso:** subir imagen del plano → georreferenciar con 3 puntos.
3. **Salones:** dibujar contorno (o pegar punto) + ficha.
4. **Vértices y tramos:** clic para colocar vértices; trazar tramos con puntos intermedios; longitud y desnivel automáticos; panel lateral por tramo (escaleras, superficie, ancho, verificado).
5. **Vista «grafo»:** red completa y bultos desconectados **en rojo**; botón «revisar conectividad».
6. **Informe de accesibilidad por bloque** (si marcas «accesible», exige ancho, pendiente en norma y verificación en campo).

Nada edita la app directamente: todo está en la base central con **vista previa** (mapa + 360 + chatbot), y solo llega a los teléfonos al pulsar **Publicar**.

## Subida y procesado de medios

```
Sube foto / esférica / vuelo.zip → R2 temporal → Procesador:
  · Ficha → comprime + miniatura
  · Esférica 2:1 → valida → LODs
  · Ortomosaico → recorta al campus → tiles z14–z20
  · Video → comprime + póster
→ «listo para asociar» con vista previa (PSV para 360, MapLibre para mapa)
```

## Publicación y versiones

- Tarjeta **«Cambios sin publicar»**: `+ 3 tramos, ~ 2 espacios, + 12 medios`.
- **Validar** → informe (errores bloquean; advertencias se aceptan por escrito).
- **Publicar** → GitHub Action con progreso en vivo — ver [[Datos y publicación]].
- **Historial** con botón «Revertir a esta» (segundos).
- **Canales:** `produccion` y `pruebas` (build interno del equipo).

## Roles

| Rol | Puede |
|---|---|
| **Superadmin** | Todo + usuarios + auditoría + revertir + borrar |
| **Editor** (equipo de mapeo) | Crear/editar contenido, subir medios, publicar |
| **Lector** (Planta Física, Coordinación) | Ver, comentar, exportar informes |

## Auditoría (requisito «quién entra y sale»)

- Registra **sesión inicio/fin**, intentos fallidos y **toda escritura** con valor antes/después, IP y agente.
- Línea de tiempo filtrable por usuario/fecha/entidad + export CSV.
- Retención sugerida: 12 meses. Política de tratamiento de datos (Ley 1581).
- 2FA para superadmin, sesiones de 8 h, URLs firmadas para subir.

## Respaldos

| Qué | Cómo |
|---|---|
| Base central | Neon PITR (restauración a punto en el tiempo) + `pg_dump` diario a R2 |
| Paquetes publicados | Inmutables en R2 ⇒ **cada versión es un respaldo del contenido público** |
| Medios fuente | Originales en R2 (`datos/medios-fuente/`) |

## Costos estimados

| Servicio | Estimado |
|---|---|
| Vercel | 0 USD (Hobby; el panel es de bajo tráfico) |
| Neon | 0 USD al inicio (~0,5 GB) |
| R2 | ~1-2 USD/mes por 10 GB (egreso gratis) |
| GitHub Actions | 0 USD |
| Dron | el rubro más alto (vuelos/permisos) |

> **Regla:** los medios pesados nunca pasan por Vercel, siempre por R2.

Volver a [[00 Sistema - Índice]] · [[00 UniPaz360 - Índice]]
