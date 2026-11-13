'use client';

/**
 * El catálogo de íconos (`iconosPunto.generado.ts`) con buscador y grupos. Lo usan los puntos
 * de las fotos 360° y las secciones del menú de la app; la app Flutter dibuja los mismos íconos
 * de Lucide (`iconos_lucide.generado.dart`).
 */
import { useMemo, useState } from 'react';
import { Search } from 'lucide-react';
import { svgIcono } from '@/components/panoramicas/iconosPunto';
import { CATEGORIAS_ICONO, CATEGORIA_ICONO, ETIQUETA_ICONO, ICONOS_PUNTO, type CategoriaIcono, type IconoPunto } from '@/lib/iconosPunto.generado';

const sinTildes = (s: string) =>
  s
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase();

/** Un ícono del catálogo (SVG plano de Lucide, como lo dibuja el visor). */
export function IconoCatalogo({ icono, tamano = 16 }: { icono: IconoPunto; tamano?: number }) {
  return <span className="grid shrink-0 place-items-center" aria-hidden dangerouslySetInnerHTML={{ __html: svgIcono(icono, tamano) }} />;
}

type Grupo = CategoriaIcono | 'todos';
const GRUPOS: readonly { id: Grupo; etiqueta: string }[] = [{ id: 'todos', etiqueta: 'Todos' }, ...CATEGORIAS_ICONO];

export function SelectorIconos({
  valor,
  alElegir,
  antes,
  columnas = 8,
}: {
  valor: IconoPunto | '' | null;
  alElegir: (icono: IconoPunto) => void;
  /** Botones antes de la cuadrícula (por ejemplo, «Del tipo»). */
  antes?: React.ReactNode;
  columnas?: number;
}) {
  const [busqueda, setBusqueda] = useState('');
  const [grupo, setGrupo] = useState<Grupo>('todos');
  const lista = useMemo(() => {
    const q = sinTildes(busqueda.trim());
    return ICONOS_PUNTO.filter((i) => (q ? true : grupo === 'todos' || CATEGORIA_ICONO[i] === grupo) && (!q || sinTildes(`${ETIQUETA_ICONO[i]} ${i}`).includes(q)));
  }, [busqueda, grupo]);

  return (
    <div className="space-y-2">
      <label className="relative block">
        <Search size={14} className="pointer-events-none absolute left-2.5 top-1/2 -translate-y-1/2 text-tinta-tenue" aria-hidden />
        <input
          value={busqueda}
          onChange={(e) => setBusqueda(e.target.value)}
          placeholder={`Buscar entre ${ICONOS_PUNTO.length} íconos`}
          aria-label="Buscar un ícono"
          className="campo !h-9 !pl-8 !text-[13px]"
        />
      </label>
      {!busqueda.trim() && (
        <div className="flex flex-wrap gap-1" role="group" aria-label="Grupos de íconos">
          {GRUPOS.map((g) => (
            <button
              key={g.id}
              type="button"
              onClick={() => setGrupo(g.id)}
              aria-pressed={grupo === g.id}
              className={`rounded-full px-2.5 py-1 text-[11px] transition ${grupo === g.id ? 'bg-riel text-white' : 'bg-white/70 text-tinta-suave hover:bg-white'}`}
            >
              {g.etiqueta}
            </button>
          ))}
        </div>
      )}
      <div className="grid max-h-60 gap-1 overflow-y-auto pr-0.5" style={{ gridTemplateColumns: `repeat(${columnas}, minmax(0, 1fr))` }}>
        {antes}
        {lista.map((ic) => (
          <button
            type="button"
            key={ic}
            onClick={() => alElegir(ic)}
            title={ETIQUETA_ICONO[ic]}
            aria-label={ETIQUETA_ICONO[ic]}
            aria-pressed={valor === ic}
            className={`grid h-8 place-items-center rounded-lg transition ${valor === ic ? 'bg-riel text-white' : 'bg-white/70 text-tinta-suave hover:bg-white'}`}
          >
            <IconoCatalogo icono={ic} tamano={15} />
          </button>
        ))}
        {lista.length === 0 && <p className="col-span-full py-3 text-center text-[12px] text-tinta-tenue">No hay íconos con ese nombre.</p>}
      </div>
    </div>
  );
}
