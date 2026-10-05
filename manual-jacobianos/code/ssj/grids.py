"""Grillas y discretizacion de procesos exogenos."""
import numpy as np


def asset_grid(amin, amax, n, pivot=0.25):
    """Grilla doblemente exponencial: densa cerca de amin, rala cerca de amax.

    El 'pivot' desplaza el origen para poder usar amin negativo o cero.
    Es la grilla estandar en la literatura de mercados incompletos: concentra
    puntos donde la funcion de politica tiene mas curvatura (cerca de la
    restriccion de endeudamiento).
    """
    pivot = np.abs(amin) + pivot
    grid = np.geomspace(amin + pivot, amax + pivot, n) - pivot
    grid[0] = amin  # corrige error de redondeo en el primer punto
    return grid


def rouwenhorst(rho, sigma, n):
    """Discretiza  log z_t = rho log z_{t-1} + eps_t,  sd(eps) = sigma.

    Devuelve (z, Pi, pi) con z normalizado a media 1 bajo la distribucion
    estacionaria pi. El metodo de Rouwenhorst (1995) domina a Tauchen cuando
    rho es alto, que es el caso relevante en calibraciones trimestrales.
    """
    # matriz de transicion por recursion
    p = (1 + rho) / 2
    Pi = np.array([[p, 1 - p], [1 - p, p]])
    for i in range(3, n + 1):
        Pi_old = Pi
        Pi = np.zeros((i, i))
        Pi[:-1, :-1] += p * Pi_old
        Pi[:-1, 1:] += (1 - p) * Pi_old
        Pi[1:, :-1] += (1 - p) * Pi_old
        Pi[1:, 1:] += p * Pi_old
        Pi[1:-1, :] /= 2  # las filas interiores se cuentan dos veces

    # grilla equiespaciada que replica la varianza incondicional
    sigma_y = sigma / np.sqrt(1 - rho ** 2)
    s = np.linspace(-np.sqrt(n - 1) * sigma_y, np.sqrt(n - 1) * sigma_y, n)

    pi = stationary(Pi)
    z = np.exp(s)
    z /= np.vdot(pi, z)  # normalizacion: E[z] = 1
    return z, Pi, pi


def stationary(Pi, tol=1e-14, maxit=100_000):
    """Distribucion estacionaria de una matriz de Markov por iteracion de potencias."""
    pi = np.full(Pi.shape[0], 1 / Pi.shape[0])
    for _ in range(maxit):
        pi_new = pi @ Pi
        if np.max(np.abs(pi_new - pi)) < tol:
            return pi_new / pi_new.sum()
        pi = pi_new
    raise RuntimeError("la distribucion estacionaria no convergio")
