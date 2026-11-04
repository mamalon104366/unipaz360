-- ===========================================================================
--  0004 · Configuración visual de la app (aditiva)
--  Lo que se edita en "Cliente" del panel: marca, colores, encabezado, barra
--  lateral, minimapa y pantalla de inicio. Viaja en el paquete (tabla
--  configuracion_app del esquema local) para que la app Flutter lo aplique.
-- ===========================================================================
CREATE TABLE configuracion_app (
    campus_id       TEXT PRIMARY KEY REFERENCES campus(id) ON DELETE CASCADE,
    config          JSONB NOT NULL DEFAULT '{}'::jsonb,
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE configuracion_app IS 'Apariencia de la app del visitante, editada en el apartado Cliente del panel.';

CREATE TRIGGER configuracion_app_tocar BEFORE UPDATE ON configuracion_app
    FOR EACH ROW EXECUTE FUNCTION tocar_actualizado_en();
