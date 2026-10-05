# 06 · Logit agregado, nested logit y BLP

> **Extiende S07.** El curso presenta la inversión de Berry, el nested logit agregado y los markups. Aquí: la demostración de la inversión, la prueba de que el mapa de contracción de BLP es efectivamente una contracción, la estructura completa del GMM de BLP, los instrumentos de diferenciación de Gandhi–Houde, micro-momentos, y los errores de implementación que hacen que las estimaciones de BLP fallen en la práctica.

---

## 1. La idea

La Semana 6 tenía datos de elecciones individuales. La realidad tiene **participaciones de mercado**. La pregunta es: ¿se puede recuperar los mismos parámetros de preferencias cuando solo se observa el agregado?

La respuesta de Berry (1994) es sí, y el mecanismo es elegante: con logit, las participaciones de mercado contienen exactamente la misma información que las probabilidades individuales, porque **una participación agregada *es* una probabilidad de elección** (ley de los grandes números sobre un continuo de consumidores). El problema es solo invertir el mapa $\delta\to s$. Para logit, esa inversión es cerrada. Para BLP, requiere un punto fijo numérico.

```
                  Micro (S06)                    Agregado (S07, Cap. 06)
    ───────────────────────────────    ──────────────────────────────────────
    Dato:    elección de consumidor     participación de mercado s_jt
    Modelo:  P_ij = exp(V_ij)/Σexp      s_jt = exp(δ_jt)/Σexp(δ_kt)
    Estim.:  máxima verosimilitud       inversión + IV (o GMM)
    Error:   —                          ξ_jt (calidad no observada) ← ¡endógena!
```

**El nuevo objeto es $\xi_{jt}$**: la calidad no observada del producto $j$ en el mercado $t$. Es el error estructural y es la razón por la que todo el aparato de identificación del Cap. 02 vuelve a ser necesario.

---

## 2. La inversión de Berry: demostración

### 2.1 El modelo agregado

$$u_{ijt} = \underbrace{x_{jt}'\beta - \alpha p_{jt} + \xi_{jt}}_{\delta_{jt}} + \varepsilon_{ijt}, \qquad \varepsilon \sim \text{Gumbel i.i.d.}$$

Bien externo: $\delta_{0t}=0$ (normalización, no supuesto — ver §2.3).

Con un continuo de consumidores y la LGN, la participación de mercado iguala la probabilidad de elección:
$$s_{jt}=\frac{e^{\delta_{jt}}}{\sum_{k=0}^{J}e^{\delta_{kt}}}$$

### 2.2 La inversión

**Paso 1.** Tomar el cociente con el bien externo:
$$\frac{s_{jt}}{s_{0t}}=\frac{e^{\delta_{jt}}\big/\sum_k e^{\delta_{kt}}}{e^{\delta_{0t}}\big/\sum_k e^{\delta_{kt}}}=\frac{e^{\delta_{jt}}}{e^{0}}=e^{\delta_{jt}}$$

El denominador —que contiene *todas* las utilidades y es lo que hace al modelo no lineal— **se cancela exactamente**.

**Paso 2.** Tomar logaritmos:
$$\boxed{\ \ln s_{jt}-\ln s_{0t}=\delta_{jt}=x_{jt}'\beta-\alpha p_{jt}+\xi_{jt}\ }$$

$\blacksquare$

**Lo que acabamos de hacer:** convertir un modelo de elección discreta no lineal en una **regresión lineal** donde el lado izquierdo se construye con datos y el error es el término estructural. Todo el Cap. 02 aplica directamente.

### 2.3 Por qué $\delta_{0t}=0$ es solo una normalización

Sumar $c_t$ a todos los $\delta_{kt}$:
$$\frac{e^{\delta_{jt}+c_t}}{\sum_k e^{\delta_{kt}+c_t}}=\frac{e^{c_t}e^{\delta_{jt}}}{e^{c_t}\sum_k e^{\delta_{kt}}}=s_{jt}$$

Las participaciones son invariantes. Solo las **diferencias** de utilidad están identificadas. Fijar $\delta_{0t}=0$ es elegir el origen de coordenadas, exactamente como fijar una alternativa de referencia en S06. $\blacksquare$

### 2.4 Nested logit agregado

Usando la descomposición GEV del Cap. 05 §5.2, $s_{jt}=s_{j\mid g,t}\cdot s_{gt}$, y aplicando la misma inversión:

$$\ln s_{jt}-\ln s_{0t}=x_{jt}'\beta-\alpha p_{jt}+\sigma\ln s_{j\mid g,t}+\xi_{jt}$$

**Derivación rápida.** De §5.2 del Cap. 05, con $D_g\equiv\sum_{k\in g}e^{\delta_k/(1-\sigma)}$:
$$s_{j|g}=\frac{e^{\delta_j/(1-\sigma)}}{D_g},\qquad s_g=\frac{D_g^{1-\sigma}}{\sum_{g'}D_{g'}^{1-\sigma}},\qquad s_0=\frac{1}{\sum_{g'}D_{g'}^{1-\sigma}}$$
Entonces $s_j/s_0 = s_{j|g}\,D_g^{1-\sigma}$. Tomando logs:
$$\ln s_j - \ln s_0 = \ln s_{j|g} + (1-\sigma)\ln D_g$$
y de la primera expresión, $\ln D_g = \delta_j/(1-\sigma) - \ln s_{j|g}$. Sustituyendo:
$$\ln s_j-\ln s_0 = \ln s_{j|g}+\delta_j - (1-\sigma)\ln s_{j|g} = \delta_j + \sigma\ln s_{j|g} \qquad\blacksquare$$

> **⚠️ El punto que S07 enfatiza y es correcto: ahora hay DOS regresores endógenos.** $\ln s_{j|g,t}$ se construye de participaciones observadas, que son función de $\xi_{jt}$ por la propia inversión. Un shock positivo a $\xi_j$ sube $s_j$, sube $s_{j|g}$, y crea correlación positiva con el error. Estimar por OLS está **doblemente** sesgado.

---

## 3. Instrumentos: las tres familias y sus mecanismos

### 3.1 Desplazadores de costo

Precios de insumos, salarios, energía, tipo de cambio, aranceles. Requieren variación a nivel producto-mercado.

**Limitación práctica:** en un panel tienda-semana, los costos varían poco a nivel de producto. Suelen quedar absorbidos por efectos fijos de producto.

### 3.2 Instrumentos Hausman

$$z_{jt}^{H}=\frac{1}{|\mathcal{T}_{-t}|}\sum_{m\ne t}p_{jm}$$

Covered en Cap. 03 §3.3. En S07, el lab usa la media de precios del mismo UPC en **otras tiendas** la misma semana. **Para paneles de retail esta es la mejor versión del instrumento Hausman**, porque el shock de costo mayorista es común a las tiendas de la cadena y el shock de demanda es local a la tienda.

### 3.3 Instrumentos BLP y la versión moderna

**Instrumentos BLP originales (1995):**
$$z_{jt}^{BLP} = \Big\{\sum_{k\ne j, k\in \mathcal{F}_j} x_{kt},\ \sum_{k\notin \mathcal{F}_j}x_{kt}\Big\}$$
Sumas de características de rivales (propios y de otras firmas).

**Lógica:** el markup de $j$ depende de cuán cercanos son sus rivales en el espacio de características. Si $j$ está rodeado de rivales similares, su markup es bajo. Como las características son fijadas ex ante (diseño de producto), son exógenas a $\xi_{jt}$ contemporáneo.

**Problema (Armstrong 2016):** con muchos productos, estos instrumentos pierden potencia porque las sumas convergen a constantes y la variación desaparece. En mercados grandes, los instrumentos BLP se vuelven **débiles asintóticamente**.

**Instrumentos de diferenciación (Gandhi y Houde 2019) — el estándar actual:**
$$d_{jk,t} = x_{jt}-x_{kt},\qquad z_{jt}^{GH}=\Big\{\sum_{k\ne j}\mathbf{1}\{|d_{jk,t}|<c\},\ \ \sum_{k\ne j}d_{jk,t}^2\Big\}$$

**Lógica mejorada:** lo que importa no es la suma de características de rivales, sino **cuántos rivales están cerca en el espacio de características**. Contar vecinos locales captura directamente la curvatura de la demanda, que es lo que identifica los parámetros no lineales.

**Resultado:** mucho más fuertes, y teóricamente justificados como aproximación de los instrumentos óptimos de Chamberlain.

```python
# Gandhi-Houde en pyblp
import pyblp
differentiation = pyblp.build_differentiation_instruments(
    pyblp.Formulation('0 + hp_weight + mpg + space'),
    product_data, version='local'      # 'local' = conteos; 'quadratic' = sumas d²
)
```

---

## 4. BLP: random coefficients

### 4.1 El modelo

$$u_{ijt}=\underbrace{x_{jt}'\beta-\alpha p_{jt}+\xi_{jt}}_{\delta_{jt}\ (\text{común})}+\underbrace{\sum_k x_{jt}^{(k)}\big(\sigma_k v_{ik}+\pi_k D_{ik}\big)}_{\mu_{ijt}\ (\text{heterogéneo})}+\varepsilon_{ijt}$$

- $v_i\sim N(0,I)$: heterogeneidad no observada.
- $D_i$: demografía observada del mercado (de censo o encuesta).
- $\theta_1=(\beta,\alpha)$: parámetros **lineales**.
- $\theta_2=(\sigma,\pi)$: parámetros **no lineales** — son los que rompen IIA.

$$s_{jt}(\delta,\theta_2)=\int\frac{e^{\delta_{jt}+\mu_{ijt}}}{1+\sum_k e^{\delta_{kt}+\mu_{ikt}}}\,dF(v,D)$$

**Si $\theta_2=0$, esto colapsa al logit agregado de §2.** Todo BLP es "logit + heterogeneidad".

### 4.2 Por qué la heterogeneidad rompe IIA

Con $\sigma_{\text{precio}}>0$, hay consumidores sensibles al precio y consumidores insensibles. Un alza de precio de un auto barato expulsa sobre todo a consumidores sensibles al precio, que se van hacia... **otros autos baratos**. La sustitución se vuelve **local en el espacio de características**, que es lo que la realidad muestra (el Yugo y el BMW de S07).

**Las elasticidades ya no tienen forma cerrada:**
$$\frac{\partial s_{jt}}{\partial p_{kt}}=\begin{cases}
-\displaystyle\int \alpha_i\, s_{ijt}(1-s_{ijt})\,dF & j=k\\[2mm]
\displaystyle\int \alpha_i\, s_{ijt}s_{ikt}\,dF & j\ne k
\end{cases}$$

**Y aquí está la clave:** la elasticidad cruzada $\partial s_j/\partial p_k$ ahora depende de **cuánto se solapan** $s_{ij}$ y $s_{ik}$ a lo largo de la distribución de consumidores. Productos que atraen al mismo tipo de consumidor tienen alta sustitución. **IIA muere.**

### 4.3 El algoritmo

```
PARA cada candidato θ₂:
  ┌─ PASO INTERNO (contracción) ────────────────────────────────┐
  │ δ⁰ = ln s_obs − ln s₀_obs           (inicializar con logit)  │
  │ REPETIR:                                                     │
  │   δ^{h+1} = δ^h + ln s_obs − ln s(δ^h, θ₂)                  │
  │ HASTA ‖δ^{h+1} − δ^h‖ < 1e-14       (¡tolerancia estricta!)  │
  └──────────────────────────────────────────────────────────────┘
  ξ(θ₂) = δ(θ₂) − X θ₁(θ₂)      donde θ₁ sale por IV-GMM lineal
  g(θ₂)  = (1/N) Z' ξ(θ₂)
  Q(θ₂)  = g(θ₂)' W g(θ₂)
MINIMIZAR Q sobre θ₂
```

### 4.4 Demostración de que el mapa es una contracción

Este resultado (BLP 1995, Apéndice I) es lo que garantiza que el paso interno converge, y rara vez se demuestra en cursos.

**Definimos** $T(\delta)=\delta+\ln s^{obs}-\ln s(\delta)$.

**Objetivo:** mostrar que $T$ es una contracción con módulo $<1$ en la norma del supremo, de modo que el teorema del punto fijo de Banach aplique.

**Paso 1 — La matriz Jacobiana.** 
$$\frac{\partial T_j}{\partial \delta_k}=\delta_{jk}-\frac{1}{s_j}\frac{\partial s_j}{\partial \delta_k}$$

De la fórmula de participación (integrando sobre consumidores):
$$\frac{\partial s_j}{\partial \delta_j}=\int s_{ij}(1-s_{ij})\,dF>0,\qquad \frac{\partial s_j}{\partial \delta_k}=-\int s_{ij}s_{ik}\,dF<0\ (k\ne j)$$

**Paso 2 — Los elementos del Jacobiano son no negativos.**
$$\frac{\partial T_j}{\partial \delta_j}=1-\frac{1}{s_j}\int s_{ij}(1-s_{ij})dF = \frac{1}{s_j}\int s_{ij}^2\,dF \ge 0$$
$$\frac{\partial T_j}{\partial \delta_k}=\frac{1}{s_j}\int s_{ij}s_{ik}\,dF\ \ge 0\quad (k\ne j)$$

**Paso 3 — Las filas suman menos que 1.**
$$\sum_{k=1}^{J}\frac{\partial T_j}{\partial \delta_k}=\frac{1}{s_j}\int s_{ij}\Big(\sum_{k=1}^{J}s_{ik}\Big)dF=\frac{1}{s_j}\int s_{ij}(1-s_{i0})\,dF$$

Como $s_{i0}>0$ **estrictamente** (siempre hay probabilidad positiva de elegir el bien externo), tenemos $1-s_{i0}<1$ y por tanto
$$\sum_k\frac{\partial T_j}{\partial\delta_k}<\frac{1}{s_j}\int s_{ij}\,dF=\frac{s_j}{s_j}=1$$

**Paso 4 — Conclusión.** La norma matricial inducida por la norma del supremo es el máximo de las sumas por fila:
$$\|\nabla T\|_\infty=\max_j\sum_k\Big|\frac{\partial T_j}{\partial\delta_k}\Big|<1$$

Por el teorema del valor medio, $\|T(\delta)-T(\delta')\|_\infty\le \|\nabla T\|_\infty\|\delta-\delta'\|_\infty$, de modo que $T$ es una contracción y tiene un punto fijo único al que converge desde cualquier inicio. $\blacksquare$

> **La existencia del bien externo es lo que hace funcionar la contracción.** Si $s_{i0}=0$ (todos compran algo), el módulo sería exactamente 1 y la convergencia no estaría garantizada. **Esta es una razón teórica —no solo práctica— para incluir siempre un bien externo con participación estrictamente positiva.**

### 4.5 Errores de implementación que arruinan BLP

Dubé, Fox y Su (2012) y Knittel–Metaxoglou (2014) documentan que BLP mal implementado da resultados **sin sentido y no replicables**. Los cinco errores:

| Error | Consecuencia | Solución |
|---|---|---|
| Tolerancia laxa en la contracción ($10^{-6}$) | El error de la contracción propaga a la función objetivo y crea **mínimos locales espurios** | Tolerancia $10^{-12}$ a $10^{-14}$ |
| Pocos draws de simulación ($R=50$) | Error de simulación domina la señal | $R\ge 1000$, Halton o **quadratura esférica** |
| Un solo punto inicial | Convergencia a óptimos locales | ≥ 20 puntos iniciales aleatorios |
| Optimizador sin gradientes analíticos | Convergencia falsa | Usar gradientes analíticos (pyblp los tiene) |
| No reportar la sensibilidad a $M_t$ | Resultados frágiles sin advertirlo | Reportar $\{0.5M, M, 2M\}$ |

**La alternativa MPEC (Dubé, Fox y Su 2012):** en lugar de contracción anidada, resolver el problema con restricciones:
$$\min_{\theta,\xi}\ \xi'Z W Z'\xi \quad \text{s.a.}\quad s(\delta(\xi,\theta))=s^{obs}$$
Es más rápido y evita el error de propagación de la contracción. Implementado en `pyblp` con `method='mpec'`.

---

## 5. Micro-momentos: la mejora más importante de la década

**El problema:** con solo participaciones de mercado, los parámetros de heterogeneidad $\theta_2$ están **débilmente identificados**. La información sobre *quién* compra *qué* simplemente no está en los datos agregados.

**La solución (Petrin 2002; Berry, Levinsohn y Pakes 2004; Conlon y Gortmaker 2020):** añadir momentos que combinan datos agregados con información micro externa:

$$E\big[\text{demografía del comprador de } j\big] = \text{dato de encuesta}$$

**Ejemplos:**
- Petrin (2002): usa la Consumer Expenditure Survey para saber que los compradores de minivans tienen más hijos. Esto identifica directamente la interacción (tamaño familiar × característica "capacidad").
- BLP (2004): usa datos del CAMIP sobre ingreso de compradores de autos.
- En retail: paneles de hogares (Kantar, Nielsen Homescan) dan la correlación entre demografía y marca comprada.

**Impacto:** los parámetros de heterogeneidad pasan de estar en el límite de la identificación a estar precisamente estimados, y las elasticidades cruzadas se vuelven mucho más creíbles. **Hoy, un paper de BLP sin micro-momentos y sin justificar su ausencia tiene problemas en referato.**

> **🇵🇪 Perú.** ENAHO tiene módulos de gasto con detalle de categoría y demografía completa del hogar. Combinarla con datos de scanner o de participaciones de mercado sectoriales (Produce, gremios) para construir micro-momentos es técnicamente directo. **Nadie lo ha hecho para Perú y es la vía más corta para un paper estructural publicable con datos locales.**

---

## 6. Las tres estimaciones y qué dice cada una

Replicando la lógica de la tabla de S07:

| | OLS | Logit IV | Nested IV | BLP | Verdad (DGP) |
|---|---|---|---|---|---|
| $\hat\alpha$ | −0.61 | −1.39 | −1.97 | ≈ −2.0 | −2.00 |
| $\hat\sigma$ | — | — | 0.22 | (implícito) | 0.20 |
| Elast. propia media | −0.91 | −1.94 | −2.69 | ≈ −2.8 | −2.80 |
| Patrón de sustitución | IIA | IIA | por nido | **flexible** | — |

**Las dos lecciones:**
1. **OLS está sesgado hacia cero** por $\text{Cov}(p,\xi)>0$. Es la misma simultaneidad de S03, sobreviviendo intacta a la agregación.
2. **Instrumentos válidos no salvan un modelo mal especificado.** El logit IV usa instrumentos correctos y aun así no llega a la verdad, porque la variable omitida $\sigma\ln s_{j|g}$ está correlacionada con el precio. Este es el resultado más importante de S07 y vale repetirlo: *la especificación del patrón de sustitución es tan importante como la identificación*.

---

## 7. Diagnósticos obligatorios

```python
import pyblp, numpy as np
pyblp.options.digits = 3

problem = pyblp.Problem(
    product_formulations=(
        pyblp.Formulation('1 + prices + sugar + mushy'),          # X1 (lineales)
        pyblp.Formulation('0 + prices + sugar'),                  # X2 (aleatorios)
    ),
    product_data=product_data,
    agent_formulation=pyblp.Formulation('0 + income + child'),    # demografía
    agent_data=agent_data,
)

results = problem.solve(
    sigma=np.diag([0.5, 0.1]), pi=np.array([[0.5, 0], [0, 0.2]]),
    optimization=pyblp.Optimization('trust-constr', {'gtol': 1e-8}),
    iteration=pyblp.Iteration('squarem', {'atol': 1e-14}),   # tolerancia estricta
    method='2s',                                             # GMM dos etapas
)

# --- DIAGNÓSTICOS ---
print(results)
print(results.compute_elasticities().mean(axis=0))        # matriz de elasticidades
print(results.compute_diversion_ratios())                 # para antimonopolio
print(results.compute_markups().mean())                   # markups implícitos
print(results.compute_costs().min())                      # ¡deben ser positivos!
print(results.run_hansen_test())                           # sobreidentificación

# Sensibilidad al tamaño de mercado
for factor in [0.5, 1.0, 2.0]:
    pd2 = product_data.copy()
    pd2['market_size'] = product_data['market_size'] * factor
    # recalcular shares y re-estimar
```

**La lista de verificación:**
- [ ] ¿Todos los costos marginales implícitos son **positivos**? Si no, el modelo de conducta o la demanda están mal.
- [ ] ¿Las elasticidades propias son todas $<-1$? (Un monopolista nunca opera en la parte inelástica. Si $|\varepsilon|<1$ para un producto con markup positivo, hay una contradicción con la FOC.)
- [ ] ¿Los diversion ratios suman cerca de 1 (incluyendo el bien externo)?
- [ ] ¿El $\hat\sigma$ del nested está en $[0,1)$?
- [ ] ¿Los resultados son estables con 20 puntos iniciales distintos?
- [ ] ¿Los resultados son estables con $M_t\in\{0.5M, M, 2M\}$?

---

## 8. Lecturas

- **Berry (1994)**, "Estimating Discrete-Choice Models of Product Differentiation", *RAND* 25(2). — la inversión.
- **Berry, Levinsohn y Pakes (1995)**, "Automobile Prices in Market Equilibrium", *Econometrica* 63(4). — el modelo completo.
- **Nevo (2000)**, "A Practitioner's Guide to Estimation of Random-Coefficients Logit Models of Demand", *JEMS* 9(4). — **el manual de implementación; de lectura obligatoria antes de tocar código**.
- Nevo (2001), "Measuring Market Power in the Ready-to-Eat Cereal Industry", *Econometrica* 69(2).
- Petrin (2002), "Quantifying the Benefits of New Products: The Case of the Minivan", *JPE* 110(4). — micro-momentos.
- Dubé, Fox y Su (2012), "Improving the Numerical Performance of BLP", *Econometrica* 80(5). — MPEC.
- Knittel y Metaxoglou (2014), "Estimation of Random-Coefficient Demand Models", *RESTAT* 96(1). — los peligros numéricos.
- **Gandhi y Houde (2019)**, "Measuring Substitution Patterns in Differentiated Products Industries", NBER WP 26375. — instrumentos de diferenciación.
- **Conlon y Gortmaker (2020)**, "Best Practices for Differentiated Products Demand Estimation with PyBLP", *RAND* 51(4). — **la referencia práctica actual**.
- Armstrong (2016), "Large Market Asymptotics for Differentiated Product Demand Estimators", *Econometrica* 84(5).
