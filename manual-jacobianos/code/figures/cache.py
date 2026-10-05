"""Resuelve y guarda en disco los objetos pesados que usan las figuras."""
import os
import pickle
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CACHE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_cache")
os.makedirs(CACHE, exist_ok=True)


def memo(nombre, fn):
    ruta = os.path.join(CACHE, nombre + ".pkl")
    if os.path.exists(ruta):
        with open(ruta, "rb") as f:
            return pickle.load(f)
    print(f"  [calculando {nombre} ...]", flush=True)
    obj = fn()
    with open(ruta, "wb") as f:
        pickle.dump(obj, f)
    return obj


# ----------------------------------------------------------------- Krusell-Smith
ALPHA, DELTA, N_SS, KY = 0.36, 0.025, 1.0, 10.0
K_SS = KY ** (1 / (1 - ALPHA))
Y_SS = K_SS ** ALPHA
R_SS = ALPHA * (K_SS / N_SS) ** (ALPHA - 1) - DELTA
W_SS = (1 - ALPHA) * (K_SS / N_SS) ** ALPHA


def ks():
    def _build():
        from models.krusell_smith import make_household, household_ss
        het = make_household(n_a=200, amax=20 * K_SS)
        ss = household_ss(het, r=R_SS, w=W_SS, eis=0.5, target_A=K_SS)
        return {"beta": ss["beta"], "ss": ss}
    d = memo("ks_ss", _build)
    from models.krusell_smith import make_household
    het = make_household(n_a=200, amax=20 * K_SS)
    return het, d["ss"]


def ks_jacobians(T=300):
    het, ss = ks()
    return memo(f"ks_J_{T}", lambda: het.jacobians(ss, ["r", "w"], T=T, return_F=True))


def ks_G(T=300):
    het, ss = ks()
    def _build():
        from models.krusell_smith import make_ks_model
        ssf = dict(ss); ssf.update(K=K_SS, Z=1.0, Y=Y_SS, asset_mkt=0.0)
        m = make_ks_model(het, ss, T, K_ss=K_SS, alpha=ALPHA, delta=DELTA, N=N_SS)
        G = m.solve(ssf, T)
        return {k: v for k, v in G.items()}
    return memo(f"ks_G_{T}", _build)


# ------------------------------------------------------------------------ bancos
def bancos():
    def _build():
        from models.banks import make_banks, banks_ss_consistente
        blk = make_banks()
        ss = banks_ss_consistente(blk)
        return {"cal": blk.cal, "ss": {k: v for k, v in ss.items()}}
    d = memo("bancos_ss", _build)
    from models.banks import make_banks
    blk = make_banks(); blk.cal = d["cal"]
    return blk, d["ss"]


def bancos_jacobians(T=200):
    blk, ss = bancos()
    ins = ["rhou", "rb", "Psiue", "phie", "eta"]
    return memo(f"bancos_J_{T}", lambda: blk.jacobians(ss, ins, T=T))


def bancos_G(T=200):
    blk, ss = bancos()
    def _build():
        from models.banks_ge import make_ge
        m, ssf = make_ge(blk, ss, T)
        return {"G": m.solve(ssf, T), "ssf": ssf}
    return memo(f"bancos_G_{T}", _build)
