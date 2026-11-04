import { Suspense } from 'react';
import Link from 'next/link';
import { connection } from 'next/server';
import { ArrowRight, Check, CircleAlert } from 'lucide-react';
import { leerResumen } from '@/lib/grafo';
import { Encabezado } from '@/components/ui/Encabezado';

export default function Inicio() {
  return (
    <Suspense fallback={<div className="px-10 pt-9"><Encabezado titulo="Inicio" subtitulo="Cargando el estado del campus…" /></div>}>
      <ContenidoInicio />
    </Suspense>
  );
}

async function ContenidoInicio() {
  await connection();
  const r = await leerResumen().catch(() => null);
  if (!r) {
    return (
      <div className="p-10">
        <Encabezado titulo="Inicio" subtitulo="No hay conexión con la base central." />
        <p className="mt-6 max-w-xl text-tinta-suave">
          Revisa que exista <code className="rounded bg-black/5 px-1">DATABASE_URL</code> en el entorno o en{' '}
          <code className="rounded bg-black/5 px-1">~/dev/unipaz360.secretos.env</code>.
        </p>
      </div>
    );
  }

  const pctAccesible = r.tramos ? Math.round((r.accesibles / r.tramos) * 100) : 0;
  const revisiones = [
    {
      ok: r.vertices > 0 && r.componentes <= 1,
      texto: r.vertices === 0 ? 'Aún no hay nodos en el mapa' : r.componentes <= 1 ? 'El grafo está conectado' : `El grafo tiene ${r.componentes} partes separadas`,
    },
    {
      ok: r.porVerificar === 0 && r.tramos > 0,
      texto: r.tramos === 0 ? 'Aún no hay rutas trazadas' : r.porVerificar ? `${r.porVerificar} tramos sin verificar en campo` : 'Todos los tramos están verificados',
    },
    { ok: r.accesibles > 0, texto: r.accesibles ? `${r.accesibles} tramos aptos para la ruta accesible` : 'Ningún tramo marcado como accesible' },
    { ok: r.panoramicas > 0, texto: r.panoramicas ? `${r.panoramicas} panorámicas cargadas` : 'Sin panorámicas 360° (llegan en P2)' },
  ];

  return (
    <div className="h-full overflow-y-auto px-10 pb-10 pt-9">
      <Encabezado titulo="Inicio" subtitulo="El campus, sus rutas y lo que falta antes de publicar." />

      <div className="mt-8 grid gap-5 lg:grid-cols-[1.4fr_1fr]">
        <section className="relieve rounded-[26px] p-7">
          <div className="text-[17px] text-tinta-suave">Nodos en el mapa</div>
          <div className="mt-2 flex items-end gap-4">
            <span className="text-[96px] font-light leading-none tracking-tight tabular-nums">{r.vertices}</span>
            <span className="mb-3 rounded-xl bg-acento-suave px-2.5 py-1 text-sm font-medium text-acento">
              {r.tramos} tramos
            </span>
          </div>
          <Link
            href="/mapa"
            className="hundido mt-7 flex items-center justify-between rounded-2xl px-5 py-3.5 text-[15px] font-medium transition hover:bg-black/[0.06]"
          >
            Abrir el editor de mapa <ArrowRight size={18} />
          </Link>
        </section>

        <section className="grid grid-cols-2 gap-5">
          <Dato titulo="Ruta accesible" valor={`${pctAccesible} %`} nota="de los tramos" />
          <Dato titulo="Por verificar" valor={r.porVerificar} nota="tramos en campo" alerta={r.porVerificar > 0} />
          <Dato titulo="Panorámicas" valor={r.panoramicas} nota="fotos 360°" />
          <Dato titulo="Espacios" valor={r.espacios} nota="aulas y oficinas" />
        </section>
      </div>

      <h2 className="mt-12 text-[34px] font-normal tracking-tight">Antes de publicar</h2>
      <p className="mt-1 text-tinta-tenue">Las mismas reglas que valida el empaquetador antes de generar el paquete.</p>
      <ul className="relieve mt-5 divide-y divide-black/[0.06] overflow-hidden rounded-[22px]">
        {revisiones.map(({ ok, texto }) => (
          <li key={texto} className="flex items-center gap-4 px-6 py-4">
            <span className={`grid h-8 w-8 place-items-center rounded-full ${ok ? 'bg-acento-suave text-acento' : 'bg-alerta-suave text-alerta'}`}>
              {ok ? <Check size={16} /> : <CircleAlert size={16} />}
            </span>
            <span className="text-[15px]">{texto}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}

function Dato({ titulo, valor, nota, alerta }: { titulo: string; valor: number | string; nota: string; alerta?: boolean }) {
  return (
    <div className="relieve flex flex-col justify-between rounded-[22px] p-5">
      <div className="text-[15px] text-tinta-suave">{titulo}</div>
      <div>
        <div className={`mt-3 text-[40px] font-light leading-none tabular-nums ${alerta ? 'text-alerta' : ''}`}>{valor}</div>
        <div className="mt-1 text-sm text-tinta-tenue">{nota}</div>
      </div>
    </div>
  );
}
