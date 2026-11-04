-- ===========================================================================
--  0002 · Plataforma completa (sprint P2)
--
--  Todo es aditivo: no se borra ni se renombra nada de 0001.
--   1. Contadores: identificadores que NUNCA se reutilizan (V-001, T-001, QR-001…)
--   2. Cuentas del panel: contraseña con scrypt y sesiones en la base
--   3. Anclajes QR: instalación y retiro (una URI impresa jamás se reutiliza)
--   4. Panorámicas: ajustes no destructivos, título y posición manual de flechas
--   5. Puntos de información sobre las panorámicas (hotspots)
-- ===========================================================================

-- ---------------------------------------------------------------- 1. contadores
CREATE TABLE contador (
    campus_id   TEXT NOT NULL REFERENCES campus(id) ON DELETE CASCADE,
    entidad     TEXT NOT NULL,
    ultimo      INTEGER NOT NULL DEFAULT 0 CHECK (ultimo >= 0),
    PRIMARY KEY (campus_id, entidad)
);
COMMENT ON TABLE contador IS 'Último número usado por entidad: los identificadores no se reutilizan aunque se borre el registro.';

INSERT INTO contador (campus_id, entidad, ultimo)
SELECT campus_id, 'vertice', coalesce(max(substring(id from '^V-(\d+)$')::int), 0)
  FROM vertice GROUP BY campus_id
ON CONFLICT DO NOTHING;

INSERT INTO contador (campus_id, entidad, ultimo)
SELECT campus_id, 'tramo', coalesce(max(substring(id from '^T-(\d+)$')::int), 0)
  FROM tramo GROUP BY campus_id
ON CONFLICT DO NOTHING;

-- ---------------------------------------------------------------- 2. cuentas y sesiones
ALTER TABLE usuario
    ADD COLUMN clave_hash          TEXT,                       -- scrypt$N$r$p$sal$hash
    ADD COLUMN debe_cambiar_clave  BOOLEAN NOT NULL DEFAULT false;

CREATE TABLE sesion (
    id          TEXT PRIMARY KEY,                              -- SHA-256 del token (el token solo vive en la cookie)
    usuario_id  UUID NOT NULL REFERENCES usuario(id) ON DELETE CASCADE,
    creado_en   TIMESTAMPTZ NOT NULL DEFAULT now(),
    expira_en   TIMESTAMPTZ NOT NULL,
    ip          INET,
    agente      TEXT
);
COMMENT ON TABLE sesion IS 'Sesiones abiertas del panel. Cerrar sesión o desactivar la cuenta las elimina.';
CREATE INDEX sesion_usuario_idx ON sesion(usuario_id);
CREATE INDEX sesion_expira_idx  ON sesion(expira_en);

CREATE INDEX auditoria_fecha_idx   ON auditoria(creado_en DESC);
CREATE INDEX auditoria_entidad_idx ON auditoria(entidad, entidad_id);

-- ---------------------------------------------------------------- 3. anclajes QR
ALTER TABLE anclaje
    ADD COLUMN autorizado_por  TEXT,
    ADD COLUMN instalada       BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN retirado_en     TIMESTAMPTZ;
COMMENT ON COLUMN anclaje.retirado_en IS 'Placa retirada: no se publica, pero su URI queda reservada para siempre.';

-- ---------------------------------------------------------------- 4. panorámicas
ALTER TABLE panoramica
    ADD COLUMN titulo   TEXT,
    ADD COLUMN ajustes  JSONB NOT NULL DEFAULT '{}'::jsonb;
COMMENT ON COLUMN panoramica.ajustes IS
    'Edición no destructiva: {norte, inclinacion, alabeo, exposicion, contraste, saturacion, temperatura, nadir, difuminados[]}. El original no se toca.';

ALTER TABLE enlace_panoramica
    ADD COLUMN yaw    DOUBLE PRECISION,                        -- NULL = posición automática según el mapa
    ADD COLUMN pitch  DOUBLE PRECISION;

-- ---------------------------------------------------------------- 5. puntos de información
CREATE TABLE punto_informacion (
    id                     TEXT PRIMARY KEY,
    campus_id              TEXT NOT NULL REFERENCES campus(id) ON DELETE CASCADE,
    panoramica_id          TEXT NOT NULL REFERENCES panoramica(id) ON DELETE CASCADE,
    tipo                   TEXT NOT NULL
                           CHECK (tipo IN ('informacion','anuncio','imagen','video','enlace','espacio','accesibilidad')),
    yaw                    DOUBLE PRECISION NOT NULL,          -- grados; 0 = centro de la foto, + a la derecha
    pitch                  DOUBLE PRECISION NOT NULL CHECK (pitch BETWEEN -90 AND 90),
    titulo                 TEXT NOT NULL,
    texto                  TEXT,
    medio_id               TEXT REFERENCES medio(id) ON DELETE SET NULL,
    url                    TEXT,
    destino_panoramica_id  TEXT REFERENCES panoramica(id) ON DELETE CASCADE,
    espacio_id             TEXT REFERENCES espacio(id) ON DELETE CASCADE,
    vigente_desde          TIMESTAMPTZ,
    vigente_hasta          TIMESTAMPTZ,
    creado_en              TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en         TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (tipo <> 'enlace'  OR destino_panoramica_id IS NOT NULL),
    CHECK (tipo <> 'espacio' OR espacio_id IS NOT NULL),
    CHECK (vigente_desde IS NULL OR vigente_hasta IS NULL OR vigente_desde < vigente_hasta)
);
COMMENT ON TABLE punto_informacion IS
    'Contenido sobre una panorámica: información, anuncio con vigencia, imagen, video, enlace a otro nodo, ficha de espacio o advertencia de accesibilidad.';
CREATE INDEX punto_panoramica_idx ON punto_informacion(panoramica_id);

CREATE TRIGGER punto_informacion_tocar BEFORE UPDATE ON punto_informacion
    FOR EACH ROW EXECUTE FUNCTION tocar_actualizado_en();
