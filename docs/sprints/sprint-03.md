# Sprint 3 · Base integrada y vertical slice técnico

**Objetivo:** pasar de pantallas/repositorios de muestra y pipeline separado a una ruta técnica reproducible: paquete real de prueba → almacenamiento/consulta local → lista/ficha navegables; dejar el contrato de grafo/ruta listo para la siguiente rebanada.

**Estado/dependencias:** Sprint 2 aprobado; app remota sincronizada; datos de piloto disponibles o uso claramente rotulado de `../../datos/ejemplo/`. TEC-01/04/05 aparecen implementados parcialmente en estructura y scripts; no se reabren salvo fallas. TEC-02 exige repositorio SQLite con pruebas; la generación de SQLite por script no demuestra por sí sola consumo de SQLite en Flutter.

#### Historias y criterios de aceptación

| Historia | Criterios verificables |
|---|---|
| S3-01 · Lista navegable (HU-S3-01) | **Como estudiante nuevo**, quiero abrir la lista de espacios, **para** comenzar la búsqueda desde la app. **Prioridad:** Must. **Dependencia:** S2 y router sincronizado. **Prueba:** navegación de `/espacios`, contenido, Atrás; no redirige a inicio. |
| S3-02 · Datos offline (HU-S3-02) | **Como visitante**, quiero consultar el catálogo local, **para** encontrar lugares aunque no tenga señal. **Prioridad:** Must. **Dependencia:** TEC-02/04/05 y paquete válido. **Prueba:** catálogo desde SQLite en modo avión, sin llamadas de red. |
| S3-03 · Búsqueda y ficha (HU-S3-03) | **Como visitante**, quiero buscar y abrir ficha, **para** confirmar el lugar. **Prioridad:** Must. **Dependencia:** S3-01/02. **Prueba:** nombre, código, vacío, horario y placeholder de imagen. |
| S3-04 · Datos inválidos (HU-S3-04) | **Como usuario**, quiero saber si los datos locales no son válidos, **para** no recibir una ubicación falsa. **Prioridad:** alta. **Dependencia:** paquete/manifest. **Prueba:** hash, esquema o referencia dañada bloquea catálogo/ruta y produce error recuperable. |
| S3-05 · Contrato del grafo (HU-S3-05) | **Como desarrollador**, quiero probar los casos límite del grafo, **para** que la ruta se comporte correctamente al conectarse al piloto. **Prioridad:** alta. **Dependencia:** TEC-04 y datos de fixture. **Prueba:** origen=destino, vértice inexistente, desconectado y filtro de tramos. |

#### Tareas técnicas

| ID | Tarea | Descripción técnica | Responsable o perfil | Prioridad | Dependencia | Entregable | Criterio de finalización |
|---|---|---|---|---|---|---|---|
| S3-T01 | Verificar entorno y CI | Anotar Flutter/Dart/Node/Android usados; ejecutar checks en el baseline y documentar fallas del entorno aparte de fallas de código | SM + revisor | Alta | S2 aprobado | Registro de versiones/checks por SHA | Checks reproducibles o impedimentos aislados y asignados |
| S3-T02 | Integrar navegación | Conectar las rutas a lista/ficha respetando el flujo aprobado y Atrás | Developer 1 | Must | S3-T01 | Rutas accesibles | Pruebas de navegación pasan; no redirect inesperado |
| S3-T03 | Implementar repositorio local | Abrir SQLite local, mapear entidades y manejar versión/esquema sin SQL en Widgets | Developer 2 | Must | TEC-04/paquete | Adaptador y migración | Pruebas de consulta, inexistente y esquema inválido pasan |
| S3-T04 | Implementar búsqueda | Consultar nombre/código con índice disponible, vacío y normalización acordada | Developer 1 | Must | T02/T03 | Búsqueda conectada a UI | Casos de coincidencia, acento y sin resultados pasan |
| S3-T05 | Validar paquete | Consumir manifest/hash, validar versión y fallar de modo recuperable; probar instalación/rollback definida | Developer 2 + SM | Alta | Scripts existentes y SQLite | Paquete ejemplo reproducible | Hash alterado no se acepta y no deja DB parcial visible |
| S3-T06 | Separar demo de piloto | Mantener fixtures de ejemplo identificables y preparar archivos piloto sin rellenar valores ficticios | PO + campus | Alta | Acceso al responsable | Dataset claramente etiquetado | Ninguna fixture se confunde con dato validado de campo |

**Entregables:** flujo lista/ficha integrado; repositorio local comprobable; paquete de ejemplo consumido en modo avión; contrato documentado de grafo; CI enlazado al commit.

**Validación/evidencia:** pruebas de repositorio/UI para carga, búsqueda, ficha, vacío y paquete inválido; instalar APK en Android físico cuando esté disponible, activar modo avión, repetir lista/ficha; guardar versión y SHA del APK/commit. `flutter analyze`, `flutter test` y scripts deben quedar verdes para los cambios cubiertos.

**Aceptación del sprint:** no existen redirects que bloqueen HU-01/02; lista/ficha leen una fuente SQLite definida; ejemplo sin red pasa; una prueba demuestra fallo de hash/esquema recuperable. **DoD Sprint 3:** PR revisado, CI verde, pruebas pasan, documentación de migración/contrato actualizada. Si solo funciona el mock, no aceptar como integración offline.

---

Plan derivado de [11-planificacion-sprints.md](../plan/11-planificacion-sprints.md), sección 4. Las actividades aquí descritas son planificadas; no representan trabajo completado.
