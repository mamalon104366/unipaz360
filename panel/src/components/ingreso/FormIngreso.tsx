'use client';

import { CircleAlert, ShieldCheck } from 'lucide-react';

const MENSAJES: Record<string, string> = {
  'no-autorizado': 'Tu correo no está autorizado para la plataforma. Pide a un superadministrador que lo agregue.',
  dominio: 'Solo se admiten cuentas institucionales @unipaz.edu.co.',
  cancelado: 'Cancelaste el ingreso con Google.',
  estado: 'El intento de ingreso caducó. Vuelve a intentarlo.',
  configuracion: 'El ingreso con Google no está configurado en este servidor.',
  google: 'Google no pudo completar el ingreso. Vuelve a intentarlo.',
};

/** Ingreso únicamente con Google, cuenta institucional. */
export function FormIngreso({ volver, error }: { volver: string; error: string | null }) {
  return (
    <div className="flex h-full flex-col justify-center">
      <div className="mb-6 flex items-center gap-2 self-start rounded-full bg-acento-suave px-3 py-1 text-[12px] font-medium text-acento">
        <ShieldCheck size={14} /> Acceso solo para cuentas autorizadas
      </div>
      <h2 className="text-[34px] font-normal leading-tight tracking-tight">Iniciar sesión</h2>
      <p className="mt-1.5 text-[15px] text-tinta-tenue">Usa tu cuenta de Google institucional @unipaz.edu.co.</p>

      {error && (
        <div role="alert" className="mt-6 flex items-start gap-2 rounded-xl bg-peligro/10 px-3 py-2.5 text-[13px] text-peligro">
          <CircleAlert size={16} className="mt-px shrink-0" /> {MENSAJES[error] ?? MENSAJES.google}
        </div>
      )}

      <a
        href={`/api/sesion/google?volver=${encodeURIComponent(volver)}`}
        className="mt-8 flex h-13 items-center justify-center gap-3 rounded-2xl border border-black/10 bg-white py-3.5 text-[15px] font-medium text-tinta shadow-[0_10px_24px_-14px_rgb(0_0_0/0.5)] transition hover:bg-white/80"
      >
        {/* La «G» oficial de Google (signin-assets.zip, tema claro). */}
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/marca/google-g.png" alt="" width={20} height={20} />
        Continuar con Google
      </a>
      <p className="mt-5 text-center text-[13px] text-tinta-tenue">El panel no guarda contraseñas. Solo entran los correos autorizados por un superadministrador.</p>
    </div>
  );
}
