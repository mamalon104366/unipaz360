import { Proximamente } from '@/components/ui/Proximamente';

export default function Panoramicas() {
  return (
    <Proximamente
      titulo="Panorámicas 360°"
      subtitulo="La foto esférica de cada nodo, limpia y con su contenido encima."
      sprint="SPRINT P2"
      puntos={[
        'Arrastrar la foto 360° sobre un nodo del mapa',
        'Nivelar el horizonte y elegir hacia dónde mira al abrir',
        'Tapar el trípode con el logo y difuminar rostros o placas',
        'Agregar información, anuncios con vigencia, imágenes y videos',
        'Ver la panorámica tal como la verá el visitante',
      ]}
    />
  );
}
