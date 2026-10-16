-- ============================================================================
--  UniPaz360 · Esquema de la base central (PostgreSQL + PostGIS)
--  Migración 0001 — esquema inicial
--
--  La ejecuta db/migrar.mjs. Es idempotente a nivel de migración: se aplica
--  una sola vez y queda registrada en la tabla "migraciones".
--
--  Convenciones
--   · Claves de catálogo: TEXT (identificadores legibles, fáciles de editar
--     por el panel y de versionar en el repositorio).
--   · Claves transaccionales: BIGSERIAL o UUID.
--   · Geometría: SRID 4326 (WGS84), con índice GIST. Se guarda WKT/GeoJSON
--     además de las columnas planas cuando hace falta (lat/lon).
--   · Fechas: TIMESTAMPTZ. Horas: TIME.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- gen_random_uuid()

-- ---------------------------------------------------------------------------
--  Función de utilidad: mantiene "actualizado_en" al día en cada UPDATE.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION tocar_actualizado_en() RETURNS trigger AS $$
BEGIN
    NEW.actualizado_en := clock_timestamp();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ===========================================================================
--  1. CATÁLOGO DEL CAMPUS
-- ===========================================================================

CREATE TABLE campus (
    id              TEXT PRIMARY KEY,
    nombre          TEXT NOT NULL,
    descripcion     TEXT,
    centro_lat      DOUBLE PRECISION,
    centro_lon      DOUBLE PRECISION,
    zoom_defecto    INTEGER NOT NULL DEFAULT 18,
    activo          BOOLEAN NOT NULL DEFAULT true,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE campus IS 'Sede o campus. P. ej. Centro de Investigaciones Santa Lucía de UNIPAZ.';

CREATE TABLE bloque (
    id              TEXT PRIMARY KEY,
    campus_id       TEXT NOT NULL REFERENCES campus(id) ON DELETE CASCADE,
    nombre          TEXT NOT NULL,
    descripcion     TEXT,
    altura_m        DOUBLE PRECISION,
    geometria       geometry(Polygon, 4326),
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE bloque IS 'Edificio o bloque dentro de un campus (su huella en el plano).';

CREATE TABLE nivel (
    id              TEXT PRIMARY KEY,
    bloque_id       TEXT NOT NULL REFERENCES bloque(id) ON DELETE CASCADE,
    numero          INTEGER NOT NULL,          -- 0 = planta baja, negativos = sótanos
    nombre          TEXT,
    elevacion_m     DOUBLE PRECISION,
    plano_url       TEXT,                      -- plano 2D georreferenciado (clave en R2)
    plano_bounds    JSONB,                     -- esquinas del plano para georreferenciar
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (bloque_id, numero)
);
COMMENT ON TABLE nivel IS 'Piso de un bloque. Agrupa los espacios que hay en esa planta.';

CREATE TABLE espacio (
    id              TEXT PRIMARY KEY,
    campus_id       TEXT NOT NULL REFERENCES campus(id) ON DELETE CASCADE,
    nivel_id        TEXT REFERENCES nivel(id) ON DELETE SET NULL,
    nombre          TEXT NOT NULL,
    codigo          TEXT NOT NULL,
    categoria       TEXT NOT NULL,
    servicios       TEXT[] NOT NULL DEFAULT '{}',
    descripcion     TEXT,
    foto_url        TEXT,
    horario         TEXT,                      -- horario general en texto (informativo)
    vertice_id      TEXT,                      -- vértice de acceso (FK se declara tras vertice)
    geometria       geometry(Polygon, 4326),
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (campus_id, codigo)
);
COMMENT ON TABLE espacio IS 'Aula, oficina, laboratorio u otro lugar buscable. Se llega por su vértice de acceso.';

CREATE TABLE vertice (
    id              TEXT PRIMARY KEY,
    campus_id       TEXT NOT NULL REFERENCES campus(id) ON DELETE CASCADE,
    lat             DOUBLE PRECISION NOT NULL,
    lon             DOUBLE PRECISION NOT NULL,
    nivel           INTEGER NOT NULL DEFAULT 0,
    bloque_id       TEXT REFERENCES bloque(id) ON DELETE SET NULL,
    tipo            TEXT NOT NULL
                    CHECK (tipo IN ('puerta','cruce','escalera','rampa','ascensor','acceso','referencia')),
    descripcion     TEXT,
    geometria       geometry(Point, 4326),
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE vertice IS 'Punto de la red peatonal: puerta, cruce, escalera, rampa, acceso o referencia.';

CREATE TABLE tramo (
    id              TEXT PRIMARY KEY,
    campus_id       TEXT NOT NULL REFERENCES campus(id) ON DELETE CASCADE,
    origen_id       TEXT NOT NULL REFERENCES vertice(id) ON DELETE CASCADE,
    destino_id      TEXT NOT NULL REFERENCES vertice(id) ON DELETE CASCADE,
    longitud_m      DOUBLE PRECISION,
    desnivel_m      DOUBLE PRECISION NOT NULL DEFAULT 0,
    pendiente_pct   DOUBLE PRECISION NOT NULL DEFAULT 0,
    escaleras       BOOLEAN NOT NULL DEFAULT false,
    superficie      TEXT CHECK (superficie IS NULL OR
                    superficie IN ('piso','tierra','grava','pasto','rampa','escalera')),
    ancho_m         DOUBLE PRECISION,
    accesible       BOOLEAN NOT NULL DEFAULT false,
    bidireccional   BOOLEAN NOT NULL DEFAULT true,
    verificado      BOOLEAN NOT NULL DEFAULT false,
    geometria       geometry(LineString, 4326),
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (origen_id <> destino_id),
    -- Un tramo marcado accesible no puede tener escaleras y debe estar verificado.
    CHECK (accesible = false OR (escaleras = false AND verificado = true))
);
COMMENT ON TABLE tramo IS 'Trozo de camino entre dos vértices. Sus atributos deciden si la ruta es accesible.';

CREATE TABLE anclaje (
    id              TEXT PRIMARY KEY,
    campus_id       TEXT NOT NULL REFERENCES campus(id) ON DELETE CASCADE,
    uri             TEXT NOT NULL UNIQUE,      -- contenido del QR (p. ej. unipaz360://...)
    vertice_id      TEXT NOT NULL REFERENCES vertice(id) ON DELETE CASCADE,
    ubicacion       TEXT,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE anclaje IS 'Placa QR instalada en el campus: su URI se traduce al vértice de origen.';

CREATE TABLE medio (
    id              TEXT PRIMARY KEY,
    campus_id       TEXT NOT NULL REFERENCES campus(id) ON DELETE CASCADE,
    tipo            TEXT NOT NULL CHECK (tipo IN ('foto','panoramica','ortofoto','video','modelo','plano')),
    archivo         TEXT NOT NULL,             -- clave/objeto dentro del bucket de R2
    url_publica     TEXT,
    mime            TEXT,
    bytes           BIGINT,
    sha256          TEXT,
    licencia        TEXT,
    ancho           INTEGER,
    alto            INTEGER,
    lods            JSONB,                     -- variantes por nivel de detalle
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE medio IS 'Archivo multimedia (foto, panorama, ortofoto, video, modelo o plano) guardado en R2.';

CREATE TABLE panoramica (
    id              TEXT PRIMARY KEY,
    campus_id       TEXT NOT NULL REFERENCES campus(id) ON DELETE CASCADE,
    vertice_id      TEXT NOT NULL REFERENCES vertice(id) ON DELETE CASCADE,
    medio_id        TEXT REFERENCES medio(id) ON DELETE SET NULL,
    archivo         TEXT NOT NULL,
    rumbo_inicial   DOUBLE PRECISION,          -- hacia dónde abre el visor 360°
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE panoramica IS 'Foto 360° tomada en un vértice.';

CREATE TABLE enlace_panoramica (
    origen_id       TEXT NOT NULL REFERENCES panoramica(id) ON DELETE CASCADE,
    destino_id      TEXT NOT NULL REFERENCES panoramica(id) ON DELETE CASCADE,
    PRIMARY KEY (origen_id, destino_id),
    CHECK (origen_id <> destino_id)
);
COMMENT ON TABLE enlace_panoramica IS 'Relación muchos a muchos entre panorámicas para saltar de una a otra.';

-- FK diferida de espacio.vertice_id (ya existe "vertice").
ALTER TABLE espacio
    ADD CONSTRAINT espacio_vertice_fk FOREIGN KEY (vertice_id)
    REFERENCES vertice(id) ON DELETE SET NULL;


-- ===========================================================================
--  2. HORARIOS Y CALENDARIO  (alimentan el chatbot; visibles con correo institucional)
-- ===========================================================================

CREATE TABLE horario (
    id              BIGSERIAL PRIMARY KEY,
    campus_id       TEXT NOT NULL REFERENCES campus(id) ON DELETE CASCADE,
    espacio_id      TEXT NOT NULL REFERENCES espacio(id) ON DELETE CASCADE,
    dia             SMALLINT NOT NULL CHECK (dia BETWEEN 1 AND 7),  -- ISO: 1 = lunes … 7 = domingo
    hora_inicio     TIME NOT NULL,
    hora_fin        TIME NOT NULL,
    materia         TEXT,
    programa        TEXT,
    semestre        INTEGER,
    grupo           TEXT,
    docente         TEXT,
    notas           TEXT,
    vigencia_desde  DATE,
    vigencia_hasta  DATE,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (hora_inicio < hora_fin)
);
COMMENT ON TABLE horario IS 'Franja de clase de un espacio. Base para responder "¿qué hay en el Aula 101 el martes?".';

CREATE TABLE calendario_academico (
    id              BIGSERIAL PRIMARY KEY,
    campus_id       TEXT REFERENCES campus(id) ON DELETE CASCADE,
    fecha           DATE NOT NULL,
    tipo            TEXT NOT NULL
                    CHECK (tipo IN ('festivo','no_laborable','inicio_semestre','fin_semestre','examen','evento')),
    descripcion     TEXT,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (campus_id, fecha, tipo)
);
COMMENT ON TABLE calendario_academico IS 'Días sin clase, festivos y fechas clave. Base para "¿hay clase el 20 de julio?".';


-- ===========================================================================
--  3. CUENTAS, AUDITORÍA Y PUBLICACIONES  (panel de administración)
-- ===========================================================================

CREATE TABLE usuario (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    correo          TEXT NOT NULL UNIQUE,
    nombre          TEXT,
    rol             TEXT NOT NULL DEFAULT 'lector'
                    CHECK (rol IN ('superadmin','editor','lector','estudiante')),
    institucional   BOOLEAN NOT NULL DEFAULT false,   -- correo @unipaz.edu.co verificado
    activo          BOOLEAN NOT NULL DEFAULT true,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    ultimo_acceso   TIMESTAMPTZ
);
COMMENT ON TABLE usuario IS 'Cuentas del panel (superadmin/editor/lector) y de la app (estudiante).';

CREATE TABLE perfil_estudiante (
    usuario_id      UUID PRIMARY KEY REFERENCES usuario(id) ON DELETE CASCADE,
    programa        TEXT,
    semestre        INTEGER,
    grupo           TEXT,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    actualizado_en  TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE perfil_estudiante IS 'Datos de un estudiante para filtrar los horarios que le interesan.';

CREATE TABLE auditoria (
    id              BIGSERIAL PRIMARY KEY,
    usuario_id      UUID REFERENCES usuario(id) ON DELETE SET NULL,
    accion          TEXT NOT NULL,             -- crear / actualizar / borrar / publicar / iniciar_sesion / salir
    entidad         TEXT,
    entidad_id      TEXT,
    antes           JSONB,
    despues         JSONB,
    ip              INET,
    agente          TEXT,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now()
);
COMMENT ON TABLE auditoria IS 'Bitácora de cambios del panel. Registra quién cambió qué y cuándo.';

CREATE TABLE publicacion (
    id              BIGSERIAL PRIMARY KEY,
    version         TEXT NOT NULL UNIQUE,
    estado          TEXT NOT NULL DEFAULT 'borrador'
                    CHECK (estado IN ('borrador','en_proceso','publicada','fallida','revertida')),
    notas           TEXT,
    autor_id        UUID REFERENCES usuario(id) ON DELETE SET NULL,
    sha256          TEXT,
    tamano_bytes    BIGINT,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    publicado_en    TIMESTAMPTZ
);
COMMENT ON TABLE publicacion IS 'Versión del paquete de datos generada y publicada a producción.';

CREATE TABLE reporte (
    id              BIGSERIAL PRIMARY KEY,
    campus_id       TEXT REFERENCES campus(id) ON DELETE SET NULL,
    tipo            TEXT NOT NULL CHECK (tipo IN ('ruta','ficha','horario','otro')),
    referencia      TEXT,
    descripcion     TEXT NOT NULL,
    estado          TEXT NOT NULL DEFAULT 'nuevo'
                    CHECK (estado IN ('nuevo','en_proceso','resuelto','descartado')),
    lat             DOUBLE PRECISION,
    lon             DOUBLE PRECISION,
    creado_en       TIMESTAMPTZ NOT NULL DEFAULT now(),
    resuelto_en     TIMESTAMPTZ
);
COMMENT ON TABLE reporte IS 'Reporte de error enviado desde la app (con o sin conexión).';


-- ===========================================================================
--  4. ÍNDICES
-- ===========================================================================

CREATE INDEX bloque_campus_idx       ON bloque(campus_id);
CREATE INDEX bloque_geom_idx         ON bloque USING gist(geometria);
CREATE INDEX nivel_bloque_idx        ON nivel(bloque_id);
CREATE INDEX espacio_campus_idx      ON espacio(campus_id);
CREATE INDEX espacio_nivel_idx       ON espacio(nivel_id);
CREATE INDEX espacio_nombre_idx      ON espacio(lower(nombre));
CREATE INDEX espacio_geom_idx        ON espacio USING gist(geometria);
CREATE INDEX vertice_campus_idx      ON vertice(campus_id);
CREATE INDEX vertice_geom_idx        ON vertice USING gist(geometria);
CREATE INDEX tramo_campus_idx        ON tramo(campus_id);
CREATE INDEX tramo_origen_idx        ON tramo(origen_id);
CREATE INDEX tramo_destino_idx       ON tramo(destino_id);
CREATE INDEX anclaje_vertice_idx     ON anclaje(vertice_id);
CREATE INDEX medio_campus_idx        ON medio(campus_id);
CREATE INDEX panoramica_vertice_idx  ON panoramica(vertice_id);
CREATE INDEX horario_espacio_idx     ON horario(espacio_id, dia, hora_inicio);
CREATE INDEX horario_programa_idx    ON horario(programa, semestre, grupo);
CREATE INDEX calendario_fecha_idx    ON calendario_academico(fecha);
CREATE INDEX auditoria_usuario_idx   ON auditoria(usuario_id, creado_en DESC);
CREATE INDEX reporte_estado_idx      ON reporte(estado, creado_en DESC);


-- ===========================================================================
--  5. TRIGGERS: actualizado_en
-- ===========================================================================

DO $$
DECLARE t text;
BEGIN
    FOR t IN
        SELECT unnest(ARRAY[
            'campus','bloque','nivel','espacio','vertice','tramo','anclaje','medio',
            'panoramica','horario','perfil_estudiante'
        ]::text[])
    LOOP
        EXECUTE format(
            'CREATE TRIGGER %I_tocar BEFORE UPDATE ON %I
             FOR EACH ROW EXECUTE FUNCTION tocar_actualizado_en()',
            t, t
        );
    END LOOP;
END $$;
