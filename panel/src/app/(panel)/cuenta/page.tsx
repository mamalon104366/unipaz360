import { Suspense } from 'react';
import type { Metadata } from 'next';
import { sesionPagina } from '@/lib/pagina';
import { Cargando, Pagina } from '@/components/ui/Pagina';
import { DESCRIPCION_ROL, ETIQUETA_ROL } from '@/lib/tipos';

export const metadata: Metadata = { title: 'Mi cuenta' };

export default function Cuenta({ searchParams }: PageProps<'/cuenta'>) {
  return (
    <Suspense fallback={<Cargando titulo="Mi cuenta" />}>
      <Contenido searchParams={searchParams} />
    </Suspense>
  );
}

async function Contenido({ searchParams }: Pick<PageProps<'/cuenta'>, 'searchParams'>) {
  const [{ usuario }] = await Promise.all([sesionPagina(), searchParams]);
  return (
    <Pagina titulo="Mi cuenta" subtitulo="Tus datos de acceso al panel." ancho="max-w-[880px]">
      <div className="grid gap-5 md:grid-cols-[1fr_1.2fr]">
        <section className="relieve rounded-[24px] p-6">
          <div className="text-[13px] text-tinta-tenue">Correo</div>
          <div className="mt-0.5 text-[17px]">{usuario.correo}</div>
          {usuario.institucional ? (
            <span className="chip mt-2 bg-acento-suave text-acento">Correo institucional</span>
          ) : (
            <span className="chip mt-2 bg-alerta-suave text-alerta">Correo externo</span>
          )}
          <div className="mt-6 text-[13px] text-tinta-tenue">Rol</div>
          <div className="mt-0.5 text-[17px]">{ETIQUETA_ROL[usuario.rol]}</div>
          <p className="mt-1 text-[14px] text-tinta-suave">{DESCRIPCION_ROL[usuario.rol]}</p>
        </section>
        <section className="relieve rounded-[24px] p-6">
          <h2 className="text-[19px] font-medium">Acceso con Google</h2>
          <p className="mt-2 text-[14px] leading-relaxed text-tinta-suave">
            Entras con tu cuenta institucional de Google. El panel no guarda contraseñas: si cambias la clave de tu correo, no hay que hacer nada aquí.
            Para dar acceso a otra persona, un superadministrador autoriza su correo @unipaz.edu.co en Cuentas y roles.
          </p>
        </section>
      </div>
    </Pagina>
  );
}
