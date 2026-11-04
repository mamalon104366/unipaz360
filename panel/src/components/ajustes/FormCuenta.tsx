'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { api } from '@/components/ui/api';
import { Campo } from '@/components/ui/Modal';
import { useAvisos } from '@/components/ui/useAvisos';

export function FormCuenta() {
  const router = useRouter();
  const { avisar, nodo } = useAvisos();
  const [actual, setActual] = useState('');
  const [nueva, setNueva] = useState('');
  const [repetir, setRepetir] = useState('');
  const [enviando, setEnviando] = useState(false);

  async function guardar(e: React.FormEvent) {
    e.preventDefault();
    if (nueva !== repetir) return avisar('Las dos contraseñas nuevas no coinciden.');
    setEnviando(true);
    try {
      await api('/api/cuenta/clave', 'POST', { actual, nueva });
      setActual('');
      setNueva('');
      setRepetir('');
      avisar('Contraseña actualizada.', 'ok');
      router.replace('/cuenta');
      router.refresh();
    } catch (err) {
      avisar((err as Error).message);
    } finally {
      setEnviando(false);
    }
  }

  return (
    <form onSubmit={guardar} className="mt-5 space-y-4">
      <Campo etiqueta="Contraseña actual">
        <input type="password" required value={actual} onChange={(e) => setActual(e.target.value)} autoComplete="current-password" className="campo" />
      </Campo>
      <Campo etiqueta="Nueva contraseña">
        <input type="password" required minLength={10} value={nueva} onChange={(e) => setNueva(e.target.value)} autoComplete="new-password" className="campo" />
      </Campo>
      <Campo etiqueta="Repite la nueva contraseña">
        <input type="password" required minLength={10} value={repetir} onChange={(e) => setRepetir(e.target.value)} autoComplete="new-password" className="campo" />
      </Campo>
      <button type="submit" disabled={enviando} className="boton-primario w-full">
        {enviando ? 'Guardando…' : 'Guardar contraseña'}
      </button>
      {nodo}
    </form>
  );
}
