"""
ssj: implementacion didactica del metodo de jacobianos en el espacio de secuencias
     (Auclert, Bardoczy, Rognlie y Straub, 2021, Econometrica).

Escrito desde cero, sin dependencias mas alla de numpy/scipy, para acompanar el
manual metodologico. Prioriza legibilidad sobre velocidad.
"""
from .grids import asset_grid, rouwenhorst
from .interpolate import interpolate_y, lottery
from .het import HetBlock
from .simple import SimpleBlock, HetBlockWrapper, Model, ar1

__all__ = [
    "asset_grid", "rouwenhorst", "interpolate_y", "lottery",
    "HetBlock", "SimpleBlock", "HetBlockWrapper", "Model", "ar1",
]
