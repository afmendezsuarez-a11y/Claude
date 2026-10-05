"""Figuras de la aplicacion al modelo de bancos heterogeneos."""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import matplotlib.pyplot as plt

from figures import cache as C
from figures.estilo import C as COL, SEQ, GRIS, TINTA2, cero, etiqueta_directa, rejilla

OUT = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
                   "figuras")
TIPOS = ["tipo 1: poco expuesto", "tipo 2: intermedio", "tipo 3: muy expuesto"]
CORTO = ["tipo 1", "tipo 2", "tipo 3"]


def guardar(fig, nombre):
    fig.savefig(os.path.join(OUT, nombre + ".pdf"))
    plt.close(fig)
    print("  ->", nombre + ".pdf")


# --------------------------------------------------------- 9. estado estacionario
def fig_ss():
    blk, ss = C.bancos()
    n, D = blk.grid, ss["D"]
    fig, axes = plt.subplots(1, 3, figsize=(6.5, 2.3), layout="constrained")

    for e, col in enumerate(COL):
        surv = 1 - np.cumsum(D[e] / D[e].sum())
        axes[0].loglog(n, np.maximum(surv, 1e-6), color=col, label=CORTO[e])
    axes[0].axvline(1.0, color=GRIS, lw=0.8, ls="--")
    axes[0].annotate("entrantes", (1.1, 0.35), color=TINTA2, fontsize=6.5)
    axes[0].set_xlim(0.8, 40); axes[0].set_ylim(1e-5, 1.3)
    axes[0].set_title("Cola de tamaños")
    axes[0].set_xlabel("patrimonio $n_-$"); axes[0].set_ylabel("$\\Pr(n > n_-)$ en el tipo")
    axes[0].legend(loc="lower left", handlelength=1.2, fontsize=6.8)

    for e, col in enumerate(COL):
        axes[1].plot(n, blk.cal["tau"][e] * n / (n + blk.cal["nbar"]), color=col, label=CORTO[e])
    axes[1].set_xscale("log"); axes[1].set_xlim(0.2, 30); axes[1].set_ylim(0, 1)
    axes[1].set_title("Acceso $\\tau(e,n_-)$")
    axes[1].set_xlabel("patrimonio $n_-$"); axes[1].set_ylabel("$\\tau$")
    axes[1].legend(loc="upper left", handlelength=1.2)

    x = np.arange(3)
    u = [ss[f"Uu{e}"] / ss[f"DEPu{e}"] for e in range(3)]
    c = [ss[f"COVu{e}"] / ss[f"DEPu{e}"] for e in range(3)]
    ax2 = axes[2]
    ax2.bar(x - 0.19, u, 0.34, color=COL[0], label="colchón voluntario $u^u_k$")
    ax2.bar(x + 0.19, np.array(c) * 20, 0.34, color=COL[1],
            label="cobertura usada $C^u_k$ ($\\times 20$)")
    for xi, v in zip(x - 0.19, u):
        ax2.annotate(f"{v:.3f}", (xi, v), xytext=(0, 2), textcoords="offset points",
                     ha="center", fontsize=6.3, color=TINTA2)
    for xi, v in zip(x + 0.19, c):
        ax2.annotate(f"{v:.4f}", (xi, v * 20), xytext=(0, 2), textcoords="offset points",
                     ha="center", fontsize=6.3, color=TINTA2, rotation=90)
    ax2.set_xticks(x); ax2.set_xticklabels(CORTO)
    ax2.set_title("Incidencia estacionaria")
    ax2.set_ylabel("por unidad de depósito en ME")
    ax2.legend(loc="upper left", handlelength=1.0, fontsize=6.5)
    ax2.set_ylim(0, 0.40); rejilla(ax2)
    rejilla(axes[0]); rejilla(axes[1])
    guardar(fig, "fig09_bancos_estado_estacionario")


# --------------------------------------------- 10. jacobianos del bloque bancario
def fig_jacobianos():
    J = C.bancos_jacobians(200)
    blk, ss = C.bancos()
    paneles = [("B", "crédito"), ("Uu", "colchón vol."), ("COVu", "cobertura pública")]
    fig, axes = plt.subplots(1, 3, figsize=(6.5, 2.3), layout="constrained")
    for ax, (o, tit) in zip(axes, paneles):
        M = J[(o, "rhou")]
        for col, s in zip(SEQ[1:], [0, 8, 20, 40]):
            ax.plot(100 * M[:80, s] / ss[o], color=col, label=f"$s={s}$")
        cero(ax); rejilla(ax)
        ax.set_title(f"$\\mathcal{{J}}^{{{o},\\rho^u}}$ — " + tit, fontsize=8)
        ax.set_xlabel("trimestre $t$")
    axes[0].set_ylabel("\\% del valor estacionario")
    axes[0].legend(loc="lower right", ncol=2, handlelength=1.2, columnspacing=0.9)
    guardar(fig, "fig10_bancos_jacobianos")


# ------------------------------------------------------ 11. IRFs de EG al encaje
def fig_irf_encaje():
    d = C.bancos_G(200)
    G, ssf = d["G"], d["ssf"]
    T = 200
    dr = 0.01 * 0.90 ** np.arange(T)        # +1 pp, AR(1) rho = 0.90
    H = 40
    fig, axes2 = plt.subplots(2, 2, figsize=(6.3, 3.6), layout="constrained")
    axes = axes2.ravel()

    def pct(k):
        return 100 * (G[(k, "rhou")] @ dr)[:H] / ssf[k]

    axes[0].plot(pct("B"), color=COL[0], label="crédito $B$")
    axes[0].plot(pct("N"), color=COL[1], label="patrimonio $N$")
    axes[0].set_title("Balance agregado"); axes[0].set_ylabel("desviación (\\%)")
    axes[0].legend(loc="lower right", handlelength=1.2)

    axes[1].plot(1e4 * (G[("rb", "rhou")] @ dr)[:H], color=COL[0])
    axes[1].set_title("Tasa activa $r^b$"); axes[1].set_ylabel("puntos básicos")

    axes[2].plot(pct("Uu"), color=COL[0], label="colchón $U^u$")
    axes[2].plot(pct("COVu"), color=COL[1], label="cobertura $C^u$")
    axes[2].set_title("Seguro privado y público"); axes[2].set_ylabel("desviación (\\%)")
    axes[2].legend(loc="center right", handlelength=1.2)

    axes[3].plot(100 * (G[("phie", "rhou")] @ dr)[:H], color=COL[0], label="$\\phi$ (respaldo)")
    axes[3].plot(100 * (G[("Psiue", "rhou")] @ dr)[:H], color=COL[1], label="$\\Psi^u$ (interbanc.)")
    axes[3].set_title("Capacidad de cobertura"); axes[3].set_ylabel("puntos porcentuales")
    axes[3].legend(loc="center right", handlelength=1.2)

    for ax in axes:
        cero(ax); rejilla(ax)
    for ax in axes[2:]:
        ax.set_xlabel("trimestre")
    guardar(fig, "fig11_bancos_irf_encaje")


# -------------------------------------------------------------- 12. incidencia
def fig_incidencia():
    d = C.bancos_G(200)
    G, ssf = d["G"], d["ssf"]
    T, H = 200, 40
    fig, axes = plt.subplots(1, 2, figsize=(6.3, 2.4), layout="constrained")
    choques = [("rhou", 0.01 * 0.90 ** np.arange(T), "Encaje en ME: $+1$ pp"),
               ("eta", 0.05 * 0.70 ** np.arange(T), "Escasez de dólares: $+5$ pp en $\\eta$")]
    for ax, (z, dz, tit) in zip(axes, choques):
        for e, col in enumerate(COL):
            k = f"COVu{e}"
            ax.plot(100 * (G[(k, z)] @ dz)[:H] / ssf[k], color=col, label=TIPOS[e])
        cero(ax); rejilla(ax)
        ax.set_title(tit); ax.set_xlabel("trimestre")
        ax.set_ylabel("cobertura pública usada (\\%)")
    axes[0].legend(loc="upper right", handlelength=1.2, fontsize=6.8)
    guardar(fig, "fig12_bancos_incidencia")


# ------------------------------------------------- 13. regimenes NU vs U (umbral)
def fig_regimenes():
    from models.banks import colchon_optimo
    blk, ss = C.bancos()
    cal = blk.cal
    rhos_grid = np.linspace(0.0, 0.60, 601)
    prob = [1 - cal["pesc"], cal["pesc"]]
    mshift = [0.0, -cal["eta"]]
    iota_eff = [cal["phin"] * cal["iotau"] + (1 - cal["phin"]) * cal["iotabar"],
                cal["phie"] * cal["iotau"] + (1 - cal["phie"]) * cal["iotabar"]]

    fig, axes = plt.subplots(1, 2, figsize=(6.3, 2.5), layout="constrained")
    for e, col in enumerate(COL):
        tau_e = cal["tau"][e] * 1.0 / (1.0 + cal["nbar"])      # banco del tamano de entrada
        kap = [ie * (1 - tau_e * ps) for ie, ps in zip(iota_eff, (cal["Psiun"], cal["Psiue"]))]
        libre = float(np.ravel(colchon_optimo(np.array([cal["a_u"][e]]),
                                              cal["rb"] - cal["rmu"],
                                              [np.array([k]) for k in kap], mshift, prob))[0])
        axes[0].plot(rhos_grid, np.full_like(rhos_grid, libre), color=col, ls="--", lw=1.3,
                     label=CORTO[e])
        axes[1].plot(rhos_grid, np.maximum(libre - rhos_grid, 0.0), color=col, label=CORTO[e])
        axes[1].axvline(libre, color=col, lw=0.6, ls=":")
    axes[0].set_title("Régimen NU: el encaje no es colchón")
    axes[1].set_title("Régimen U: el encaje sustituye colchón")
    for ax in axes:
        rejilla(ax); ax.set_xlabel("encaje exigible $\\rho^u$")
        ax.set_ylabel("colchón voluntario $u^u$"); ax.set_ylim(-0.01, 0.30)
    axes[0].legend(loc="center right", handlelength=1.4)
    axes[0].annotate("$\\partial u^u/\\partial \\rho^u = 0$", (0.03, 0.26), color=TINTA2, fontsize=7.5)
    axes[1].annotate("$\\partial u^u/\\partial \\rho^u = -1$\nhasta el umbral; luego $0$",
                     (0.30, 0.09), color=TINTA2, fontsize=7.5)
    axes[1].legend(loc="upper right", handlelength=1.2)
    guardar(fig, "fig13_bancos_regimenes")


if __name__ == "__main__":
    for f in (fig_ss, fig_jacobianos, fig_irf_encaje, fig_incidencia, fig_regimenes):
        print(f.__name__); f()
