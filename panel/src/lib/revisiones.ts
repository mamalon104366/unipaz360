import type { Resumen } from './tipos';

export interface Revision {
  ok: boolean;
  texto: string;
  href: string;
}

/** «1 tramo» o «3 tramos». */
const cuenta = (n: number, uno: string, varios: string) => `${n} ${n === 1 ? uno : varios}`;

/**
 * La lista «Antes de publicar» del inicio: lo mismo que revisa el empaquetador
 * (`paquete/reglas.ts`), una línea por tema y con el enlace a donde se arregla.
 */
export function revisionesInicio(r: Resumen): Revision[] {
  return [
    {
      ok: r.vertices > 0 && r.componentes <= 1,
      texto: r.vertices === 0 ? 'Aún no hay nodos en el mapa' : r.componentes <= 1 ? 'El grafo está conectado' : `El grafo tiene ${r.componentes} partes separadas`,
      href: '/mapa?ver=aislados',
    },
    {
      ok: r.porVerificar === 0 && r.tramos > 0,
      texto: r.tramos === 0 ? 'Aún no hay rutas trazadas' : r.porVerificar ? `${cuenta(r.porVerificar, 'tramo', 'tramos')} sin verificar en campo` : 'Todos los tramos están verificados',
      href: '/mapa?ver=por-verificar',
    },
    {
      ok: r.accesibles > 0,
      texto: r.accesibles ? `${cuenta(r.accesibles, 'tramo apto', 'tramos aptos')} para la ruta accesible` : 'Ningún tramo marcado como accesible',
      href: '/mapa?ver=accesibles',
    },
    { ok: r.espacios > 0, texto: r.espacios ? `${cuenta(r.espacios, 'espacio', 'espacios')} con su nodo de acceso` : 'Sin espacios registrados', href: '/espacios' },
    {
      ok: r.lugares > 0,
      texto: r.lugares ? `El asistente puede guiar a ${cuenta(r.lugares, 'lugar', 'lugares')}` : 'El asistente no tiene lugares a dónde guiar: ponle nombre a los nodos',
      href: '/mapa',
    },
    {
      ok: r.panoramicas > 0,
      texto: r.panoramicas ? cuenta(r.panoramicas, 'panorámica 360° cargada', 'panorámicas 360° cargadas') : 'Sin panorámicas 360°',
      href: '/panoramicas',
    },
    ...(r.panoramicas > 0
      ? [
          {
            ok: r.fotosSinNombre === 0,
            texto: r.fotosSinNombre
              ? `${cuenta(r.fotosSinNombre, 'foto 360° sin nombre', 'fotos 360° sin nombre')}: la app muestra el código del nodo`
              : 'Todas las fotos 360° tienen nombre',
            href: '/panoramicas',
          },
          {
            ok: r.fotosSinNorte === 0,
            texto: r.fotosSinNorte ? `${cuenta(r.fotosSinNorte, 'foto 360°', 'fotos 360°')} sin el norte calibrado` : 'Todas las fotos 360° tienen el norte calibrado',
            href: '/panoramicas',
          },
        ]
      : []),
    ...(r.panoramicas > 1
      ? [
          {
            ok: r.flechas > 0 && r.flechasSinRegreso === 0,
            texto: !r.flechas
              ? 'Las fotos 360° no tienen flechas «Ir a» entre ellas'
              : r.flechasSinRegreso
                ? `${cuenta(r.flechasSinRegreso, 'flecha «Ir a»', 'flechas «Ir a»')} sin regreso desde la foto de destino`
                : 'Las flechas «Ir a» van y vuelven',
            href: '/panoramicas',
          },
        ]
      : []),
    ...(r.minimapaVisible && r.panoramicas > 0
      ? [
          {
            ok: r.fotosFueraDelMinimapa === 0,
            texto: !r.nodosEnMinimapa
              ? 'El minimapa no tiene nodos ubicados'
              : r.fotosFueraDelMinimapa
                ? `${cuenta(r.fotosFueraDelMinimapa, 'foto 360°', 'fotos 360°')} sin su punto en el minimapa`
                : 'Las fotos 360° están ubicadas en el minimapa',
            href: '/cliente',
          },
        ]
      : []),
  ];
}
