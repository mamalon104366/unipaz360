import 'server-only';

/** Error de negocio con un mensaje legible para el panel y su código HTTP. */
export class ErrorDatos extends Error {
  constructor(
    message: string,
    public status = 400,
  ) {
    super(message);
  }
}

/** Convierte cualquier error en una respuesta JSON legible para el panel. */
export function respuestaError(e: unknown) {
  if (e instanceof ErrorDatos) return Response.json({ error: e.message }, { status: e.status });
  const msg = e instanceof Error ? e.message : String(e);
  console.error('[panel]', msg);
  if (/violates check constraint/.test(msg))
    return Response.json({ error: 'El cambio no cumple las reglas de los datos.' }, { status: 400 });
  if (/duplicate key value/.test(msg))
    return Response.json({ error: 'Ya existe un registro con ese identificador o código.' }, { status: 409 });
  if (/violates foreign key/.test(msg))
    return Response.json({ error: 'El registro está en uso o hace referencia a algo que no existe.' }, { status: 409 });
  return Response.json({ error: 'No se pudo completar la operación en la base de datos.' }, { status: 500 });
}
