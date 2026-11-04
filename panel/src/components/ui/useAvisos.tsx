'use client';

import { useCallback, useEffect, useState } from 'react';
import { CircleAlert, CircleCheck, X } from 'lucide-react';

type Tono = 'error' | 'ok';
interface Mensaje {
  texto: string;
  tono: Tono;
  clave: number;
}

/** Avisos flotantes para cualquier página: `avisar('Guardado', 'ok')`. */
export function useAvisos() {
  const [m, setM] = useState<Mensaje | null>(null);
  const avisar = useCallback((texto: string, tono: Tono = 'error') => setM({ texto, tono, clave: Date.now() }), []);
  useEffect(() => {
    if (!m) return;
    const t = setTimeout(() => setM(null), m.tono === 'error' ? 6000 : 2600);
    return () => clearTimeout(t);
  }, [m]);
  const nodo = m ? (
    <div role="status" className="fixed bottom-6 left-1/2 z-[60] -translate-x-1/2">
      <div className={`vidrio flex items-center gap-3 rounded-2xl px-4 py-3 text-sm ${m.tono === 'error' ? 'text-peligro' : 'text-tinta'}`}>
        {m.tono === 'error' ? <CircleAlert size={17} /> : <CircleCheck size={17} className="text-acento" />}
        <span className="max-w-md">{m.texto}</span>
        <button onClick={() => setM(null)} className="rounded-md p-0.5 text-tinta-tenue hover:bg-black/5" aria-label="Cerrar aviso">
          <X size={15} />
        </button>
      </div>
    </div>
  ) : null;
  return { avisar, nodo };
}
