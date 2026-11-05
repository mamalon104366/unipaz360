'use client';

import 'maplibre-gl/dist/maplibre-gl.css';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  GeoJSONSource,
  Map as MapaLibre,
  NavigationControl,
  ScaleControl,
  setWorkerUrl,
  type MapLayerMouseEvent,
  type StyleSpecification,
} from 'maplibre-gl';
import { Check, CircleDot, Layers, MousePointer2, Spline, TriangleAlert } from 'lucide-react';
import type { Grafo, Tramo, Vertice } from '@/lib/tipos';
import { componentes } from '@/lib/geo';
import { api } from './api';
import { PanelPropiedades } from './PanelPropiedades';
import { Aviso, type MensajeAviso } from './Aviso';

export type Modo = 'seleccionar' | 'nodo' | 'tramo';
export type Seleccion = { tipo: 'vertice'; id: string } | { tipo: 'tramo'; id: string } | null;
type Fondo = 'satelite' | 'calles';

const COLOR_TIPO: Record<string, string> = {
  acceso: '#2f9e6e',
  puerta: '#3b82f6',
  cruce: '#f4f4f5',
  escalera: '#f59e0b',
  rampa: '#14b8a6',
  ascensor: '#8b5cf6',
  referencia: '#ec4899',
};

const ESTILO: StyleSpecification = {
  version: 8,
  glyphs: 'https://tiles.openfreemap.org/fonts/{fontstack}/{range}.pbf',
  sources: {
    satelite: {
      type: 'raster',
      tiles: ['https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'],
      tileSize: 256,
      // Esri no tiene imágenes del campus por encima de z18: desde ahí se amplía la de z18.
      maxzoom: 18,
      attribution: 'Imágenes © Esri, Maxar, Earthstar Geographics',
    },
    calles: {
      type: 'raster',
      tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
      tileSize: 256,
      maxzoom: 19,
      attribution: '© colaboradores de OpenStreetMap',
    },
  },
  layers: [
    { id: 'fondo-satelite', type: 'raster', source: 'satelite' },
    { id: 'fondo-calles', type: 'raster', source: 'calles', layout: { visibility: 'none' } },
  ],
};

function aGeoJSON(g: { vertices: Vertice[]; tramos: Tramo[] }, aislados: Set<string>, con360: Set<string>) {
  const pos = new Map(g.vertices.map((v) => [v.id, [v.lon, v.lat] as [number, number]]));
  return {
    vertices: {
      type: 'FeatureCollection' as const,
      features: g.vertices.map((v) => ({
        type: 'Feature' as const,
        id: v.id,
        properties: { id: v.id, tipo: v.tipo, color: COLOR_TIPO[v.tipo] ?? '#fff', aislado: aislados.has(v.id), con360: con360.has(v.id) },
        geometry: { type: 'Point' as const, coordinates: [v.lon, v.lat] },
      })),
    },
    tramos: {
      type: 'FeatureCollection' as const,
      features: g.tramos
        .filter((t) => pos.has(t.origen_id) && pos.has(t.destino_id))
        .map((t) => ({
          type: 'Feature' as const,
          id: t.id,
          properties: {
            id: t.id,
            estado: t.escaleras ? 'escaleras' : t.accesible ? 'accesible' : 'normal',
            verificado: t.verificado,
          },
          geometry: { type: 'LineString' as const, coordinates: [pos.get(t.origen_id)!, pos.get(t.destino_id)!] },
        })),
    },
  };
}

export function EditorMapa({ inicial, filtro, soloLectura = false }: { inicial: Grafo; filtro: string | null; soloLectura?: boolean }) {
  const router = useRouter();
  const contenedor = useRef<HTMLDivElement>(null);
  const mapa = useRef<MapaLibre | null>(null);
  const [vertices, setVertices] = useState(inicial.vertices);
  const [tramos, setTramos] = useState(inicial.tramos);
  const [modo, setModo] = useState<Modo>('seleccionar');
  const [sel, setSel] = useState<Seleccion>(null);
  const [inicioTramo, setInicioTramo] = useState<string | null>(null);
  const [fondo, setFondo] = useState<Fondo>('satelite');
  const [aviso, setAviso] = useState<MensajeAviso | null>(null);
  const [listo, setListo] = useState(false);

  // Referencias para los manejadores del mapa (que se registran una sola vez).
  const estado = useRef({ modo, inicioTramo, vertices, tramos, sel, soloLectura });
  useEffect(() => {
    estado.current = { modo, inicioTramo, vertices, tramos, sel, soloLectura };
  });

  const grupos = useMemo(() => componentes(vertices, tramos), [vertices, tramos]);
  const aislados = useMemo(() => new Set(grupos.slice(1).flat()), [grupos]);

  const avisar = useCallback((texto: string, tono: MensajeAviso['tono'] = 'error') => {
    setAviso({ texto, tono, clave: Date.now() });
  }, []);

  /** Tras cada cambio se refrescan los contadores de la barra lateral. */
  const refrescar = useCallback(() => router.refresh(), [router]);

  // ------------------------------------------------------------------ acciones
  const crearNodo = useCallback(
    async (lon: number, lat: number) => {
      try {
        const v = await api<Vertice>('/api/vertices', 'POST', { lat, lon, tipo: 'cruce' });
        setVertices((vs) => [...vs, v]);
        refrescar();
        return v;
      } catch (e) {
        avisar((e as Error).message);
        return null;
      }
    },
    [avisar, refrescar],
  );

  const crearTramo = useCallback(
    async (origen: string, destino: string) => {
      try {
        const t = await api<Tramo>('/api/tramos', 'POST', { origen_id: origen, destino_id: destino });
        setTramos((ts) => [...ts, t]);
        refrescar();
        return t;
      } catch (e) {
        avisar((e as Error).message);
        return null;
      }
    },
    [avisar, refrescar],
  );

  const moverNodo = useCallback(
    async (id: string, lon: number, lat: number) => {
      try {
        const r = await api<{ vertice: Vertice; tramos: Tramo[] }>(`/api/vertices/${id}`, 'PATCH', { lat, lon });
        setVertices((vs) => vs.map((v) => (v.id === id ? r.vertice : v)));
        const cambiados = new Map(r.tramos.map((t) => [t.id, t]));
        setTramos((ts) => ts.map((t) => cambiados.get(t.id) ?? t));
      } catch (e) {
        avisar((e as Error).message);
      }
    },
    [avisar],
  );

  const eliminarSeleccion = useCallback(async () => {
    const s = estado.current.sel;
    if (!s) return;
    try {
      if (s.tipo === 'vertice') {
        await api(`/api/vertices/${s.id}`, 'DELETE');
        setVertices((vs) => vs.filter((v) => v.id !== s.id));
        setTramos((ts) => ts.filter((t) => t.origen_id !== s.id && t.destino_id !== s.id));
      } else {
        await api(`/api/tramos/${s.id}`, 'DELETE');
        setTramos((ts) => ts.filter((t) => t.id !== s.id));
      }
      setSel(null);
      refrescar();
      avisar(`${s.id} eliminado`, 'info');
    } catch (e) {
      avisar((e as Error).message);
    }
  }, [avisar, refrescar]);

  // ------------------------------------------------------------------ mapa
  useEffect(() => {
    if (!contenedor.current) return;
    // El worker se sirve desde public/ (lo copia scripts/copiar-worker.mjs); MapLibre exige URL absoluta.
    setWorkerUrl(new URL('/maplibre/maplibre-gl-worker.mjs', window.location.origin).href);
    const m = new MapaLibre({
      container: contenedor.current,
      style: ESTILO,
      center: inicial.campus.centro,
      zoom: inicial.campus.zoom,
      maxZoom: 21,
      attributionControl: { compact: true },
    });
    mapa.current = m;
    m.addControl(new NavigationControl({ visualizePitch: false }), 'bottom-right');
    m.addControl(new ScaleControl({ unit: 'metric' }), 'bottom-left');

    m.on('load', () => {
      m.addSource('tramos', { type: 'geojson', data: { type: 'FeatureCollection', features: [] }, promoteId: 'id' });
      m.addSource('vertices', { type: 'geojson', data: { type: 'FeatureCollection', features: [] }, promoteId: 'id' });
      m.addSource('guia', { type: 'geojson', data: { type: 'FeatureCollection', features: [] } });

      m.addLayer({
        id: 'tramos-borde',
        type: 'line',
        source: 'tramos',
        layout: { 'line-cap': 'round', 'line-join': 'round' },
        paint: {
          'line-color': ['case', ['boolean', ['feature-state', 'sel'], false], '#ffffff', 'rgba(20,20,22,0.55)'],
          'line-width': ['interpolate', ['linear'], ['zoom'], 15, 4, 20, 11],
        },
      });
      m.addLayer({
        id: 'tramos',
        type: 'line',
        source: 'tramos',
        layout: { 'line-cap': 'round', 'line-join': 'round' },
        paint: {
          'line-color': ['match', ['get', 'estado'], 'accesible', '#34d399', 'escaleras', '#fbbf24', '#e4e4e7'],
          'line-width': ['interpolate', ['linear'], ['zoom'], 15, 2, 20, 6],
          'line-dasharray': ['case', ['get', 'verificado'], ['literal', [1, 0]], ['literal', [2, 1.4]]],
        },
      });
      m.addLayer({
        id: 'guia',
        type: 'line',
        source: 'guia',
        paint: { 'line-color': '#ffffff', 'line-width': 2, 'line-dasharray': [1.5, 1.5], 'line-opacity': 0.9 },
      });
      m.addLayer({
        id: 'vertices-halo',
        type: 'circle',
        source: 'vertices',
        paint: {
          'circle-radius': ['interpolate', ['linear'], ['zoom'], 15, 6, 20, 15],
          'circle-color': ['case', ['get', 'aislado'], '#ef4444', 'rgba(20,20,22,0.6)'],
          'circle-opacity': ['case', ['boolean', ['feature-state', 'sel'], false], 1, 0.85],
          'circle-stroke-width': ['case', ['boolean', ['feature-state', 'sel'], false], 3, ['get', 'con360'], 2.5, 0],
          'circle-stroke-color': ['case', ['boolean', ['feature-state', 'sel'], false], '#ffffff', '#60a5fa'],
        },
      });
      m.addLayer({
        id: 'vertices',
        type: 'circle',
        source: 'vertices',
        paint: {
          'circle-radius': ['interpolate', ['linear'], ['zoom'], 15, 3.5, 20, 9],
          'circle-color': ['get', 'color'],
        },
      });
      m.addLayer({
        id: 'vertices-id',
        type: 'symbol',
        source: 'vertices',
        minzoom: 18.5,
        layout: {
          'text-field': ['get', 'id'],
          'text-size': 11,
          'text-offset': [0, 1.5],
          'text-font': ['Noto Sans Regular'],
        },
        paint: { 'text-color': '#ffffff', 'text-halo-color': 'rgba(0,0,0,0.75)', 'text-halo-width': 1.4 },
      });
      setListo(true);
    });

    return () => {
      m.remove();
      mapa.current = null;
    };
    // El mapa se crea una sola vez.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Datos → capas
  useEffect(() => {
    const m = mapa.current;
    if (!m || !listo) return;
    const gj = aGeoJSON({ vertices, tramos }, aislados, new Set(inicial.conPanoramica));
    (m.getSource('vertices') as GeoJSONSource).setData(gj.vertices);
    (m.getSource('tramos') as GeoJSONSource).setData(gj.tramos);
  }, [vertices, tramos, aislados, listo, inicial.conPanoramica]);

  // Selección → estado visual
  const selAnterior = useRef<Seleccion>(null);
  useEffect(() => {
    const m = mapa.current;
    if (!m || !listo) return;
    const quitar = selAnterior.current;
    if (quitar) m.setFeatureState({ source: quitar.tipo === 'vertice' ? 'vertices' : 'tramos', id: quitar.id }, { sel: false });
    const marcar = sel ?? (inicioTramo ? { tipo: 'vertice' as const, id: inicioTramo } : null);
    if (marcar) m.setFeatureState({ source: marcar.tipo === 'vertice' ? 'vertices' : 'tramos', id: marcar.id }, { sel: true });
    selAnterior.current = marcar;
  }, [sel, inicioTramo, listo, vertices, tramos]);

  // Fondo
  useEffect(() => {
    const m = mapa.current;
    if (!m || !listo) return;
    m.setLayoutProperty('fondo-satelite', 'visibility', fondo === 'satelite' ? 'visible' : 'none');
    m.setLayoutProperty('fondo-calles', 'visibility', fondo === 'calles' ? 'visible' : 'none');
  }, [fondo, listo]);

  // Filtros que llegan desde la barra lateral
  useEffect(() => {
    const m = mapa.current;
    if (!m || !listo || !filtro) return;
    const objetivo =
      filtro === 'aislados'
        ? vertices.filter((v) => aislados.has(v.id))
        : filtro === 'por-verificar'
          ? tramos.filter((t) => !t.verificado).flatMap((t) => vertices.filter((v) => v.id === t.origen_id || v.id === t.destino_id))
          : filtro === 'accesibles'
            ? tramos.filter((t) => t.accesible).flatMap((t) => vertices.filter((v) => v.id === t.origen_id || v.id === t.destino_id))
            : [];
    if (!objetivo.length) {
      const t = setTimeout(() => avisar('No hay elementos en este filtro.', 'info'), 0);
      return () => clearTimeout(t);
    }
    const lons = objetivo.map((v) => v.lon);
    const lats = objetivo.map((v) => v.lat);
    m.fitBounds([[Math.min(...lons), Math.min(...lats)], [Math.max(...lons), Math.max(...lats)]], { padding: 120, maxZoom: 19.5, duration: 700 });
    // Solo al cambiar de filtro.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filtro, listo]);

  // ------------------------------------------------------------------ interacción
  useEffect(() => {
    const m = mapa.current;
    if (!m || !listo) return;

    // Detección propia en píxeles, con los datos en memoria: no depende de que
    // MapLibre haya terminado de procesar las capas (evita perder el primer clic).
    const verticeEn = (e: { point: { x: number; y: number } }) => {
      let mejor: string | undefined;
      let dMin = 14;
      for (const v of estado.current.vertices) {
        const p = m.project([v.lon, v.lat]);
        const d = Math.hypot(p.x - e.point.x, p.y - e.point.y);
        if (d < dMin) {
          dMin = d;
          mejor = v.id;
        }
      }
      return mejor;
    };
    const tramoEn = (e: { point: { x: number; y: number } }) => {
      const pos = new Map(estado.current.vertices.map((v) => [v.id, m.project([v.lon, v.lat])]));
      let mejor: string | undefined;
      let dMin = 8;
      for (const t of estado.current.tramos) {
        const a = pos.get(t.origen_id);
        const b = pos.get(t.destino_id);
        if (!a || !b) continue;
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        const l2 = dx * dx + dy * dy || 1;
        const k = Math.max(0, Math.min(1, ((e.point.x - a.x) * dx + (e.point.y - a.y) * dy) / l2));
        const d = Math.hypot(e.point.x - (a.x + k * dx), e.point.y - (a.y + k * dy));
        if (d < dMin) {
          dMin = d;
          mejor = t.id;
        }
      }
      return mejor;
    };

    const alClic = async (e: MapLayerMouseEvent) => {
      const { modo: md, inicioTramo: ini } = estado.current;
      const idV = verticeEn(e);
      if (md === 'seleccionar') {
        const idT = idV ? undefined : tramoEn(e);
        setSel(idV ? { tipo: 'vertice', id: idV } : idT ? { tipo: 'tramo', id: idT } : null);
      } else if (md === 'nodo') {
        if (idV) {
          setSel({ tipo: 'vertice', id: idV });
          return;
        }
        const v = await crearNodo(e.lngLat.lng, e.lngLat.lat);
        if (v) setSel({ tipo: 'vertice', id: v.id });
      } else if (md === 'tramo') {
        // Encadenado: cada clic une con el anterior; un clic en vacío crea el nodo y lo une.
        let destino = idV;
        if (!destino) {
          const v = await crearNodo(e.lngLat.lng, e.lngLat.lat);
          if (!v) return;
          destino = v.id;
        }
        // Mientras se dibuja no se abre el panel (taparía el mapa); se edita luego en "Seleccionar".
        if (ini && ini !== destino) await crearTramo(ini, destino);
        setSel(null);
        setInicioTramo(destino);
      }
    };

    // Guía punteada mientras se traza un tramo.
    const alMover = (e: MapLayerMouseEvent) => {
      const { modo: md, inicioTramo: ini, vertices: vs } = estado.current;
      const sobreV = verticeEn(e);
      const sobreT = md === 'seleccionar' && !sobreV ? tramoEn(e) : undefined;
      m.getCanvas().style.cursor = sobreV ? (md === 'seleccionar' ? 'grab' : 'pointer') : sobreT ? 'pointer' : md === 'seleccionar' ? '' : 'crosshair';
      const guia = m.getSource('guia') as GeoJSONSource;
      const a = md === 'tramo' && ini ? vs.find((v) => v.id === ini) : null;
      guia.setData(
        a
          ? { type: 'Feature', properties: {}, geometry: { type: 'LineString', coordinates: [[a.lon, a.lat], [e.lngLat.lng, e.lngLat.lat]] } }
          : { type: 'FeatureCollection', features: [] },
      );
    };

    // Arrastrar nodos en modo seleccionar.
    let arrastrando: string | null = null;
    let movido = false;
    const alPresionar = (e: MapLayerMouseEvent) => {
      if (estado.current.modo !== 'seleccionar' || estado.current.soloLectura) return;
      const id = verticeEn(e);
      if (!id) return;
      e.preventDefault();
      arrastrando = id;
      movido = false;
      setSel({ tipo: 'vertice', id });
      m.getCanvas().style.cursor = 'grabbing';
      m.dragPan.disable();
    };
    const alArrastrar = (e: MapLayerMouseEvent) => {
      if (!arrastrando) return;
      movido = true;
      const id = arrastrando;
      setVertices((vs) => vs.map((v) => (v.id === id ? { ...v, lon: e.lngLat.lng, lat: e.lngLat.lat } : v)));
    };
    const alSoltar = (e: MapLayerMouseEvent) => {
      if (!arrastrando) return;
      const id = arrastrando;
      arrastrando = null;
      m.dragPan.enable();
      m.getCanvas().style.cursor = '';
      if (movido) moverNodo(id, e.lngLat.lng, e.lngLat.lat);
    };

    m.on('click', alClic);
    m.on('mousemove', alMover);
    m.on('mousedown', alPresionar);
    m.on('mousemove', alArrastrar);
    m.on('mouseup', alSoltar);
    return () => {
      m.off('click', alClic);
      m.off('mousemove', alMover);
      m.off('mousedown', alPresionar);
      m.off('mousemove', alArrastrar);
      m.off('mouseup', alSoltar);
    };
  }, [listo, crearNodo, crearTramo, moverNodo]);

  // Teclado: V / N / T cambian de modo, Supr elimina, Esc cancela.
  useEffect(() => {
    const alTeclear = (e: KeyboardEvent) => {
      const t = e.target as HTMLElement;
      if (t.tagName === 'INPUT' || t.tagName === 'SELECT' || t.tagName === 'TEXTAREA') return;
      const k = e.key.toLowerCase();
      if (estado.current.soloLectura && k !== 'escape') return;
      if (k === 'v') cambiarModo('seleccionar');
      else if (k === 'n') cambiarModo('nodo');
      else if (k === 't') cambiarModo('tramo');
      else if (k === 'escape') {
        setInicioTramo(null);
        setSel(null);
        (mapa.current?.getSource('guia') as GeoJSONSource | undefined)?.setData({ type: 'FeatureCollection', features: [] });
      } else if (k === 'delete' || k === 'backspace') eliminarSeleccion();
    };
    // En captura: el lienzo de MapLibre maneja sus propias teclas y no debe ocultarlas.
    document.addEventListener('keydown', alTeclear, true);
    return () => document.removeEventListener('keydown', alTeclear, true);
  }, [eliminarSeleccion]);

  function cambiarModo(m: Modo) {
    setModo(m);
    setInicioTramo(null);
    (mapa.current?.getSource('guia') as GeoJSONSource | undefined)?.setData({ type: 'FeatureCollection', features: [] });
  }

  const vSel = sel?.tipo === 'vertice' ? vertices.find((v) => v.id === sel.id) : undefined;
  const tSel = sel?.tipo === 'tramo' ? tramos.find((t) => t.id === sel.id) : undefined;
  const conexo = vertices.length > 0 && grupos.length <= 1;

  return (
    <div className="relative h-full w-full">
      {/* MapLibre fuerza position:relative en su contenedor: se envuelve para ocupar todo. */}
      <div className="absolute inset-0">
        <div ref={contenedor} className="h-full w-full" />
      </div>

      {/* Barra superior: título, modos y estado */}
      <div className="pointer-events-none absolute inset-x-0 top-0 z-10 flex items-start justify-between gap-4 p-4">
        <div className="vidrio pointer-events-auto rounded-2xl px-5 py-3">
          <div className="text-[19px] font-medium leading-tight">Mapa y rutas</div>
          <div className="text-[13px] text-tinta-suave">
            {inicial.campus.nombre} · {vertices.length} nodos · {tramos.length} tramos
          </div>
        </div>

        <div className="vidrio pointer-events-auto flex items-center gap-1 rounded-2xl p-1.5">
          <BotonModo activo={modo === 'seleccionar'} onClick={() => cambiarModo('seleccionar')} icono={<MousePointer2 size={17} />} texto="Seleccionar" tecla="V" />
          {!soloLectura && (
            <>
              <BotonModo activo={modo === 'nodo'} onClick={() => cambiarModo('nodo')} icono={<CircleDot size={17} />} texto="Nodo" tecla="N" />
              <BotonModo activo={modo === 'tramo'} onClick={() => cambiarModo('tramo')} icono={<Spline size={17} />} texto="Ruta" tecla="T" />
            </>
          )}
          <span className="mx-1 h-6 w-px bg-black/10" />
          <button
            onClick={() => setFondo((f) => (f === 'satelite' ? 'calles' : 'satelite'))}
            className="flex h-10 items-center gap-2 rounded-xl px-3 text-sm text-tinta-suave transition hover:bg-black/5"
            title="Cambiar el mapa de fondo"
          >
            <Layers size={17} /> {fondo === 'satelite' ? 'Satélite' : 'Calles'}
          </button>
        </div>

        <div
          className={`vidrio pointer-events-auto flex items-center gap-2 rounded-2xl px-4 py-3 text-sm font-medium ${
            vertices.length === 0 ? 'text-tinta-suave' : conexo ? 'text-acento' : 'text-alerta'
          }`}
        >
          {vertices.length === 0 ? (
            'Sin nodos todavía'
          ) : conexo ? (
            <>
              <Check size={16} /> Grafo conectado
            </>
          ) : (
            <>
              <TriangleAlert size={16} /> {grupos.length} partes separadas · {aislados.size} nodos aislados
            </>
          )}
        </div>
      </div>

      {/* Ayuda contextual del modo */}
      <div className="pointer-events-none absolute bottom-6 left-1/2 z-10 -translate-x-1/2">
        <div className="vidrio rounded-full px-5 py-2.5 text-[13px] text-tinta-suave">
          {modo === 'seleccionar' && (soloLectura ? 'Solo lectura: clic en un nodo o tramo para ver sus datos' : 'Clic para seleccionar · arrastra un nodo para moverlo · Supr para eliminar')}
          {modo === 'nodo' && 'Clic en el mapa para poner un nodo'}
          {modo === 'tramo' &&
            (inicioTramo
              ? `Desde ${inicioTramo}: clic en otro nodo o en el mapa para seguir la ruta · Esc para terminar`
              : 'Clic en un nodo (o en el mapa) para empezar la ruta')}
        </div>
      </div>

      {/* Leyenda */}
      <div className="vidrio absolute bottom-6 left-4 z-10 mb-8 rounded-2xl px-4 py-3 text-[12px] text-tinta-suave">
        <div className="mb-1.5 font-medium text-tinta">Rutas</div>
        <Leyenda color="#34d399" texto="Accesible" />
        <Leyenda color="#fbbf24" texto="Con escaleras" />
        <Leyenda color="#a1a1aa" texto="Normal" />
        <Leyenda color="#a1a1aa" texto="Sin verificar" punteada />
        <div className="mt-1.5 flex items-center gap-2 py-0.5"><span className="h-3 w-3 rounded-full border-[2.5px] border-[#60a5fa]" /> Nodo con foto 360°</div>
      </div>

      {(vSel || tSel) && (
        <PanelPropiedades
          vertice={vSel}
          tramo={tSel}
          vertices={vertices}
          aislado={vSel ? aislados.has(vSel.id) : false}
          soloLectura={soloLectura}
          tieneAnclaje={vSel ? inicial.conAnclaje.includes(vSel.id) : false}
          tienePanoramica={vSel ? inicial.conPanoramica.includes(vSel.id) : false}
          panoramica={vSel ? inicial.panoramicas.find((p) => p.vertice_id === vSel.id) : undefined}
          alCerrar={() => setSel(null)}
          alEliminar={eliminarSeleccion}
          alGuardarVertice={async (id, datos) => {
            try {
              const r = await api<{ vertice: Vertice; tramos: Tramo[] }>(`/api/vertices/${id}`, 'PATCH', datos);
              setVertices((vs) => vs.map((v) => (v.id === id ? r.vertice : v)));
              refrescar();
            } catch (e) {
              avisar((e as Error).message);
            }
          }}
          alGuardarTramo={async (id, datos) => {
            try {
              const t = await api<Tramo>(`/api/tramos/${id}`, 'PATCH', datos);
              setTramos((ts) => ts.map((x) => (x.id === id ? t : x)));
              refrescar();
            } catch (e) {
              avisar((e as Error).message);
            }
          }}
        />
      )}

      <Aviso mensaje={aviso} alCerrar={() => setAviso(null)} />
    </div>
  );
}

function BotonModo({ activo, onClick, icono, texto, tecla }: { activo: boolean; onClick: () => void; icono: React.ReactNode; texto: string; tecla: string }) {
  return (
    <button
      onClick={onClick}
      title={`${texto} (${tecla})`}
      className={`flex h-10 items-center gap-2 rounded-xl px-3.5 text-sm transition ${
        activo ? 'bg-riel text-white shadow-[0_6px_14px_-6px_rgb(0_0_0/0.6)]' : 'text-tinta-suave hover:bg-black/5'
      }`}
    >
      {icono}
      {texto}
      <kbd className={`ml-0.5 rounded-md px-1.5 text-[10px] ${activo ? 'bg-white/15' : 'bg-black/5'}`}>{tecla}</kbd>
    </button>
  );
}

function Leyenda({ color, texto, punteada }: { color: string; texto: string; punteada?: boolean }) {
  return (
    <div className="flex items-center gap-2 py-0.5">
      <span className="h-0 w-6 border-t-[3px]" style={{ borderColor: color, borderStyle: punteada ? 'dashed' : 'solid' }} />
      {texto}
    </div>
  );
}
