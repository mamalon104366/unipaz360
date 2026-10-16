-- ============================================================================
--  UniPaz360 · Esquema de la base LOCAL (SQLite) · v2
--
--  Lo usa scripts/empaquetar.mjs para construir "datos.sqlite" dentro del
--  paquete de datos. La app lo consume en SOLO LECTURA; en el dispositivo no se
--  edita a mano (la actualización reemplaza el archivo completo, decisión D4).
--
--  Está desnormalizado a propósito: la app solo necesita leer rápido, no editar.
--  El esquema completo vive en la base central (Neon): db/migraciones/*.sql.
-- ============================================================================

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------------
--  Metadatos del paquete (versión, campus, hash del contenido…)
-- ---------------------------------------------------------------------------
CREATE TABLE metadatos (
    clave  TEXT PRIMARY KEY,
    valor  TEXT NOT NULL
);

-- ---------------------------------------------------------------------------
--  Catálogo del campus
-- ---------------------------------------------------------------------------
CREATE TABLE campus (
    id          TEXT PRIMARY KEY,
    nombre      TEXT NOT NULL,
    centro_lat  REAL,
    centro_lon  REAL,
    zoom        INTEGER NOT NULL DEFAULT 18
);

CREATE TABLE medio (
    id       TEXT PRIMARY KEY,
    tipo     TEXT NOT NULL CHECK (tipo IN ('foto','panoramica','ortofoto','video','modelo','plano')),
    archivo  TEXT NOT NULL,
    mime     TEXT,
    bytes    INTEGER,
    sha256   TEXT,
    ancho    INTEGER,
    alto     INTEGER
);

-- ---------------------------------------------------------------------------
--  Red peatonal
-- ---------------------------------------------------------------------------
CREATE TABLE vertice (
    id           TEXT PRIMARY KEY,
    campus_id    TEXT NOT NULL,
    lat          REAL NOT NULL,
    lon          REAL NOT NULL,
    nivel        INTEGER NOT NULL DEFAULT 0,
    tipo         TEXT NOT NULL CHECK (tipo IN ('puerta','cruce','escalera','rampa','ascensor','acceso','referencia')),
    descripcion  TEXT
);

CREATE TABLE tramo (
    id             TEXT PRIMARY KEY,
    campus_id      TEXT NOT NULL,
    origen_id      TEXT NOT NULL REFERENCES vertice(id),
    destino_id     TEXT NOT NULL REFERENCES vertice(id),
    longitud_m     REAL,
    desnivel_m     REAL NOT NULL DEFAULT 0,
    pendiente_pct  REAL NOT NULL DEFAULT 0,
    escaleras      INTEGER NOT NULL DEFAULT 0 CHECK (escaleras IN (0,1)),
    superficie     TEXT,
    ancho_m        REAL,
    accesible      INTEGER NOT NULL DEFAULT 0 CHECK (accesible IN (0,1)),
    bidireccional  INTEGER NOT NULL DEFAULT 1 CHECK (bidireccional IN (0,1)),
    verificado     INTEGER NOT NULL DEFAULT 0 CHECK (verificado IN (0,1)),
    CHECK (origen_id <> destino_id),
    CHECK (accesible = 0 OR (escaleras = 0 AND verificado = 1))
);

-- ---------------------------------------------------------------------------
--  Espacios buscables
-- ---------------------------------------------------------------------------
CREATE TABLE espacio (
    id           TEXT PRIMARY KEY,
    campus_id    TEXT NOT NULL,
    nombre       TEXT NOT NULL,
    codigo       TEXT NOT NULL,
    categoria    TEXT NOT NULL,
    bloque       TEXT,
    nivel        INTEGER NOT NULL DEFAULT 0,
    vertice_id   TEXT REFERENCES vertice(id),
    horario      TEXT,
    servicios    TEXT,
    descripcion  TEXT,
    foto         TEXT,
    UNIQUE (campus_id, codigo)
);

-- ---------------------------------------------------------------------------
--  Realidad aumentada / 360° / placas QR
-- ---------------------------------------------------------------------------
CREATE TABLE anclaje (
    id              TEXT PRIMARY KEY,
    campus_id       TEXT NOT NULL,
    uri             TEXT NOT NULL UNIQUE,
    vertice_id      TEXT NOT NULL REFERENCES vertice(id),
    ubicacion       TEXT,
    autorizado_por  TEXT,
    instalada       INTEGER NOT NULL DEFAULT 0 CHECK (instalada IN (0,1))
);

CREATE TABLE panoramica (
    id              TEXT PRIMARY KEY,
    campus_id       TEXT NOT NULL,
    vertice_id      TEXT NOT NULL REFERENCES vertice(id),
    archivo         TEXT NOT NULL,
    rumbo_inicial   REAL
);

CREATE TABLE enlace_panoramica (
    origen_id   TEXT NOT NULL REFERENCES panoramica(id),
    destino_id  TEXT NOT NULL REFERENCES panoramica(id),
    PRIMARY KEY (origen_id, destino_id),
    CHECK (origen_id <> destino_id)
);

-- ---------------------------------------------------------------------------
--  Horarios y calendario (el chatbot los usa)
-- ---------------------------------------------------------------------------
CREATE TABLE horario (
    id           TEXT PRIMARY KEY,
    espacio_id   TEXT NOT NULL REFERENCES espacio(id),
    dia          INTEGER NOT NULL CHECK (dia BETWEEN 1 AND 7),   -- ISO: 1 = lunes
    hora_inicio  TEXT NOT NULL,   -- HH:MM
    hora_fin     TEXT NOT NULL,
    materia      TEXT,
    programa     TEXT,
    semestre     INTEGER,
    grupo        TEXT,
    docente      TEXT,
    CHECK (hora_inicio < hora_fin)
);

CREATE TABLE calendario_academico (
    fecha        TEXT NOT NULL,
    tipo         TEXT NOT NULL CHECK (tipo IN ('festivo','no_laborable','inicio_semestre','fin_semestre','examen','evento')),
    descripcion  TEXT,
    PRIMARY KEY (fecha, tipo)
);

-- ---------------------------------------------------------------------------
--  Reportes sin conexión (cola local que la app envía cuando hay red)
-- ---------------------------------------------------------------------------
CREATE TABLE reporte (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo         TEXT NOT NULL CHECK (tipo IN ('ruta','ficha','horario','otro')),
    referencia   TEXT,
    descripcion  TEXT NOT NULL,
    creado_en    TEXT NOT NULL DEFAULT (datetime('now')),
    enviado      INTEGER NOT NULL DEFAULT 0 CHECK (enviado IN (0,1))
);

-- ---------------------------------------------------------------------------
--  Índices y búsqueda difusa (FTS5)
-- ---------------------------------------------------------------------------
CREATE INDEX idx_tramo_origen    ON tramo(origen_id);
CREATE INDEX idx_tramo_destino   ON tramo(destino_id);
CREATE INDEX idx_espacio_nombre  ON espacio(nombre);
CREATE INDEX idx_espacio_codigo  ON espacio(codigo);
CREATE INDEX idx_horario_espacio ON horario(espacio_id, dia, hora_inicio);
CREATE INDEX idx_horario_materia ON horario(materia);
CREATE INDEX idx_calendario_fecha ON calendario_academico(fecha);
CREATE INDEX idx_reporte_enviado ON reporte(enviado);

CREATE VIRTUAL TABLE espacio_fts USING fts5(
    id UNINDEXED, nombre, codigo, bloque, servicios,
    tokenize = 'unicode61 remove_diacritics 2'
);

CREATE VIRTUAL TABLE materia_fts USING fts5(
    materia, programa, espacio_id UNINDEXED,
    tokenize = 'unicode61 remove_diacritics 2'
);
