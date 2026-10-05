"""Interpolacion lineal y loteria de Young (2010).

Dos operaciones elementales sostienen todo el metodo:

  * `interpolate_y`  : evalua una funcion definida sobre una grilla en puntos
                       arbitrarios. Es el corazon del metodo del punto endogeno.
  * `lottery`        : convierte una politica continua a' en pesos sobre dos
                       puntos adyacentes de la grilla. Es lo que vuelve a la
                       matriz de transicion Lambda una matriz honesta de Markov
                       y preserva exactamente la masa y la media de la politica.
"""
import numpy as np


def interpolate_y(x, xq, y):
    """Interpola y(x) en los puntos xq. `x` debe ser estrictamente creciente.

    Extrapola linealmente fuera del rango usando el segmento del extremo.
    Equivale a np.interp con extrapolacion, pero vectorizado sobre la ultima
    dimension cuando x, y son 2D (una fila por estado exogeno).
    """
    x, xq, y = np.atleast_2d(x), np.atleast_2d(xq), np.atleast_2d(y)
    out = np.empty(xq.shape)
    for r in range(x.shape[0]):
        xr = x[r] if x.shape[0] > 1 else x[0]
        yr = y[r] if y.shape[0] > 1 else y[0]
        i = np.searchsorted(xr, xq[r], side="left")
        i = np.clip(i, 1, len(xr) - 1)
        w = (xq[r] - xr[i - 1]) / (xr[i] - xr[i - 1])
        out[r] = yr[i - 1] + w * (yr[i] - yr[i - 1])
    return out.squeeze() if out.shape[0] == 1 else out


def lottery(pol, grid):
    """Loteria de Young: pol -> (indice i, peso p sobre grid[i]).

    Cada banco/hogar cuya politica cae en [grid[i], grid[i+1]] se reparte entre
    ambos puntos con pesos que preservan exactamente la media de la politica:
        p * grid[i] + (1-p) * grid[i+1] = pol
    Sin esto, redondear al punto mas cercano introduce un sesgo de agregacion
    de primer orden y contamina todos los jacobianos.
    """
    i = np.searchsorted(grid, pol, side="right") - 1
    i = np.clip(i, 0, len(grid) - 2)
    p = (grid[i + 1] - pol) / (grid[i + 1] - grid[i])
    p = np.clip(p, 0.0, 1.0)
    return i, p


def forward_policy(D, i, p):
    """Un paso hacia adelante de la distribucion por el estado ENDOGENO.

    D[e, a_-] -> Dtilde[e, a].  No mezcla todavia el estado exogeno.
    """
    ne, na = D.shape
    out = np.zeros_like(D)
    for e in range(ne):
        out[e] = (np.bincount(i[e], weights=D[e] * p[e], minlength=na)
                  + np.bincount(i[e] + 1, weights=D[e] * (1 - p[e]), minlength=na))
    return out


def forward_step(D, Pi, i, p):
    """D_{t+1} = Lambda' D_t : primero la loteria endogena, luego Markov exogeno."""
    return Pi.T @ forward_policy(D, i, p)


def expectation_step(E, Pi, i, p):
    """E_t = Lambda E_{t-1} : primero Markov exogeno, luego la loteria (transpuesta).

    Notese el orden INVERSO al de forward_step. Es la transpuesta del mismo
    operador: si  Lambda' = Pi' L'  entonces  Lambda = L Pi.
    Confundir este orden es el error silencioso mas comun al implementar el
    algoritmo: los jacobianos salen casi correctos y el diagnostico cuesta horas.
    """
    Etilde = Pi @ E
    ne, na = E.shape
    out = np.empty_like(E)
    for e in range(ne):
        out[e] = p[e] * Etilde[e, i[e]] + (1 - p[e]) * Etilde[e, i[e] + 1]
    return out
