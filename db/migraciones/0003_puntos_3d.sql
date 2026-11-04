-- ===========================================================================
--  0003 · Presentación de los puntos de información (aditiva)
--
--  `estilo` describe cómo se dibuja el punto dentro de la panorámica:
--    forma     'etiqueta' | 'icono' | 'circulo' | 'flecha' | 'capa3d'
--    ancho/alto tamaño en "píxeles de esfera": ancho_angular (rad) ≈ ancho / 1000
--    rotacion  {yaw, pitch, roll} en grados, aplicada sobre el plano que mira al centro
--    animacion 'ninguna' | 'pulso' | 'flotar'
--  Así la app Flutter puede dibujar exactamente lo mismo que el editor web.
-- ===========================================================================
ALTER TABLE punto_informacion
    ADD COLUMN estilo JSONB NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN punto_informacion.estilo IS
    'Presentación: {forma, ancho, alto, rotacion:{yaw,pitch,roll}, animacion}. Ancho angular (rad) ≈ ancho/1000.';
