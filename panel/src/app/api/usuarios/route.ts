import { connection } from 'next/server';
import { respuestaError } from '@/lib/errores';
import { requerir } from '@/lib/sesion';
import { crearUsuario, listarUsuarios } from '@/lib/usuarios';

export async function GET() {
  await connection();
  try {
    await requerir('superadmin');
    return Response.json(await listarUsuarios());
  } catch (e) {
    return respuestaError(e);
  }
}

export async function POST(request: Request) {
  try {
    const admin = await requerir('superadmin');
    return Response.json(await crearUsuario(admin, await request.json()), { status: 201 });
  } catch (e) {
    return respuestaError(e);
  }
}
