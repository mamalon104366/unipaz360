import { Suspense } from 'react';
import type { Metadata } from 'next';
import { CircleCheck, TriangleAlert } from 'lucide-react';

export const metadata: Metadata = { title: 'Cuenta institucional' };

const MENSAJES: Record<string, { bien: boolean; titulo: string; texto: string }> = {
  listo: { bien: true, titulo: 'Listo, ya entraste', texto: 'Vuelve a UniPaz360: la app ya tiene tu cuenta institucional. Puedes cerrar esta pestaña.' },
  dominio: { bien: false, titulo: 'Esa cuenta no es institucional', texto: 'UniPaz360 solo admite cuentas @unipaz.edu.co. Vuelve a la app e inténtalo con tu correo institucional.' },
  vencido: { bien: false, titulo: 'El ingreso venció', texto: 'Pasaron más de 15 minutos. Vuelve a la app y toca «Continuar con Google» otra vez.' },
  cancelado: { bien: false, titulo: 'Ingreso cancelado', texto: 'No se inició sesión. Si fue sin querer, vuelve a la app e inténtalo de nuevo.' },
  inactivo: { bien: false, titulo: 'Todavía no está activo', texto: 'El ingreso institucional de la app aún no se ha activado en la plataforma. Puedes seguir usando la app sin cuenta.' },
  enlace: { bien: false, titulo: 'El enlace no es válido', texto: 'Abre el ingreso desde la app UniPaz360, con el botón «Continuar con Google».' },
  google: { bien: false, titulo: 'No se pudo entrar', texto: 'Google no confirmó la cuenta. Vuelve a la app e inténtalo de nuevo.' },
};

type Parametros = { searchParams: Promise<Record<string, string | string[] | undefined>> };

/** A dónde llega el navegador cuando alguien entra con Google desde la app. */
export default function IngresoApp({ searchParams }: Parametros) {
  return (
    <div className="grid h-full place-items-center overflow-y-auto bg-riel p-6">
      <div className="w-full max-w-[420px] rounded-[30px] bg-white p-9 text-center shadow-[0_30px_80px_-30px_rgb(0_0_0/0.7)]">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/marca/logo-horizontal.svg" alt="UNIPAZ - Instituto Universitario de la Paz" width={190} height={66} className="mx-auto" />
        <Suspense fallback={<div className="h-[150px]" />}>
          <Mensaje searchParams={searchParams} />
        </Suspense>
      </div>
    </div>
  );
}

async function Mensaje({ searchParams }: Parametros) {
  const { estado } = await searchParams;
  const m = MENSAJES[typeof estado === 'string' ? estado : ''] ?? MENSAJES.enlace;
  return (
    <>
      <div className={`mx-auto mt-7 grid h-14 w-14 place-items-center rounded-full ${m.bien ? 'bg-acento-suave text-acento' : 'bg-alerta-suave text-alerta'}`}>
        {m.bien ? <CircleCheck size={30} /> : <TriangleAlert size={28} />}
      </div>
      <h1 className="mt-5 text-[22px] font-semibold tracking-tight text-tinta">{m.titulo}</h1>
      <p className="mt-2 text-[15px] leading-relaxed text-tinta-suave">{m.texto}</p>
      <div className="mt-7 text-[11px] tracking-[0.22em] text-tinta-tenue">UNIPAZ360</div>
    </>
  );
}
