"""Figuras de la parte metodologica del manual."""
import os
import sys
import time

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import matplotlib.pyplot as plt

from figures import cache as C
from figures.estilo import C as COL, SEQ, DIV, GRIS, TINTA2, cero, etiqueta_directa, rejilla

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "figuras")
os.makedirs(OUT, exist_ok=True)
def guardar(fig, nombre):
    fig.savefig(os.path.join(OUT, nombre + ".pdf"))
    plt.close(fig)
    print("  ->", nombre + ".pdf")


# ---------------------------------------------------------------- 1. columnas de J
def fig_columnas():
    (J, F) = C.ks_jacobians(300)
    Jar = J[("A", "r")]
    fig, axes = plt.subplots(1, 2, figsize=(6.3, 2.5), layout="constrained")
    for ax, (key, tit) in zip(axes, [(("A", "r"), r"Ahorro: $\mathcal{J}^{A,r}$"),
                                     (("C", "r"), r"Consumo: $\mathcal{J}^{C,r}$")]):
        M = J[key]
        for col, sh in zip(SEQ, [0, 25, 50, 75, 100]):
            ax.plot(M[:200, sh], color=col, label=f"$s={sh}$")
        cero(ax); rejilla(ax)
        ax.set_title(tit); ax.set_xlabel("período $t$"); ax.set_xlim(0, 200)
    axes[0].legend(loc="lower right", ncol=2, handlelength=1.3, columnspacing=1.0)
    axes[0].set_ylabel("respuesta de $A_t$")
    axes[1].set_ylabel("respuesta de $C_t$")
    guardar(fig, "fig01_columnas_jacobiano")


# ------------------------------------------------- 2. mapa de calor e invarianza
def fig_estructura():
    (J, F) = C.ks_jacobians(300)
    M = J[("A", "r")]
    from matplotlib.colors import LinearSegmentedColormap
    SEQMAP = LinearSegmentedColormap.from_list("seq", ["#f4f8fe"] + SEQ)
    fig, axes = plt.subplots(1, 2, figsize=(6.5, 2.6), layout="constrained")
    im = axes[0].imshow(M[:150, :150], cmap=SEQMAP, vmin=0, vmax=M[:150, :150].max(),
                        origin="upper")
    axes[0].set_title("Mapa de calor de $\\mathcal{J}^{A,r}$")
    axes[0].set_xlabel("fecha de la noticia $s$"); axes[0].set_ylabel("fecha de respuesta $t$")
    axes[0].spines[:].set_visible(False)
    cb = fig.colorbar(im, ax=axes[0], fraction=0.046, pad=0.02)
    cb.outline.set_visible(False); cb.ax.tick_params(labelsize=6.5, width=0.5)

    ax = axes[1]
    for col, s in zip(SEQ[1:], [40, 70, 100, 130]):
        ax.plot(np.arange(-40, 120), M[s - 40:s + 120, s], color=col, label=f"$s={s}$")
    ax.axvline(0, color=GRIS, lw=0.7)
    cero(ax); rejilla(ax)
    ax.set_title("Alineadas en $t-s$, casi coinciden")
    ax.set_xlabel("$t - s$ (distancia a la noticia)")
    ax.set_ylabel("respuesta de $A_t$")
    ax.legend(loc="lower right", ncol=2, handlelength=1.3)
    guardar(fig, "fig02_estructura_jacobiano")


# ------------------------------------------------------- 3. la matriz fake news
def fig_fakenews():
    (J, F) = C.ks_jacobians(300)
    Fm = F[("A", "r")]
    fig, axes = plt.subplots(1, 2, figsize=(6.3, 2.5), layout="constrained")
    axes[0].plot(Fm[:200, 0], color=COL[0])
    etiqueta_directa(axes[0], 60, Fm[60, 0], "$s=0$", COL[0], dx=4)
    axes[0].set_title("Primera columna de $\\mathcal{F}$ (= primera de $\\mathcal{J}$)")
    for col, s in zip(SEQ[1:], [25, 50, 75, 100]):
        axes[1].plot(Fm[:200, s], color=col, label=f"$s={s}$")
    axes[1].legend(loc="upper right", ncol=2, handlelength=1.3, columnspacing=1.0)
    axes[1].set_title("Columnas posteriores de $\\mathcal{F}$")
    for ax in axes:
        cero(ax); rejilla(ax); ax.set_xlabel("período $t$"); ax.set_xlim(0, 200)
    axes[0].set_ylabel("$\\mathcal{F}_{t,0}$"); axes[1].set_ylabel("$\\mathcal{F}_{t,s}$")
    guardar(fig, "fig03_matriz_fakenews")


# ------------------------------------------------- 4. vectores de expectativa
def fig_expectativa():
    het, ss = C.ks()
    Es = het._expectations(ss, 160)["A"]
    e_med = het.ne // 2
    fig, axes = plt.subplots(1, 2, figsize=(6.3, 2.5), layout="constrained")
    for col, t in zip(SEQ, [0, 4, 16, 48, 120]):
        axes[0].plot(het.grid, Es[t][e_med], color=col, label=f"$t={t}$")
    axes[0].set_xscale("log")
    axes[0].set_title(r"Vectores de expectativa $\mathcal{E}_t$")
    axes[0].set_xlabel("activos iniciales $a_-$"); axes[0].set_ylabel(r"$\mathcal{E}_t(e,a_-)$")
    axes[0].set_xlim(0.5, het.grid[-1] * 1.1)
    axes[0].legend(loc="upper left", ncol=2, handlelength=1.3, columnspacing=1.0)

    # cuanto tarda en desaparecer la informacion de la distribucion
    disp = np.array([np.sqrt(np.vdot(ss["D"], (E - np.vdot(ss["D"], E)) ** 2)) for E in Es])
    axes[1].semilogy(disp / disp[0], color=COL[0])
    axes[1].set_title("Cuánto queda de la información distributiva")
    axes[1].set_xlabel("período $t$")
    axes[1].set_ylabel("relativa a la de $t=0$")
    rejilla(axes[0]); rejilla(axes[1])
    guardar(fig, "fig04_vectores_expectativa")


# -------------------------------------------------------------- 5. verificacion
def fig_verificacion():
    def _calc():
        from models.krusell_smith import household_ss, make_household
        het = make_household(n_a=100, amax=150)
        ss = household_ss(het, r=0.01, w=1.0, eis=0.5, target_A=3.0)
        Ts, t_fake, t_dir, err = [10, 20, 30, 40, 50], [], [], []
        for T in Ts:
            t0 = time.time(); Jf = het.jacobians(ss, ["r"], T=T); t_fake.append(time.time() - t0)
            t0 = time.time(); Jd = het.jacobians_direct(ss, ["r"], T=T); t_dir.append(time.time() - t0)
            err.append(max(np.abs(Jf[k] - Jd[k]).max() / np.abs(Jd[k]).max() for k in Jf))
        return Ts, t_fake, t_dir, err
    Ts, t_fake, t_dir, err = C.memo("verificacion", _calc)

    fig, axes = plt.subplots(1, 2, figsize=(6.3, 2.5), layout="constrained")
    axes[0].semilogy(Ts, t_dir, "o-", color=COL[1], ms=4)
    axes[0].semilogy(Ts, t_fake, "o-", color=COL[0], ms=4)
    etiqueta_directa(axes[0], Ts[-1], t_dir[-1], "directo", COL[1], dx=4)
    etiqueta_directa(axes[0], Ts[-1], t_fake[-1], "fake news", COL[0], dx=4)
    axes[0].set_title("Costo de calcular $\\mathcal{J}$")
    axes[0].set_xlabel("horizonte de truncamiento $T$"); axes[0].set_ylabel("segundos")
    axes[0].set_xlim(5, 72); axes[0].set_xticks(Ts)

    axes[1].semilogy(Ts, err, "o-", color=COL[0], ms=4)
    axes[1].axhline(1e-6, color=GRIS, lw=0.8, ls="--")
    axes[1].annotate("tolerancia $10^{-6}$", (Ts[0], 1.3e-6), color=TINTA2, fontsize=7)
    axes[1].set_title("Discrepancia entre ambos métodos")
    axes[1].set_xlabel("horizonte de truncamiento $T$")
    axes[1].set_ylabel("error relativo máximo")
    axes[1].set_ylim(1e-10, 1e-4); axes[1].set_xticks(Ts)
    rejilla(axes[0]); rejilla(axes[1])
    guardar(fig, "fig05_verificacion")


# ------------------------------------------------------------- 6. truncamiento
def fig_truncamiento():
    def _calc():
        from models.krusell_smith import make_ks_model, make_household
        het, ss = C.ks()
        Tmax = 600
        Jfull = C.memo("ks_J_600", lambda: het.jacobians(ss, ["r", "w"], T=Tmax, return_F=True))[0]
        res = {}
        for rho in (0.9, 0.99):
            base = None
            fila = []
            for T in (600, 60, 100, 150, 200, 300, 400, 500):
                Jt = {k: v[:T, :T] for k, v in Jfull.items()}
                class W:
                    name, inputs, outputs = "hogares", ["r", "w"], ["A", "C"]
                    def jacobians(self, ss, T, h=None): return Jt
                from ssj import Model, SimpleBlock
                def firms(K, Z):
                    Kl = np.concatenate(([C.K_SS], K[:-1]))
                    return {"r": C.ALPHA * Z * Kl ** (C.ALPHA - 1) - C.DELTA,
                            "w": (1 - C.ALPHA) * Z * Kl ** C.ALPHA,
                            "Y": Z * Kl ** C.ALPHA}
                m = Model([SimpleBlock(firms, ["K", "Z"], ["r", "w", "Y"], name="empresas"), W(),
                           SimpleBlock(lambda A, K: {"asset_mkt": A - K}, ["A", "K"], ["asset_mkt"],
                                       name="vaciado")],
                          unknowns=["K"], targets=["asset_mkt"], exogenous=["Z"])
                ssf = dict(ss); ssf.update(K=C.K_SS, Z=1.0, Y=C.Y_SS, asset_mkt=0.0)
                G = m.solve(ssf, T)
                dK = G[("K", "Z")] @ (0.01 * rho ** np.arange(T))
                if T == 600:
                    base = dK[:60]
                else:
                    fila.append((T, np.sqrt(np.mean((dK[:60] - base) ** 2)) / C.K_SS))
            res[rho] = fila
        return res
    res = C.memo("truncamiento", _calc)

    fig, ax = plt.subplots(figsize=(3.4, 2.5), layout="constrained")
    for col, (rho, fila) in zip(COL, sorted(res.items())):
        T, e = zip(*sorted(fila))
        ax.semilogy(T, np.maximum(e, 1e-17), "o-", color=col, ms=3.5)
        etiqueta_directa(ax, T[-1], max(e[-1], 1e-17), f"$\\rho={rho}$", col, dx=4)
    ax.set_title("Error por truncar en $T$")
    ax.set_xlabel("horizonte $T$")
    ax.set_ylabel("RMSE de $dK_t/K_{ss}$")
    ax.set_xlim(40, 640); rejilla(ax)
    guardar(fig, "fig06_truncamiento")


# --------------------------------------------------------------- 7. IRFs de EG
def fig_irf_ks():
    T = 300
    G = C.ks_G(T)
    fig, axes = plt.subplots(1, 2, figsize=(6.3, 2.5), layout="constrained")
    for col, rho in zip(SEQ[1:], [0.3, 0.5, 0.7, 0.9]):
        dZ = 0.01 * rho ** np.arange(T)
        dK = 100 * (G[("K", "Z")] @ dZ) / C.K_SS
        axes[0].plot(dK[:60], color=col, label=f"$\\rho={rho}$")
    axes[0].legend(loc="upper right", ncol=2, handlelength=1.3, columnspacing=1.0)
    axes[0].set_title("Choque de PTF del 1 por ciento")
    for col, s in zip(SEQ[1:], [5, 10, 20, 40]):
        dZ = np.zeros(T); dZ[s] = 0.01
        dK = 100 * (G[("K", "Z")] @ dZ) / C.K_SS
        axes[1].plot(dK[:60], color=col, label=f"$s={s}$")
    axes[1].legend(loc="upper right", ncol=2, handlelength=1.3, columnspacing=1.0)
    axes[1].set_title("Noticia de PTF mayor en $s$")
    for ax in axes:
        cero(ax); rejilla(ax); ax.set_xlabel("trimestre $t$")
        ax.set_ylabel("desviación de $K$ (\\%)")
    guardar(fig, "fig07_irf_krusell_smith")


# ---------------------------------------------- 8. el quiebre y la esperanza
def fig_quiebre():
    from models.banks import cobertura_marginal, deficit_esperado
    mu = np.linspace(-0.35, 0.35, 801)
    fig, axes = plt.subplots(1, 2, figsize=(6.3, 2.5), layout="constrained")
    axes[0].plot(mu, np.maximum(-mu, 0), color=GRIS, lw=1.2, ls="--",
                 label="caso individual $(-\\mu)^+$")
    for col, a in zip(COL, [0.08, 0.15, 0.28]):
        axes[0].plot(mu, deficit_esperado(mu, a), color=col, label=f"$a={a:.2f}$")
    axes[0].set_title("Faltante esperado $G(\\mu;a)$")
    axes[0].set_ylabel("$G(\\mu;a)$")
    axes[0].legend(loc="upper right", handlelength=1.4)

    axes[1].plot(mu, (mu < 0).astype(float), color=GRIS, lw=1.2, ls="--",
                 label="caso individual")
    for col, a in zip(COL, [0.08, 0.15, 0.28]):
        axes[1].plot(mu, cobertura_marginal(mu, a), color=col, label=f"$a={a:.2f}$")
    axes[1].set_title("Probabilidad de faltante $-G'(\\mu;a)$")
    axes[1].set_ylabel("$-G'(\\mu;a)$"); axes[1].set_ylim(-0.05, 1.28)
    axes[1].legend(loc="upper right", ncol=2, handlelength=1.4)
    for ax in axes:
        rejilla(ax); ax.set_xlabel("colchón efectivo $\\mu$")
        ax.axvline(0, color=GRIS, lw=0.7)
    guardar(fig, "fig08_quiebre_esperanza")


if __name__ == "__main__":
    for f in (fig_columnas, fig_estructura, fig_fakenews, fig_expectativa,
              fig_verificacion, fig_truncamiento, fig_irf_ks, fig_quiebre):
        print(f.__name__); f()
