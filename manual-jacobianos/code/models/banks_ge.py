"""Equilibrio general del modelo de bancos heterogeneos, sobre un DAG.

Estructura del grafo (se lee de izquierda a derecha):

                            +-> credito ------> loan_mkt   (objetivo 1)
    choques: rhou, eta ---> |
    incognitas: rb,        BANCOS (bloque heterogeneo)
                Psiue, ---> |-> interbancario -> ib_mkt     (objetivo 2)
                phie        +-> respaldo ------> bs_mkt     (objetivo 3)

Las tres incognitas existen porque el modelo tiene SIMULTANEIDAD: la holgura
del interbancario Psi^u y la capacidad de respaldo phi afectan la decision de
liquidez de cada banco, y esa decision determina a su vez la oferta, la demanda
y el faltante residual que fijan Psi^u y phi. En el espacio de secuencias esos
ciclos no se iteran: se rompen declarando la variable como incognita y su
condicion de consistencia como objetivo, y el sistema se resuelve de una vez.
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from ssj import HetBlockWrapper, Model, SimpleBlock


def make_ge(blk, ss, T, elas_credito=2.0, shocked=("rb", "Psiue", "phie", "rhou", "eta")):
    """Construye el modelo de equilibrio general y devuelve (modelo, ss_completo)."""
    vF = ss["vF"]
    B_ss, rb_ss = ss["B"], blk.cal["rb"]

    def credito(B, rb):
        # demanda de credito de isoelasticidad `elas_credito`
        return {"loan_mkt": B - B_ss * (rb / rb_ss) ** (-elas_credito)}

    def interbancario(Psiue, Pue, Que):
        # eq. (15) del PT. En el estado estacionario P/Q = 0.36 < 1: la rama
        # activa es la de racionamiento y el minimo no esta en su quiebre.
        return {"ib_mkt": Psiue - np.minimum(1.0, Pue / Que)}

    def respaldo(phie, rhou, DEPu, RESIDue):
        # eqs. (17)-(18) del PT: F^u = v_F rho^u D^u, phi = min(1, F^u/Delta^u).
        Fu = vF * rhou * DEPu
        return {"bs_mkt": phie - np.minimum(1.0, Fu / RESIDue)}

    blocks = [
        HetBlockWrapper(blk, ss, T, shocked_inputs=list(shocked), name="bancos"),
        SimpleBlock(credito, ["B", "rb"], ["loan_mkt"], name="credito"),
        SimpleBlock(interbancario, ["Psiue", "Pue", "Que"], ["ib_mkt"], name="interbancario"),
        SimpleBlock(respaldo, ["phie", "rhou", "DEPu", "RESIDue"], ["bs_mkt"], name="respaldo"),
    ]
    modelo = Model(blocks,
                   unknowns=["rb", "Psiue", "phie"],
                   targets=["loan_mkt", "ib_mkt", "bs_mkt"],
                   exogenous=["rhou", "eta"])

    ss_full = {k: v for k, v in ss.items() if np.isscalar(v) or isinstance(v, float)}
    ss_full.update({k: blk.cal[k] for k in blk.inputs})
    ss_full.update(loan_mkt=0.0, ib_mkt=0.0, bs_mkt=0.0)
    return modelo, ss_full
