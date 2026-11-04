import type { Metadata } from 'next';
import { Geist, Geist_Mono } from 'next/font/google';
import { connection } from 'next/server';
import { Marco } from '@/components/marco/Marco';
import { leerResumen } from '@/lib/grafo';
import type { Resumen } from '@/lib/tipos';
import './globals.css';

const geistSans = Geist({ variable: '--font-geist-sans', subsets: ['latin'] });
const geistMono = Geist_Mono({ variable: '--font-geist-mono', subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'UniPaz360 · Plataforma',
  description: 'Plataforma de gestión del recorrido virtual y el grafo del campus de UNIPAZ.',
};

/** Contadores de la barra lateral: siempre frescos, se leen en cada petición. */
async function cargarResumen(): Promise<Resumen | null> {
  await connection();
  try {
    return await leerResumen();
  } catch (e) {
    console.error('[panel] no se pudo leer el resumen:', e);
    return null;
  }
}

export default function RootLayout({ children }: LayoutProps<'/'>) {
  return (
    <html lang="es" className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}>
      <body className="h-full overflow-hidden">
        <Marco resumen={cargarResumen()}>{children}</Marco>
      </body>
    </html>
  );
}
