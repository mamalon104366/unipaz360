# Google Maps y ubicación de UNIPAZ

La pantalla de ubicación tiene dos capas:

- Una vista aérea local (`app/assets/imagenes/mapa-dron.jpg`) para consulta sin conexión.
- Un mapa interactivo de Google Maps Embed API en Flutter Web cuando se compila con una clave válida.

La coordenada del Centro de Investigaciones Santa Lucía se fija en `7.066153703270713, -73.74487959820672`. El botón de indicaciones abre Google Maps con esa coordenada y no necesita una clave de API.

## Mapa interactivo en web

La implementación lee `GOOGLE_MAPS_API_KEY` como `--dart-define`. Desde `app/`:

```powershell
flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=TU_CLAVE_RESTRINGIDA
```

Para producción, usar el mismo argumento al compilar y restringir la clave en Google Cloud a Maps Embed API y a los dominios autorizados. No guardar la clave en Git ni en archivos de configuración compartidos.

Si la clave no está configurada, el tour conserva el mapa aéreo offline y muestra la coordenada exacta; el enlace a Google Maps permite obtener navegación en línea.

## Recursos oficiales usados en admisiones

- `aspirantes-inscripcion.webp`: imagen de “Diligencia tu formulario”, publicada en el sitio oficial de UNIPAZ (`https://unipaz.edu.co/wp-content/uploads/2025/10/1.1.webp`).
- `aspirantes-documentos.jpg`: imagen de “Carga tus documentos”, publicada en el sitio oficial de UNIPAZ (`https://unipaz.edu.co/wp-content/uploads/2025/10/2.jpeg`).
- `programas-pregrado-oficial.jpg`: fotografía de la sección de pregrados del sitio oficial de UNIPAZ (`https://unipaz.edu.co/wp-content/uploads/2024/07/Imagen-Pregrados-e1722956361754.jpg`).
- `unipaz-banner-oficial.png`: banner institucional del sitio oficial de UNIPAZ.
- `BienvenidosUNIPAZ.mp4`: video institucional copiado desde la carpeta Descargas del usuario.

Páginas institucionales de referencia: [Soy aspirante](https://unipaz.edu.co/soy-aspirante/), [admisiones y matrícula](https://unipaz.edu.co/inscripcion-entrega-de-documentos-admision-y-matricula-territorio/) y [programas de pregrado](https://unipaz.edu.co/programas-de-pregrado/). Los requisitos, precios y periodos se enlazan al sitio oficial para evitar fijar en la app información que cambia.

La integración sigue el formato de la [Maps Embed API](https://developers.google.com/maps/documentation/embed/quickstart), que requiere una API key restringida. La navegación por [Maps URLs](https://developers.google.com/maps/documentation/urls/get-started) abre Google Maps sin una key.
