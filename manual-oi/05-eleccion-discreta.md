# 05 · Elección discreta: RUM, logit, GEV e IIA

> **Extiende S06.** El curso da la fórmula logit, deriva las elasticidades y expone IIA con el ejemplo del bus rojo/bus azul. Aquí: la demostración completa de la fórmula logit (con el álgebra Gumbel paso a paso), la teoría GEV que *genera* el nested logit en lugar de postularlo, el mixed logit y el teorema de aproximación universal de McFadden–Train, el cálculo de bienestar y disposición a pagar en RUM, y el diagnóstico honesto de IIA.

---

## 1. La idea

Hay un cambio de objeto conceptual entre el Cap. 04 y este. En AIDS, la utilidad es función de **cantidades** y la respuesta es *cuánto de cada bien*. En elección discreta, la utilidad es función de **características** y la respuesta es *cuál producto*.

El cambio tiene una consecuencia de escalamiento decisiva: los parámetros se adhieren a **características**, no a pares de productos. Un producto nuevo no agrega parámetros, solo una fila de datos. Por eso la elección discreta escala a 250 modelos de auto mientras AIDS se ahoga en 31,375 parámetros.

El costo es que hay que creer dos cosas: (i) que la utilidad es separable en una parte observada y un shock, y (ii) que el shock tiene una distribución específica. La segunda es donde vive IIA.

---

## 2. El modelo de utilidad aleatoria (RUM)

$$U_{ij} = V_{ij} + \varepsilon_{ij}, \qquad V_{ij} = x_{ij}'\beta - \alpha p_j + z_i'\gamma_j$$

El consumidor elige $j$ si y solo si $U_{ij}\ge U_{ik}\ \forall k$. Reordenando:
$$\varepsilon_{ik}-\varepsilon_{ij} \le V_{ij}-V_{ik}\qquad \forall k\ne j$$

$$P_{ij} = \Pr\big(\varepsilon_{ik}-\varepsilon_{ij}\le V_{ij}-V_{ik}\ \forall k\ne j\big)$$

Esto es una integral $(J-1)$-dimensional sobre la densidad conjunta de $\varepsilon_i$. **Intratable en general.** Toda la literatura de elección discreta es una búsqueda de supuestos distribucionales que la hagan tratable.

### 2.1 Las tres normalizaciones que siempre hay que hacer

1. **Nivel de utilidad.** Solo las *diferencias* están identificadas: $V_{ij}\to V_{ij}+c$ no cambia nada. ⇒ normalizar una constante alternativa-específica a cero (elegir alternativa de referencia).
2. **Escala.** $U_{ij}\to \lambda U_{ij}$ no cambia la elección. ⇒ normalizar $\text{Var}(\varepsilon)$. En logit, $\text{Var}(\varepsilon)=\pi^2/6$ por construcción; en probit, $\sigma=1$. **Consecuencia: los coeficientes de logit y probit no son comparables directamente**; hay que escalarlos (el factor aproximado es $\pi/\sqrt3\approx 1.81$).
3. **Regresores invariantes a la alternativa.** Una variable que es igual en todas las alternativas con el mismo coeficiente se cancela. S06 lo demuestra correctamente: para usar el ingreso, hay que interactuarlo ($\gamma_j Z_i$, no $\delta Z_i$).

---

## 3. Por qué Gumbel: la demostración completa

### 3.1 La distribución

$$F(\varepsilon)=\exp\big(-e^{-\varepsilon}\big), \qquad f(\varepsilon)=e^{-\varepsilon}\exp\big(-e^{-\varepsilon}\big)$$

Media $\approx 0.5772$ (Euler–Mascheroni), varianza $\pi^2/6$.

**Tres propiedades que la hacen única:**
1. La **diferencia** de dos Gumbel i.i.d. es **logística** → el caso binario es logit binario exacto.
2. El **máximo** de Gumbels i.i.d. es Gumbel (estabilidad bajo maximización). Como la regla de decisión *es* un máximo, la distribución es cerrada bajo la operación del modelo.
3. $\max_j(V_j+\varepsilon_j)$ tiene media $\ln\sum_j e^{V_j} + 0.5772$ — el **log-sum**, que es la base del cálculo de bienestar (§6).

### 3.2 Demostración de la fórmula logit

**Objetivo:** mostrar que $P_j = e^{V_j}/\sum_k e^{V_k}$.

**Paso 1 — Condicionar.** Fijemos $\varepsilon_j = e$. Entonces $j$ gana si $\varepsilon_k \le e + V_j - V_k$ para todo $k\ne j$. Por independencia:
$$\Pr(j \text{ gana}\mid \varepsilon_j = e) = \prod_{k\ne j} F(e+V_j-V_k) = \prod_{k\ne j}\exp\Big(-e^{-(e+V_j-V_k)}\Big)$$

**Paso 2 — Integrar.**
$$P_j = \int_{-\infty}^{\infty}\prod_{k\ne j}\exp\Big(-e^{-(e+V_j-V_k)}\Big)\cdot e^{-e}\exp(-e^{-e})\,de$$

Podemos incluir $k=j$ en el producto porque para $k=j$ el término es $\exp(-e^{-e})$, que es justamente el factor de la densidad:
$$P_j = \int_{-\infty}^{\infty} \exp\Big(-\sum_{k}e^{-(e+V_j-V_k)}\Big)e^{-e}\,de$$

**Paso 3 — Factorizar.**
$$\sum_k e^{-(e+V_j-V_k)} = e^{-e}\sum_k e^{-(V_j-V_k)} = e^{-e}\cdot e^{-V_j}\sum_k e^{V_k}$$

Definimos $A \equiv e^{-V_j}\sum_k e^{V_k}$. Entonces
$$P_j=\int_{-\infty}^{\infty}\exp\big(-e^{-e}A\big)\,e^{-e}\,de$$

**Paso 4 — Cambio de variable.** Sea $u = e^{-e}$, de donde $du = -e^{-e}de$, es decir $e^{-e}de = -du$. Cuando $e\to-\infty$, $u\to\infty$; cuando $e\to\infty$, $u\to 0$:
$$P_j = \int_{\infty}^{0}\exp(-uA)(-du)=\int_0^{\infty}e^{-uA}du = \left[\frac{-e^{-uA}}{A}\right]_0^\infty = \frac{1}{A}$$

**Paso 5 — Sustituir.**
$$P_j = \frac{1}{e^{-V_j}\sum_k e^{V_k}} = \boxed{\frac{e^{V_j}}{\sum_k e^{V_k}}}\qquad\blacksquare$$

La magia está en el paso 3: la suma de exponenciales de Gumbel se factoriza porque la función generadora es ella misma exponencial. Ninguna otra distribución tiene esta propiedad con forma cerrada en $J$ dimensiones.

---

## 4. Elasticidades e IIA

### 4.1 Derivación

Con $V_j = -\alpha p_j + x_j'\beta$:
$$\ln P_j = V_j - \ln\sum_k e^{V_k}$$
$$\frac{\partial \ln P_j}{\partial p_j} = \frac{\partial V_j}{\partial p_j} - \frac{e^{V_j}\cdot\partial V_j/\partial p_j}{\sum_k e^{V_k}} = -\alpha + \alpha P_j = -\alpha(1-P_j)$$
$$\boxed{\varepsilon_{jj} = -\alpha p_j (1-P_j)}$$

Para $k\ne j$: $\partial V_j/\partial p_k = 0$, y
$$\frac{\partial \ln P_j}{\partial p_k} = -\frac{e^{V_k}(-\alpha)}{\sum_\ell e^{V_\ell}} = \alpha P_k \quad\Longrightarrow\quad \boxed{\varepsilon_{jk}=\alpha p_k P_k}$$

### 4.2 La huella digital de IIA

**$\varepsilon_{jk}$ no depende de $j$.** Toda la columna $k$ de la matriz de elasticidades es idéntica. Esto es visible de inmediato en cualquier tabla estimada: en la tabla de calefacción de S06, la columna GC tiene $+0.76$ en todas las filas.

**Consecuencia sustantiva:** si sube el precio de la calefacción a gas central, los consumidores que se van se distribuyen **proporcionalmente a las participaciones** entre todas las demás opciones. No importa que "gas room" sea físicamente mucho más parecido a "gas central" que una bomba de calor.

### 4.3 El origen formal de IIA

$$\frac{P_j}{P_k}=\frac{e^{V_j}/\sum_\ell e^{V_\ell}}{e^{V_k}/\sum_\ell e^{V_\ell}}=e^{V_j-V_k}$$

El denominador se cancela. El cociente **no depende de ninguna otra alternativa**. Esto no es un supuesto adicional que se pueda relajar dentro del logit: es una consecuencia algebraica inevitable de la i.i.d. Gumbel.

### 4.4 Cuándo IIA es una virtud

S06 presenta IIA como una patología, lo cual es correcto para la mayoría de aplicaciones. Pero hay dos casos donde es exactamente lo que se quiere:

1. **Choice set variable entre consumidores.** Si distintos consumidores enfrentan menús distintos (por disponibilidad geográfica, por ejemplo), IIA permite estimar con el menú de cada uno y los parámetros son comparables. Un modelo sin IIA requeriría modelar el menú.
2. **Muestreo de alternativas.** Con $J$ enorme (todos los modelos de celular), se puede estimar consistentemente usando una **muestra aleatoria** de alternativas no elegidas. **Esta propiedad depende de IIA** (McFadden 1978). Es la razón por la que el logit sigue siendo usado en recomendadores con millones de ítems.

---

## 5. GEV: la teoría que genera el nested logit

S06 y S07 presentan el nested logit como "un parámetro extra que relaja IIA". Eso subvende el resultado. El nested logit es un caso particular de una **familia completa** derivada de un teorema.

### 5.1 El teorema de McFadden (1978)

> **Teorema (GEV).** Sea $G:\mathbb{R}^J_+\to\mathbb{R}_+$ una función que satisface:
> 1. $G(y)\ge 0$;
> 2. **Homogénea de grado 1**: $G(\lambda y)=\lambda G(y)$;
> 3. $G(y)\to\infty$ cuando $y_j\to\infty$ para cualquier $j$;
> 4. Las derivadas parciales cruzadas de orden $k$ son **no negativas para $k$ impar y no positivas para $k$ par**.
>
> Entonces $F(\varepsilon)=\exp\big(-G(e^{-\varepsilon_1},\dots,e^{-\varepsilon_J})\big)$ es una función de distribución válida, y la probabilidad de elección es
> $$P_j = \frac{y_j\, G_j(y)}{G(y)}, \qquad y_j=e^{V_j},\quad G_j=\partial G/\partial y_j$$

**Elegir $G$ es elegir el patrón de sustitución.** Es el objeto de diseño del modelo.

### 5.2 Los casos particulares

| $G(y)$ | Modelo resultante |
|---|---|
| $\sum_j y_j$ | **Logit multinomial** (IIA completo) |
| $\sum_{g}\Big(\sum_{j\in g} y_j^{1/(1-\sigma)}\Big)^{1-\sigma}$ | **Nested logit** |
| Anidamiento recursivo | **Nested logit de múltiples niveles** |
| $\sum_g w_g\big(\sum_j y_j^{1/\lambda_g}\big)^{\lambda_g}$ con $j$ en varios $g$ | **Cross-nested / PCL** (nidos solapados) |
| Formas con pesos de proximidad | **Ordered GEV**, **spatial logit** |

**Verificación para el logit simple:** $G=\sum_k y_k$, $G_j=1$, entonces $P_j = y_j/\sum_k y_k = e^{V_j}/\sum_k e^{V_k}$. ✓

**Derivación del nested logit.** Con $G=\sum_g\big(\sum_{j\in g}y_j^{1/(1-\sigma)}\big)^{1-\sigma}$:
$$G_j = (1-\sigma)\Big(\sum_{k\in g}y_k^{1/(1-\sigma)}\Big)^{-\sigma}\cdot\frac{1}{1-\sigma}y_j^{\sigma/(1-\sigma)} = y_j^{\sigma/(1-\sigma)}\Big(\sum_{k\in g}y_k^{1/(1-\sigma)}\Big)^{-\sigma}$$

Sustituyendo en $P_j = y_jG_j/G$:
$$P_j = \underbrace{\frac{y_j^{1/(1-\sigma)}}{\sum_{k\in g}y_k^{1/(1-\sigma)}}}_{P_{j\mid g}}\cdot\underbrace{\frac{\big(\sum_{k\in g}y_k^{1/(1-\sigma)}\big)^{1-\sigma}}{\sum_{g'}\big(\sum_{k\in g'}y_k^{1/(1-\sigma)}\big)^{1-\sigma}}}_{P_g}$$

**La descomposición $P_j = P_{j\mid g}\cdot P_g$ sale del teorema, no se postula.** Esta es la base algebraica de la inversión nested de Berry en S07. $\blacksquare$

### 5.3 Las restricciones sobre $\sigma$

Para que $G$ satisfaga la condición 4 del teorema, se requiere $\sigma\in[0,1)$. Fuera de ese rango:
- $\sigma<0$: no es un GEV válido; sugiere nidos mal especificados.
- $\sigma\ge1$: la utilidad dentro del nido no está acotada; el modelo se degenera.

**Estimar $\hat\sigma$ fuera de $[0,1)$ es un diagnóstico de especificación errónea, no un resultado.** S07 lo señala y es correcto.

---

## 6. Bienestar y disposición a pagar en RUM

### 6.1 La utilidad esperada: el log-sum

> **Resultado.** Si $\varepsilon$ es i.i.d. Gumbel con escala 1,
> $$E\Big[\max_j (V_j+\varepsilon_j)\Big] = \ln\sum_j e^{V_j} + \gamma$$
> con $\gamma\approx 0.5772$.

**Demostración.** El máximo de Gumbels i.i.d. con localizaciones $V_j$ es Gumbel con localización $\ln\sum_j e^{V_j}$ y escala 1. (La función de distribución del máximo es $\prod_j \exp(-e^{-(x-V_j)}) = \exp(-e^{-x}\sum_je^{V_j})=\exp(-e^{-(x-\ln\sum_je^{V_j})})$.) La media de un Gumbel con localización $\mu$ es $\mu+\gamma$. $\blacksquare$

### 6.2 Variación compensatoria

Si la utilidad es lineal en el ingreso con coeficiente marginal $\alpha$ (= coeficiente de precio con signo cambiado), la variación compensatoria de un cambio de $V^0$ a $V^1$ es:

$$\boxed{\ CV = \frac{1}{\alpha}\Big[\ln\sum_j e^{V_j^1} - \ln\sum_j e^{V_j^0}\Big]\ }$$

(La constante de Euler se cancela.)

**Este es el objeto que valora todo contrafactual de elección discreta:**
- **Introducción de un producto nuevo:** $CV>0$ porque el log-sum crece al añadir un término.
- **Fusión que elimina un producto:** $CV<0$, y es la medida de daño al consumidor.
- **Mejora de calidad:** $\Delta V_j = \Delta x_j'\beta$.

### 6.3 Disposición a pagar por una característica

$$WTP_k = \frac{\partial V/\partial x_k}{\partial V/\partial(-p)} = \frac{\beta_k}{\alpha}$$

**Ejemplo de S06:** en la elección de sistema de calefacción, $\alpha_{IC}=-0.00153$ y $\alpha_{OC}=-0.00700$. El cociente $\alpha_{IC}/\alpha_{OC}=0.219$ dice que **un dólar de ahorro anual en operación se valora como $0.22 de reducción en costo de instalación**. Invertido: $1/0.219 = 4.57$ es el factor de capitalización que el consumidor aplica, lo que implica una **tasa de descuento implícita** de $r$ tal que $\sum_{t=1}^{30}(1+r)^{-t}=4.57$, es decir $r\approx 21\%$ anual.

> **Esto es un resultado sustantivo, no un detalle técnico.** Una tasa implícita de 21% en una inversión de eficiencia energética con horizonte de 30 años es evidencia de **miopía energética** (*energy efficiency gap*) y es el fundamento de las políticas de estándares mínimos de eficiencia. Toda una literatura (Hausman 1979; Allcott y Greenstone 2012) nace de este cálculo.

> **🇵🇪 Perú.** El mismo ejercicio con la elección de cocina (GLP vs. leña vs. eléctrica) en hogares rurales, usando ENAHO y precios de FISE, daría la tasa de descuento implícita de hogares rurales peruanos y el subsidio necesario para inducir conversión. **Es una tesis de política pública completa y los datos existen.**

---

## 7. Mixed logit: cuando IIA se rompe en todas partes

### 7.1 El modelo

$$U_{ij} = x_j'\beta_i + \varepsilon_{ij}, \qquad \beta_i\sim f(\beta\mid\theta)$$

$$P_{ij} = \int \frac{e^{x_j'\beta}}{\sum_k e^{x_k'\beta}}\,f(\beta\mid\theta)\,d\beta$$

Es una **mezcla** de logits. Condicional a $\beta_i$, hay IIA. **Integrando sobre la heterogeneidad, no.**

**Intuición de por qué rompe IIA:** si un consumidor valora mucho "ser bus" (alto $\beta$ en la característica "bus"), elegirá bus rojo o bus azul con alta probabilidad y auto con baja. Esa correlación inducida por la heterogeneidad es exactamente la correlación de los shocks que el logit simple prohíbe.

### 7.2 El teorema de aproximación universal

> **Teorema (McFadden y Train 2000).** Para cualquier modelo de utilidad aleatoria con probabilidades de elección $P^*_j$, y para cualquier $\epsilon>0$, existe un mixed logit con una especificación de $f(\beta)$ tal que $|P_j - P^*_j|<\epsilon$ para todo $j$.

**Es decir: el mixed logit puede aproximar cualquier patrón de sustitución arbitrariamente bien.** No hay restricción de IIA, ni de forma de la matriz de elasticidades, ni de nada.

**Las dos letras pequeñas:**
- La aproximación puede requerir una $f$ muy flexible (muchas dimensiones de mezcla) → costo computacional e identificación práctica difícil.
- El teorema es de **aproximación**, no de identificación. Que exista una $f$ que ajusta no significa que tus datos la identifiquen.

### 7.3 Estimación por máxima verosimilitud simulada

$$\hat P_{ij}=\frac{1}{R}\sum_{r=1}^{R}\frac{e^{x_j'\beta^r}}{\sum_k e^{x_k'\beta^r}}, \qquad \beta^r = \bar\beta + \Sigma\, v^r,\ v^r\sim N(0,I)$$

**Detalles que importan:**
- Usar **Halton draws** o **scrambled Halton**, no pseudoaleatorios: convergen mucho más rápido (Train 2009, cap. 9). Con 100 Halton se consigue lo que requiere ~1000 aleatorios.
- La verosimilitud simulada es **sesgada** para $R$ finito (por la desigualdad de Jensen, al estar el logaritmo fuera de la simulación). El sesgo es $O(1/R)$. Hay que usar $R$ grande y verificar estabilidad: si los resultados cambian al pasar de $R=500$ a $R=1000$, $R$ es insuficiente.
- La verosimilitud **no es globalmente cóncava** (a diferencia del logit simple) → múltiples óptimos locales. Probar varios puntos iniciales.

### 7.4 Qué distribución para $\beta$

| Distribución | Cuándo | Riesgo |
|---|---|---|
| Normal | Default, características generales | Admite signos "incorrectos" en las colas |
| **Log-normal** | Coeficiente de precio (debe ser < 0) | Colas muy pesadas → WTP infinita en algunos individuos |
| Triangular / uniforme acotada | Cuando se necesita soporte acotado | Menos estándar |
| **En el espacio de WTP** (Train–Weeks 2005) | Cuando el objeto de interés es WTP | **Preferido en política**: evita WTP explosiva |

> **⚠️ Trampa seria.** Con coeficiente de precio log-normal, la distribución de $WTP=\beta_k/\alpha_i$ tiene media y varianza que pueden ser **infinitas**. Papers que reportan "WTP promedio" con esa especificación están reportando un artefacto numérico del sample. **Reportar la mediana, no la media**, o estimar directamente en el espacio de WTP.

---

## 8. Testear IIA honestamente

### 8.1 Hausman–McFadden

$$H = (\hat\beta_R-\hat\beta_F)'\big[\widehat{V}(\hat\beta_R)-\widehat{V}(\hat\beta_F)\big]^{-1}(\hat\beta_R-\hat\beta_F)\ \xrightarrow{d}\ \chi^2_k$$

donde $F$ = conjunto completo, $R$ = subconjunto.

**Problemas reales (que S06 enumera correctamente):**
- La diferencia de matrices de varianza puede no ser definida positiva en muestras finitas → $H<0$, test indefinido.
- **Poca potencia.** Simulaciones muestran que no detecta violaciones moderadas de IIA.
- El resultado depende de **qué alternativa se excluye**: distintas exclusiones dan distintas conclusiones.

### 8.2 Small–Hsiao

Divide la muestra en dos, estima en cada mitad con conjuntos de alternativas distintos, compara por LR. Más estable que Hausman–McFadden pero depende de la partición aleatoria (correr varias semillas).

### 8.3 La recomendación práctica

**No confíes en el test. Usa el juicio económico y luego verifica con un modelo que relaje IIA.**

Protocolo recomendado:
1. Estimar logit simple.
2. Mirar la matriz de elasticidades. **Si las columnas son constantes y eso es implausible para el mercado, IIA es un problema, independientemente del test.**
3. Estimar nested logit con una partición que tenga sentido físico/económico. Testear $H_0:\sigma=0$ con un $t$ de Wald — **este sí tiene potencia** (S07, Cap. 06).
4. Si los datos lo permiten (micro-datos o muchos mercados), estimar mixed logit.
5. Comparar la matriz de elasticidades y el contrafactual clave entre los tres modelos. **Si el contrafactual no cambia, IIA no era el problema. Si cambia mucho, reportar el modelo flexible.**

---

## 9. Código

```r
library(mlogit)
H <- dfidx(Heating, choice = "depvar", varying = c(3:12),
           idx = list(c("idcase","id")), idnames = c("chid","alt"))

# Logit condicional
m1 <- mlogit(depvar ~ ic + oc | 0, data = H)
summary(m1)

# Tasa de descuento implícita
r_implicita <- coef(m1)["ic"] / coef(m1)["oc"]       # ≈ 0.22

# Elasticidades
effects(m1, covariate = "ic", type = "rr")           # relativas (elasticidades)

# Nested logit
m2 <- mlogit(depvar ~ ic + oc | 0, data = H,
             nests = list(gas = c("gc","gr"), elec = c("ec","er","hp")),
             un.nest.el = TRUE)
lrtest(m1, m2)                                        # test de IIA con potencia

# Mixed logit (coeficiente de ic aleatorio normal)
m3 <- mlogit(depvar ~ ic + oc | 0, data = H,
             rpar = c(ic = "n"), R = 500, halton = NA, panel = FALSE)
summary(m3)

# Test de Hausman-McFadden (con sus caveats)
m_sub <- mlogit(depvar ~ ic + oc | 0, data = H, alt.subset = c("gc","gr","ec"))
hmftest(m1, m_sub)
```

```python
import xlogit
model = xlogit.MixedLogit()
model.fit(X=X, y=y, varnames=varnames, alts=alts, ids=ids,
          randvars={'price':'ln', 'quality':'n'},   # 'ln' = lognormal
          n_draws=1000, halton=True, optim_method='L-BFGS-B')
model.summary()
```

---

## 10. Lecturas

- **Train (2009), *Discrete Choice Methods with Simulation*, 2ª ed.** — el libro. Caps. 2–3 (logit), 4 (GEV), 6 (mixed logit), 9 (simulación).
- McFadden (1974), "Conditional Logit Analysis of Qualitative Choice Behavior", en Zarembka.
- McFadden (1978), "Modelling the Choice of Residential Location", en Karlqvist et al. — **el paper del teorema GEV**.
- McFadden y Train (2000), "Mixed MNL Models for Discrete Response", *JAE* 15(5).
- Hausman y McFadden (1984), "Specification Tests for the Multinomial Logit Model", *Econometrica* 52(5).
- Cardell (1997), "Variance Components Structures for the Extreme-Value and Logistic Distributions", *Econometric Theory* 13(2).
- Train y Weeks (2005), "Discrete Choice Models in Preference Space and Willingness-to-Pay Space", en Scarpa y Alberini.
- Allcott y Greenstone (2012), "Is There an Energy Efficiency Gap?", *JEP* 26(1).
