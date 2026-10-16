# App UniPaz360 (Flutter)

Aquí vive la **aplicación multiplataforma** —Android, iOS, web y escritorio con el mismo código—. Se crea en **TEC-01**.

## Crear el proyecto (TEC-01)

```bash
cd app
flutter create --project-name unipaz360 --org edu.unipaz --platforms android,ios,web,windows .
```

> El comando se ejecuta *dentro* de `app/` (el punto final es la carpeta actual). El proyecto se llama `unipaz360`, **no** `app`.

## Organización prevista de `lib/`

| Carpeta | Contenido |
|---|---|
| `lib/datos/` | SQLite (drift), lector del paquete de datos, sincronizador de versiones |
| `lib/dominio/` | Grafo y A\*, búsqueda, chatbot y horarios (Dart puro, con pruebas) |
| `lib/ui/` | Pantallas: mapa 2D, 360°, dron, tour QR, chat, ajustes |
| `lib/plataforma/` | Adaptadores: archivos, conectividad, cámara QR, compartir |

El diseño completo está en [`docs/plan/04-cliente-flutter.md`](../docs/plan/04-cliente-flutter.md).

## Comandos

```bash
flutter pub get          # dependencias
flutter analyze          # análisis estático (lo corre el CI)
flutter test             # pruebas (las corre el CI)
flutter run -d windows   # también -d chrome o un Android conectado
```

El CI (`.github/workflows/ci.yml`) ejecuta `analyze` y `test` en cada PR cuando existe `app/pubspec.yaml`.
