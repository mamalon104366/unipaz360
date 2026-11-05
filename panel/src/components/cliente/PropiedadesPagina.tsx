'use client';

import { useState } from 'react';
import {
  AlignCenter,
  AlignCenterHorizontal,
  AlignCenterVertical,
  AlignEndHorizontal,
  AlignEndVertical,
  AlignLeft,
  AlignRight,
  AlignStartHorizontal,
  AlignStartVertical,
  ArrowDown,
  ArrowUp,
  BringToFront,
  Circle,
  Copy,
  Eye,
  EyeOff,
  Image as ImageIcon,
  ImageUp,
  Lock,
  Map as MapIcon,
  Minus,
  MousePointerClick,
  Plus,
  SendToBack,
  Square,
  StretchVertical,
  Trash2,
  Type,
  Unlock,
  Video,
  type LucideIcon,
} from 'lucide-react';
import { ETIQUETA_ELEMENTO, type Elemento, type PestanaPagina, type SeccionApp, type TipoElemento } from '@/lib/configApp';
import { subirMedio } from '@/components/ui/subida';
import { AreaTexto, BotonIcono, Color, Interruptor, Numero, Opciones, Rango, Seccion, Texto } from './controles';
import { altoNecesario, type ModoAlinear } from './operaciones';
import { IMAGENES_APP, VIDEOS_APP, nombreRecurso, urlRecurso } from './recursos';

export const ICONO_ELEMENTO: Record<TipoElemento, LucideIcon> = {
  texto: Type,
  imagen: ImageIcon,
  video: Video,
  boton: MousePointerClick,
  forma: Square,
  mapa: MapIcon,
};

function Fuente({ e, cambiar }: { e: Elemento; cambiar: (p: Partial<Elemento>, grupo?: string) => void }) {
  return (
    <Seccion titulo="Texto">
      <AreaTexto etiqueta={e.tipo === 'boton' ? 'Texto del botón' : 'Contenido'} valor={e.texto ?? ''} filas={e.tipo === 'boton' ? 1 : 4} alCambiar={(v) => cambiar({ texto: v }, `texto-${e.id}`)} />
      <Opciones
        valor={e.fuente ?? 'sans'}
        opciones={[
          ['sans', <span key="s" style={{ fontFamily: 'var(--font-app-sans)' }}>Roboto</span>],
          ['serif', <span key="r" style={{ fontFamily: 'var(--font-app-serif)', fontStyle: 'italic' }}>Noto Serif</span>],
        ]}
        alCambiar={(v) => cambiar({ fuente: v })}
      />
      <div className="grid grid-cols-2 gap-2">
        <Numero etiqueta="Tm" valor={e.tamano ?? 16} min={6} max={200} alCambiar={(v) => cambiar({ tamano: v }, `tam-${e.id}`)} sufijo="pt" />
        <select value={e.peso ?? 400} onChange={(ev) => cambiar({ peso: Number(ev.target.value) as Elemento['peso'] })} className="campo !px-2.5 !py-1.5 !text-[13px]">
          <option value={400}>Normal</option>
          <option value={500}>Media</option>
          <option value={600}>Seminegrita</option>
          <option value={700}>Negrita</option>
          <option value={800}>Extra negrita</option>
        </select>
      </div>
      <div className="flex items-center gap-1.5">
        <Opciones
          valor={e.alineacion ?? 'izquierda'}
          opciones={[
            ['izquierda', <AlignLeft key="i" size={15} />, 'Alinear a la izquierda'],
            ['centro', <AlignCenter key="c" size={15} />, 'Centrar'],
            ['derecha', <AlignRight key="d" size={15} />, 'Alinear a la derecha'],
          ]}
          alCambiar={(v) => cambiar({ alineacion: v })}
        />
        <BotonIcono titulo="Cursiva" activo={!!e.cursiva} onClick={() => cambiar({ cursiva: !e.cursiva })} icono={<span className="font-serif text-[15px] italic">I</span>} />
        <BotonIcono titulo="Mayúsculas" activo={!!e.mayusculas} onClick={() => cambiar({ mayusculas: !e.mayusculas })} icono={<span className="text-[12px] font-semibold">AA</span>} />
      </div>
      <Color etiqueta="Color del texto" valor={e.color ?? '#1c1c1f'} alCambiar={(v) => cambiar({ color: v }, `color-${e.id}`)} />
      {e.tipo === 'texto' && <Rango etiqueta="Interlineado" valor={e.interlineado ?? 1.4} min={0.8} max={3} paso={0.05} formato={(v) => v.toFixed(2)} alCambiar={(v) => cambiar({ interlineado: v }, `interl-${e.id}`)} />}
    </Seccion>
  );
}

function Fuentes({ e, cambiar, avisar }: { e: Elemento; cambiar: (p: Partial<Elemento>) => void; avisar: (t: string) => void }) {
  const [subiendo, setSubiendo] = useState<number | null>(null);
  const [url, setUrl] = useState('');
  const video = e.tipo === 'video';
  async function subir(f: File | undefined) {
    if (!f) return;
    try {
      setSubiendo(0);
      const m = await subirMedio(f, setSubiendo);
      cambiar({ src: m.url });
    } catch (err) {
      avisar((err as Error).message);
    } finally {
      setSubiendo(null);
    }
  }
  return (
    <Seccion titulo={video ? 'Video' : e.tipo === 'mapa' ? 'Imagen sin conexión' : 'Imagen'}>
      <div className="truncate rounded-lg bg-black/[0.04] px-2.5 py-1.5 font-mono text-[11px] text-tinta-tenue" title={e.src}>
        {e.src?.startsWith('app://') ? `En la app · ${nombreRecurso(e.src)}` : nombreRecurso(e.src)}
      </div>
      {!video ? (
        <div className="grid grid-cols-4 gap-1.5">
          {IMAGENES_APP.map((n) => {
            const src = `app://imagenes/${n}`;
            return (
              <button key={n} type="button" title={n} onClick={() => cambiar({ src })} className={`overflow-hidden rounded-lg ring-2 ${e.src === src ? 'ring-[#3b82f6]' : 'ring-transparent hover:ring-black/20'}`}>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src={urlRecurso(src)} alt="" className="aspect-square w-full object-cover" />
              </button>
            );
          })}
        </div>
      ) : (
        <div className="flex flex-wrap gap-1.5">
          {VIDEOS_APP.map((n) => (
            <button key={n} type="button" onClick={() => cambiar({ src: `app://videos/${n}` })} className={`chip ${e.src === `app://videos/${n}` ? 'bg-riel text-white' : 'bg-black/5'}`}>
              {n}
            </button>
          ))}
        </div>
      )}
      <label className="boton-suave w-full cursor-pointer !h-10">
        <ImageUp size={15} /> {subiendo !== null ? `Subiendo… ${Math.round(subiendo * 100)} %` : video ? 'Subir video (MP4)' : 'Subir imagen o GIF'}
        <input type="file" className="hidden" accept={video ? 'video/mp4,video/webm' : 'image/jpeg,image/png,image/webp,image/gif'} onChange={(ev) => subir(ev.target.files?.[0])} />
      </label>
      <div className="flex gap-1.5">
        <input value={url} onChange={(ev) => setUrl(ev.target.value)} placeholder="…o pega un enlace https://" className="campo !py-1.5 !text-[13px]" />
        <button
          type="button"
          onClick={() => {
            if (!/^https:\/\/\S+$/.test(url)) return avisar('El enlace debe empezar por https://');
            cambiar({ src: url });
            setUrl('');
          }}
          className="boton-suave !h-9 !px-3 !text-[13px]"
        >
          Usar
        </button>
      </div>
      {e.tipo !== 'mapa' && (
        <Opciones
          etiqueta="Ajuste"
          valor={e.ajuste ?? 'cubrir'}
          opciones={[
            ['cubrir', 'Llenar (recorta)'],
            ['contener', 'Completa'],
          ]}
          alCambiar={(v) => cambiar({ ajuste: v })}
        />
      )}
      {video && <Interruptor etiqueta="Reproducir solo y sin sonido" valor={!!e.automatico} alCambiar={(v) => cambiar({ automatico: v })} />}
    </Seccion>
  );
}

function Enlace({ e, cambiar, secciones, panoramicas }: { e: Elemento; cambiar: (p: Partial<Elemento>) => void; secciones: SeccionApp[]; panoramicas: { id: string; titulo: string }[] }) {
  const v = e.enlace ?? '';
  const tipo = v.startsWith('https://') ? 'web' : v.startsWith('seccion:') ? 'seccion' : v.startsWith('panoramica:') ? 'panoramica' : v === '' ? 'nada' : 'web';
  const [web, setWeb] = useState(tipo === 'web' ? v : '');
  return (
    <Seccion titulo="Al tocarlo">
      <select
        value={tipo}
        onChange={(ev) => {
          const t = ev.target.value;
          cambiar({ enlace: t === 'nada' ? '' : t === 'seccion' ? `seccion:${secciones[0]?.id ?? ''}` : t === 'panoramica' ? `panoramica:${panoramicas[0]?.id ?? ''}` : web.startsWith('https://') ? web : '' });
          if (t === 'web' && !web) setWeb('https://');
        }}
        className="campo !py-2 !text-[14px]"
      >
        <option value="nada">No hace nada</option>
        <option value="web">Abre una página web</option>
        <option value="seccion">Abre otra sección de la app</option>
        <option value="panoramica" disabled={!panoramicas.length}>
          Lleva a una foto 360°
        </option>
      </select>
      {tipo === 'web' && (
        <input
          value={web}
          onChange={(ev) => {
            setWeb(ev.target.value);
            if (/^https:\/\/[^\s"'<>]+$/.test(ev.target.value)) cambiar({ enlace: ev.target.value });
          }}
          placeholder="https://unipaz.edu.co/…"
          className="campo !py-2 !text-[13px]"
        />
      )}
      {tipo === 'seccion' && (
        <select value={v.slice(8)} onChange={(ev) => cambiar({ enlace: `seccion:${ev.target.value}` })} className="campo !py-2 !text-[14px]">
          {secciones.map((s) => (
            <option key={s.id} value={s.id}>
              {s.titulo}
            </option>
          ))}
        </select>
      )}
      {tipo === 'panoramica' && (
        <select value={v.slice(11)} onChange={(ev) => cambiar({ enlace: `panoramica:${ev.target.value}` })} className="campo !py-2 !text-[14px]">
          {panoramicas.map((p) => (
            <option key={p.id} value={p.id}>
              {p.id} · {p.titulo}
            </option>
          ))}
        </select>
      )}
    </Seccion>
  );
}

/** Propiedades del elemento elegido (o de la pestaña si no hay ninguno) y la lista de capas. */
export function PropiedadesPagina({
  pestana,
  seleccion,
  secciones,
  panoramicas,
  alSeleccionar,
  alCambiarPestana,
  alAlinear,
  alOrdenar,
  alDuplicar,
  alEliminar,
  avisar,
}: {
  pestana: PestanaPagina;
  seleccion: string[];
  secciones: SeccionApp[];
  panoramicas: { id: string; titulo: string }[];
  alSeleccionar: (ids: string[]) => void;
  alCambiarPestana: (f: (t: PestanaPagina) => PestanaPagina, grupo?: string) => void;
  alAlinear: (m: ModoAlinear | 'distribuir-h' | 'distribuir-v') => void;
  alOrdenar: (m: 'subir' | 'bajar' | 'frente' | 'fondo') => void;
  alDuplicar: () => void;
  alEliminar: () => void;
  avisar: (t: string) => void;
}) {
  const sel = pestana.elementos.filter((e) => seleccion.includes(e.id));
  const e = sel.length === 1 ? sel[0] : null;
  const cambiar = (p: Partial<Elemento>, grupo?: string) =>
    e && alCambiarPestana((t) => ({ ...t, elementos: t.elementos.map((x) => (x.id === e.id ? { ...x, ...p } : x)) }), grupo);
  const Icono = e ? ICONO_ELEMENTO[e.tipo] : null;

  return (
    <div className="space-y-4">
      {sel.length > 0 && (
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            {Icono && (
              <span className="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-riel text-white">
                <Icono size={16} />
              </span>
            )}
            {e ? (
              <input value={e.nombre} onChange={(ev) => cambiar({ nombre: ev.target.value }, `nombre-${e.id}`)} className="campo !py-1.5 !text-[14px] font-medium" title="Nombre de la capa" />
            ) : (
              <div className="text-[15px] font-medium">{sel.length} elementos</div>
            )}
          </div>
          <div className="flex flex-wrap items-center gap-0.5">
            <BotonIcono titulo="Alinear a la izquierda" onClick={() => alAlinear('izquierda')} icono={<AlignStartVertical size={15} />} />
            <BotonIcono titulo="Centrar horizontalmente" onClick={() => alAlinear('centro')} icono={<AlignCenterVertical size={15} />} />
            <BotonIcono titulo="Alinear a la derecha" onClick={() => alAlinear('derecha')} icono={<AlignEndVertical size={15} />} />
            {sel.length > 1 && (
              <>
                <BotonIcono titulo="Alinear arriba" onClick={() => alAlinear('arriba')} icono={<AlignStartHorizontal size={15} />} />
                <BotonIcono titulo="Centrar verticalmente" onClick={() => alAlinear('medio')} icono={<AlignCenterHorizontal size={15} />} />
                <BotonIcono titulo="Alinear abajo" onClick={() => alAlinear('abajo')} icono={<AlignEndHorizontal size={15} />} />
              </>
            )}
            {sel.length > 2 && <BotonIcono titulo="Repartir en vertical" onClick={() => alAlinear('distribuir-v')} icono={<StretchVertical size={15} />} />}
            <span className="mx-1 h-5 w-px bg-black/10" />
            <BotonIcono titulo="Traer al frente (Ctrl + Mayús + ])" onClick={() => alOrdenar('frente')} icono={<BringToFront size={15} />} />
            <BotonIcono titulo="Enviar al fondo (Ctrl + Mayús + [)" onClick={() => alOrdenar('fondo')} icono={<SendToBack size={15} />} />
            <BotonIcono titulo="Duplicar (Ctrl + D)" onClick={alDuplicar} icono={<Copy size={15} />} />
            <BotonIcono titulo="Eliminar (Supr)" onClick={alEliminar} icono={<Trash2 size={15} />} />
          </div>
        </div>
      )}

      {e && (
        <>
          <Seccion titulo="Posición y tamaño">
            <div className="grid grid-cols-2 gap-2">
              <Numero etiqueta="X" valor={e.x} alCambiar={(v) => cambiar({ x: v }, `x-${e.id}`)} />
              <Numero etiqueta="Y" valor={e.y} alCambiar={(v) => cambiar({ y: v }, `y-${e.id}`)} />
              <Numero etiqueta="An" valor={e.ancho} min={4} alCambiar={(v) => cambiar({ ancho: v }, `w-${e.id}`)} />
              <Numero etiqueta="Al" valor={e.alto} min={1} alCambiar={(v) => cambiar({ alto: v }, `h-${e.id}`)} />
            </div>
            <Rango etiqueta="Giro" valor={e.rotacion} min={-180} max={180} paso={1} formato={(v) => `${v}°`} alCambiar={(v) => cambiar({ rotacion: v }, `rot-${e.id}`)} />
            <Rango etiqueta="Opacidad" valor={e.opacidad} min={0} max={1} paso={0.05} formato={(v) => `${Math.round(v * 100)} %`} alCambiar={(v) => cambiar({ opacidad: v }, `op-${e.id}`)} />
            <div className="flex gap-2">
              <button type="button" onClick={() => cambiar({ bloqueado: !e.bloqueado })} className="boton-suave flex-1 !h-9 !text-[13px]">
                {e.bloqueado ? <Unlock size={14} /> : <Lock size={14} />} {e.bloqueado ? 'Desbloquear' : 'Bloquear'}
              </button>
              <button type="button" onClick={() => cambiar({ oculto: !e.oculto })} className="boton-suave flex-1 !h-9 !text-[13px]">
                {e.oculto ? <Eye size={14} /> : <EyeOff size={14} />} {e.oculto ? 'Mostrar' : 'Ocultar'}
              </button>
            </div>
          </Seccion>

          {(e.tipo === 'texto' || e.tipo === 'boton') && <Fuente e={e} cambiar={cambiar} />}
          {(e.tipo === 'imagen' || e.tipo === 'video' || e.tipo === 'mapa') && <Fuentes e={e} cambiar={cambiar} avisar={avisar} />}

          {e.tipo === 'mapa' && (
            <Seccion titulo="Mapa en línea">
              <div className="grid grid-cols-2 gap-2">
                <Numero etiqueta="Lat" valor={e.lat ?? 0} min={-90} max={90} paso={0.0001} alCambiar={(v) => cambiar({ lat: v })} />
                <Numero etiqueta="Lon" valor={e.lon ?? 0} min={-180} max={180} paso={0.0001} alCambiar={(v) => cambiar({ lon: v })} />
              </div>
              <Rango etiqueta="Acercamiento" valor={e.zoomMapa ?? 16} min={3} max={20} paso={1} formato={(v) => String(v)} alCambiar={(v) => cambiar({ zoomMapa: v }, `zoom-${e.id}`)} />
              <p className="text-[12px] text-tinta-tenue">Con internet la app muestra Google Maps; sin conexión, la imagen de arriba.</p>
            </Seccion>
          )}

          {(e.tipo === 'forma' || e.tipo === 'boton' || e.tipo === 'imagen' || e.tipo === 'video' || e.tipo === 'mapa') && (
            <Seccion titulo={e.tipo === 'forma' ? 'Forma' : 'Bordes'}>
              {e.tipo === 'forma' && (
                <Opciones
                  valor={e.figura ?? 'rectangulo'}
                  opciones={[
                    ['rectangulo', <Square key="r" size={15} />, 'Rectángulo'],
                    ['elipse', <Circle key="e" size={15} />, 'Elipse'],
                    ['linea', <Minus key="l" size={15} />, 'Línea'],
                  ]}
                  alCambiar={(v) => cambiar({ figura: v })}
                />
              )}
              {(e.tipo === 'forma' || e.tipo === 'boton') && e.figura !== 'linea' && <Color etiqueta="Relleno" opcional valor={e.relleno ?? ''} alCambiar={(v) => cambiar({ relleno: v }, `relleno-${e.id}`)} />}
              {e.figura !== 'elipse' && e.figura !== 'linea' && (
                <Rango etiqueta="Esquinas redondeadas" valor={e.radio ?? 0} min={0} max={Math.round(Math.min(e.ancho, e.alto) / 2)} paso={1} formato={(v) => String(v)} alCambiar={(v) => cambiar({ radio: v }, `radio-${e.id}`)} />
              )}
              {e.tipo !== 'video' && e.tipo !== 'mapa' && (
                <>
                  <Color etiqueta={e.figura === 'linea' ? 'Color de la línea' : 'Borde'} opcional={e.figura !== 'linea'} valor={e.borde ?? ''} alCambiar={(v) => cambiar({ borde: v }, `borde-${e.id}`)} />
                  {(e.borde || e.figura === 'linea') && (
                    <Rango etiqueta="Grosor" valor={e.grosorBorde ?? 0} min={0} max={40} paso={1} formato={(v) => String(v)} alCambiar={(v) => cambiar({ grosorBorde: v }, `grosor-${e.id}`)} />
                  )}
                  <Interruptor etiqueta="Sombra" valor={!!e.sombra} alCambiar={(v) => cambiar({ sombra: v })} />
                </>
              )}
            </Seccion>
          )}

          {(e.tipo === 'boton' || e.tipo === 'imagen' || e.tipo === 'forma') && <Enlace key={e.id} e={e} cambiar={cambiar} secciones={secciones} panoramicas={panoramicas} />}
        </>
      )}

      {sel.length === 0 && (
        <Seccion titulo="Pestaña">
          <Texto etiqueta="Nombre de la pestaña" valor={pestana.titulo} alCambiar={(v) => alCambiarPestana((t) => ({ ...t, titulo: v }), 'titulo-pestana')} />
          <Color etiqueta="Fondo" valor={pestana.fondo} alCambiar={(v) => alCambiarPestana((t) => ({ ...t, fondo: v }), 'fondo-pestana')} />
          <div className="flex items-end gap-2">
            <div className="flex-1">
              <span className="mb-1.5 block text-[13px] font-medium text-tinta-suave">Alto del lienzo</span>
              <Numero etiqueta="Al" valor={pestana.alto} min={200} max={20000} paso={10} alCambiar={(v) => alCambiarPestana((t) => ({ ...t, alto: v }), 'alto-pestana')} />
            </div>
            <button type="button" onClick={() => alCambiarPestana((t) => ({ ...t, alto: altoNecesario(t.elementos) }))} className="boton-suave !h-10 !px-3 !text-[13px]" title="Que quepa justo todo el contenido">
              Ajustar al contenido
            </button>
          </div>
          <p className="text-[12px] leading-snug text-tinta-tenue">
            El lienzo mide 1000 de ancho: la app lo escala al ancho del panel, así se ve igual en el celular, en Windows y en la web. Doble clic en un texto para escribir; Mayús para seleccionar varios.
          </p>
        </Seccion>
      )}

      <Seccion titulo={`Capas (${pestana.elementos.length})`}>
        <ul className="space-y-0.5">
          {[...pestana.elementos].reverse().map((x) => {
            const I = ICONO_ELEMENTO[x.tipo];
            const activo = seleccion.includes(x.id);
            const indice = pestana.elementos.indexOf(x);
            return (
              <li key={x.id}>
                <div
                  onClick={(ev) => alSeleccionar(ev.shiftKey ? (activo ? seleccion.filter((s) => s !== x.id) : [...seleccion, x.id]) : [x.id])}
                  className={`group flex cursor-pointer items-center gap-2 rounded-lg px-2 py-1.5 text-[13px] ${activo ? 'bg-[#3b82f6]/12 text-[#1d4ed8]' : 'hover:bg-black/[0.04]'} ${x.oculto ? 'opacity-50' : ''}`}
                >
                  <I size={14} className="shrink-0 opacity-70" />
                  <span className="min-w-0 flex-1 truncate" title={`${ETIQUETA_ELEMENTO[x.tipo]} · ${x.nombre}`}>
                    {x.nombre}
                  </span>
                  <span className="flex opacity-0 transition group-hover:opacity-100">
                    <button
                      type="button"
                      title="Subir"
                      disabled={indice === pestana.elementos.length - 1}
                      onClick={(ev) => {
                        ev.stopPropagation();
                        alSeleccionar([x.id]);
                        alCambiarPestana((t) => {
                          const l = [...t.elementos];
                          const i = l.findIndex((y) => y.id === x.id);
                          if (i < l.length - 1) [l[i], l[i + 1]] = [l[i + 1], l[i]];
                          return { ...t, elementos: l };
                        });
                      }}
                      className="rounded p-0.5 hover:bg-black/10 disabled:opacity-30"
                    >
                      <ArrowUp size={12} />
                    </button>
                    <button
                      type="button"
                      title="Bajar"
                      disabled={indice === 0}
                      onClick={(ev) => {
                        ev.stopPropagation();
                        alSeleccionar([x.id]);
                        alCambiarPestana((t) => {
                          const l = [...t.elementos];
                          const i = l.findIndex((y) => y.id === x.id);
                          if (i > 0) [l[i], l[i - 1]] = [l[i - 1], l[i]];
                          return { ...t, elementos: l };
                        });
                      }}
                      className="rounded p-0.5 hover:bg-black/10 disabled:opacity-30"
                    >
                      <ArrowDown size={12} />
                    </button>
                  </span>
                  <button
                    type="button"
                    title={x.bloqueado ? 'Desbloquear' : 'Bloquear'}
                    onClick={(ev) => {
                      ev.stopPropagation();
                      alCambiarPestana((t) => ({ ...t, elementos: t.elementos.map((y) => (y.id === x.id ? { ...y, bloqueado: !y.bloqueado } : y)) }));
                    }}
                    className={`rounded p-0.5 hover:bg-black/10 ${x.bloqueado ? '' : 'opacity-0 group-hover:opacity-60'}`}
                  >
                    {x.bloqueado ? <Lock size={12} /> : <Unlock size={12} />}
                  </button>
                  <button
                    type="button"
                    title={x.oculto ? 'Mostrar' : 'Ocultar'}
                    onClick={(ev) => {
                      ev.stopPropagation();
                      alCambiarPestana((t) => ({ ...t, elementos: t.elementos.map((y) => (y.id === x.id ? { ...y, oculto: !y.oculto } : y)) }));
                    }}
                    className={`rounded p-0.5 hover:bg-black/10 ${x.oculto ? '' : 'opacity-0 group-hover:opacity-60'}`}
                  >
                    {x.oculto ? <EyeOff size={12} /> : <Eye size={12} />}
                  </button>
                </div>
              </li>
            );
          })}
          {pestana.elementos.length === 0 && (
            <li className="flex items-center gap-2 px-2 py-3 text-[13px] text-tinta-tenue">
              <Plus size={14} /> Agrega elementos desde la barra de arriba.
            </li>
          )}
        </ul>
      </Seccion>
    </div>
  );
}
