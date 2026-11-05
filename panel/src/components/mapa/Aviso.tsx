'use client';

import { useEffect } from 'react';
import { CircleAlert, Info, X } from 'lucide-react';

export interface MensajeAviso {
  texto: string;
  tono: 'error' | 'info';
  clave: number;
}

/** Aviso flotante que se cierra solo a los pocos segundos. */
export function Aviso({ mensaje, alCerrar }: { mensaje: MensajeAviso | null; alCerrar: () => void }) {
  useEffect(() => {
    if (!mensaje) return;
    const t = setTimeout(alCerrar, mensaje.tono === 'error' ? 6000 : 2500);
    return () => clearTimeout(t);
  }, [mensaje, alCerrar]);
  if (!mensaje) return null;
  return (
    <div role="status" className="absolute left-1/2 top-24 z-30 -translate-x-1/2">
      <div className={`vidrio flex items-center gap-3 rounded-2xl px-4 py-3 text-sm ${mensaje.tono === 'error' ? 'text-peligro' : 'text-tinta'}`}>
        {mensaje.tono === 'error' ? <CircleAlert size={17} /> : <Info size={17} />}
        <span className="max-w-md">{mensaje.texto}</span>
        <button onClick={alCerrar} className="rounded-md p-0.5 text-tinta-tenue hover:bg-black/5" aria-label="Cerrar aviso">
          <X size={15} />
        </button>
      </div>
    </div>
  );
}
