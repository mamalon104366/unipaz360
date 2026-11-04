import { Encabezado } from './Encabezado';

/** Pantalla de un módulo que llega en un sprint posterior. */
export function Proximamente({ titulo, subtitulo, sprint, puntos }: { titulo: string; subtitulo: string; sprint: string; puntos: string[] }) {
  return (
    <div className="h-full overflow-y-auto px-10 pb-10 pt-9">
      <Encabezado titulo={titulo} subtitulo={subtitulo} />
      <div className="hundido mt-8 grid min-h-[360px] place-items-center rounded-[26px] p-10">
        <div className="max-w-md text-center">
          <span className="rounded-full bg-black/5 px-3 py-1 text-xs font-medium tracking-wide text-tinta-suave">{sprint}</span>
          <p className="mt-4 text-[17px] text-tinta-suave">Este módulo se construye en el siguiente sprint. Hará lo siguiente:</p>
          <ul className="mt-4 space-y-2 text-left text-[15px] text-tinta">
            {puntos.map((p) => (
              <li key={p} className="flex gap-2"><span className="text-tinta-tenue">·</span>{p}</li>
            ))}
          </ul>
        </div>
      </div>
    </div>
  );
}
