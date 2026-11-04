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
        <svg width="20" height="20" viewBox="0 0 48 48" aria-hidden>
          <path fill="#FFC107" d="M43.6 20.5H42V20H24v8h11.3C33.7 32.7 29.3 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20 20-8.9 20-20c0-1.3-.1-2.4-.4-3.5z" />
          <path fill="#FF3D00" d="m6.3 14.7 6.6 4.8C14.7 15.1 19 12 24 12c3.1 0 5.8 1.2 7.9 3.1l5.7-5.7C34 6.1 29.3 4 24 4 16.3 4 9.7 8.3 6.3 14.7z" />
          <path fill="#4CAF50" d="M24 44c5.2 0 9.9-2 13.4-5.2l-6.2-5.2C29.2 35.1 26.7 36 24 36c-5.3 0-9.7-3.3-11.3-8l-6.5 5C9.5 39.6 16.2 44 24 44z" />
          <path fill="#1976D2" d="M43.6 20.5H42V20H24v8h11.3c-.8 2.2-2.2 4.2-4.1 5.6l6.2 5.2C37 39.2 44 34 44 24c0-1.3-.1-2.4-.4-3.5z" />
        </svg>
        Continuar con Google
      </a>
      <p className="mt-5 text-center text-[13px] text-tinta-tenue">El panel no guarda contraseñas. Solo entran los correos autorizados por un superadministrador.</p>
    </div>
  );
}
