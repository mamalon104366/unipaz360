"""Arma los maestros SVG del logo de UNIPAZ a partir de los trazos (trazos.json).

- logo-vertical.svg: el logo oficial (símbolo arriba, UNIPAZ y el nombre debajo).
- logo-horizontal.svg: el mismo símbolo a la izquierda y el bloque de texto a la derecha,
  con las proporciones del texto intactas.
- isotipo.svg: solo el símbolo.

Uso: py -I componer_marca.py <trazos.json> <carpeta de salida>
"""
import json
import os
import sys

import numpy as np

datos = json.load(open(sys.argv[1]))
SALIDA = sys.argv[2]
os.makedirs(SALIDA, exist_ok=True)
TINTAS = datos['tintas']
CAPAS = datos['capas']


def puntos(t):
    return np.array(t).reshape(-1, 2)


def caja(trazos):
    p = np.vstack([puntos(t) for t in trazos])
    return p.min(axis=0), p.max(axis=0)


def transformar(trazos, escala, dx, dy):
    return [[round(v * escala + (dx if i % 2 == 0 else dy), 2) for i, v in enumerate(t)] for t in trazos]


def recta(x0, y0, c):
    """¿La cúbica es una recta? (los controles a menos de 0.12 de la cuerda)."""
    p0 = np.array([x0, y0])
    p3 = np.array(c[4:6])
    d = p3 - p0
    n = np.linalg.norm(d)
    if n < 1e-9:
        return True
    for k in (0, 2):
        q = np.array(c[k:k + 2]) - p0
        if abs(d[0] * q[1] - d[1] * q[0]) / n > 0.12:
            return False
        s = (q @ d) / (n * n)
        if s < -0.01 or s > 1.01:
            return False
    return True


def numero(v):
    s = f'{v:.2f}'.rstrip('0').rstrip('.')
    return '0' if s in ('-0', '') else s


def ruta(trazos):
    partes = []
    for t in trazos:
        x, y = t[0], t[1]
        cmd = [f'M{numero(x)} {numero(y)}']
        for k in range(2, len(t), 6):
            c = t[k:k + 6]
            if recta(x, y, c):
                cmd.append(f'L{numero(c[4])} {numero(c[5])}')
            else:
                cmd.append('C' + ' '.join(numero(v) for v in c))
            x, y = c[4], c[5]
        partes.append(''.join(cmd) + 'Z')
    return ''.join(partes)


def svg(nombre, capas, ancho, alto, titulo):
    cuerpo = '\n'.join(
        f'  <path id="{c}" fill="{TINTAS[c]}" fill-rule="evenodd" d="{ruta(t)}"/>' for c, t in capas.items() if t
    )
    texto = (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {numero(ancho)} {numero(alto)}" role="img" aria-label="{titulo}">\n'
        f'  <title>{titulo}</title>\n{cuerpo}\n</svg>\n'
    )
    open(os.path.join(SALIDA, nombre), 'w', encoding='utf8', newline='\n').write(texto)
    print(nombre, f'{ancho:.0f}×{alto:.0f}', len(texto) // 1024, 'KB')


simbolo = {'azul': CAPAS['azul'], 'verde': CAPAS['verde']}
(sx0, sy0), (sx1, sy1) = caja(CAPAS['azul'] + CAPAS['verde'])
(tx0, ty0), (tx1, ty1) = caja(CAPAS['negro'])
print('símbolo', sx0, sy0, sx1, sy1, '· texto', tx0, ty0, tx1, ty1)

# --- vertical (oficial): margen igual a 4 % del ancho
(vx0, vy0), (vx1, vy1) = caja(CAPAS['azul'] + CAPAS['verde'] + CAPAS['negro'])
m = round((vx1 - vx0) * 0.04)
vertical = {c: transformar(t, 1, -vx0 + m, -vy0 + m) for c, t in CAPAS.items()}
svg('logo-vertical.svg', vertical, vx1 - vx0 + 2 * m, vy1 - vy0 + 2 * m, 'UNIPAZ - Instituto Universitario de la Paz')

# --- isotipo: cuadrado, el símbolo centrado
lado = max(sx1 - sx0, sy1 - sy0)
mi = round(lado * 0.04)
iso = {c: transformar(t, 1, -sx0 + mi + (lado - (sx1 - sx0)) / 2, -sy0 + mi + (lado - (sy1 - sy0)) / 2) for c, t in simbolo.items()}
svg('isotipo.svg', iso, lado + 2 * mi, lado + 2 * mi, 'UNIPAZ')

# --- horizontal: el bloque de texto mide 58 % del alto del símbolo y va centrado
alto_s = sy1 - sy0
escala_t = 0.58 * alto_s / (ty1 - ty0)
hueco = 0.13 * alto_s
mh = round(alto_s * 0.06)
dx_t = mh + (sx1 - sx0) + hueco - tx0 * escala_t
dy_t = mh + (alto_s - (ty1 - ty0) * escala_t) / 2 - ty0 * escala_t
horizontal = {
    'azul': transformar(CAPAS['azul'], 1, -sx0 + mh, -sy0 + mh),
    'verde': transformar(CAPAS['verde'], 1, -sx0 + mh, -sy0 + mh),
    'negro': transformar(CAPAS['negro'], escala_t, dx_t, dy_t),
}
ancho_h = mh + (sx1 - sx0) + hueco + (tx1 - tx0) * escala_t + mh
svg('logo-horizontal.svg', horizontal, ancho_h, alto_s + 2 * mh, 'UNIPAZ - Instituto Universitario de la Paz')
