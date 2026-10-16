-- Semilla idempotente: campus piloto.
-- El identificador "santa-lucia" es el que usará el paquete de datos y el panel.

INSERT INTO campus (id, nombre, descripcion, centro_lat, centro_lon, zoom_defecto, activo)
VALUES (
    'santa-lucia',
    'Centro de Investigaciones Santa Lucía',
    'Campus piloto de UniPaz360.',
    NULL, NULL, 18, true
)
ON CONFLICT (id) DO NOTHING;
