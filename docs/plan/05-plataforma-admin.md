# 5 · Plataforma de administración (el «Google Business + editor» de UniPaz360)

> El objetivo es que el equipo de mapeo (y quien herede el proyecto) pueda **crear el mapa, dibujar rutas, subir edificios y fotos, y publicar al teléfono de todos sin escribir una línea de código**.

## 5.1 Módulos del panel

| Módulo | Qué se hace | Historias relacionadas |
|---|---|---|
| **Mapa y estructuras** | Dibujar bloques (polígonos), planos de piso, salones y sus contornos | TEC-10, nuevo |
| **Red peatonal (grafo)** | Colocar vértices, trazar tramos, marcar accesibilidad (escaleras, pendiente, ancho) | INV-01, HU-04, HU-07 |
| **Espacios** | Ficha completa: código, nombre, categoría, horario, servicios, fotos | HU-01, HU-02 |
| **Anclajes QR** | Registrar placas, asignarlas a vértices, generar PDF imprimible con el QR | HU-06 |
| **Panorámicas** | Subir la esférica, ubicarla en un vértice, fijar orientación, enlazar con otras | HU-10, HU-12 |
| **Medios** | Fotos, videos de dron, ortomosaicos (con procesado automático a LODs/tiles) | nuevo |
| **Horarios** | Importar CSV/Excel de Coordinación; editor por franjas; detección de choques | nuevo |
| **Tour** | Marcar checkpoints del minijuego, insignias, textos | nuevo |
| **Reportes** | Bandeja de reportes de usuarios sobre el mapa (nuevo/en proceso/resuelto) | HU-13 |
| **Publicar** | Validar, empaquetar y poner en producción; historial y reversión | TEC-07, HU-09 |
| **Auditoría** | Quién entró, quién cambió qué y cuándo; exportable | seguridad |
| **Usuarios y roles** | Altas/bajas, roles (superadmin, editor, lector) | seguridad |

## 5.2 El editor de mapas (cómo se dibuja todo)

**Tecnología:** MapLibre GL JS + capa de dibujo (estilo terra-draw). Todo el trabajo es visual:

1. **Bloques:** se dibujan polígonos encima del ortomosaico o del mapa base; nombre, altura, número de niveles.
2. **Planos de piso:** sube la imagen del plano del bloque, se georreferencia con 3 puntos (clic en 3 esquinas conocidas) y queda encima del bloque.
3. **Salones:** se dibuja el contorno (o se pega un punto) y se llena la ficha.
4. **Vértices y tramos:** 
   - Clic en el mapa coloca un vértice (el panel avisa si no «toca» ningún tramo ⇒ grafo desconectado).
   - Un tramo se traza haciendo clic en dos vértices y **arrastrando puntos intermedios** para darle la forma del pasillo; el panel calcula longitud y desnivel automáticamente.
   - Panel lateral por tramo: escaleras (sí/no), superficie, ancho, un solo sentido, «verificado en campo».
   - Vista «grafo»: muestra la red y **resalta en rojo** los bultos desconectados; botón «revisar conectividad».
5. **Espacios:** se busca el código oficial y se asocia a su vértice de acceso; si un salón no tiene puerta asignada, el panel lo marca en rojo.
6. **Accesibilidad:** si marcas «accesible», el panel exige ancho, pendiente dentro de norma y «verificado en campo» (coherente con el CHECK de SQLite). Hay un informe «rutas accesibles por bloque».

**Nada de esto edita la app directamente:** todo vive en la base central; los cambios se ven en vivo en una **vista previa** (mapa + 360 + chatbot) y solo llegan a los teléfonos al pulsar **Publicar**.

## 5.3 Subida y procesado de medios

```
Editor sube foto.jpg / esférica.jpg / vuelo.zip
   → R2 carpeta temporal (URL firmada)
   → Procesador (GitHub Action o servicio):
       · Fotos de ficha  → comprime + miniatura + LOD
       · Esférica (equirectangular) → valida 2:1 → orientación EXIF → LODs (+ tiles si se decide)
       · Ortomosaico (GeoTIFF) → recorta al campus → tiles z14–z20 (MBTiles)
       · Video de dron → comprime H.264/H.265 + póster
   → vuelve al panel: «listo para asociar» (con vista previa 360 y de mapa)
```

- Límites y formatos aceptados con mensajes claros (p. ej. «la esférica debe ser 2:1, ≥ 5 376 × 2 688 px»).
- **Nada se publica sin previsualizarse** en el panel (esférica en Photo Sphere Viewer, ruta en MapLibre).

## 5.4 Publicación y versiones (botón «Enviar a producción»)

Flujo detallado en [03-datos-y-publicacion](03-datos-y-publicacion.md) §3.4. En el panel:

- Tarjeta **«Cambios sin publicar»**: lista de diferencias respecto a la última versión (`+ 3 tramos, ~ 2 espacios, + 12 medios`).
- Botón **Validar**: corre las 7 reglas y muestra informe (errores bloquean; advertencias se aceptan con confirmación escrita).
- Botón **Publicar** (solo rol editor/superadmin): dispara la GitHub Action, muestra progreso en vivo (logs).
- **Historial de versiones:** versión, autor, fecha, notas, tamaño; botón **«Revertir a esta»** (cambia el puntero en segundos).
- **Canales:** `produccion` y `pruebas`; una versión de pruebas se instala solo en teléfonos del equipo (build interno) sin afectar a los usuarios.

## 5.5 Cuentas, roles y auditoría

| Rol | Puede |
|---|---|
| **Superadmin** (2-3 personas, incl. docente/futuro responsable) | Todo + usuarios + auditoría + revertir + borrar |
| **Editor** (equipo de mapeo) | Crear/editar contenido, subir medios, publicar |
| **Lector** (p. ej. Planta Física, Coordinación) | Ver, comentar, exportar informes; no publica |

- **Ingreso:** cuenta institucional Google (`@unipaz.edu.co`) restringida por dominio; alternativa de contraseña local **solo** para cuentas de prueba creadas por un superadmin.
- **Auditoría (requisito «quién entra y sale»):**
  - `sesion_inicio`, `sesion_fin` (y fracasos de ingreso).
  - Toda escritura: entidad, id, **valor antes / valor después**, IP y agente.
  - Consultas sensibles (exportar auditoría) también se registran.
  - Interfaz: línea de tiempo filtrable por usuario/fecha/entidad + export CSV.
  - Retención definida (recomendado 12 meses) y política de tratamiento de datos (Ley 1581).
- **Protecciones:** 2FA obligatorio para superadmin (Google lo da), sesiones de 8 h, límite de intentos, URLs firmadas para subir medios.

## 5.6 Respaldos y recuperación

| Qué | Cómo | Frecuencia |
|---|---|---|
| Base central | Neon: ramas + restauración a punto en el tiempo (PITR) | continuo |
| Foto de seguridad | Export `pg_dump` → R2 (bucket privado) | diaria |
| Paquetes publicados | Son inmutables en R2 ⇒ **cada versión publicada es un respaldo completo del contenido público** | por publicación |
| Medios fuente | Carpeta `datos/medios-fuente/` en R2 (originales sin comprimir) | al subir |
| Configuración | IaC mínima: documentar en `docs/plan` + variables en Vercel/Neon | por cambio |

**Plan de recuperación:** si Neon cae, el panel no funciona pero **la app no se entera** (los teléfonos siguen con su paquete). Si se corrompe un dato, se restaura con PITR o se revierte la versión pública.

## 5.7 Costos estimados (escala del proyecto)

| Servicio | Plan | Costo esperado |
|---|---|---|
| Vercel | Hobby/Pro | 0 USD (Hobby) — el panel es de bajo tráfico |
| Neon | Free/Launch | 0 USD al inicio (~0,5 GB de datos) |
| Cloudflare R2 | Pago por uso | ~1-2 USD/mes por 10 GB + operaciones (egreso gratis) |
| GitHub | Free | 0 USD (Actions incluidas en horas de repo público/privado pequeño) |
| Dron | — | variable: piloto y permisos (el rubro más alto del proyecto) |

> Regla: **los medios pesados nunca pasan por Vercel**; siempre por R2. Eso evita sorpresas de factura y límites.
