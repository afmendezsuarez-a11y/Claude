"""Bloques simples, grafo aciclico dirigido (DAG) y solucion de equilibrio general.

Un bloque simple es cualquier mapeo Y_t = h(X_{t-k}, ..., X_{t+l}) entre
secuencias. Sus jacobianos son matrices T x T con estructura de banda y se
obtienen por diferenciacion numerica a costo trivial.

El equilibrio general se escribe H(U, Z) = 0 con tantos objetivos como
incognitas, y se resuelve con  dU = -H_U^{-1} H_Z dZ.
"""
import numpy as np


class SimpleBlock:
    """Bloque simple definido por una funcion sobre TRAYECTORIAS completas.

    f recibe un dict {nombre: array de largo T} y devuelve {nombre: array}.
    Internamente se diferencia numericamente columna por columna: T evaluaciones
    por insumo, cada una O(T). Es despreciable frente al bloque heterogeneo.
    """

    def __init__(self, f, inputs, outputs, name="simple"):
        self.f, self.inputs, self.outputs, self.name = f, list(inputs), list(outputs), name

    def jacobians(self, ss, T, h=1e-6):
        base = {k: np.full(T, ss[k]) for k in self.inputs}
        y0 = self.f(**base)
        J = {}
        for i in self.inputs:
            cols = {o: np.empty((T, T)) for o in self.outputs}
            for s in range(T):
                xp = {k: v.copy() for k, v in base.items()}
                xm = {k: v.copy() for k, v in base.items()}
                xp[i][s] += h
                xm[i][s] -= h
                yp, ym = self.f(**xp), self.f(**xm)
                for o in self.outputs:
                    cols[o][:, s] = (yp[o] - ym[o]) / (2 * h)
            for o in self.outputs:
                J[(o, i)] = cols[o]
        del y0
        return J


class HetBlockWrapper:
    """Adapta un HetBlock ya resuelto a la interfaz de bloque del DAG."""

    def __init__(self, het, ss, T, shocked_inputs=None, h=1e-4, name="het"):
        self.name = name
        self.inputs = list(shocked_inputs or het.inputs)
        self.outputs = list(het.outputs)
        self._J = het.jacobians(ss, self.inputs, T, h)

    def jacobians(self, ss, T, h=None):
        return self._J


class Model:
    """Conjunto de bloques sobre un DAG, con incognitas, objetivos y choques."""

    def __init__(self, blocks, unknowns, targets, exogenous):
        self.blocks = list(blocks)
        self.unknowns, self.targets, self.exogenous = list(unknowns), list(targets), list(exogenous)
        if len(self.unknowns) != len(self.targets):
            raise ValueError("el modelo necesita tantas incognitas como objetivos")
        self.order = self._topological_sort()

    def _topological_sort(self):
        """Ordena los bloques de modo que cada insumo ya haya sido calculado.

        Si no existe tal orden, el grafo tiene un ciclo: hay simultaneidad que
        debe romperse agregando una incognita y su objetivo (vease el capitulo
        sobre el DAG).
        """
        producer = {o: b for b in self.blocks for o in b.outputs}
        known = set(self.exogenous) | set(self.unknowns)
        pending, order = list(self.blocks), []
        while pending:
            progress = False
            for b in list(pending):
                if all((i in known) or (i not in producer) for i in b.inputs):
                    order.append(b)
                    known |= set(b.outputs)
                    pending.remove(b)
                    progress = True
            if not progress:
                nombres = [b.name for b in pending]
                raise ValueError(f"el grafo tiene un ciclo; bloques irresolubles: {nombres}")
        return order

    def total_jacobians(self, ss, T):
        """Acumulacion hacia adelante: J^{o,i} total a lo largo del DAG."""
        I = np.eye(T)
        total = {i: {i: I} for i in self.exogenous + self.unknowns}
        for b in self.order:
            Jb = b.jacobians(ss, T)
            for o in b.outputs:
                total.setdefault(o, {})
                for i in self.exogenous + self.unknowns:
                    acc = None
                    for m in b.inputs:
                        if (o, m) not in Jb or m not in total or i not in total[m]:
                            continue
                        term = Jb[(o, m)] @ total[m][i]
                        acc = term if acc is None else acc + term
                    if acc is not None:
                        total[o][i] = acc
        return total

    def solve(self, ss, T):
        """Devuelve G: dict (variable, choque) -> matriz T x T de respuestas."""
        total = self.total_jacobians(ss, T)
        nu, nz = len(self.unknowns), len(self.exogenous)
        H_U = np.zeros((len(self.targets) * T, nu * T))
        H_Z = np.zeros((len(self.targets) * T, nz * T))
        for a, tgt in enumerate(self.targets):
            for b_, u in enumerate(self.unknowns):
                H_U[a * T:(a + 1) * T, b_ * T:(b_ + 1) * T] = total[tgt].get(u, np.zeros((T, T)))
            for b_, z in enumerate(self.exogenous):
                H_Z[a * T:(a + 1) * T, b_ * T:(b_ + 1) * T] = total[tgt].get(z, np.zeros((T, T)))

        G_UZ = -np.linalg.solve(H_U, H_Z)
        G = {}
        for b_, u in enumerate(self.unknowns):
            for c, z in enumerate(self.exogenous):
                G[(u, z)] = G_UZ[b_ * T:(b_ + 1) * T, c * T:(c + 1) * T]
        # el resto de variables se recupera por la regla de la cadena
        for o in total:
            if o in self.unknowns:
                continue
            for c, z in enumerate(self.exogenous):
                acc = total[o].get(z, np.zeros((T, T))).copy()
                for u in self.unknowns:
                    if u in total[o]:
                        acc = acc + total[o][u] @ G[(u, z)]
                G[(o, z)] = acc
        return G


def ar1(rho, T, size=1.0):
    """Trayectoria AR(1) de un choque: dZ_t = size * rho^t."""
    return size * rho ** np.arange(T)
