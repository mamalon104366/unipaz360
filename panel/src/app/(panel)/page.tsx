import { Suspense } from 'react';
import Link from 'next/link';
import { ArrowRight, Check, CircleAlert, Send } from 'lucide-react';
import { leerResumen } from '@/lib/grafo';
import { leerAuditoria } from '@/lib/auditoria';
import { sesionPagina } from '@/lib/pagina';
import { Cargando, Pagina } from '@/components/ui/Pagina';
import { LineaAuditoria } from '@/components/ajustes/LineaAuditoria';

export default function Inicio() {
  return (
    <Suspense fallback={<Cargando titulo="Inicio" texto="Cargando el estado del campus…" />}>
      <ContenidoInicio />
    </Suspense>
  );
}

function saludo() {
  const h = Number(new Date().toLocaleString('en-US', { hour: 'numeric', hour12: false, timeZone: 'America/Bogota' }));
  return h < 12 ? 'Buenos días' : h < 19 ? 'Buenas tardes' : 'Buenas noches';
}

async function ContenidoInicio() {
  const { usuario } = await sesionPagina();
  const [r, actividad] = await Promise.all([
    leerResumen().catch(() => null),
    leerAuditoria({ limite: 8 }).then((a) => a.filter((e) => !['iniciar_sesion', 'salir', 'ingreso_fallido'].includes(e.accion)).slice(0, 6)).catch(() => []),
  ]);
  const nombre = usuario.nombre?.split(' ')[0] ?? usuario.correo.split('@')[0];
  if (!r) {
    return (
      <Pagina titulo={`${saludo()}, ${nombre}`} subtitulo="No hay conexión con la base central.">
        <p className="max-w-xl text-tinta-suave">
          Revisa que exista <code className="rounded bg-black/5 px-1">DATABASE_URL</code> en el entorno o en{' '}
          <code className="rounded bg-black/5 px-1">~/dev/unipaz360.secretos.env</code>.
        </p>
      </Pagina>
    );
  }

  const pctAccesible = r.tramos ? Math.round((r.accesibles / r.tramos) * 100) : 0;
  const revisiones = [
    {
      ok: r.vertices > 0 && r.componentes <= 1,
      texto: r.vertices === 0 ? 'Aún no hay nodos en el mapa' : r.componentes <= 1 ? 'El grafo está conectado' : `El grafo tiene ${r.componentes} partes separadas`,
      href: '/mapa?ver=aislados',
    },
    {
      ok: r.porVerificar === 0 && r.tramos > 0,
      texto: r.tramos === 0 ? 'Aún no hay rutas trazadas' : r.porVerificar ? `${r.porVerificar} tramos sin verificar en campo` : 'Todos los tramos están verificados',
      href: '/mapa?ver=por-verificar',
    },
    { ok: r.accesibles > 0, texto: r.accesibles ? `${r.accesibles} tramos aptos para la ruta accesible` : 'Ningún tramo marcado como accesible', href: '/mapa?ver=accesibles' },
    { ok: r.espacios > 0, texto: r.espacios ? `${r.espacios} espacios con su nodo de acceso` : 'Sin espacios registrados', href: '/espacios' },
    { ok: r.panoramicas > 0, texto: r.panoramicas ? `${r.panoramicas} panorámicas 360° cargadas` : 'Sin panorámicas 360°', href: '/panoramicas' },
  ];

  return (
    <Pagina titulo={`${saludo()}, ${nombre}`} subtitulo="El campus, sus rutas y lo que falta antes de publicar.">
      <div className="grid gap-5 lg:grid-cols-[1.4fr_1fr]">
        <section className="relieve rounded-[26px] p-7">
          <div className="text-[17px] text-tinta-suave">Nodos en el mapa</div>
          <div className="mt-2 flex items-end gap-4">
            <span className="text-[96px] font-light leading-none tracking-tight tabular-nums">{r.vertices}</span>
            <span className="mb-3 rounded-xl bg-acento-suave px-2.5 py-1 text-sm font-medium text-acento">{r.tramos} tramos</span>
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
          <Dato titulo="Placas QR" valor={r.anclajes} nota="instaladas o por instalar" />
        </section>
      </div>

      <div className="mt-6 grid gap-5 lg:grid-cols-[1.4fr_1fr]">
        <section>
          <h2 className="text-[30px] font-normal tracking-tight">Antes de publicar</h2>
          <p className="mt-1 text-tinta-tenue">Las mismas reglas que valida el empaquetador antes de generar el paquete.</p>
          <ul className="relieve mt-5 divide-y divide-black/[0.06] overflow-hidden rounded-[22px]">
            {revisiones.map(({ ok, texto, href }) => (
              <li key={texto}>
                <Link href={href} className="flex items-center gap-4 px-6 py-4 transition hover:bg-black/[0.02]">
                  <span className={`grid h-8 w-8 place-items-center rounded-full ${ok ? 'bg-acento-suave text-acento' : 'bg-alerta-suave text-alerta'}`}>
                    {ok ? <Check size={16} /> : <CircleAlert size={16} />}
                  </span>
                  <span className="text-[15px]">{texto}</span>
                </Link>
              </li>
            ))}
          </ul>
        </section>
        <section className="relieve flex flex-col justify-between rounded-[26px] bg-riel p-7 text-white">
          <div>
            <div className="text-[15px] text-white/60">Cambios sin publicar</div>
            <div className="mt-2 text-[72px] font-light leading-none tabular-nums">{r.cambiosPendientes}</div>
            <p className="mt-3 text-[14px] text-white/60">
              {r.ultimaPublicacion
                ? `Desde la versión del ${new Date(r.ultimaPublicacion).toLocaleDateString('es-CO', { dateStyle: 'long' })}.`
                : 'Todavía no se ha publicado ninguna versión.'}
            </p>
          </div>
          <Link href="/publicar" className="mt-6 flex items-center justify-between rounded-2xl bg-white/10 px-5 py-3.5 text-[15px] font-medium transition hover:bg-white/15">
            Revisar y publicar <Send size={17} />
          </Link>
        </section>
      </div>

      {actividad.length > 0 && (
        <section className="mt-10">
          <h2 className="mb-4 text-[30px] font-normal tracking-tight">Actividad reciente</h2>
          <LineaAuditoria entradas={actividad} />
        </section>
      )}
    </Pagina>
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
