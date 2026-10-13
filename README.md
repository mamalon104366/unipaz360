# UniPaz360

App móvil de orientación para el **Centro de Investigaciones Santa Lucía de UNIPAZ**. Encuentra aulas y oficinas y muestra la ruta a pie, incluida una ruta sin escaleras. **Funciona sin conexión.**

**Curso:** Desarrollo de Aplicaciones Móviles · Ingeniería Informática · VIII semestre · UNIPAZ · 2026
**Metodología:** Mobile-D con Scrum (sprints de 1 semana) y Kanban en GitHub Projects
**Tecnología:** Flutter (Android) · SQLite · API del paquete de datos · cámara (lectura de QR)

---

## Equipo y roles

| Rol | Integrante | Usuario de GitHub |
|---|---|---|
| Product Owner (PO) | `[nombre]` | `@...` |
| Scrum Master (SM) | `[nombre]` | `@...` |
| Developer | Esteban David Merlano Quintana | [@mamalon104366](https://github.com/mamalon104366) |
| Developer | Andrés Fernández | [@ondresz](https://github.com/ondresz) |
| Developer | Keyner Trujillo | [@Causa-Trujillo](https://github.com/Causa-Trujillo) |
| Usuario real de referencia | `[estudiante de primer semestre o visitante]` | — |

Los tres son Developers. El PO y el SM también desarrollan.

**Rotación:**
- El rol de Scrum Master rota cada 3 sprints.
- El PO se mantiene durante el semestre.
- El Daily dura 10 minutos, a la misma hora, y lo conduce el SM.

---

## Visión

> Para los **estudiantes nuevos, visitantes y personas con movilidad reducida** que llegan al Centro de Investigaciones Santa Lucía de UNIPAZ y **no saben dónde queda un aula u oficina ni cómo llegar**, **UniPaz360** es una **app móvil de orientación en el campus** que **encuentra el espacio y muestra la ruta a pie —con opción sin escaleras— en menos de un minuto, aunque no haya señal**. A diferencia de **preguntar en portería o guiarse por letreros y planos impresos**, nuestro producto **funciona sin conexión, fija el punto de partida con un código QR y deja recorrer el campus en fotos 360° antes de ir**.

## Objetivo del Producto

> **Que un estudiante nuevo o un visitante del Centro de Investigaciones Santa Lucía obtenga, sin conexión y en menos de un minuto, la ruta a pie hasta cualquier aula u oficina —con opción sin escaleras— y llegue sin pedir ayuda.**

Así se verifica: en la prueba con usuarios, al menos el 90 % de las tareas «llegar a un aula» se completa sin ayuda, y la búsqueda más el cálculo de la ruta toman menos de 60 segundos en modo avión.

---

## Alcance (MoSCoW)

| Must (MVP · Hito 2) | Should (Hito 3) | Could | Won't (este semestre) |
|---|---|---|---|
| Buscar un espacio por nombre o código | Escanear un QR para fijar el origen | Ruta piso por piso | Versión iOS publicada en App Store |
| Ficha del espacio | Ruta sin escaleras (accesible) | Saltar de la foto 360° a la ficha y la ruta | Versión de escritorio (Windows) |
| Elegir el origen de una lista | Distancia y tiempo de la ruta | Reportar un error en una ruta o ficha | Panel web de administración |
| Calcular el camino más corto | Descargar los datos actualizados (API) | Texto grande y lector de pantalla | Posicionamiento continuo en interiores (balizas o Wi-Fi) |
| Ver la ruta sobre el plano | Recorrido virtual 360° | | Guía por voz |
| Datos del campus guardados en el teléfono (SQLite) | APK de prueba distribuido | | Otras sedes de UNIPAZ |
| | | | Integración con horarios y sistema académico |

**Regla del 60 %:** las Must suman 27 de 63 puntos (43 %).

**Cobertura del Hito 3:**
- API: descarga del paquete de datos (HU-09) y reporte de errores (HU-13).
- Persistencia: SQLite (TEC-02).
- Función del dispositivo: cámara para leer el QR (HU-06).

### Fuera del alcance (este semestre)
- La app no sigue tu posición en tiempo real dentro de los edificios. El origen se fija con un QR o se elige de una lista.
- No se publica en iOS ni en Windows. Se entrega un APK de Android.
- No hay cuentas de usuario y la app no guarda datos personales ni tu ubicación.
- Solo se modela el Centro de Investigaciones Santa Lucía, empezando por un bloque piloto.
- No hay panel web: los datos del campus se editan como archivos en este repositorio (`datos/`).

---

## Product Backlog

El backlog vive en el **[tablero del proyecto](../../projects)**. Tiene 18 elementos y 63 puntos, y la historia de referencia es HU-02 = 2 puntos. Las épicas son **Base · Encontrar · Llegar · Conocer · Mantener**.

| Orden | ID | Épica | Elemento | MoSCoW | Pts |
|---|---|---|---|---|---|
| 1 | TEC-01 | Base | Crear el proyecto Flutter, configurar ramas, proteger `main` y correr `flutter analyze` en cada PR | Must | 2 |
| 2 | TEC-02 | Base | Modelo Espacio–Vértice–Tramo y repositorio SQLite con sus pruebas | Must | 3 |
| 3 | INV-01 | Base | Levantar un bloque piloto del campus en el formato del paquete de datos | Must | 5 |
| 4 | HU-01 | Encontrar | Como estudiante nuevo, quiero buscar un aula u oficina por su nombre o código para saber dónde queda | Must | 3 |
| 5 | HU-02 | Encontrar | Como visitante, quiero ver la ficha de un espacio (bloque, piso, horario y foto) para confirmar que es el lugar que busco | Must | 2 |
| 6 | TEC-03 | Base | Configurar Firebase App Distribution para repartir el APK de prueba | Should | 2 |
| 7 | HU-03 | Llegar | Como estudiante nuevo, quiero elegir de una lista el lugar donde estoy para indicar desde dónde salgo | Must | 2 |
| 8 | HU-04 | Llegar | Como estudiante nuevo, quiero que la app calcule el camino más corto a pie hasta el espacio para no perderme | Must | 5 |
| 9 | HU-05 | Llegar | Como estudiante nuevo, quiero ver la ruta dibujada sobre el plano del campus para seguirla mientras camino | Must | 5 |
| 10 | HU-08 | Llegar | Como estudiante, quiero ver la distancia y el tiempo estimado de la ruta para saber si llego a tiempo | Should | 2 |
| 11 | HU-06 | Llegar | Como estudiante, quiero escanear el código QR de una placa para que la app sepa dónde estoy sin buscarlo | Should | 3 |
| 12 | HU-07 | Llegar | Como persona con movilidad reducida, quiero pedir una ruta sin escaleras ni desniveles para llegar sin barreras | Should | 5 |
| 13 | HU-09 | Mantener | Como usuario, quiero que la app descargue los datos actualizados del campus cuando haya internet para no ir a un aula que cambió | Should | 5 |
| 14 | HU-10 | Conocer | Como aspirante, quiero recorrer el campus en fotos 360° para conocerlo antes de ir | Should | 8 |
| 15 | HU-12 | Conocer | Como visitante, quiero saltar desde una foto 360° a la ficha y la ruta del espacio para ir al lugar que vi | Could | 3 |
| 16 | HU-11 | Llegar | Como estudiante, quiero ver la ruta piso por piso cuando el destino está en otro nivel para no equivocarme de escalera | Could | 3 |
| 17 | HU-13 | Mantener | Como usuario, quiero reportar un error en una ruta o en una ficha para que la universidad lo corrija | Could | 3 |
| 18 | HU-14 | Encontrar | Como persona con baja visión, quiero agrandar el texto y usar el lector de pantalla para leer las indicaciones | Could | 2 |

**Por qué este orden:**
1. Primero la base técnica y los datos del bloque piloto: sin ellos no se puede buscar ni calcular rutas.
2. Luego las Must en el orden en que el usuario las vive: encontrar, ubicarse, llegar.
3. TEC-03 sube porque desde la semana 6 la DoD exige probar el APK en un dispositivo.
4. HU-10 (8 puntos) queda abajo por su tamaño e incertidumbre: antes conviene una investigación rápida (spike) sobre el visor 360°.

---

## Definición del Flujo de Trabajo

| Columna | Política de entrada | WIP |
|---|---|---|
| Backlog | Cualquier idea con título claro. El PO decide su orden. | — |
| Listo | Cumple INVEST, tiene criterios de aceptación y puntos, y el equipo la entiende. | 4 |
| En desarrollo | Alguien se la asigna y crea su rama (`hu-04-ruta-corta`). Solo una tarjeta por persona. | 3 (= integrantes) |
| En revisión | Hay un PR abierto que enlaza el issue (`Closes #N`) y `flutter analyze` está limpio. | 2 |
| En dispositivo | PR aprobado por otra persona; el APK de la rama está instalado en un Android físico y probado **en modo avión**. | 2 |
| Hecho | Cumple la Definición de Terminado y el PR está fusionado. | — |

- **Elemento de trabajo:** un issue del repositorio. Puede ser una historia, una tarea técnica, un defecto o una investigación.
- **Inicio y fin:** empieza al entrar en «En desarrollo» y termina al entrar en «Hecho». Entre esos dos momentos se mide el *cycle time*.
- **Expectativa de nivel de servicio (provisional):** «la mayoría de nuestros elementos se terminan en 4 días o menos». Se revisa con datos reales en el Sprint 4.
- **Bloqueos:** una tarjeta bloqueada lleva la etiqueta `bloqueada` y se menciona en el siguiente Daily. Si sigue bloqueada dos días, interviene el Scrum Master.

### Definición de Terminado: fase de Exploración (semanas 3 a 5)
- La historia tiene criterios de aceptación verificables en formato Dado / Cuando / Entonces.
- Su pantalla existe en el prototipo de Figma, como mínimo en baja fidelidad.
- El PO la validó con al menos un usuario real (un estudiante nuevo o un visitante) y anotó qué dijo.
- Si la historia usa rutas, los espacios y tramos que necesita están en el levantamiento del bloque piloto (`datos/piloto/`).

### Definición de Terminado: desde la semana 6
Se suma a la anterior. Es la DoD base del curso, ajustada a UniPaz360:
- El código está fusionado en `main` mediante un PR revisado por otra persona, con `flutter analyze` sin errores y las pruebas pasando.
- Cumple todos sus criterios de aceptación.
- El APK se probó en un Android físico **en modo avión**.

---

## Sprints

El detalle de cada sprint está en [`docs/sprints/`](docs/sprints).

| Sprint | Semana | Objetivo |
|---|---|---|
| 0 | 3 | Tablero, backlog inicial y reglas de trabajo |
| 1 | 4 | Las historias Must de Encontrar y Llegar tienen criterios de aceptación Dado / Cuando / Entonces validados con dos estudiantes nuevos y un visitante, y su pantalla en el prototipo de Figma |

---

## Cómo trabajamos

Las reglas de ramas, commits y pull requests están en [CONTRIBUTING.md](CONTRIBUTING.md). Los datos del campus y su formato están en [`docs/datos/`](docs/datos) y [`datos/`](datos).
