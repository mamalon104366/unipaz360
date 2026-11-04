'use client';

import { useEffect } from 'react';
import { X } from 'lucide-react';

/** Ventana modal con fondo difuminado. Se cierra con Esc o al hacer clic fuera. */
export function Modal({
  titulo,
  subtitulo,
  abierto,
  alCerrar,
  children,
  ancho = 'max-w-lg',
}: {
  titulo: string;
  subtitulo?: string;
  abierto: boolean;
  alCerrar: () => void;
  children: React.ReactNode;
  ancho?: string;
}) {
  useEffect(() => {
    if (!abierto) return;
    const tecla = (e: KeyboardEvent) => e.key === 'Escape' && alCerrar();
    window.addEventListener('keydown', tecla);
    return () => window.removeEventListener('keydown', tecla);
  }, [abierto, alCerrar]);
  if (!abierto) return null;
  return (
    <div
      className="fixed inset-0 z-50 grid place-items-center bg-black/25 p-4 backdrop-blur-[3px]"
      onMouseDown={(e) => e.target === e.currentTarget && alCerrar()}
      role="dialog"
      aria-modal="true"
      aria-label={titulo}
    >
      <div className={`vidrio max-h-[90vh] w-full ${ancho} overflow-y-auto rounded-[28px] p-7`}>
        <div className="mb-5 flex items-start justify-between gap-4">
          <div>
            <h2 className="text-[22px] font-medium tracking-tight">{titulo}</h2>
            {subtitulo && <p className="mt-1 text-[14px] text-tinta-suave">{subtitulo}</p>}
          </div>
          <button onClick={alCerrar} className="rounded-lg p-1.5 text-tinta-tenue hover:bg-black/5" aria-label="Cerrar">
            <X size={18} />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}

export function Campo({ etiqueta, ayuda, children }: { etiqueta: string; ayuda?: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-[13px] font-medium text-tinta-suave">{etiqueta}</span>
      {children}
      {ayuda && <span className="mt-1 block text-[12px] text-tinta-tenue">{ayuda}</span>}
    </label>
  );
}
