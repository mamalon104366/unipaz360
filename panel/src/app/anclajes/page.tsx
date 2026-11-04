import { Proximamente } from '@/components/ui/Proximamente';

export default function Anclajes() {
  return (
    <Proximamente
      titulo="Anclajes QR"
      subtitulo="Las placas que fijan el punto de partida de la ruta."
      sprint="SPRINT P2"
      puntos={['Asignar una placa a un nodo con el esquema unipaz360://nodo/{id}', 'Generar el PDF imprimible de las placas', 'Un QR publicado nunca se reutiliza: está impreso']}
    />
  );
}
