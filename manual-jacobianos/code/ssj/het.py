"""Bloque de agentes heterogeneos y algoritmo *fake news*.

Implementa las proposiciones 1 y 2 de Auclert, Bardoczy, Rognlie y Straub (2021)
para problemas con un estado endogeno y un estado exogeno de Markov. La notacion
sigue la del manual:

    v_t = v(v_{t+1}, X_t)            (iteracion hacia atras)
    D_{t+1} = Lambda(v_{t+1}, X_t)' D_t   (iteracion hacia adelante)
    Y_t = y(v_{t+1}, X_t)' D_t            (agregacion)
"""
import numpy as np

from .interpolate import lottery, forward_step, expectation_step


class HetBlock:
    """Bloque de agentes heterogeneos.

    Parametros
    ----------
    backward : callable
        backward(V_next, Pi, grid, **extra, **inputs) -> (V, pol, outcomes)
        V_next, V : (ne, na)  variable de continuacion (p.ej. Va = dV/da)
        pol       : (ne, na)  politica del estado endogeno, en niveles
        outcomes  : dict nombre -> (ne, na)
    Pi : (ne, ne) matriz de transicion del estado exogeno
    grid : (na,) grilla del estado endogeno
    inputs : lista de nombres de los insumos agregados X
    outputs : lista de nombres de los productos agregados Y (claves de outcomes)
    """

    def __init__(self, backward, Pi, grid, inputs, outputs, extra=None):
        self.backward, self.Pi, self.grid = backward, Pi, grid
        self.inputs, self.outputs = list(inputs), list(outputs)
        self.extra = dict(extra or {})   # objetos fijos (grillas, parametros)
        self.ne, self.na = Pi.shape[0], len(grid)

    def _step(self, V_next, **inputs):
        return self.backward(V_next, self.Pi, self.grid, **self.extra, **inputs)

    # Operadores de la distribucion. Se aislan en metodos para que una subclase
    # pueda cambiarlos (entrada y salida, varias etapas por periodo) sin tocar
    # el algoritmo: es exactamente la generalidad que da la proposicion 2.
    def _forward(self, D, i, p):
        """D_{t+1} = Lambda' D_t."""
        return forward_step(D, self.Pi, i, p)

    def _expect(self, E, i, p):
        """E_t = Lambda E_{t-1}."""
        return expectation_step(E, self.Pi, i, p)

    # ------------------------------------------------------------------
    # Estado estacionario
    # ------------------------------------------------------------------
    def steady_state(self, V_init, D_init=None, tol=1e-11, maxit=20_000, **inputs):
        """Resuelve el estado estacionario: punto fijo de (10)-(12) con X_t = X_ss."""
        V = V_init.copy()
        for it in range(maxit):
            V_new, pol, out = self._step(V, **inputs)
            if it % 10 == 0 and np.max(np.abs(V_new - V)) < tol * (1 + np.max(np.abs(V))):
                V = V_new
                break
            V = V_new
        else:
            raise RuntimeError("la iteracion hacia atras no convergio")
        V, pol, out = self._step(V, **inputs)

        i, p = lottery(pol, self.grid)
        D = D_init
        if D is None:
            D = np.ones((self.ne, self.na)) / (self.ne * self.na)
        for it in range(maxit):
            D_new = self._forward(D, i, p)
            if np.max(np.abs(D_new - D)) < 1e-14:
                D = D_new
                break
            D = D_new
        else:
            raise RuntimeError("la distribucion no convergio")

        ss = dict(inputs)
        ss.update(V=V, D=D, pol=pol, i=i, p=p, outcomes=out)
        for o in self.outputs:
            ss[o] = float(np.vdot(out[o], D))
        return ss

    # ------------------------------------------------------------------
    # Paso 1 del algoritmo: Y_s y D_s
    # ------------------------------------------------------------------
    def _backward_fakenews(self, ss, shocked, T, h):
        """Una sola iteracion hacia atras entrega TODAS las columnas.

        Devuelve
          curlyY[o][s] = dY_0^s / dx   (efecto en el producto HOY de una noticia
                                        sobre el insumo dentro de s periodos)
          curlyD[s]    = dD_1^s / dx   (efecto en la distribucion de MANANA)
        Se usa diferenciacion numerica de dos lados: dos recursiones completas,
        una con +h y otra con -h. Cuesta el doble y gana entre uno y dos ordenes
        de magnitud de precision frente a la version de un lado.
        """
        base = {k: ss[k] for k in self.inputs}
        curlyY = {o: np.empty((2, T)) for o in self.outputs}
        curlyD = np.empty((2, T, self.ne, self.na))

        for sgn_idx, sgn in enumerate((+1.0, -1.0)):
            V_next = ss["V"]
            for s in range(T):
                args = dict(base)
                if s == 0:
                    args[shocked] = base[shocked] + sgn * h
                V_next, pol, out = self._step(V_next, **args)
                for o in self.outputs:
                    curlyY[o][sgn_idx, s] = np.vdot(out[o], ss["D"])
                i, p = lottery(pol, self.grid)
                curlyD[sgn_idx, s] = self._forward(ss["D"], i, p)

        dY = {o: (curlyY[o][0] - curlyY[o][1]) / (2 * h) for o in self.outputs}
        dD = (curlyD[0] - curlyD[1]) / (2 * h)
        return dY, dD

    # ------------------------------------------------------------------
    # Paso 2: vectores de expectativa
    # ------------------------------------------------------------------
    def _expectations(self, ss, T):
        """E_t = Lambda^t y_ss : valor esperado del producto para un agente que
        hoy esta en cada punto de la grilla, bajo comportamiento de estado
        estacionario. Son T-1 aplicaciones de una matriz fija: baratisimo."""
        curlyE = {}
        for o in self.outputs:
            E = np.empty((T - 1, self.ne, self.na))
            E[0] = ss["outcomes"][o]
            for t in range(1, T - 1):
                E[t] = self._expect(E[t - 1], ss["i"], ss["p"])
            curlyE[o] = E
        return curlyE

    # ------------------------------------------------------------------
    # Pasos 3 y 4: matriz fake news y jacobiano
    # ------------------------------------------------------------------
    def jacobians(self, ss, shocked_inputs=None, T=300, h=1e-4, return_F=False):
        """Jacobianos J^{o,i} de dimension T x T para cada producto o e insumo i."""
        shocked_inputs = shocked_inputs or self.inputs
        curlyE = self._expectations(ss, T)

        dY, dD = {}, {}
        for i in shocked_inputs:
            dY[i], dD[i] = self._backward_fakenews(ss, i, T, h)

        Fs, Js = {}, {}
        for o in self.outputs:
            Emat = curlyE[o].reshape(T - 1, -1)          # (T-1) x n_g
            for i in shocked_inputs:
                F = np.empty((T, T))
                F[0, :] = dY[i][o]
                F[1:, :] = Emat @ dD[i].reshape(T, -1).T  # (T-1) x T
                Fs[(o, i)] = F
                J = F.copy()
                for t in range(1, T):
                    J[t, 1:] += J[t - 1, :-1]
                Js[(o, i)] = J
        return (Js, Fs) if return_F else Js

    # ------------------------------------------------------------------
    # Metodo directo (solo para verificacion; cuesta un factor T mas)
    # ------------------------------------------------------------------
    def jacobians_direct(self, ss, shocked_inputs, T, h=1e-4):
        base = {k: ss[k] for k in self.inputs}
        Js = {(o, i): np.empty((T, T)) for o in self.outputs for i in shocked_inputs}

        for i_name in shocked_inputs:
            for s in range(T):
                Yplus = self._path(ss, base, i_name, s, +h, T)
                Yminus = self._path(ss, base, i_name, s, -h, T)
                for o in self.outputs:
                    Js[(o, i_name)][:, s] = (Yplus[o] - Yminus[o]) / (2 * h)
        return Js

    def _path(self, ss, base, i_name, s, dx, T):
        """Resuelve la transicion completa ante un choque de tamano dx en la
        fecha s: T pasos hacia atras y T hacia adelante. Esto es lo que el
        algoritmo fake news evita repetir T veces."""
        pols, outs = [None] * T, [None] * T
        V = ss["V"]
        for t in range(T - 1, -1, -1):
            args = dict(base)
            if t == s:
                args[i_name] = base[i_name] + dx
            V, pol, out = self._step(V, **args)
            pols[t], outs[t] = pol, out
        Y = {o: np.empty(T) for o in self.outputs}
        D = ss["D"]
        for t in range(T):
            for o in self.outputs:
                Y[o][t] = np.vdot(outs[t][o], D)
            i, p = lottery(pols[t], self.grid)
            D = self._forward(D, i, p)
        return Y
