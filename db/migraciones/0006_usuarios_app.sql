-- ===========================================================================
--  0006 · Quién usa la app con la cuenta institucional (aditiva)
--
--  La app abre sin pedir cuenta. Quien quiere ver lo institucional entra con
--  Google (@unipaz.edu.co) desde la propia app: el navegador pasa por el panel,
--  que valida la cuenta y deja el resultado para que la app lo recoja.
--
--  usuario_app: una fila por persona, con cuántas veces entró y abrió la app.
--  sesion_app : un ingreso por dispositivo. `reto` es el SHA-256 de un secreto
--               que solo tiene ese dispositivo; `ficha_hash`, el SHA-256 de la
--               ficha con la que después avisa cada vez que se abre la app.
--               Aquí nunca se guardan el secreto ni la ficha.
-- ===========================================================================
CREATE TABLE usuario_app (
    correo          TEXT PRIMARY KEY,
    nombre          TEXT,
    primer_ingreso  TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultimo_ingreso  TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultimo_uso      TIMESTAMPTZ NOT NULL DEFAULT now(),
    ingresos        INTEGER NOT NULL DEFAULT 0 CHECK (ingresos >= 0),
    aperturas       INTEGER NOT NULL DEFAULT 0 CHECK (aperturas >= 0)
);
COMMENT ON TABLE usuario_app IS 'Personas que entraron a la app con su cuenta institucional, y cuánto la usan.';
COMMENT ON COLUMN usuario_app.ingresos IS 'Veces que inició sesión con Google en la app.';
COMMENT ON COLUMN usuario_app.aperturas IS 'Veces que abrió la app con la sesión iniciada.';

CREATE TABLE sesion_app (
    reto            TEXT PRIMARY KEY CHECK (reto ~ '^[0-9a-f]{64}$'),
    correo          TEXT REFERENCES usuario_app(correo) ON DELETE CASCADE,
    ficha_hash      TEXT UNIQUE,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    confirmado_en   TIMESTAMPTZ,
    ultimo_uso      TIMESTAMPTZ
);
CREATE INDEX sesion_app_correo ON sesion_app (correo);
CREATE INDEX sesion_app_pendientes ON sesion_app (creado_en) WHERE ficha_hash IS NULL;
COMMENT ON TABLE sesion_app IS 'Ingresos de la app por dispositivo: pendiente, confirmado por Google y con ficha entregada.';
