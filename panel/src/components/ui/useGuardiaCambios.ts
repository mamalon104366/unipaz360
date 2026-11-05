'use client';

import { useEffect } from 'react';

/**
 * Avisa antes de perder cambios sin guardar: al cerrar o recargar la pestaña y al hacer
 * clic en un enlace interno del panel (riel, barra lateral, botones «Volver»).
 */
export function useGuardiaCambios(activo: boolean, mensaje = 'Tienes cambios sin guardar. ¿Salir de todos modos?') {
  useEffect(() => {
    if (!activo) return;
    const antesDeSalir = (e: BeforeUnloadEvent) => {
      e.preventDefault();
      e.returnValue = '';
    };
    const clic = (e: MouseEvent) => {
      if (e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
      const a = (e.target as HTMLElement | null)?.closest?.('a[href]') as HTMLAnchorElement | null;
      if (!a || (a.target && a.target !== '_self') || a.hasAttribute('download')) return;
      const destino = new URL(a.href, location.href);
      if (destino.origin !== location.origin) return;
      // Misma ruta con otros parámetros (p. ej. otra capa del Cliente): el editor sigue montado y no se pierde nada.
      if (destino.pathname === location.pathname) return;
      if (!confirm(mensaje)) {
        e.preventDefault();
        e.stopPropagation();
      }
    };
    window.addEventListener('beforeunload', antesDeSalir);
    document.addEventListener('click', clic, true);
    return () => {
      window.removeEventListener('beforeunload', antesDeSalir);
      document.removeEventListener('click', clic, true);
    };
  }, [activo, mensaje]);
}
