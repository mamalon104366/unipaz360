# Panel de administración (web)

Consola para gestionar los mapas, los nodos y las rutas del campus, subir edificios y fotos, y **publicar** los datos a la app. Se construye en la fase **F3**.

> Todavía no hay código: esta carpeta reserva su lugar en el monorepo.

## Qué irá aquí

- **Next.js** (App Router) + TypeScript, desplegado en Vercel.
- Editor de mapas con **MapLibre GL JS** (dibujar bloques, salones y tramos).
- Vista previa 360° con **Photo Sphere Viewer**.
- Autenticación institucional, roles y **auditoría**.
- Botón **Publicar** que dispara el empaquetado de `scripts/` y sube el paquete a R2.

El diseño completo está en [`docs/plan/05-plataforma-admin.md`](../docs/plan/05-plataforma-admin.md).

## Comandos previstos

```bash
npm install
npm run dev      # desarrollo local
npm run build    # el CI lo ejecuta cuando exista panel/package.json
```
