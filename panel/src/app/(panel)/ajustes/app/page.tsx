import { Suspense } from 'react';
import type { Metadata } from 'next';
import { Download } from 'lucide-react';
import { sesionPagina } from '@/lib/pagina';
import { faltaMigracion, listarUsuariosApp, type UsuarioAppFila } from '@/lib/usuariosApp';
import { Cargando, Pagina, SinPermiso } from '@/components/ui/Pagina';

export const metadata: Metadata = { title: 'Usuarios de la app' };
const TITULO = 'Usuarios de la app';

export default function UsuariosApp() {
  return (
    <Suspense fallback={<Cargando titulo={TITULO} />}>
      <Contenido />
    </Suspense>
  );
}

const fecha = (f: string) => new Date(f).toLocaleString('es-CO', { dateStyle: 'medium', timeStyle: 'short', timeZone: 'America/Bogota' });

async function Contenido() {
  const { permitido } = await sesionPagina('superadmin');
  if (!permitido) return <SinPermiso titulo={TITULO} />;
  let usuarios: UsuarioAppFila[];
  try {
    usuarios = await listarUsuariosApp();
  } catch (e) {
    if (!faltaMigracion(e)) throw e;
    return (
      <Pagina titulo={TITULO}>
        <div className="hundido rounded-[26px] p-8">
          <div className="text-[18px] font-medium">Falta activar este apartado</div>
          <p className="mt-2 max-w-2xl text-tinta-suave">
            La base de datos todavía no tiene las tablas donde se anota quién entra a la app. Se crean una sola vez con la migración{' '}
            <span className="font-mono text-tinta">0006_usuarios_app.sql</span> (<span className="font-mono text-tinta">node db/migrar.mjs</span>). Mientras tanto la app
            funciona igual, pero el ingreso con Google le avisa a la persona que aún no está activo.
          </p>
        </div>
      </Pagina>
    );
  }
  const aperturas = usuarios.reduce((n, u) => n + u.aperturas, 0);
  const activos = usuarios.filter((u) => u.esta_semana).length;

  return (
    <Pagina
      titulo={TITULO}
      subtitulo="Quién entró a la app con su cuenta institucional @unipaz.edu.co y cuántas veces la ha abierto."
      acciones={
        usuarios.length > 0 && (
          <a href="/api/usuarios-app" className="boton-suave">
            <Download size={16} /> Exportar CSV
          </a>
        )
      }
    >
      <div className="mb-6 grid gap-3 md:grid-cols-3">
        <Dato etiqueta="Personas" valor={usuarios.length} nota="con cuenta institucional" />
        <Dato etiqueta="Aperturas de la app" valor={aperturas} nota="con la sesión iniciada" />
        <Dato etiqueta="Activas esta semana" valor={activos} nota="la abrieron en los últimos 7 días" />
      </div>

      {usuarios.length === 0 ? (
        <div className="hundido grid min-h-[220px] place-items-center rounded-[26px] p-10 text-center">
          <div>
            <div className="text-[18px] font-medium">Todavía nadie ha entrado con su cuenta</div>
            <p className="mt-2 text-tinta-suave">Cuando alguien toque «Continuar con Google» en la app, aparecerá aquí.</p>
          </div>
        </div>
      ) : (
        <div className="relieve overflow-hidden rounded-[24px]">
          <table className="w-full text-left text-[14px]">
            <thead className="text-[12px] uppercase tracking-[0.08em] text-tinta-tenue">
              <tr className="border-b border-black/[0.06]">
                <th className="px-5 py-3.5 font-medium">Persona</th>
                <th className="px-3 py-3.5 text-right font-medium">Veces que abrió la app</th>
                <th className="hidden px-3 py-3.5 text-right font-medium md:table-cell">Ingresos</th>
                <th className="hidden px-3 py-3.5 text-right font-medium lg:table-cell">Dispositivos</th>
                <th className="hidden px-3 py-3.5 font-medium lg:table-cell">Primera vez</th>
                <th className="px-5 py-3.5 font-medium">Último uso</th>
              </tr>
            </thead>
            <tbody>
              {usuarios.map((u) => (
                <tr key={u.correo} className="border-b border-black/[0.04] last:border-0">
                  <td className="px-5 py-3.5">
                    <div className="font-medium">{u.nombre || u.correo.split('@')[0]}</div>
                    <div className="text-[13px] text-tinta-suave">{u.correo}</div>
                  </td>
                  <td className="px-3 py-3.5 text-right text-[17px] font-medium tabular-nums">{u.aperturas}</td>
                  <td className="hidden px-3 py-3.5 text-right tabular-nums text-tinta-suave md:table-cell">{u.ingresos}</td>
                  <td className="hidden px-3 py-3.5 text-right tabular-nums text-tinta-suave lg:table-cell">{u.dispositivos}</td>
                  <td className="hidden px-3 py-3.5 text-tinta-suave lg:table-cell">{fecha(u.primer_ingreso)}</td>
                  <td className="px-5 py-3.5 text-tinta-suave">{fecha(u.ultimo_uso)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      <p className="mt-5 max-w-3xl text-[13px] leading-relaxed text-tinta-tenue">
        Solo se anota a quien decide entrar con Google: su correo, su nombre y las veces que abre la app con la sesión iniciada. Quien la usa sin cuenta no deja ningún registro. Una
        apertura se cuenta como máximo una vez por minuto en cada dispositivo.
      </p>
    </Pagina>
  );
}

function Dato({ etiqueta, valor, nota }: { etiqueta: string; valor: number; nota: string }) {
  return (
    <div className="hundido rounded-2xl px-5 py-4">
      <div className="text-[12px] font-medium uppercase tracking-[0.1em] text-tinta-tenue">{etiqueta}</div>
      <div className="mt-1 text-[30px] font-light leading-none tabular-nums">{valor.toLocaleString('es-CO')}</div>
      <div className="mt-1.5 text-[13px] text-tinta-suave">{nota}</div>
    </div>
  );
}
