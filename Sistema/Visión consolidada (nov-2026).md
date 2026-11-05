---
tags: [unipaz360, sistema, vision, plan]
fecha: 2026-11-04
---
# Visión consolidada (nov-2026)

> Esta nota reúne en un solo plan el documento [[Avance documental (oct-2026)]], el plan técnico de [[00 Sistema - Índice|Sistema]] y el código real del repositorio. Si alguna nota anterior la contradice, esta manda.

## 1. Qué es UniPaz360: dos productos sobre un mismo modelo

| | **App cliente** (lo que ve la gente) | **Plataforma UniPaz360** (lo que usamos nosotros) |
|---|---|---|
| Quién la usa | Estudiantes, docentes, aspirantes y visitantes | El equipo y, después, la oficina que herede el proyecto |
| Qué hace | Mapa, búsqueda, rutas (estándar y accesible), recorrido 360°, QR y avisos | **Arma el tour virtual**: nodos, rutas, fotos 360°, edición de la imagen, anuncios y publicación |
| Tecnología | **Flutter** | **Next.js + MapLibre GL JS + Photo Sphere Viewer** (web) |
| Conexión | **Sin conexión**: trabaja con el paquete descargado | En línea: Neon (PostgreSQL + PostGIS) y Cloudflare R2 |
| Carpeta | `app/` | `panel/` |

**Regla que los une:** todo lo que se hace en la plataforma termina en un **paquete de datos versionado** (`datos.sqlite`, `manifest.json` y medios) que la app descarga. La app **nunca se recompila** para cambiar el contenido. Ver [[Datos y publicación]].

## 2. La plataforma: editor del tour virtual

El flujo de trabajo es este: **nodo → ruta → foto 360° → limpieza de la foto → contenido encima → vista previa → publicar**.

### 2.1 Nodos sobre el mapa
- Clic en el mapa (ortofoto del dron o mapa base) para crear un nodo. Cada nodo tiene tipo (portería, puerta, intersección, escalera, rampa, punto de interés o espacio), nombre, bloque y piso.
- Los nodos se pueden arrastrar, renombrar o borrar. Borrar un nodo con QR impreso **lo retira, nunca reutiliza su ID**.
- Cada nodo tiene un ID estable que es el que va en el QR (`unipaz360://nodo/{id}`).

### 2.2 Rutas entre nodos (las líneas)
- Se dibuja una línea de nodo a nodo, con puntos intermedios para seguir el camino real.
- La longitud se calcula sola. En el panel lateral se marcan **escaleras, rampa, pendiente, superficie, cubierta, ancho y "verificado en campo"**.
- Con esos datos la app calcula la **ruta estándar** y la **ruta accesible** (ver [[Grafo del campus]] y [[Ruta accesible]]).
- Un botón **"Revisar conectividad"** pinta en rojo los nodos aislados.

### 2.3 Foto 360° en cada nodo
- Se arrastra la foto esférica (equirrectangular 2:1) sobre el nodo.
- La plataforma la valida y genera **dos versiones** para la app: una ligera (~1–2 MB, siempre disponible sin conexión) y una de alta resolución (~6–8 MB, bajo demanda).
- Los nodos vecinos con foto se enlazan solos como **flechas de navegación** al estilo Street View, y se pueden ajustar a mano.

### 2.4 Editar la imagen ahí mismo ("que quede súper clean")
Todo se hace sin salir del visor 360°. Se guarda la **foto original** más una **lista de ajustes**, de modo que cualquier cambio se puede deshacer.

| Herramienta | Para qué |
|---|---|
| **Nivelar horizonte** (giro, inclinación y alabeo) | Corregir una foto tomada torcida |
| **Vista inicial** (hacia dónde mira al abrir) | Que la foto arranque mirando hacia el camino o el edificio |
| **Parche del suelo (nadir)** | Tapar el trípode o la mano con el logo de UNIPAZ |
| **Difuminar** (pincel o rectángulo) | Ocultar rostros y placas de vehículos (Ley 1581) |
| **Luz y color** (exposición, contraste, saturación, temperatura) | Igualar fotos tomadas a distintas horas |
| **Recorte de cielo y suelo** | Fotos que no cubren la esfera completa |

### 2.5 Contenido encima de la foto (hotspots)
Se hace clic en un punto de la foto y se elige qué poner:

| Tipo | Qué muestra en la app |
|---|---|
| **Información** | Tarjeta con título, texto e ícono |
| **Anuncio** | Aviso destacado con **fecha de inicio y de fin**: desaparece solo cuando vence |
| **Imagen** | Foto o afiche, con zoom |
| **Video** | Video corto (MP4) con póster, o un enlace si se requiere conexión |
| **Ir a otro nodo** | Salta a otra foto 360° |
| **Ficha de espacio** | Abre la ficha del aula o laboratorio y el botón "Cómo llegar" |
| **Accesibilidad** | Advertencia como "escalón sin rampa" o "rampa a la izquierda" |

La posición se guarda en grados (yaw y pitch) sobre la foto, así que **cambiar el contenido no obliga a volver a subir la imagen**.

### 2.6 Vista previa y publicación
- El botón **"Ver como el visitante"** muestra el nodo tal como lo verá la app.
- La tarjeta **"Cambios sin publicar"** muestra un resumen como `+3 nodos, +2 rutas, 5 fotos, 4 anuncios`.
- Al publicar se ejecutan las 7 validaciones, luego el paquete y la subida a R2. La app avisa con **[Actualizar ahora] / [Más tarde]**. Revertir toma segundos.

### 2.7 Lo de soporte
Las cuentas `@unipaz.edu.co`, los roles (superadmin, editor y lector), la auditoría, los respaldos, los reportes de usuarios y los horarios siguen como ya estaban diseñados en [[Plataforma de administración]].

## 3. App cliente: plataformas

| Plataforma | Estado en el proyecto |
|---|---|
| **Android** (Android Studio y emulador) | ✅ Obligatoria. **En el celular la app va en horizontal** (ya está fijado en `main.dart` y en el `AndroidManifest`) |
| **Windows** (escritorio) | ✅ Obligatoria. **Falta crear la carpeta `app/windows`** |
| **Web** | ✅ Obligatoria |
| **iOS** | ⚪ **Límite del proyecto**: se integra solo si hay un Mac o un servicio de CI con macOS |
| **macOS** | ⚪ **Límite del proyecto**, igual que iOS |

## 4. Diagnóstico del código actual (`app/`, rama `main`)

**Lo que ya está bien:** el visor 360° propio (`motor_360.dart`, sin dependencias), el ingreso como invitado o con cuenta, el mapa del dron, el recorrido institucional, las vistas recientes, 9 archivos de pruebas, el modo horizontal y, en `scripts/` y `db/`, las 7 validaciones, el empaquetador y el esquema en Neon.

**Lo que hay que ordenar:**

| # | Problema | Qué hacer |
|---|---|---|
| 1 | Archivos gigantes: `pantalla_dron.dart` (2.084 líneas), `contenido_tour.dart` (1.507) y `pantalla_visor.dart` (1.220) | Partirlos en widgets de menos de 300 líneas, cada uno en su archivo |
| 2 | Estructura por capas (`ui/`, `data/`, `domain/`) que mezcla funciones | Pasar a **una carpeta por función**: `features/mapa`, `features/visor360`, `features/rutas`, `features/espacios`, `features/sesion`, `features/tour`, más un `core/` compartido |
| 3 | Los datos vienen de `repositorio_simulado.dart` y de texto escrito dentro de los widgets | Leer el **`datos.sqlite` del paquete** (drift o sqlite3). Los textos institucionales también van al paquete, así se cambian desde la plataforma |
| 4 | `google_maps_embed` y `webview_flutter` | Chocan con el "sin conexión" y con el software libre del documento. Reemplazar por la ortofoto y el mapa propio (flutter_map con teselas locales). Mientras tanto, en Windows (sin WebView) ya muestra el plano del dron (5-nov-2026) |
| 5 | El paquete `material_ui` en lugar del Material de Flutter | ✅ **Resuelto (5-nov-2026):** `material_ui` es el Material **oficial** que Flutter separó del SDK, y se queda. El error eran 3 archivos con el Material viejo, ya migrados. Ver [[Flutter - listo para empezar]] |
| 6 | No existen el motor de rutas (A* y Dijkstra), el lector de QR ni el sincronizador de paquetes | Son los sprints S2, S3 y S4 del documento: `features/rutas` y `core/paquete` |
| 7 | Los hotspots del visor no tienen modelo de datos | Crear el modelo `Hotspot` (tipo, yaw, pitch, contenido y vigencia) que comparten la app y la plataforma |
| 8 | 19 MB de imágenes y videos dentro de `assets/` | Dejar solo lo mínimo de arranque; lo demás llega con el paquete |

**Estructura destino de `app/lib`:**
```
lib/
├─ main.dart                 # orientación horizontal, arranque
├─ app/                      # tema, rutas (go_router), inyección
├─ core/
│  ├─ paquete/               # descarga, verificación SHA-256, cambio atómico, reversión
│  ├─ datos/                 # SQLite del paquete (solo lectura)
│  ├─ modelo/                # Espacio, Nodo, Tramo, Panorama, Hotspot, Anuncio
│  └─ ui/                    # componentes comunes (panel contraíble, barra lateral, avisos)
└─ features/
   ├─ mapa/                  # mapa 2D + capa dron + selector de piso
   ├─ espacios/              # búsqueda y ficha
   ├─ rutas/                 # A*, Dijkstra (oráculo), perfiles, paso a paso
   ├─ origen_qr/             # lector y esquema unipaz360://
   ├─ visor360/              # motor, hotspots, flechas, minimapa
   ├─ tour/                  # recorrido institucional
   ├─ sesion/                # invitado / @unipaz.edu.co
   └─ actualizaciones/       # aviso [Actualizar ahora] / [Más tarde]
```

## 5. Cambios que pide el documento de grado (`.docx`)

El avance describe **solo la app cliente**. Con la plataforma hay que ajustar:

| Sección | Ajuste |
|---|---|
| **Título** | Agregar "…y plataforma de gestión del recorrido virtual" (o dejar la plataforma como producto complementario) |
| **Resumen y abstract** | Mencionar la plataforma de gestión |
| **OE2 / OE3** | OE2 diseña también el modelo compartido y la plataforma. OE3 desarrolla la app **y** la plataforma (editor de nodos, rutas, 360° y contenido) |
| **4.1 Alcance funcional** | Añadir un **quinto módulo: plataforma de gestión del contenido**, y en la Figura 2 la flecha plataforma → paquete → app |
| **4.2 Delimitación tecnológica** | Hoy dice "Android e iOS… y Windows". Cambiar a **Android (horizontal), Windows y web**, con iOS/macOS como límite |
| **Tabla 1 (riesgos)** | La fila de iOS pasa a ser una limitación declarada |
| **Tabla 2** | La fila de UniPaz360 pasa a "Android, Windows y web" |
| **5.2.6 (360°)** | Sustentar la edición sin pérdida (ajustes no destructivos) y los hotspots |
| **Tabla 6 (sprints)** | Agregar sprints de la plataforma: P1 nodos y rutas, P2 360° y edición, P3 contenido y publicación |
| **Tabla 10 (presupuesto)** | Agregar Neon, R2 y Vercel (0–5 USD/mes) |
| **4.1, párrafo de "sin conexión"** | Aclarar que la app opera sin conexión y que **la plataforma sí requiere red**, sin contradecir la "operación sin servidor" de la justificación |

## 6. Orden de trabajo propuesto

1. **Ordenar la app** (sección 4): estructura por funciones, partir los archivos gigantes, crear `app/windows` y quitar Google Maps. Las pruebas deben seguir en verde.
2. **Modelo compartido**: `Nodo`, `Tramo`, `Panorama`, `Hotspot` y `Anuncio` en `db/` y en el esquema local del paquete.
3. **La app lee el paquete** en lugar del repositorio simulado.
4. **Plataforma P1**: nodos y rutas sobre el mapa.
5. **Plataforma P2**: foto 360° por nodo y edición de la imagen.
6. **Plataforma P3**: hotspots, anuncios, vista previa y publicar.
7. Motor de rutas, QR y aviso de actualización en la app (S2–S4 del documento).

Volver a [[00 Sistema - Índice]] · [[00 UniPaz360 - Índice]]
