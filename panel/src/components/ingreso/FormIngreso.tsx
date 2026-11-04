'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { ArrowRight, CircleAlert, Eye, EyeOff, ShieldCheck } from 'lucide-react';

type Modo = 'ingresar' | 'instalar' | 'sin-cuentas';

export function FormIngreso({ modo, volver, errorBase }: { modo: Modo; volver: string; errorBase: boolean }) {
  const router = useRouter();
  const [nombre, setNombre] = useState('');
  const [correo, setCorreo] = useState('');
  const [clave, setClave] = useState('');
  const [ver, setVer] = useState(false);
  const [error, setError] = useState<string | null>(errorBase ? 'No hay conexión con la base de datos.' : null);
  const [enviando, setEnviando] = useState(false);

  async function enviar(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setEnviando(true);
    try {
      const r = await fetch(modo === 'instalar' ? '/api/sesion/instalar' : '/api/sesion', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ nombre, correo, clave }),
      });
      const datos = await r.json().catch(() => ({}));
      if (!r.ok) throw new Error(datos.error ?? 'No se pudo iniciar sesión.');
      router.replace(datos.debe_cambiar_clave ? '/cuenta?cambiar=1' : volver);
      router.refresh();
    } catch (err) {
      setError((err as Error).message);
      setEnviando(false);
    }
  }

  if (modo === 'sin-cuentas') {
    return (
      <div className="flex h-full flex-col justify-center">
        <h2 className="text-[30px] font-normal tracking-tight">Aún no hay cuentas</h2>
        <p className="mt-3 text-[15px] leading-relaxed text-tinta-suave">
          Por seguridad, la primera cuenta (superadministrador) se crea desde el panel local con{' '}
          <code className="rounded bg-black/5 px-1.5">npm run dev</code>. Después podrás entrar aquí con esa cuenta.
        </p>
      </div>
    );
  }

  const instalar = modo === 'instalar';
  return (
    <form onSubmit={enviar} className="flex h-full flex-col justify-center">
      {instalar && (
        <div className="mb-6 flex items-center gap-2 self-start rounded-full bg-acento-suave px-3 py-1 text-[12px] font-medium text-acento">
          <ShieldCheck size={14} /> Primera vez: crea la cuenta de superadministrador
        </div>
      )}
      <h2 className="text-[34px] font-normal leading-tight tracking-tight">{instalar ? 'Bienvenido' : 'Iniciar sesión'}</h2>
      <p className="mt-1.5 text-[15px] text-tinta-tenue">
        {instalar ? 'Esta cuenta podrá crear las demás y asignar roles.' : 'Usa tu correo institucional @unipaz.edu.co.'}
      </p>

      <div className="mt-8 space-y-4">
        {instalar && (
          <Campo etiqueta="Nombre">
            <input value={nombre} onChange={(e) => setNombre(e.target.value)} autoComplete="name" placeholder="Nombre y apellido" className="campo" />
          </Campo>
        )}
        <Campo etiqueta="Correo">
          <input
            type="email"
            required
            value={correo}
            onChange={(e) => setCorreo(e.target.value)}
            autoComplete="username"
            placeholder="nombre@unipaz.edu.co"
            className="campo"
          />
        </Campo>
        <Campo etiqueta="Contraseña">
          <div className="relative">
            <input
              type={ver ? 'text' : 'password'}
              required
              minLength={instalar ? 10 : undefined}
              value={clave}
              onChange={(e) => setClave(e.target.value)}
              autoComplete={instalar ? 'new-password' : 'current-password'}
              placeholder={instalar ? 'Mínimo 10 caracteres' : '••••••••••'}
              className="campo pr-11"
            />
            <button
              type="button"
              onClick={() => setVer((v) => !v)}
              className="absolute right-2 top-1/2 -translate-y-1/2 rounded-lg p-1.5 text-tinta-tenue hover:bg-black/5"
              aria-label={ver ? 'Ocultar contraseña' : 'Mostrar contraseña'}
            >
              {ver ? <EyeOff size={17} /> : <Eye size={17} />}
            </button>
          </div>
        </Campo>
      </div>

      {error && (
        <div role="alert" className="mt-4 flex items-start gap-2 rounded-xl bg-peligro/10 px-3 py-2.5 text-[13px] text-peligro">
          <CircleAlert size={16} className="mt-px shrink-0" /> {error}
        </div>
      )}

      <button
        type="submit"
        disabled={enviando}
        className="mt-7 flex h-12 items-center justify-center gap-2 rounded-2xl bg-riel text-[15px] font-medium text-white shadow-[0_12px_24px_-12px_rgb(0_0_0/0.7)] transition hover:bg-black disabled:opacity-60"
      >
        {enviando ? 'Un momento…' : instalar ? 'Crear cuenta y entrar' : 'Entrar'} <ArrowRight size={17} />
      </button>
      {!instalar && (
        <p className="mt-5 text-center text-[13px] text-tinta-tenue">¿Olvidaste la contraseña? Pide a un superadministrador que la restablezca.</p>
      )}
    </form>
  );
}

function Campo({ etiqueta, children }: { etiqueta: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-[13px] font-medium text-tinta-suave">{etiqueta}</span>
      {children}
    </label>
  );
}
