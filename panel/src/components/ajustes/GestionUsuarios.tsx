'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Copy, KeyRound, Plus, ShieldCheck, UserRoundX, UserRoundCheck } from 'lucide-react';
import { api } from '@/components/ui/api';
import { Campo, Modal } from '@/components/ui/Modal';
import { Pagina } from '@/components/ui/Pagina';
import { useAvisos } from '@/components/ui/useAvisos';
import { DESCRIPCION_ROL, ETIQUETA_ROL, ROLES, type Rol, type UsuarioFila } from '@/lib/tipos';

const fecha = (f: string | null) =>
  f ? new Date(f).toLocaleString('es-CO', { dateStyle: 'medium', timeStyle: 'short' }) : 'Nunca';

export function GestionUsuarios({ inicial, yo }: { inicial: UsuarioFila[]; yo: string }) {
  const router = useRouter();
  const { avisar, nodo } = useAvisos();
  const [usuarios, setUsuarios] = useState(inicial);
  const [nueva, setNueva] = useState(false);
  const [temporal, setTemporal] = useState<{ correo: string; clave: string } | null>(null);

  async function cambiar(u: UsuarioFila, datos: Partial<{ rol: Rol; activo: boolean; restablecer: boolean }>) {
    try {
      const r = await api<{ usuario: UsuarioFila; claveTemporal: string | null }>(`/api/usuarios/${u.id}`, 'PATCH', datos);
      setUsuarios((us) => us.map((x) => (x.id === u.id ? r.usuario : x)));
      if (r.claveTemporal) setTemporal({ correo: u.correo, clave: r.claveTemporal });
      else avisar('Cambios guardados.', 'ok');
      router.refresh();
    } catch (e) {
      avisar((e as Error).message);
    }
  }

  return (
    <Pagina
      titulo="Cuentas y roles"
      subtitulo="Quién puede entrar al panel y qué puede hacer."
      acciones={
        <button onClick={() => setNueva(true)} className="boton-primario">
          <Plus size={17} /> Nueva cuenta
        </button>
      }
    >
      <div className="mb-6 grid gap-3 md:grid-cols-3">
        {ROLES.map((r) => (
          <div key={r} className="hundido rounded-2xl px-4 py-3">
            <div className="text-[14px] font-medium">{ETIQUETA_ROL[r]}</div>
            <div className="mt-0.5 text-[13px] text-tinta-suave">{DESCRIPCION_ROL[r]}</div>
          </div>
        ))}
      </div>

      <div className="relieve overflow-hidden rounded-[24px]">
        <table className="w-full text-left text-[14px]">
          <thead className="text-[12px] uppercase tracking-[0.08em] text-tinta-tenue">
            <tr className="border-b border-black/[0.06]">
              <th className="px-5 py-3.5 font-medium">Persona</th>
              <th className="px-3 py-3.5 font-medium">Rol</th>
              <th className="hidden px-3 py-3.5 font-medium lg:table-cell">Último acceso</th>
              <th className="px-5 py-3.5 text-right font-medium">Acciones</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-black/[0.05]">
            {usuarios.map((u) => (
              <tr key={u.id} className={u.activo ? '' : 'opacity-50'}>
                <td className="px-5 py-3.5">
                  <div className="flex items-center gap-3">
                    <div className="grid h-10 w-10 shrink-0 place-items-center rounded-full bg-riel text-[12px] font-semibold text-white">
                      {(u.nombre || u.correo).slice(0, 2).toUpperCase()}
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center gap-2 font-medium">
                        <span className="truncate">{u.nombre || u.correo.split('@')[0]}</span>
                        {u.id === yo && <span className="chip bg-black/5 text-tinta-suave">Tú</span>}
                        {!u.activo && <span className="chip bg-black/5 text-tinta-suave">Desactivada</span>}
                      </div>
                      <div className="flex items-center gap-1.5 truncate text-[13px] text-tinta-tenue">
                        {u.correo}
                        {u.institucional && <ShieldCheck size={13} className="text-acento" aria-label="Correo institucional" />}
                      </div>
                    </div>
                  </div>
                </td>
                <td className="px-3 py-3.5">
                  <select
                    value={u.rol}
                    disabled={!u.activo}
                    onChange={(e) => cambiar(u, { rol: e.target.value as Rol })}
                    className="campo !w-auto !py-1.5 !text-[14px]"
                  >
                    {ROLES.map((r) => (
                      <option key={r} value={r}>
                        {ETIQUETA_ROL[r]}
                      </option>
                    ))}
                  </select>
                </td>
                <td className="hidden px-3 py-3.5 text-tinta-suave lg:table-cell">{fecha(u.ultimo_acceso)}</td>
                <td className="px-5 py-3.5">
                  <div className="flex justify-end gap-1">
                    <button
                      onClick={() => cambiar(u, { restablecer: true })}
                      disabled={!u.activo}
                      title="Restablecer contraseña"
                      className="rounded-xl p-2 text-tinta-suave hover:bg-black/5 disabled:opacity-40"
                    >
                      <KeyRound size={17} />
                    </button>
                    {u.id !== yo &&
                      (u.activo ? (
                        <button onClick={() => cambiar(u, { activo: false })} title="Desactivar cuenta" className="rounded-xl p-2 text-peligro hover:bg-peligro/10">
                          <UserRoundX size={17} />
                        </button>
                      ) : (
                        <button onClick={() => cambiar(u, { activo: true })} title="Reactivar cuenta" className="rounded-xl p-2 text-acento hover:bg-acento-suave">
                          <UserRoundCheck size={17} />
                        </button>
                      ))}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <NuevaCuenta
        abierto={nueva}
        alCerrar={() => setNueva(false)}
        alCrear={(u, clave) => {
          setUsuarios((us) => [...us, u]);
          setNueva(false);
          setTemporal({ correo: u.correo, clave });
          router.refresh();
        }}
        avisar={avisar}
      />

      <Modal
        titulo="Contraseña temporal"
        subtitulo="Compártela por un canal seguro. Solo se muestra esta vez: al entrar, la persona deberá cambiarla."
        abierto={!!temporal}
        alCerrar={() => setTemporal(null)}
      >
        {temporal && (
          <div>
            <div className="text-[13px] text-tinta-tenue">{temporal.correo}</div>
            <div className="hundido mt-2 flex items-center justify-between rounded-2xl px-4 py-3">
              <code className="font-mono text-[20px] tracking-wider">{temporal.clave}</code>
              <button
                onClick={() => navigator.clipboard.writeText(temporal.clave).then(() => avisar('Copiada.', 'ok'))}
                className="rounded-xl p-2 text-tinta-suave hover:bg-black/5"
                title="Copiar"
              >
                <Copy size={18} />
              </button>
            </div>
            <button onClick={() => setTemporal(null)} className="boton-primario mt-5 w-full">
              Listo
            </button>
          </div>
        )}
      </Modal>
      {nodo}
    </Pagina>
  );
}

function NuevaCuenta({
  abierto,
  alCerrar,
  alCrear,
  avisar,
}: {
  abierto: boolean;
  alCerrar: () => void;
  alCrear: (u: UsuarioFila, clave: string) => void;
  avisar: (t: string) => void;
}) {
  const [correo, setCorreo] = useState('');
  const [nombre, setNombre] = useState('');
  const [rol, setRol] = useState<Rol>('editor');
  const [enviando, setEnviando] = useState(false);

  async function crear(e: React.FormEvent) {
    e.preventDefault();
    setEnviando(true);
    try {
      const r = await api<{ usuario: UsuarioFila; claveTemporal: string }>('/api/usuarios', 'POST', { correo, nombre, rol });
      setCorreo('');
      setNombre('');
      alCrear(r.usuario, r.claveTemporal);
    } catch (err) {
      avisar((err as Error).message);
    } finally {
      setEnviando(false);
    }
  }

  return (
    <Modal titulo="Nueva cuenta" subtitulo="Se genera una contraseña temporal que la persona cambiará al entrar." abierto={abierto} alCerrar={alCerrar}>
      <form onSubmit={crear} className="space-y-4">
        <Campo etiqueta="Correo" ayuda={correo && !correo.toLowerCase().endsWith('@unipaz.edu.co') ? 'No es un correo @unipaz.edu.co: quedará marcado como externo.' : undefined}>
          <input type="email" required value={correo} onChange={(e) => setCorreo(e.target.value)} placeholder="nombre@unipaz.edu.co" className="campo" />
        </Campo>
        <Campo etiqueta="Nombre">
          <input value={nombre} onChange={(e) => setNombre(e.target.value)} placeholder="Nombre y apellido" className="campo" />
        </Campo>
        <Campo etiqueta="Rol" ayuda={DESCRIPCION_ROL[rol]}>
          <select value={rol} onChange={(e) => setRol(e.target.value as Rol)} className="campo">
            {ROLES.map((r) => (
              <option key={r} value={r}>
                {ETIQUETA_ROL[r]}
              </option>
            ))}
          </select>
        </Campo>
        <button type="submit" disabled={enviando} className="boton-primario w-full">
          {enviando ? 'Creando…' : 'Crear cuenta'}
        </button>
      </form>
    </Modal>
  );
}
