import { Encabezado } from './Encabezado';

/** Contenedor estándar de una página del panel: título, acciones y contenido con scroll. */
export function Pagina({
  titulo,
  subtitulo,
  acciones,
  children,
  ancho = 'max-w-[1240px]',
}: {
  titulo: string;
  subtitulo?: string;
  acciones?: React.ReactNode;
  children: React.ReactNode;
  ancho?: string;
}) {
  return (
    <div className="h-full overflow-y-auto">
      <div className={`mx-auto w-full ${ancho} px-6 pb-12 pt-8 lg:px-10 lg:pt-9`}>
        <div className="flex flex-wrap items-end justify-between gap-4">
          <Encabezado titulo={titulo} subtitulo={subtitulo} />
          {acciones && <div className="flex flex-wrap items-center gap-2">{acciones}</div>}
        </div>
        <div className="mt-8">{children}</div>
      </div>
    </div>
  );
}

export function Cargando({ titulo, texto = 'Cargando…' }: { titulo: string; texto?: string }) {
  return (
    <div className="mx-auto w-full max-w-[1240px] px-6 pt-8 lg:px-10 lg:pt-9">
      <Encabezado titulo={titulo} subtitulo={texto} />
      <div className="mt-8 grid gap-4 md:grid-cols-3">
        {[0, 1, 2].map((i) => (
          <div key={i} className="hundido h-32 animate-pulse rounded-[22px]" />
        ))}
      </div>
    </div>
  );
}

export function SinPermiso({ titulo }: { titulo: string }) {
  return (
    <Pagina titulo={titulo}>
      <div className="hundido grid min-h-[280px] place-items-center rounded-[26px] p-10 text-center">
        <div>
          <div className="text-[19px] font-medium">No tienes acceso a esta sección</div>
          <p className="mt-2 text-tinta-suave">Solo un superadministrador puede verla. Si la necesitas, pídele que cambie tu rol.</p>
        </div>
      </div>
    </Pagina>
  );
}
