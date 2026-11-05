'use client';

import { useCallback, useState } from 'react';

interface Estado<T> {
  pasado: T[];
  presente: T;
  futuro: T[];
  /** Los cambios seguidos del mismo grupo (arrastrar, mover un deslizador, escribir) son un solo paso. */
  grupo: string | null;
  en: number;
}

const LIMITE = 100;

/** Deshacer y rehacer (Ctrl+Z / Ctrl+Shift+Z) para el editor del apartado Cliente. */
export function useHistorial<T>(inicial: T) {
  const [h, setH] = useState<Estado<T>>({ pasado: [], presente: inicial, futuro: [], grupo: null, en: 0 });

  const cambiar = useCallback((f: T | ((x: T) => T), grupo?: string) => {
    setH((e) => {
      const nuevo = typeof f === 'function' ? (f as (x: T) => T)(e.presente) : f;
      if (Object.is(nuevo, e.presente)) return e;
      const ahora = Date.now();
      const junto = !!grupo && e.grupo === grupo && ahora - e.en < 1500;
      return { pasado: junto ? e.pasado : [...e.pasado.slice(-(LIMITE - 1)), e.presente], presente: nuevo, futuro: [], grupo: grupo ?? null, en: ahora };
    });
  }, []);

  const deshacer = useCallback(
    () => setH((e) => (e.pasado.length ? { pasado: e.pasado.slice(0, -1), presente: e.pasado[e.pasado.length - 1], futuro: [e.presente, ...e.futuro], grupo: null, en: 0 } : e)),
    [],
  );
  const rehacer = useCallback(
    () => setH((e) => (e.futuro.length ? { pasado: [...e.pasado, e.presente], presente: e.futuro[0], futuro: e.futuro.slice(1), grupo: null, en: 0 } : e)),
    [],
  );
  /** Termina el grupo actual: el próximo cambio será un paso nuevo. */
  const cortar = useCallback(() => setH((e) => (e.grupo ? { ...e, grupo: null } : e)), []);
  const reiniciar = useCallback((x: T) => setH({ pasado: [], presente: x, futuro: [], grupo: null, en: 0 }), []);

  return { valor: h.presente, cambiar, deshacer, rehacer, cortar, reiniciar, puedeDeshacer: h.pasado.length > 0, puedeRehacer: h.futuro.length > 0 };
}
