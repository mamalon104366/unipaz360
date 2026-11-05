#!/usr/bin/env node
// Lleva a la app Flutter lo que necesita del apartado Cliente, sacado del código del panel:
//
//   app/assets/config/por_defecto.json        la configuración por defecto (con las páginas
//                                             iniciales), para paquetes que no traen una
//   app/test/cliente/casos_normalizar.json    entradas raras y lo que `normalizarConfig` del
//                                             panel devuelve con ellas: la prueba de Dart
//                                             exige el mismo resultado
//
// Uso (desde la raíz del repositorio), cada vez que cambie panel/src/lib/configApp.ts o
// paginasIniciales.ts:
//   node --conditions=react-server --experimental-transform-types panel/scripts/config-app-flutter.mjs
import './lib/ts.mjs';
import { mkdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const raiz = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const { normalizarConfig } = await import('../src/lib/configApp.ts');

const escribir = (ruta, valor, sangria = 1) => {
  const destino = path.join(raiz, ruta);
  mkdirSync(path.dirname(destino), { recursive: true });
  writeFileSync(destino, `${JSON.stringify(valor, null, sangria)}\n`);
  console.log(`escrito: ${ruta}`);
};

escribir('app/assets/config/por_defecto.json', normalizarConfig(null));

const el = (extra) => ({ id: 'a', tipo: 'texto', x: 10, y: 10, ancho: 100, alto: 40, ...extra });
const casos = [
  null,
  {},
  { marca: { nombre: '   ', subtitulo: 'x'.repeat(120), colorPrimario: '#ABCDEF', colorAcento: 'verde' }, interfaz: { escala: 3 } },
  // El encabezado ya no existe: se ignora. mostrarLogo solo acepta booleanos.
  { encabezado: { titulo: '  Hola  ', alto: 10, estilo: 'neón', mostrarLogo: 'si', plegable: false }, barraLateral: { mostrarLogo: 'si', ancho: 5 }, inicio: { pantalla: 'mapa', textoBoton: 'Volver al inicio del recorrido completo', bienvenida: '' } },
  {
    barraLateral: {
      posicion: 'derecha',
      estilo: 'claro',
      ancho: '30',
      mostrarLogo: false,
      iniciaPlegada: true,
      secciones: [
        { id: 'Nosotros', titulo: 'Quiénes somos', icono: 'info' },
        { id: 'nosotros', titulo: 'Repetida', icono: 'cohete', tipo: 'otra' },
        { id: 'Eventos 2027!', titulo: '', visible: false, tipo: 'pagina', icono: 'estrella' },
        { id: 'vistas', titulo: 'Recorrido' },
        { id: 'rutas', tipo: 'pagina' },
        { titulo: 'Sin id' },
        'no soy un objeto',
      ],
    },
  },
  {
    minimapa: {
      plegable: false,
      iniciaPlegado: true,
      imagen: 'app://mapa-dron',
      zoom: 9,
      rotacion: -400,
      desplazamientoX: 75.5,
      opacidad: 0.1,
      tamano: 'grande',
      nodos: [
        { vertice_id: ' V-001 ', x: 0.123456, y: 2 },
        { vertice_id: 'V-001', x: 0.5, y: 0.5 },
        { vertice_id: '', x: 0.1, y: 0.1 },
        { vertice_id: 'V-002', x: '0.25', y: -1 },
        { x: 0.3 },
      ],
    },
  },
  { minimapa: { imagen: 'app://videos/BienvenidosUNIPAZ.mp4', estadoInicial: 'maximizado', centrarEnActual: true, mostrarNombres: true, permitirMaximizar: false } },
  { minimapa: { imagen: 'https://datos.ejemplo/mapa.jpg', estadoInicial: 'oculto' } },
  {
    barraLateral: { secciones: [{ id: 'nosotros', tipo: 'pagina' }, { id: 'ubicacion', tipo: 'recorrido' }, { id: 'nueva', titulo: 'Agenda académica', tipo: 'pagina' }] },
    paginas: {
      ubicacion: { pestanas: [{ id: 'u', titulo: 'Mapa', alto: 50, fondo: '#FFF', elementos: [el({ tipo: 'mapa', zoomMapa: 25.6, lat: 100, lon: -73.7, src: 'http://inseguro/mapa.jpg' })] }] },
      nosotros: {
        pestanas: [
          {
            id: 'Historia',
            titulo: '',
            alto: '1500',
            fondo: '#ffffff',
            elementos: [
              el({ id: 'Título Principal', texto: 'Hola\nmundo', fuente: 'mono', tamano: '24', peso: '700', cursiva: 1, mayusculas: true, color: '#FF0000', alineacion: 'justificado', interlineado: 5, rotacion: 500, opacidad: 2 }),
              el({ id: 'Título Principal', tipo: 'boton', peso: 450, relleno: '', borde: 'red', grosorBorde: 60, sombra: true, enlace: 'javascript:alert(1)', radio: -3 }),
              el({ tipo: 'boton', enlace: 'seccion:admisiones', relleno: '#00FF00', x: '  15.55 ', y: 'abc' }),
              el({ tipo: 'imagen', src: 'app://imagenes/portada-campus.jpg', ajuste: 'contener', enlace: 'panoramica:P-002', borde: '#000000', grosorBorde: 2.25 }),
              el({ tipo: 'imagen', src: 'app://imagenes/../secreto', enlace: 'https://unipaz.edu.co/ruta con espacio' }),
              el({ tipo: 'video', automatico: 'si', ajuste: 'estirar', src: 'https://datos.ejemplo/v.mp4' }),
              el({ tipo: 'forma', figura: 'triangulo', relleno: 'azul', radio: 2000, ancho: 2, alto: 0 }),
              el({ tipo: 'forma', figura: 'linea', borde: '#123456', grosorBorde: 3 }),
              el({ tipo: 'cohete', texto: 'Tipo desconocido' }),
              el({ id: undefined, tipo: 'texto', texto: 42, oculto: true, bloqueado: 'no', x: 99999, ancho: 1 }),
            ],
          },
          { id: 'historia', titulo: 'Segunda con el mismo id', elementos: 'nada' },
          { id: 'historia', titulo: 'Tercera' },
          { titulo: '4' },
          { titulo: '5' },
          { titulo: '6' },
          { titulo: '7' },
          { titulo: '8' },
          { titulo: 'Novena: se descarta' },
        ],
      },
    },
  },
  { paginas: { video: { pestanas: [] } }, barraLateral: { secciones: [{ id: 'video', titulo: 'Video', icono: 'video', tipo: 'pagina' }] } },
];
escribir(
  'app/test/cliente/casos_normalizar.json',
  casos.map((entrada) => ({ entrada, salida: normalizarConfig(entrada) })),
  0,
);
