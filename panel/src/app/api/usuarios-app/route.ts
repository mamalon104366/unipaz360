import { connection } from 'next/server';
import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { listarUsuariosApp } from '@/lib/usuariosApp';

/** Quién usa la app con la cuenta institucional, en CSV (solo superadministrador). */
export async function GET() {
  await connection();
  try {
    await requerir('superadmin');
    const filas = await listarUsuariosApp();
    // Un valor que empiece por = + - @ se guarda como texto: Excel no lo toma como fórmula.
    const esc = (v: unknown) => {
      const t = String(v ?? '');
      return `"${(/^[=+\-@\t\r]/.test(t) ? `'${t}` : t).replaceAll('"', '""')}"`;
    };
    const csv = [
      ['correo', 'nombre', 'aperturas', 'ingresos', 'dispositivos', 'primer_ingreso', 'ultimo_uso'].join(','),
      ...filas.map((f) =>
        [f.correo, f.nombre, f.aperturas, f.ingresos, f.dispositivos, new Date(f.primer_ingreso).toISOString(), new Date(f.ultimo_uso).toISOString()].map(esc).join(','),
      ),
    ].join('\n');
    return new Response('﻿' + csv, {
      headers: {
        'Content-Type': 'text/csv; charset=utf-8',
        'Content-Disposition': `attachment; filename="usuarios-app-unipaz360-${new Date().toISOString().slice(0, 10)}.csv"`,
        'Cache-Control': 'no-store',
      },
    });
  } catch (e) {
    return respuestaError(e);
  }
}
