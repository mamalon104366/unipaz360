-- Esquema de la base de datos local de UniPaz360 (SQLite) · borrador de TEC-04
-- Se crea al instalar la app y se llena con el paquete de datos del campus.

PRAGMA foreign_keys = ON;

CREATE TABLE metadatos (
    version       TEXT PRIMARY KEY,
    generado      TEXT NOT NULL,
    campus        TEXT NOT NULL,
    sha256        TEXT NOT NULL,
    instalado_en  TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE vertice (
    id           TEXT PRIMARY KEY,
    lat          REAL NOT NULL,
    lon          REAL NOT NULL,
    nivel        INTEGER NOT NULL DEFAULT 0,
    tipo         TEXT NOT NULL CHECK (tipo IN ('puerta','cruce','escalera','rampa','ascensor','acceso','referencia')),
    descripcion  TEXT
);

CREATE TABLE espacio (
    id          TEXT PRIMARY KEY,
    nombre      TEXT NOT NULL,
    codigo      TEXT NOT NULL UNIQUE,
    categoria   TEXT NOT NULL CHECK (categoria IN ('aula','laboratorio','oficina','auditorio','biblioteca','bano','cafeteria','deportivo','porteria','parqueadero','otro')),
    bloque      TEXT,
    nivel       INTEGER NOT NULL DEFAULT 0,
    vertice_id  TEXT NOT NULL REFERENCES vertice(id),
    horario     TEXT,
    servicios   TEXT,
    foto        TEXT
);

CREATE TABLE tramo (
    id             TEXT PRIMARY KEY,
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

CREATE TABLE anclaje (
    id          TEXT PRIMARY KEY,
    uri         TEXT NOT NULL UNIQUE,
    vertice_id  TEXT NOT NULL REFERENCES vertice(id),
    ubicacion   TEXT
);

CREATE TABLE panoramica (
    id          TEXT PRIMARY KEY,
    archivo     TEXT NOT NULL,
    vertice_id  TEXT NOT NULL REFERENCES vertice(id)
);

CREATE TABLE enlace_panoramica (
    origen_id   TEXT NOT NULL REFERENCES panoramica(id),
    destino_id  TEXT NOT NULL REFERENCES panoramica(id),
    PRIMARY KEY (origen_id, destino_id),
    CHECK (origen_id <> destino_id)
);

CREATE TABLE reporte (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo         TEXT NOT NULL CHECK (tipo IN ('ruta','ficha','otro')),
    referencia   TEXT,
    descripcion  TEXT NOT NULL,
    creado_en    TEXT NOT NULL DEFAULT (datetime('now')),
    enviado      INTEGER NOT NULL DEFAULT 0 CHECK (enviado IN (0,1))
);

CREATE INDEX idx_tramo_origen   ON tramo(origen_id);
CREATE INDEX idx_tramo_destino  ON tramo(destino_id);
CREATE INDEX idx_espacio_nombre ON espacio(nombre);
CREATE INDEX idx_reporte_envio  ON reporte(enviado);
