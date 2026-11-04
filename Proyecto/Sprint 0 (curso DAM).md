---
tags: [unipaz360, proyecto, curso-dam, scrum, sprint]
---
# Sprint 0: tablero y backlog (curso DAM)

**Curso:** Desarrollo de Aplicaciones Móviles (DAM), VIII semestre, UNIPAZ, 2026. **Guía:** Unidad 2, semana 3, sesión B, recibida el 2026-10-13. El original y el texto extraído están en `C:\Users\mamalon\Pictures\univerrsidadaddadada\curso_dam\` (`Sprint_0.html` y `Sprint_0.md`).

## Qué pide el curso
- **Metodología:** Mobile-D (este es el Sprint 0 de la fase de Exploración, semanas 3 a 5), con sprints de **1 semana**, Scrum y Kanban.
- **Entregable:** el **enlace al proyecto de GitHub Projects**, antes de la Sesión A de la semana 4. Cuenta en la nota de talleres (20 %).
- **Hitos del curso:**
  - Hito 0: problema ODS y tecnología.
  - Hito 1: informe con el backlog por épica y el historial de sprints.
  - Hito 2: MVP con las Must.
  - **Hito 3: API + persistencia + una función del dispositivo.**
  - Demo Day.
- **Rúbrica:** visión 20 % · alcance 15 % · backlog 30 % · tablero 20 % · reglas 15 %.
- **Reglas:**
  - Al menos 12 elementos de backlog, ninguno de 13 puntos o más, y las Must no pasan del 60 % del esfuerzo.
  - Tablero con 6 columnas y límites WIP, campos Tipo/Prioridad/Épica/Puntos/Sprint, vistas Backlog/Sprint actual/Por épica y automatizaciones.
  - Plantilla `historia.yml` en el repositorio.
  - Definición del flujo de trabajo y DoD de Exploración en el README.
- **Desde la semana 6**, la DoD exige un APK probado en dispositivo.

## Cómo quedó para UniPaz360
Todo está en `curso_dam/sprint0/`:
- `README.md`: visión, Objetivo del Producto, MoSCoW, backlog, flujo, DoD y Sprint 1.
- `historia.yml`: la plantilla de issues.
- `crear_backlog.ps1`: crea las etiquetas y los issues con GitHub CLI.
- `backlog_campos.csv`: los valores de los campos de cada issue.
- `PASOS_GITHUB.md`: la lista de pasos en la interfaz de GitHub.

**Backlog:**
- 18 elementos y 63 puntos. Must: 27 puntos (43 %).
- 5 épicas: Base, Encontrar, Llegar, Conocer y Mantener.
- **Hito 3 cubierto:** API (HU-09 descarga de datos y HU-13 reporte de errores), persistencia SQLite (TEC-02) y cámara para el QR (HU-06).
- **Won't este semestre:** iOS, Windows, panel web, posicionamiento en interiores y guía por voz. En la [[Formulación y evaluación (curso 910802)|tesis]] el alcance es mayor; el semestre entrega el MVP en Android.
- **Sprint 1 (semana 4):** criterios Dado/Cuando/Entonces y pantallas en Figma de HU-01 a HU-05, más el levantamiento del bloque piloto (INV-01).

## Montado en GitHub (2026-10-13)
- **Repositorio (privado):** https://github.com/mamalon104366/unipaz360. Contiene README, CONTRIBUTING, plantillas de issues y PR, CI con `flutter analyze`, `docs/` y `datos/piloto/`. La copia local está en `univerrsidadaddadada/unipaz360`.
- **Tablero:** https://github.com/users/mamalon104366/projects/1, con 25 tarjetas y 79 puntos.
  - Vistas: Backlog, Tablero (todas las tarjetas), Sprint actual (vacía hasta que empiece el Sprint 1, el 20 de octubre) y Por épica.
  - Límites por columna: Listo 6, En desarrollo 3, En revisión 2 y En dispositivo 2.
  - Campo Sprint: iteraciones semanales desde el 13 de octubre.
  - Automatizaciones: ítem agregado → Backlog; PR enlazado → En revisión; ítem cerrado o PR fusionado → Hecho; al llegar a Hecho se cierra el issue.
- **Equipo:**
  - Esteban (@mamalon104366): PO y Developer.
  - Juan Andrés Rangel (@ondresz): Scrum Master y Developer.
  - Keyner Trujillo (@Causa-Trujillo): Developer.
  - Los dos compañeros están invitados con permiso de escritura al repositorio y al tablero; tienen que aceptar la invitación.
- **Sin rastros de IA:** sin «Co-Authored-By» en los commits. Ver la memoria «sin-atribucion-claude».
- **Script reutilizable:** `curso_dam/sprint0/configurar_github.py`.
- **Ampliación (2026-10-13):**
  - TEC-01 ya no pide proteger `main`.
  - Nuevas tareas: TEC-04 (modelo entidad-relación), TEC-05, TEC-06, TEC-07, TEC-10, INV-02 e INV-03 (script `backlog_v2.py`).
  - Borradores del modelo ER en `docs/datos/modelo-er.md` (Mermaid) y `docs/datos/esquema.sql` (SQLite, validado).
- **Entregable:** el enlace al tablero en el canal del curso, antes de la Sesión A de la semana 4. El texto está en `curso_dam/sprint0/entrega/mensaje_canal.txt`. La evidencia opcional está en `curso_dam/sprint0/entrega/Sprint 0 - UniPaz360 - Evidencia.pdf` (7 páginas, 12 capturas).

## Pendiente
- [x] Roles definidos. Falta el **usuario real** de referencia.
- [x] Repositorio y tablero creados. Falta **instalar Flutter** (para TEC-01, en el Sprint 2).
- [ ] Dar acceso de lectura al **docente** (falta su usuario de GitHub).
- [ ] Confirmar con el profe si un JSON servido por HTTPS cuenta como la «API» del Hito 3. Si no, usar Supabase.

Volver a [[00 UniPaz360 - Índice]]
