import { Proximamente } from '@/components/ui/Proximamente';

export default function Publicar() {
  return (
    <Proximamente
      titulo="Publicar versión"
      subtitulo="Llevar los cambios del panel a la app de todos."
      sprint="SPRINT P2"
      puntos={['Resumen de cambios sin publicar', 'Validar las 7 reglas del grafo y los contenidos', 'Construir el paquete de datos y subirlo a R2', 'La app avisa: [Actualizar ahora] / [Más tarde]']}
    />
  );
}
