"""Modelo de Krusell y Smith (1998) resuelto con jacobianos secuenciales.

Es el caso de referencia del manual: hogares con mercados incompletos, una
restriccion de no endeudamiento y un sector productivo neoclasico. Sirve para
(i) verificar el algoritmo fake news contra el metodo directo y
(ii) mostrar como se compone el equilibrio general sobre un DAG.
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from ssj import HetBlock, HetBlockWrapper, Model, SimpleBlock, asset_grid, rouwenhorst


# ----------------------------------------------------------------------
# Bloque de hogares: metodo del punto endogeno (Carroll 2006)
# ----------------------------------------------------------------------
def household_backward(Va_next, Pi, a_grid, e_grid, r, w, beta, eis):
    """Un paso hacia atras de la ecuacion de Euler.

    Va = dV/da_- es la variable de continuacion. El metodo del punto endogeno
    evita resolver una ecuacion no lineal en cada punto de la grilla: se parte
    del consumo implicado por la ecuacion de Euler y se recupera el nivel de
    activos iniciales que lo racionaliza.
    """
    Wa = beta * (Pi @ Va_next)                       # valor marginal esperado
    c_endog = Wa ** (-eis)                           # Euler: c = (Wa)^{-eis}
    coh_endog = c_endog + a_grid                     # recursos que lo sostienen
    coh = (1 + r) * a_grid[np.newaxis, :] + w * e_grid[:, np.newaxis]

    a = np.empty_like(coh)
    for e in range(Pi.shape[0]):
        a[e] = np.interp(coh[e], coh_endog[e], a_grid)
    a = np.maximum(a, a_grid[0])                     # restriccion de no endeudamiento
    c = coh - a
    Va = (1 + r) * c ** (-1 / eis)
    return Va, a, {"A": a, "C": c}


def make_household(rho_e=0.966, sigma_e=0.5, n_e=7, amax=200.0, n_a=200, amin=0.0):
    """Construye el bloque heterogeneo con su proceso de ingreso y su grilla."""
    e_grid, Pi, pi = rouwenhorst(rho_e, sigma_e * np.sqrt(1 - rho_e ** 2), n_e)
    a_grid = asset_grid(amin, amax, n_a)
    het = HetBlock(household_backward, Pi, a_grid,
                   inputs=["r", "w", "beta", "eis"], outputs=["A", "C"],
                   extra={"e_grid": e_grid})
    het.e_grid, het.pi = e_grid, pi
    return het


def household_ss(het, r=0.01, w=1.0, beta=0.981, eis=0.5, target_A=None):
    """Estado estacionario. Si se da `target_A`, calibra beta por biseccion para
    que la demanda agregada de activos iguale ese nivel de capital."""
    Va0 = np.ones((het.ne, 1)) * (0.1 + 0.1 * het.grid[np.newaxis, :]) ** (-1 / eis)

    def solve(b):
        return het.steady_state(Va0, r=r, w=w, beta=b, eis=eis)

    if target_A is None:
        return solve(beta)

    lo, hi = 0.95, 0.9995
    for _ in range(80):
        mid = 0.5 * (lo + hi)
        ss = solve(mid)
        if ss["A"] > target_A:
            hi = mid
        else:
            lo = mid
        if abs(ss["A"] - target_A) < 1e-10:
            break
    return solve(0.5 * (lo + hi))


# ----------------------------------------------------------------------
# Equilibrio general
# ----------------------------------------------------------------------
def make_ks_model(het, ss_het, T, K_ss, alpha=0.11, delta=0.025, N=1.0):
    """DAG: empresas -> hogares -> vaciado del mercado de capitales.

    El capital de hoy se alquila con el stock acumulado AYER: por eso el rezago
    explicito. Un bloque heterogeneo no admite rezagos del insumo (vease el
    capitulo de extensiones); aqui el rezago vive en el bloque simple, que si
    los admite sin problema.
    """

    def firms(K, Z):
        Klag = np.concatenate(([K_ss], K[:-1]))
        r = alpha * Z * (Klag / N) ** (alpha - 1) - delta
        w = (1 - alpha) * Z * (Klag / N) ** alpha
        Y = Z * Klag ** alpha * N ** (1 - alpha)
        return {"r": r, "w": w, "Y": Y}

    def mkt_clearing(A, K):
        return {"asset_mkt": A - K}

    blocks = [
        SimpleBlock(firms, ["K", "Z"], ["r", "w", "Y"], name="empresas"),
        HetBlockWrapper(het, ss_het, T, shocked_inputs=["r", "w"], name="hogares"),
        SimpleBlock(mkt_clearing, ["A", "K"], ["asset_mkt"], name="vaciado"),
    ]
    return Model(blocks, unknowns=["K"], targets=["asset_mkt"], exogenous=["Z"])
