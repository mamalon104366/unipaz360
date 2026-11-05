'use client';

import { Printer } from 'lucide-react';

export function BotonImprimir() {
  return (
    <button onClick={() => window.print()} className="boton-primario">
      <Printer size={16} /> Imprimir o guardar PDF
    </button>
  );
}
