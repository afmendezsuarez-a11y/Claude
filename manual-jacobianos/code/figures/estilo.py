"""Estilo comun de las figuras del manual.

Paleta validada con el verificador del skill de visualizacion: los tres colores
categoricos superan los umbrales de separacion para vision normal y para las
tres formas de daltonismo (deuteranopia, protanopia, tritanopia). El aqua queda
por debajo de 3:1 de contraste contra el fondo, asi que TODA serie en aqua lleva
etiqueta directa, nunca solo color.
"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap

# categoricos (identidad): maximo tres por grafico en formas de dispersion
C = ["#2a78d6", "#eb6834", "#1baf7a"]
# ordinal (magnitud ordenada): un solo tono, claro -> oscuro, nunca mas claro
# que el paso 250 para que el extremo claro siga siendo legible en papel
SEQ = ["#86b6ef", "#5598e7", "#2a78d6", "#1c5cab", "#104281"]
# divergente (polaridad): azul <-> rojo con gris neutro al medio
DIV = LinearSegmentedColormap.from_list("div", ["#104281", "#2a78d6", "#f0efec", "#d03b3b", "#7a1f1f"])
GRIS, TINTA, TINTA2 = "#b5b4af", "#0b0b0b", "#52514e"

plt.rcParams.update({
    "figure.dpi": 140, "savefig.dpi": 140, "savefig.bbox": "tight",
    "savefig.pad_inches": 0.02, "font.size": 8.5,
    "font.family": "serif", "font.serif": ["DejaVu Serif"],
    "mathtext.fontset": "dejavuserif",
    "axes.linewidth": 0.6, "axes.edgecolor": TINTA2,
    "axes.labelcolor": TINTA, "axes.titlesize": 9, "axes.titleweight": "bold",
    "axes.titlelocation": "left", "axes.titlepad": 6,
    "axes.spines.top": False, "axes.spines.right": False,
    "xtick.color": TINTA2, "ytick.color": TINTA2,
    "xtick.labelsize": 7.5, "ytick.labelsize": 7.5,
    "xtick.major.width": 0.6, "ytick.major.width": 0.6,
    "legend.frameon": False, "legend.fontsize": 7.5,
    "lines.linewidth": 1.5, "lines.solid_capstyle": "round",
    "grid.color": "#e8e7e3", "grid.linewidth": 0.6,
})


def rejilla(ax, eje="y"):
    ax.grid(True, axis=eje, zorder=0)
    ax.set_axisbelow(True)


def etiqueta_directa(ax, x, y, texto, color, dx=2, dy=0, **kw):
    """Etiqueta al final de la serie: la identidad nunca depende solo del color."""
    ax.annotate(texto, (x, y), xytext=(dx, dy), textcoords="offset points",
                color=color, fontsize=7.5, va="center", weight="bold", **kw)


def cero(ax):
    ax.axhline(0, color=GRIS, lw=0.7, zorder=1)
