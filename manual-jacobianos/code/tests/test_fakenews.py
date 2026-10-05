"""Verificacion del algoritmo fake news contra el metodo directo.

Es la prueba que hay que correr SIEMPRE antes de confiar en un bloque nuevo:
el metodo directo es lento pero transparente, el fake news es rapido pero
depende de la proposicion 1. Si ambos coinciden, el bloque esta bien escrito.
"""
import os
import sys
import time

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from models.krusell_smith import household_ss, make_household


def test_fakenews_equals_direct(T=40, n_a=100, tol=1e-6):
    het = make_household(n_a=n_a, amax=150)
    ss = household_ss(het, r=0.01, w=1.0, eis=0.5, target_A=3.0)

    t0 = time.time()
    J_fake = het.jacobians(ss, ["r", "w"], T=T)
    t_fake = time.time() - t0

    t0 = time.time()
    J_dir = het.jacobians_direct(ss, ["r", "w"], T=T)
    t_dir = time.time() - t0

    print(f"  fake news : {t_fake:6.2f} s")
    print(f"  directo   : {t_dir:6.2f} s   (factor {t_dir / t_fake:.0f}x)")

    ok = True
    for key in J_fake:
        err = np.max(np.abs(J_fake[key] - J_dir[key]))
        rel = err / np.max(np.abs(J_dir[key]))
        flag = "OK " if rel < tol else "FALLA"
        print(f"  {flag} J^{{{key[0]},{key[1]}}}: error abs {err:.3e}, relativo {rel:.3e}")
        ok &= rel < tol
    return ok


def test_budget_and_signs():
    """Chequeos economicos que deben cumplirse por construccion."""
    het = make_household(n_a=100, amax=150)
    ss = household_ss(het, r=0.01, w=1.0, eis=0.5, target_A=3.0)
    J = het.jacobians(ss, ["r", "w"], T=30)

    # (a) un aumento del salario HOY eleva el consumo HOY
    assert J[("C", "w")][0, 0] > 0, "J^{C,w}_{0,0} deberia ser positivo"
    # (b) un aumento del salario HOY eleva el ahorro HOY
    assert J[("A", "w")][0, 0] > 0, "J^{A,w}_{0,0} deberia ser positivo"
    # (c) restriccion presupuestaria agregada en la fecha 0 ante un choque a w:
    #     dC_0 + dA_0 = dw_0 * E[e]  (los recursos de hoy no dependen de noticias)
    lhs = J[("C", "w")][0, 0] + J[("A", "w")][0, 0]
    assert abs(lhs - 1.0) < 1e-5, f"la restriccion presupuestaria falla: {lhs:.8f}"
    # (d) una NOTICIA de salario futuro no cambia los recursos de hoy:
    #     dC_0 + dA_0 = 0  para s >= 1
    for s in (1, 5, 10):
        resid = J[("C", "w")][0, s] + J[("A", "w")][0, s]
        assert abs(resid) < 1e-6, f"noticia s={s}: dC_0+dA_0 = {resid:.3e} != 0"
    print("  OK  restriccion presupuestaria agregada y signos")
    return True


if __name__ == "__main__":
    print("Verificacion 1: fake news == metodo directo")
    a = test_fakenews_equals_direct()
    print("Verificacion 2: coherencia economica")
    b = test_budget_and_signs()
    print("\nRESULTADO:", "TODO OK" if (a and b) else "HAY FALLAS")
    sys.exit(0 if (a and b) else 1)
