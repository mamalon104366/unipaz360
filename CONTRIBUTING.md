# Cómo trabajamos en UniPaz360

## 1. Del issue a «Hecho»
1. **Tomar una tarjeta de «Listo»:** asígnatela y pásala a «En desarrollo». Solo una tarjeta por persona.
2. **Crear la rama desde `main`.** El nombre de la rama es el ID en minúsculas más 2 o 3 palabras:
   ```bash
   git switch main
   git pull
   git switch -c hu-04-ruta-corta
   ```
   Otros ejemplos: `tec-02-sqlite`, `inv-01-bloque-piloto`.
3. **Hacer commits pequeños** con el formato `tipo(ID): qué cambió`. Ejemplos:
   - `feat(HU-04): calcular ruta con A*`
   - `test(HU-04): comparar A* con Dijkstra`
   - `fix(HU-01): ignorar tildes en la búsqueda`
   - `docs(INV-01): agregar tramos del bloque 1`

   Tipos: `feat`, `fix`, `test`, `docs`, `refactor`, `chore`.
4. **Abrir el pull request** con `Closes #N` en la descripción y pasar la tarjeta a «En revisión». El CI corre `flutter analyze` y las pruebas.
5. **Revisión:** otra persona del equipo revisa y aprueba. Nadie fusiona su propio PR sin aprobación.
6. **En dispositivo:** se instala el APK de la rama en un Android físico y se prueba **en modo avión**. Si pasa, la tarjeta va a «En dispositivo» y luego se fusiona.
7. **Fusionar:** al fusionar el PR, GitHub cierra el issue y la tarjeta pasa sola a «Hecho».

## 2. Reglas de `main`
- No se hace push directo a `main`; todo entra por pull request.
- `main` siempre compila y se puede instalar.

## 3. Bloqueos
Si una tarjeta no puede avanzar:
- Ponle la etiqueta `bloqueada` y dilo en el Daily.
- Si sigue bloqueada dos días, el Scrum Master interviene.

## 4. Datos del campus
- Los datos se editan en `datos/` siguiendo [docs/datos/formato-paquete.md](docs/datos/formato-paquete.md).
- Cada cambio de datos también va por pull request.
- Solo se marca un tramo como accesible si se verificó en campo.
