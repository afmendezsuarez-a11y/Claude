"""Extension dinamica del modelo de bancos heterogeneos, encaje y dolarizacion.

Prototipo que traslada al espacio de secuencias el marco estatico por capas de
Gomez Puican y Mendez Suarez (2026): banco representativo -> heterogeneidad en
la exposicion al choque de liquidez -> acceso desigual al interbancario ->
soles y dolares con respaldo publico asimetrico.

NO es el modelo final de la tesis. Es el andamio minimo que convierte ese marco
en un bloque de agentes heterogeneos en el sentido de (10)-(12) del manual, para
poder calcular jacobianos secuenciales y leer la INCIDENCIA dinamica de un
cambio de encaje.

Correspondencia con el Plan de Trabajo
-------------------------------------
    PT (estatico)                        Aqui (dinamico)
    ------------------------------------ -----------------------------------
    tipos k in {L,S}, masas mu_k         estado exogeno e, Markov Pi
    m = rho + u                          igual, pero u_t se reelige cada periodo
    eps_k ~ F_k                          eps ~ U[-a_e, a_e]
    omega^c = beta_k A^c + eps^c (11)    estado agregado A in {normal, escaso}
    tau_k = 1 - exp(-lambda_k)           tau(e,n) = tau_e * n/(n+nbar)
    psi_k = tau_k min(1, P/Q) (7),(15)   igual, por estado agregado
    Delta = sum mu_k (1-psi_k) D_k (8)   RESIDu, agregado sobre la distribucion
    F^u = v_F rho^u D^u + R_D (17)       igual
    phi = min(1, F^u/Delta^u) (18)       igual
    C^u_k = E[phi (1-psi_k) D^u_k] (19)  COVu por tipo: la variable de incidencia
    ---                                  patrimonio n_- como estado endogeno
    ---                                  entrada y salida de bancos

Lo que el PT deja abierto en el Anexo IV y aqui queda cerrado: la liquidez
voluntaria u sale de un problema de decision (una condicion de primer orden
explicita), no de un parametro impuesto.
"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from ssj import HetBlock, asset_grid
from ssj.grids import stationary


# ----------------------------------------------------------------------
# Momentos parciales del choque uniforme
# ----------------------------------------------------------------------
def deficit_esperado(mu, a):
    """G(mu; a) = E[(-(eps + mu))^+] con eps ~ U[-a, a].

    Faltante esperado por unidad de depositos cuando la posicion de liquidez
    esperada es mu. PUNTO CENTRAL DEL MANUAL: aunque (x)^+ tiene un quiebre en
    cero, su ESPERANZA sobre una distribucion continua es derivable con
    continuidad. El quiebre individual no sobrevive a la integracion, y por eso
    la perturbacion de primer orden es legitima aqui.
    """
    mu, a = np.asarray(mu, float), np.asarray(a, float)
    return np.where(mu >= a, 0.0, np.where(mu <= -a, -mu, (a - mu) ** 2 / (4 * a)))


def excedente_esperado(mu, a):
    """X(mu; a) = E[(eps + mu)^+]. Identidad: X - G = E[eps + mu] = mu."""
    return deficit_esperado(mu, a) + mu


def cobertura_marginal(mu, a):
    """-G'(mu) = Pr(faltante) = (a-mu)/(2a) truncado a [0,1].

    Es el beneficio marginal de una unidad extra de colchon: la probabilidad de
    que esa unidad llegue a usarse.
    """
    return np.clip((a - mu) / (2 * a), 0.0, 1.0)


def colchon_optimo(a, spread, kappa, mshift, prob, n_iter=80):
    """Resuelve la CPO del colchon voluntario por biseccion.

        spread = sum_A prob_A * kappa_A * (-G'(u + mshift_A))

    `kappa_A` es el costo esperado por unidad de faltante en el estado agregado
    A (ya neto de lo que cubre el interbancario y del respaldo publico).

    Con un solo estado agregado la solucion es cerrada, u* = a(1 - 2*spread/kappa);
    con varios estados el lado derecho es lineal a trozos y conviene bisecar. El
    costo es despreciable y evita errores de algebra en los casos de esquina.
    """
    a = np.asarray(a, float)
    lo = np.zeros_like(a)
    hi = a - min(mshift) + 1e-9          # por encima de esto nunca hay faltante

    def MB(u):
        return sum(p * k * cobertura_marginal(u + m, a)
                   for p, k, m in zip(prob, kappa, mshift))

    # si ni con colchon nulo el beneficio marginal cubre el costo, la esquina manda
    esquina = MB(lo) <= spread
    for _ in range(n_iter):
        mid = 0.5 * (lo + hi)
        lo = np.where(MB(mid) > spread, mid, lo)
        hi = np.where(MB(mid) > spread, hi, mid)
    return np.where(esquina, 0.0, 0.5 * (lo + hi))


# ----------------------------------------------------------------------
# Paso hacia atras del bloque bancario
# ----------------------------------------------------------------------
def bank_backward(Va_next, Pi, n_grid, a_s, a_u, tau, w, nbar, kappa_op, pesc,
                  regime, surv, beta, eis,
                  rb, rd, rms, rmu, rhos, rhou, iotas, iotau, iotabar,
                  Psis, Psiun, Psiue, phin, phie, lam, eta):
    ne = Pi.shape[0]
    col = lambda v: np.asarray(v, float)[:, np.newaxis]
    a_s_t, a_u_t, w_c = col(a_s), col(a_u), col(w)

    # Acceso al interbancario creciente en el TAMANO del banco: tercera capa del
    # PT combinada con su Hecho Estilizado 2 (los bancos mas pequenos tienen
    # depositos mas volatiles). Esta dependencia es la que hace que la
    # DISTRIBUCION de tamanos importe para los agregados, y no solo su media.
    n_row = n_grid[np.newaxis, :]
    tau_c = col(tau) * (n_row / (n_row + nbar))

    # ---------------- (A) liquidez en soles: ventanilla elastica -------------
    kap_s = [iotas * (1 - tau_c * Psis)]
    u_s = colchon_optimo(a_s_t * np.ones_like(tau_c), rb - rms, kap_s, [0.0], [1.0])
    if regime == "U":
        u_s = np.maximum(u_s - rhos, 0.0)
    mu_s = u_s + (rhos if regime == "U" else 0.0)
    res_s = rhos + u_s
    G_s = deficit_esperado(mu_s, a_s_t)

    # ---------------- (B) liquidez en dolares: dos estados agregados ---------
    # A = normal (prob 1-pesc, desplazamiento 0) y escaso (prob pesc, -eta):
    # es la ecuacion (11) del PT, omega^u = beta_k A^u + eps^u con A^u = -eta.
    prob = [1 - pesc, pesc]
    mshift = [0.0, -eta]
    iota_eff = [phin * iotau + (1 - phin) * iotabar,      # costo efectivo del faltante
                phie * iotau + (1 - phie) * iotabar]      # residual, por estado
    psi_u = [tau_c * Psiun, tau_c * Psiue]                # fraccion cubierta (eq. 15)
    kap_u = [ie * (1 - ps) for ie, ps in zip(iota_eff, psi_u)]

    u_u = colchon_optimo(a_u_t * np.ones_like(tau_c), rb - rmu, kap_u, mshift, prob)
    if regime == "U":
        u_u = np.maximum(u_u - rhou, 0.0)
    mu_u_base = u_u + (rhou if regime == "U" else 0.0)
    res_u = rhou + u_u

    G_u = [deficit_esperado(mu_u_base + m, a_u_t) for m in mshift]
    X_u = [excedente_esperado(mu_u_base + m, a_u_t) for m in mshift]
    resid_u = [(1 - ps) * g for ps, g in zip(psi_u, G_u)]          # eq. (8)/(16)
    cov_u = [ph * r for ph, r in zip((phin, phie), resid_u)]       # eq. (19)

    costo_s = (rb - rms) * res_s + iotas * (1 - tau_c * Psis) * G_s
    costo_u = ((rb - rmu) * res_u
               + sum(p * ie * r for p, ie, r in zip(prob, iota_eff, resid_u)))

    om_u, om_s = w_c, 1 - w_c
    R = 1 + rb + lam * ((rb - rd) - kappa_op - om_s * costo_s - om_u * costo_u)

    # ---------------- (C) decision dinamica: dividendos vs patrimonio --------
    # El banquero que sale consume su patrimonio: de ahi el termino (1 - surv).
    Wa = beta * (surv * (Pi @ Va_next) + (1 - surv) * n_row ** (-1 / eis))
    div_endog = Wa ** (-eis)
    n_endog = (div_endog + n_row) / R
    n_pol = np.empty((ne, len(n_grid)))
    for e in range(ne):
        n_pol[e] = np.interp(n_grid, n_endog[e], n_grid)
    n_pol = np.clip(n_pol, n_grid[0], n_grid[-1])
    div = np.maximum(R * n_row - n_pol, 1e-14)
    Va = R * div ** (-1 / eis)

    # ---------------- (D) productos agregables -------------------------------
    n_ = n_row * np.ones((ne, 1))
    dep = lam * n_
    dep_u, dep_s = om_u * dep, om_s * dep
    out = {
        "N": n_, "DEP": dep, "DEPu": dep_u, "DIV": div,
        "B": n_ + dep - res_s * dep_s - res_u * dep_u,
        "RESu": res_u * dep_u,
        "Uu": u_u * dep_u, "Us": u_s * dep_s,
        "TAUu": tau_c * dep_u,
        # estado escaso: es el que determina el racionamiento y el respaldo
        "Pue": tau_c * X_u[1] * dep_u,          # oferta al interbancario (eq. 14)
        "Que": tau_c * G_u[1] * dep_u,          # demanda al interbancario
        "RESIDue": resid_u[1] * dep_u,          # faltante residual Delta^u (eq. 16)
        "DEFue": G_u[1] * dep_u,
        # cobertura publica esperada: la variable de INCIDENCIA del PT
        "COVu": sum(p * c for p, c in zip(prob, cov_u)) * dep_u,
    }
    for e in range(ne):
        ind = np.zeros((ne, 1)); ind[e] = 1.0
        out[f"COVu{e}"] = ind * out["COVu"]
        out[f"DEPu{e}"] = ind * dep_u
        out[f"Uu{e}"] = ind * out["Uu"]
        out[f"B{e}"] = ind * out["B"]
    return Va, n_pol, out


# ----------------------------------------------------------------------
# Bloque con entrada y salida
# ----------------------------------------------------------------------
class BankBlock(HetBlock):
    """HetBlock con entrada y salida de bancos.

    La ley de movimiento pasa a ser
        D_{t+1} = surv * Lambda' D_t + (1 - surv) * Psi_entrantes,
    con Psi_entrantes FIJA. Por la proposicion 2 del manual (apendice A.2 del
    paper), con entrada exogena se tiene D_D = surv * Lambda'_ss e Y_D = y'_ss,
    de modo que el algoritmo fake news se aplica SIN cambios: basta descontar
    los vectores de expectativa por la tasa de supervivencia.
    """

    def __init__(self, *args, surv, entrants, **kwargs):
        super().__init__(*args, **kwargs)
        self.surv, self.entrants = surv, entrants

    def _forward(self, D, i, p):
        from ssj.interpolate import forward_step
        return self.surv * forward_step(D, self.Pi, i, p) + (1 - self.surv) * self.entrants

    def _expect(self, E, i, p):
        from ssj.interpolate import expectation_step
        # E_t = (D_D')^t Y_D' = surv^t Lambda^t y_ss: un banco que sale deja de
        # contribuir al agregado futuro, y el vector de expectativa lo refleja.
        return self.surv * expectation_step(E, self.Pi, i, p)


# ----------------------------------------------------------------------
# Calibracion
# ----------------------------------------------------------------------
CAL = dict(
    # tipos: a_e es la semiamplitud del choque de retiro sobre depositos.
    # sd(eps) = a/raiz(3): a = [.08,.15,.28] -> sd = [4.6%, 8.7%, 16.2%], el
    # rango del Panel B de la Figura 1 del PT.
    a_s=np.array([0.08, 0.15, 0.28]),
    a_u=np.array([0.08, 0.15, 0.28]),
    tau=np.array([0.90, 0.70, 0.50]),
    w=np.array([0.40, 0.35, 0.30]),
    p_stay=0.95, nbar=1.0, kappa_op=0.0075,
    # politica y precios (trimestrales)
    rhos=0.0556, rhou=0.3537,              # encaje exigible jul-2026 (BCRPData)
    rb=0.0190, rd=0.0040, rms=0.0020, rmu=0.0000,
    iotas=0.05, iotau=0.10, iotabar=0.60,  # respaldo disponible vs. faltante sin cubrir
    Psis=1.00, Psiun=1.00, Psiue=0.60,     # soles elastico; dolares racionado si escasez
    phin=1.00, phie=0.80,                  # el fondo cubre todo en normal, 80% en escasez
    lam=7.0, eta=0.20, pesc=0.15,          # salida agregada de dolares y su probabilidad
    beta=0.99, eis=0.5, surv=0.985,
    regime="NU",
)
PARAMS_FIJOS = ("a_s", "a_u", "tau", "w", "nbar", "kappa_op", "pesc",
                "regime", "surv", "beta", "eis")


def make_banks(cal=None, n_n=170, nmax=600.0, nmin=0.10, n_entry=1.0):
    cal = {**CAL, **(cal or {})}
    ne = len(cal["a_s"])
    p = cal["p_stay"]
    Pi = np.full((ne, ne), (1 - p) / (ne - 1))
    np.fill_diagonal(Pi, p)
    pi = stationary(Pi)

    n_grid = asset_grid(nmin, nmax, n_n)
    j = int(np.searchsorted(n_grid, n_entry))
    entrants = np.zeros((ne, n_n))
    entrants[:, j] = pi                    # masa (1-surv) repartida segun pi

    inputs = ["rb", "rd", "rms", "rmu", "rhos", "rhou", "iotas", "iotau", "iotabar",
              "Psis", "Psiun", "Psiue", "phin", "phie", "lam", "eta"]
    outputs = ["N", "DEP", "DEPu", "B", "RESu", "Uu", "Us", "TAUu",
               "Pue", "Que", "RESIDue", "DEFue", "COVu", "DIV"]
    outputs += [f"{v}{e}" for v in ("COVu", "DEPu", "Uu", "B") for e in range(ne)]

    blk = BankBlock(bank_backward, Pi, n_grid, inputs, outputs,
                    extra={k: cal[k] for k in PARAMS_FIJOS},
                    surv=cal["surv"], entrants=entrants)
    blk.cal, blk.pi, blk.n_tipos = cal, pi, ne
    return blk


def banks_ss(blk, **override):
    cal = {**blk.cal, **override}
    Va0 = np.ones((blk.ne, 1)) * (0.3 * blk.grid[np.newaxis, :]) ** (-1 / cal["eis"])
    ss = blk.steady_state(Va0, **{k: cal[k] for k in blk.inputs})
    ss["_cal"] = cal
    return ss


def banks_ss_consistente(blk, phi_objetivo=0.80, tol=1e-10, maxit=200, verbose=False):
    """Estado estacionario con el interbancario y el respaldo publico CONSISTENTES.

    Resuelve el punto fijo
        Psi^u_e = min(1, P^u_e / Q^u_e)          (vaciado del interbancario, eq. 15)
        phi_e   = min(1, F^u / Delta^u_e)        (capacidad de respaldo, eq. 18)
    y calibra la fraccion movilizable v_F del fondo de encaje para que el
    respaldo cubra `phi_objetivo` del faltante residual en el estado escaso.

    Es la version de estado estacionario del sistema H(U, Z) = 0 que mas
    adelante se resuelve en el espacio de secuencias.
    """
    cal = dict(blk.cal)
    Psiue, phie = cal["Psiue"], cal["phie"]
    for it in range(maxit):
        ss = banks_ss(blk, Psiue=Psiue, phie=phie)
        Psi_new = min(1.0, ss["Pue"] / ss["Que"])
        vF = phi_objetivo * ss["RESIDue"] / (cal["rhou"] * ss["DEPu"])
        phi_new = min(1.0, vF * cal["rhou"] * ss["DEPu"] / ss["RESIDue"])
        err = max(abs(Psi_new - Psiue), abs(phi_new - phie))
        Psiue += 0.5 * (Psi_new - Psiue)
        phie += 0.5 * (phi_new - phie)
        if verbose and it % 10 == 0:
            print(f"  it {it:3d}: Psi={Psiue:.6f} phi={phie:.6f} err={err:.2e}")
        if err < tol:
            break
    ss = banks_ss(blk, Psiue=Psiue, phie=phie)
    ss["vF"] = phi_objetivo * ss["RESIDue"] / (cal["rhou"] * ss["DEPu"])
    ss["Psiue"], ss["phie"] = Psiue, phie
    ss["Fu"] = ss["vF"] * cal["rhou"] * ss["DEPu"]
    blk.cal = {**cal, "Psiue": Psiue, "phie": phie}
    return ss
