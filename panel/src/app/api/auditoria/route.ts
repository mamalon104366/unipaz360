import { connection } from 'next/server';
import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { leerAuditoria } from '@/lib/auditoria';

/** Bitácora en CSV (para entregar o archivar). */
export async function GET(request: Request) {
  await connection();
  try {
    await requerir('superadmin');
    const p = new URL(request.url).searchParams;
    const filas = await leerAuditoria({
      usuario: p.get('usuario') ?? undefined,
      entidad: p.get('entidad') ?? undefined,
      desde: p.get('desde') ?? undefined,
      limite: 2000,
    });
    const esc = (v: unknown) => `"${String(v ?? '').replaceAll('"', '""')}"`;
    const csv = [
      ['fecha', 'usuario', 'accion', 'entidad', 'id', 'ip', 'antes', 'despues'].join(','),
      ...filas.map((f) =>
        [new Date(f.creado_en).toISOString(), f.correo, f.accion, f.entidad, f.entidad_id, f.ip, JSON.stringify(f.antes ?? ''), JSON.stringify(f.despues ?? '')]
          .map(esc)
          .join(','),
      ),
    ].join('\n');
    return new Response('﻿' + csv, {
      headers: {
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': `attachment; filename="auditoria-unipaz360-${new Date().toISOString().slice(0, 10)}.csv"`,
      },
    });
  } catch (e) {
    return respuestaError(e);
  }
}
