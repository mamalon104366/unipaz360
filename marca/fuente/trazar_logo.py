"""Vectoriza el logo de UNIPAZ (JPG de 1042 px) en trazos SVG por color.

Pasos: cobertura de cada tinta (azul, verde y negro) con mezcla lineal contra el blanco,
un desenfoque leve para quitar el ruido del JPG, marching squares a nivel 0.5 (subpíxel),
esquinas afiladas por intersección de tangentes y curvas de Bézier cúbicas (Schneider).

Uso: py -I trazar_logo.py <logo.jpg> <salida.json>
"""
import json
import math
import sys

import numpy as np
from PIL import Image

ORIGEN, SALIDA = sys.argv[1], sys.argv[2]
DEPURAR = False
img = np.asarray(Image.open(ORIGEN).convert('RGB')).astype(np.float64) / 255.0
ALTO, ANCHO, _ = img.shape
BLANCO = np.array([1.0, 1.0, 1.0])
CORTE_TEXTO = 728  # fila que separa el símbolo (arriba) del texto (abajo)
RECORTE = (195, 110, 850, 935)  # x0, y0, x1, y1: deja fuera la mota de la esquina


def mediana(mask):
    return np.median(img[mask], axis=0)


r, g, b = img[..., 0], img[..., 1], img[..., 2]
lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
filas = np.arange(ALTO)[:, None]
simbolo = filas < CORTE_TEXTO

azul = mediana(simbolo & (b > g + 0.15) & (lum < 0.3))
verde = mediana(simbolo & (g > b + 0.2) & (g > r + 0.3))
negro = mediana(~simbolo & (img.max(axis=2) < 0.25))
print('tintas', [tuple(int(round(v * 255)) for v in c) for c in (azul, verde, negro)])

# --- cobertura con la luminancia (resolución completa en el JPG); el color solo decide la capa
Y = 0.299 * r + 0.587 * g + 0.114 * b


def luma(c):
    return 0.299 * c[0] + 0.587 * c[1] + 0.114 * c[2]


def cobertura(tinta):
    return np.clip((1 - Y) / (1 - luma(tinta)), 0, 1)


es_verde = None  # se define abajo, después de tener el desenfoque
x0, y0, x1, y1 = RECORTE
ventana = np.zeros((ALTO, ANCHO), bool)
ventana[y0:y1, x0:x1] = True


def desenfocar(a, sigma):
    rad = int(math.ceil(sigma * 3))
    k = np.exp(-0.5 * (np.arange(-rad, rad + 1) / sigma) ** 2)
    k /= k.sum()
    p = np.pad(a, rad, mode='edge')
    t = sum(k[i] * p[:, i:i + a.shape[1]] for i in range(2 * rad + 1))
    t = sum(k[i] * t[i:i + a.shape[0], :] for i in range(2 * rad + 1))
    return t


# ------------------------------------------------------------------ marching squares
def contornos(f, t=0.5):
    f = np.pad(f, 1)
    h, w = f.shape
    tl, tr, br, bl = f[:-1, :-1], f[:-1, 1:], f[1:, 1:], f[1:, :-1]
    caso = (tl > t) * 1 + (tr > t) * 2 + (br > t) * 4 + (bl > t) * 8
    ii, jj = np.nonzero((caso > 0) & (caso < 15))

    def punto(clave):
        tipo, i, j = clave
        if tipo == 'h':  # entre (i, j) y (i, j+1)
            a, c = f[i, j], f[i, j + 1]
            return (j + (t - a) / (c - a) - 1, i - 1)
        a, c = f[i, j], f[i + 1, j]  # 'v': entre (i, j) y (i+1, j)
        return (j - 1, i + (t - a) / (c - a) - 1)

    sig = {}
    for i, j in zip(ii.tolist(), jj.tolist()):
        cs = int(caso[i, j])
        T, R, B, L = ('h', i, j), ('v', i, j + 1), ('h', i + 1, j), ('v', i, j)
        # Orientación: lo de adentro (f > t) queda a la derecha al avanzar (y hacia abajo).
        tabla = {
            1: [(L, T)], 2: [(T, R)], 3: [(L, R)], 4: [(R, B)], 6: [(T, B)], 7: [(L, B)],
            8: [(B, L)], 9: [(B, T)], 11: [(B, R)], 12: [(R, L)], 13: [(R, T)], 14: [(T, L)],
        }
        if cs in (5, 10):
            centro = (tl[i, j] + tr[i, j] + br[i, j] + bl[i, j]) / 4
            if cs == 5:
                segs = [(L, B), (R, T)] if centro > t else [(L, T), (R, B)]
            else:
                segs = [(T, L), (B, R)] if centro > t else [(T, R), (B, L)]
        else:
            segs = tabla[cs]
        for a, c in segs:
            sig[a] = c
    lazos = []
    vistos = set()
    for inicio in list(sig):
        if inicio in vistos:
            continue
        lazo, k = [], inicio
        while k not in vistos:
            vistos.add(k)
            lazo.append(punto(k))
            k = sig[k]
        if len(lazo) > 2:
            lazos.append(np.array(lazo))
    return lazos


def area(p):
    x, y = p[:, 0], p[:, 1]
    return 0.5 * np.sum(x * np.roll(y, -1) - np.roll(x, -1) * y)


# ------------------------------------------------------------------ Bézier (Schneider)
def bezier(c, u):
    u = u[:, None]
    m = 1 - u
    return m ** 3 * c[0] + 3 * m * m * u * c[1] + 3 * m * u * u * c[2] + u ** 3 * c[3]


def bezier_d1(c, u):
    u = u[:, None]
    m = 1 - u
    return 3 * (m * m * (c[1] - c[0]) + 2 * m * u * (c[2] - c[1]) + u * u * (c[3] - c[2]))


def bezier_d2(c, u):
    u = u[:, None]
    return 6 * ((1 - u) * (c[2] - 2 * c[1] + c[0]) + u * (c[3] - 2 * c[2] + c[1]))


def unitario(v):
    n = np.linalg.norm(v)
    return v / n if n > 1e-12 else v


def generar(p, u, t1, t2):
    a1 = np.outer(3 * (1 - u) ** 2 * u, t1)
    a2 = np.outer(3 * (1 - u) * u ** 2, t2)
    C = np.array([[np.sum(a1 * a1), np.sum(a1 * a2)], [np.sum(a1 * a2), np.sum(a2 * a2)]])
    base = bezier(np.array([p[0], p[0], p[-1], p[-1]]), u)
    tmp = p - base
    X = np.array([np.sum(a1 * tmp), np.sum(a2 * tmp)])
    det = C[0, 0] * C[1, 1] - C[0, 1] * C[1, 0]
    dist = np.linalg.norm(p[-1] - p[0])
    if abs(det) > 1e-12:
        al = (X[0] * C[1, 1] - X[1] * C[0, 1]) / det
        ar = (C[0, 0] * X[1] - C[1, 0] * X[0]) / det
    else:
        al = ar = 0
    eps = 1e-6 * dist
    if al < eps or ar < eps or al > dist * 3 or ar > dist * 3:
        al = ar = dist / 3
    return np.array([p[0], p[0] + t1 * al, p[-1] + t2 * ar, p[-1]])


def reparametrizar(c, p, u):
    d = bezier(c, u) - p
    d1 = bezier_d1(c, u)
    d2 = bezier_d2(c, u)
    num = np.sum(d * d1, axis=1)
    den = np.sum(d1 * d1 + d * d2, axis=1)
    ok = np.abs(den) > 1e-12
    nu = u.copy()
    nu[ok] = u[ok] - num[ok] / den[ok]
    return np.clip(nu, 0, 1)


def cuerda(p):
    d = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(p, axis=0), axis=1))])
    return d / d[-1] if d[-1] > 0 else d


def ajustar(p, t1, t2, tol):
    if len(p) == 2:
        dist = np.linalg.norm(p[1] - p[0]) / 3
        return [np.array([p[0], p[0] + t1 * dist, p[1] + t2 * dist, p[1]])]
    u = cuerda(p)
    c = generar(p, u, t1, t2)
    err = np.sum((bezier(c, u) - p) ** 2, axis=1)
    k = int(np.argmax(err))
    if err[k] < tol * tol:
        return [c]
    if err[k] < (tol * 4) ** 2:
        for _ in range(20):
            u = reparametrizar(c, p, u)
            c = generar(p, u, t1, t2)
            err = np.sum((bezier(c, u) - p) ** 2, axis=1)
            k = int(np.argmax(err))
            if err[k] < tol * tol:
                return [c]
    k = min(max(k, 1), len(p) - 2)
    w = min(6, k, len(p) - 1 - k)
    tc = unitario(p[k - w] - p[k + w])
    return ajustar(p[:k + 1], t1, tc, tol) + ajustar(p[k:], -tc, t2, tol)


# ------------------------------------------------------------------ contorno → curvas
def remuestrear(p, paso):
    q = np.vstack([p, p[:1]])
    d = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(q, axis=0), axis=1))])
    n = max(int(d[-1] / paso), 8)
    s = np.linspace(0, d[-1], n, endpoint=False)
    return np.stack([np.interp(s, d, q[:, 0]), np.interp(s, d, q[:, 1])], axis=1)


def esquinas(p, ventana_px, paso, umbral_grados):
    k = max(2, int(round(ventana_px / paso)))
    a = np.roll(p, k, axis=0)
    c = np.roll(p, -k, axis=0)
    v1 = p - a
    v2 = c - p
    ang = np.degrees(np.arccos(np.clip(np.sum(v1 * v2, 1) / (np.linalg.norm(v1, axis=1) * np.linalg.norm(v2, axis=1) + 1e-12), -1, 1)))
    idx = []
    n = len(p)
    for i in range(n):
        if ang[i] < umbral_grados:
            continue
        vecinos = [ang[(i + d) % n] for d in range(-k, k + 1)]
        if ang[i] >= max(vecinos) and not any(abs(i - j) <= k or n - abs(i - j) <= k for j in idx):
            idx.append(i)
    return sorted(idx)


def recta(puntos):
    """Dirección principal de un puñado de puntos."""
    c = puntos - puntos.mean(axis=0)
    _, _, vt = np.linalg.svd(c, full_matrices=False)
    return puntos.mean(axis=0), vt[0]


def interseccion(p0, d0, p1, d1):
    m = np.array([d0, -d1]).T
    if abs(np.linalg.det(m)) < 1e-6:
        return None
    s, _ = np.linalg.solve(m, p1 - p0)
    return p0 + s * d0


def suavizar(p, fijos, veces=2, peso=0.3):
    q = p.copy()
    libre = np.ones(len(p), bool)
    libre[fijos] = False
    for _ in range(veces):
        prom = (np.roll(q, 1, axis=0) + np.roll(q, -1, axis=0)) / 2
        q[libre] = q[libre] + peso * (prom[libre] - q[libre])
    return q


def trazar(lazo, tol, limite=4.5, umbral=42, paso=0.5):
    p = remuestrear(lazo, paso)
    n = len(p)
    ix = esquinas(p, 2.6, paso, umbral)
    p = suavizar(p, ix)
    tramo_px = int(round(3.0 / paso))
    if not ix:
        # Contorno suave (ojo, la «o»…): costura con tangente continua.
        t = unitario(p[6] - p[-6])
        q = np.vstack([p, p[:1]])
        return ajustar(q, t, -t, tol)
    # Afilar cada esquina con la intersección de las rectas que llegan y salen.
    vert = {}
    for i in ix:
        antes = p[[(i - d) % n for d in range(2, tramo_px + 2)]]
        despues = p[[(i + d) % n for d in range(2, tramo_px + 2)]]
        c0, d0 = recta(antes)
        c1, d1 = recta(despues)
        x = interseccion(c0, d0, c1, d1)
        vert[i] = x if x is not None and np.linalg.norm(x - p[i]) < limite else p[i]
    curvas = []
    for a, b in zip(ix, ix[1:] + [ix[0] + n]):
        seg = p[[k % n for k in range(a, b + 1)]].copy()
        seg[0] = vert[a]
        seg[-1] = vert[b % n]
        cuerda_v = seg[-1] - seg[0]
        largo = np.linalg.norm(cuerda_v)
        if largo > 8:
            rel = seg - seg[0]
            dist = np.abs(cuerda_v[0] * rel[:, 1] - cuerda_v[1] * rel[:, 0]) / largo
            if DEPURAR:
                print(f'   tramo {largo:7.1f} px  desvío {dist.max():5.2f}  de {seg[0].round(1)} a {seg[-1].round(1)}')
            if dist.max() < (1.3 if largo > 100 else 0.5):
                curvas.append(np.array([seg[0], seg[0] + cuerda_v / 3, seg[0] + 2 * cuerda_v / 3, seg[-1]]))
                continue
        m = min(tramo_px, len(seg) - 1)
        t1 = unitario(seg[min(m, len(seg) - 1)] - seg[0])
        t2 = unitario(seg[max(len(seg) - 1 - m, 0)] - seg[-1])
        curvas += ajustar(seg, t1, t2, tol)
    return curvas


def a_trazo(curvas):
    """Lista de [x0, y0, (x1, y1, x2, y2, x, y)…] con tramos rectos marcados."""
    sub = [round(float(curvas[0][0][0]), 2), round(float(curvas[0][0][1]), 2)]
    for c in curvas:
        sub += [round(float(v), 2) for v in c[1:].ravel()]
    return sub


# El color solo decide si un borde es del azul o del verde (desenfocado: la croma del JPG va a media resolución).
es_verde = desenfocar(g - b, 2.0) > 0
a_azul = cobertura(azul) * simbolo * ~es_verde
a_verde = cobertura(verde) * simbolo * es_verde
a_negro = cobertura(negro) * (~simbolo)

resultado = {'tintas': {}, 'capas': {}}
for nombre, a, tinta in (('azul', a_azul, azul), ('verde', a_verde, verde), ('negro', a_negro, negro)):
    DEPURAR = False
    a = desenfocar(a * ventana, 0.6)
    lazos = [l for l in contornos(a) if abs(area(l)) > 3]
    trazos = [a_trazo(trazar(l, 0.3, 1.0, 50) if nombre == 'negro' else trazar(l, 0.35)) for l in lazos]
    resultado['capas'][nombre] = trazos
    resultado['tintas'][nombre] = '#%02x%02x%02x' % tuple(int(round(v * 255)) for v in tinta)
    print(nombre, len(lazos), 'contornos', sum((len(t) - 2) // 6 for t in trazos), 'curvas')

json.dump(resultado, open(SALIDA, 'w'), separators=(',', ':'))
print('ok', SALIDA)
