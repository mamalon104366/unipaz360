-- ===========================================================================
--  0005 · Quién ve cada punto de información en la app (aditiva)
--
--  'todos' (por defecto) o 'institucional': solo quien entra con la cuenta
--  @unipaz.edu.co. La app lo oculta a los invitados, pero el punto igual viaja
--  en el paquete de datos: sirve para ordenar lo que ve cada quien, no para
--  información confidencial.
-- ===========================================================================
ALTER TABLE punto_informacion
    ADD COLUMN audiencia TEXT NOT NULL DEFAULT 'todos'
        CHECK (audiencia IN ('todos', 'institucional'));

COMMENT ON COLUMN punto_informacion.audiencia IS
    'Quién lo ve en la app: todos, o institucional (solo con la cuenta @unipaz.edu.co).';
