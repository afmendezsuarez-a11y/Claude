# 01 · Fundamentos avanzados: teoría del consumidor y del productor

> **Por qué este capítulo existe.** El curso llega a AIDS diciendo "se deriva de la función de gasto PIGLOG vía el lema de Shephard" y pasa a estimar. Pero la credibilidad de todo el edificio empírico descansa en que el sistema estimado sea *integrable*: que exista alguna preferencia racional que lo genere. Sin esa disciplina, las elasticidades cruzadas son números sin interpretación de bienestar, y el cálculo de daño en un caso de cartel no tiene fundamento. Lo mismo del lado de la oferta: los markups de Bertrand–Nash de S07 presuponen una estructura de costos que casi nunca se discute.

---

## 1. La idea

La demanda que estimamos no es un objeto primitivo: es la **solución de un problema de optimización**. Eso impone restricciones comprobables (homogeneidad, simetría, negatividad semidefinida) y, lo que es más importante, permite ir **de la demanda estimada de vuelta a las preferencias**, que es lo que se necesita para medir bienestar.

El teorema central —**integrabilidad**— dice que ese camino de ida y vuelta es completo: dada una función de demanda que satisface ciertas condiciones, existe una función de utilidad que la genera, y es esencialmente única. Esto es lo que convierte a la OI empírica en una disciplina con contenido de bienestar y no en un ejercicio de correlaciones.

Del lado del productor, la **dualidad costo–tecnología** cumple el mismo rol: una función de costos bien comportada contiene toda la información de la tecnología, y es lo que se puede estimar con datos de precios de insumos.

---

## 2. Teoría del consumidor: la estructura completa

### 2.1 Los cuatro objetos y sus seis conexiones

```
        max U(q) s.t. p'q ≤ X              min p'q s.t. U(q) ≥ u
                 │                                   │
                 ▼                                   ▼
   Demanda Marshalliana  q(p,X)  ◄────────►  h(p,u)  Demanda Hicksiana
                 │          Slutsky                  │
                 │                                   │
     Identidad de Roy │                              │ Lema de Shephard
                 │                                   │
                 ▼                                   ▼
   Utilidad indirecta  v(p,X)   ◄────────►  e(p,u)   Función de gasto
                          inversas: v(p,e(p,u)) = u
```

**Las seis identidades operativas** (todas se usan en el manual):

1. **Identidad de Roy:** $\displaystyle q_i(p,X) = -\frac{\partial v/\partial p_i}{\partial v/\partial X}$
2. **Lema de Shephard:** $\displaystyle h_i(p,u) = \frac{\partial e(p,u)}{\partial p_i}$
3. **Dualidad:** $e(p, v(p,X)) = X$ y $v(p, e(p,u)) = u$
4. **Compatibilidad:** $h_i(p,u) = q_i(p, e(p,u))$
5. **Ecuación de Slutsky:** $\displaystyle \frac{\partial q_i}{\partial p_j} = \underbrace{\frac{\partial h_i}{\partial p_j}}_{\text{sustitución}} - \underbrace{q_j \frac{\partial q_i}{\partial X}}_{\text{ingreso}}$
6. **Shephard en logs** (la forma que genera AIDS): $\displaystyle w_i = \frac{\partial \ln e(p,u)}{\partial \ln p_i}$

### 2.2 Demostración de la ecuación de Slutsky

Es la demostración más utilizada del manual (aparece en Cap. 04 y Cap. 11) y vale la pena tenerla completa.

**Partimos de la identidad de compatibilidad:**
$$h_i(p,u) = q_i\big(p, e(p,u)\big)$$

Diferenciamos ambos lados respecto de $p_j$:
$$\frac{\partial h_i}{\partial p_j} = \frac{\partial q_i}{\partial p_j} + \frac{\partial q_i}{\partial X}\cdot \frac{\partial e}{\partial p_j}$$

Por el lema de Shephard, $\partial e/\partial p_j = h_j(p,u) = q_j$ en el óptimo. Sustituyendo:
$$\frac{\partial h_i}{\partial p_j} = \frac{\partial q_i}{\partial p_j} + q_j \frac{\partial q_i}{\partial X} \quad \Longrightarrow \quad \boxed{\frac{\partial q_i}{\partial p_j} = \frac{\partial h_i}{\partial p_j} - q_j\frac{\partial q_i}{\partial X}} \qquad \blacksquare$$

**En elasticidades** (la forma que se usa en los capítulos empíricos). Multiplicando por $p_j/q_i$:
$$\varepsilon_{ij}^{M} = \varepsilon_{ij}^{H} - w_j\, \eta_i$$
donde $\varepsilon^M$ es Marshalliana (no compensada), $\varepsilon^H$ Hicksiana (compensada), $w_j$ la participación presupuestal y $\eta_i$ la elasticidad-gasto.

> **⚠️ Trampa.** Dos bienes pueden ser **sustitutos Hicksianos** (lo que importa para la teoría y para el análisis antimonopolio) y **complementarios Marshallianos** (lo que sale de la regresión) si el efecto ingreso es grande. En S05, las carnes salen como sustitutos en sentido Marshalliano; verificar el signo Hicksiano es un paso que casi todos los papers aplicados omiten. Para definición de mercado relevante bajo SSNIP, **la elasticidad relevante es la Marshalliana** (el consumidor no es compensado cuando sube el precio), pero para análisis de bienestar es la Hicksiana.

### 2.3 Las cuatro propiedades de la demanda y qué testean

Cualquier sistema de demanda derivado de maximización de utilidad satisface:

| Propiedad | Formulación | En AIDS (S05) |
|---|---|---|
| **Adding-up** (Walras) | $\sum_i p_i q_i = X$ | $\sum_i \alpha_i = 1$, $\sum_i \gamma_{ij}=0$, $\sum_i \beta_i = 0$ |
| **Homogeneidad grado 0** | $q_i(\lambda p, \lambda X) = q_i(p,X)$ | $\sum_j \gamma_{ij} = 0 \ \forall i$ |
| **Simetría de Slutsky** | $s_{ij} = s_{ji}$ | $\gamma_{ij} = \gamma_{ji}$ |
| **Negatividad** | $S$ semidefinida negativa | $s_{ii} \le 0$; autovalores $\le 0$ |

**La propiedad que casi nadie verifica es la cuarta.** Simetría y homogeneidad se imponen rutinariamente; la negatividad semidefinida de la matriz de Slutsky es una restricción de *desigualdad* y no se puede imponer linealmente. En la práctica:

```r
# Verificación de negatividad tras estimar LA-AIDS
S <- matrix(NA, n, n)
for (i in 1:n) for (j in 1:n) {
  S[i,j] <- gamma[i,j] + beta[i]*beta[j]*log(X/P) +
            w[i]*w[j] - ifelse(i==j, w[i], 0)
}
eigen(S)$values   # TODOS deben ser ≤ 0 (salvo el cero asociado a homogeneidad)
```

Si hay autovalores positivos, el sistema estimado **no proviene de ninguna preferencia racional** y las medidas de bienestar derivadas no son interpretables. Esto ocurre con más frecuencia de la que se reporta.

### 2.4 Integrabilidad: el teorema que lo justifica todo

> **Teorema (Integrabilidad / Hurwicz–Uzawa).** Sea $q(p,X)$ continuamente diferenciable, homogénea de grado cero, que satisface adding-up, y cuya matriz de Slutsky $S(p,X)$ es simétrica y semidefinida negativa. Entonces existe una función de utilidad continua, creciente y cuasicóncava $U(\cdot)$ que genera $q(p,X)$ como su demanda Marshalliana.

**Esquema de la demostración** (la versión completa está en el [Apéndice A §1](A-apendice-demostraciones.md)):

1. Se plantea el sistema de ecuaciones diferenciales parciales $\partial e/\partial p_i = q_i(p, e)$ con condición inicial $e(p^0, u^0) = X^0$. Este es un sistema PDE no lineal.
2. La **simetría** de $S$ es exactamente la condición de integrabilidad de Frobenius que garantiza que ese sistema tiene solución (es decir, que las derivadas cruzadas son consistentes: $\partial^2 e/\partial p_i \partial p_j = \partial^2 e/\partial p_j \partial p_i$).
3. La **negatividad semidefinida** garantiza que la solución $e(p,u)$ es cóncava en $p$ —propiedad necesaria de toda función de gasto.
4. La **homogeneidad grado 1** de $e$ en $p$ se hereda de la homogeneidad grado 0 de $q$.
5. Se recupera $U$ invirtiendo $e$: $U(q) = \min\{u : e(p,u) \le p'q \ \forall p\}$.

**Por qué importa para la OI empírica:** cuando estimas un AIDS y luego calculas una variación compensatoria por un cartel, estás usando la función de gasto recuperada. Si tu sistema no es integrable, ese número no significa nada. El teorema establece exactamente qué hay que verificar para que signifique algo.

### 2.5 Agregación: Gorman, PIGLOG y por qué AIDS funciona

El problema que resuelve: estimamos demanda con datos **agregados**, pero la teoría es de un **individuo**. ¿Cuándo existe un "consumidor representativo"?

> **Teorema (Gorman 1961).** La demanda agregada es independiente de la distribución del gasto entre consumidores *si y solo si* las curvas de Engel de todos los consumidores son lineales y paralelas, es decir, las preferencias tienen forma **Gorman polar**:
> $$v_h(p, X_h) = \frac{X_h - a_h(p)}{b(p)}$$
> con $b(p)$ **común a todos** los hogares y $a_h(p)$ específico.

**Demostración (dirección necesaria).** Por Roy:
$$q_{ih} = -\frac{\partial v_h/\partial p_i}{\partial v_h/\partial X_h} = \frac{\partial a_h}{\partial p_i} + \frac{\partial b/\partial p_i}{b(p)}\big(X_h - a_h(p)\big)$$

que es lineal en $X_h$ con pendiente $\partial_i b / b$ **idéntica para todos los hogares**. Entonces
$$Q_i = \sum_h q_{ih} = \sum_h \frac{\partial a_h}{\partial p_i} + \frac{\partial_i b}{b}\Big(\sum_h X_h - \sum_h a_h\Big)$$
depende de $\{X_h\}$ solo a través de $\sum_h X_h = X$. $\blacksquare$

Si las pendientes difirieran entre hogares, la redistribución del gasto cambiaría $Q_i$ y no existiría agregación exacta.

**PIGLOG (Price-Independent Generalized Logarithmic)** es la extensión que usa AIDS: curvas de Engel lineales *en el logaritmo del gasto*,
$$\ln e(u, p) = (1-u)\ln a(p) + u \ln b(p)$$
Esto genera agregación exacta sobre el gasto **medio** (más precisamente, sobre la media del gasto ponderada por el "representative budget level"), que es el nivel de agregación de los datos reales. Por eso Deaton y Muellbauer lo llaman "almost ideal": agrega perfectamente y es una aproximación de segundo orden a cualquier sistema.

**La limitación y su solución moderna.** PIGLOG impone curvas de Engel **lineales en $\ln X$**. Los datos de hogares peruanos (ENAHO) muestran claramente curvaturas: la participación de alimentos cae de forma no lineal con el gasto. Esto motiva **QUAIDS** (Banks, Blundell y Lewbel 1997), que añade un término cuadrático:
$$w_i = \alpha_i + \sum_j \gamma_{ij}\ln p_j + \beta_i \ln\!\Big(\frac{X}{a(p)}\Big) + \frac{\lambda_i}{b(p)}\Big[\ln\!\Big(\frac{X}{a(p)}\Big)\Big]^2$$
y preserva la integrabilidad. Ver [Cap. 04 §5](04-sistemas-de-demanda.md).

> **🇵🇪 Perú.** Con ENAHO, el rango de gasto per cápita entre el decil 1 y el decil 10 es de un orden de magnitud. Imponer curvas de Engel lineales en ese rango es insostenible: **QUAIDS debería ser el default para Perú, no AIDS**. La mayoría de los trabajos aplicados peruanos usan LA-AIDS por conveniencia computacional; es una brecha fácil de explotar.

### 2.6 Medición de bienestar: CV, EV y el excedente exacto

Para un cambio de precios $p^0 \to p^1$:

| Medida | Definición | Interpreta |
|---|---|---|
| **Variación compensatoria (CV)** | $e(p^1, u^0) - e(p^0, u^0)$ | Cuánto hay que darle para que esté igual que antes |
| **Variación equivalente (EV)** | $e(p^1, u^1) - e(p^0, u^1)$ | Cuánto pagaría por evitar el cambio |
| **Excedente del consumidor (CS)** | $\int_{p^0}^{p^1} q(p,X)\,dp$ | Aproximación (Marshalliana) |

**Resultado (Willig 1976):** el error relativo de usar CS en lugar de CV está acotado por
$$\left|\frac{CS - CV}{CS}\right| \lesssim \frac{\eta \cdot |CS|}{2X}$$
donde $\eta$ es la elasticidad-ingreso. Para bienes con participación presupuestal pequeña (< 5%), el error es típicamente < 2% y CS es una aproximación aceptable. **Para bienes con participación grande —alimentos en hogares pobres, transporte, electricidad— no lo es**, y hay que calcular CV exactamente.

**Cálculo exacto de CV (método de Hausman 1981).** Dada una demanda estimada $q = f(p, X)$, se resuelve la EDO
$$\frac{\partial e}{\partial p} = f(p, e), \qquad e(p^0) = X$$
Para la forma log-lineal $\ln q = \alpha + \beta \ln p + \gamma \ln X$, la solución cerrada es:
$$e(p^1) = \Big[ X^{1-\gamma} + \frac{(1-\gamma)e^{\alpha}}{1+\beta}\big(p_1^{1+\beta} - p_0^{1+\beta}\big)\Big]^{1/(1-\gamma)}$$
y $CV = e(p^1) - X$. Esta fórmula es la que se usa para cuantificar **daño por cartel** (Cap. 08) y **pérdida de bienestar por fusión** (Cap. 07).

> **⚠️ Trampa.** Reportar el daño de un cartel como "sobreprecio × cantidad" ignora la pérdida de eficiencia (el triángulo) y el efecto ingreso. Para un cartel en un bien con $w \approx 0.1$ (como el papel higiénico en el presupuesto de un hogar bajo), el triángulo es pequeño comparado con la transferencia, pero no es cero, y en un litigio la metodología importa tanto como la cifra.

---

## 3. Teoría del productor: lo que los markups presuponen

### 3.1 Dualidad costo–tecnología

Simétricamente al consumidor:

> **Teorema (Shephard 1953).** Si la tecnología $V(y) = \{z : z \text{ produce } y\}$ es cerrada, convexa y de libre disposición, entonces la función de costos
> $$C(w, y) = \min_z \{w'z : z \in V(y)\}$$
> es: (i) homogénea de grado 1 en $w$, (ii) cóncava en $w$, (iii) no decreciente en $w$, (iv) no decreciente en $y$. Y recíprocamente, toda función con esas propiedades es la función de costos de alguna tecnología convexa.

**Lema de Shephard (versión productor):**
$$z_i(w, y) = \frac{\partial C(w,y)}{\partial w_i}$$

**Por qué esto es operativo:** no necesitas observar la tecnología ni resolver el problema de optimización. Si observas precios de insumos y costos, puedes estimar $C(\cdot)$ con una forma flexible (translog) y recuperar todo: elasticidades de sustitución, economías de escala, productividad.

**Translog de costos** (la forma flexible estándar):
$$\ln C = \alpha_0 + \sum_i \alpha_i \ln w_i + \beta_y \ln y + \tfrac12 \sum_i\sum_j \gamma_{ij}\ln w_i \ln w_j + \tfrac12\beta_{yy}(\ln y)^2 + \sum_i \rho_{iy}\ln w_i \ln y$$

Por Shephard en logs, las **participaciones de costo** son:
$$s_i = \frac{\partial \ln C}{\partial \ln w_i} = \alpha_i + \sum_j \gamma_{ij}\ln w_j + \rho_{iy}\ln y$$

> **Observe la simetría estructural con AIDS.** La ecuación de participación de costos del translog es *formalmente idéntica* a la ecuación de participación presupuestal de AIDS. Mismo lema (Shephard), misma forma flexible, mismas restricciones (homogeneidad: $\sum_j\gamma_{ij}=0$; simetría: $\gamma_{ij}=\gamma_{ji}$), misma técnica de estimación (SUR eliminando una ecuación). **Si entendiste S05, ya sabes estimar funciones de costos.** Esta conexión no aparece en el curso y es una de las más útiles.

**Objetos que se recuperan:**

| Objeto | Fórmula |
|---|---|
| Elasticidad de escala | $\varepsilon_{Cy} = \partial \ln C/\partial\ln y$; hay economías de escala si $< 1$ |
| Elasticidad de sustitución de Allen | $\sigma_{ij}^A = \frac{\gamma_{ij} + s_i s_j}{s_i s_j}$ |
| Elasticidad de demanda de insumo | $\eta_{ij} = \gamma_{ij}/s_i + s_j - \delta_{ij}$ |
| Costo marginal | $mc = \partial C/\partial y = (C/y)\cdot\varepsilon_{Cy}$ |

### 3.2 Costos multiproducto, subaditividad y monopolio natural

Un resultado clave para regulación (Osinergmin, OSIPTEL):

**Economías de alcance (scope):**
$$SC = \frac{C(y_1, 0) + C(0, y_2) - C(y_1, y_2)}{C(y_1, y_2)} > 0$$

**Subaditividad** (definición de monopolio natural): $C(\sum_k y^k) < \sum_k C(y^k)$ para toda partición.

> **Resultado (Baumol, Panzar y Willig 1982).** Economías de escala **no** son suficientes ni necesarias para subaditividad en el caso multiproducto. La condición suficiente es: economías de escala específicas por producto **más** economías de alcance.

Esto es exactamente lo que se discute cuando se evalúa si la distribución eléctrica o la red de fibra en Perú debe ser un monopolio regulado o puede desagregarse.

### 3.3 La función de beneficios y el lema de Hotelling

$$\pi(p, w) = \max_{y,z}\{p y - w'z\}, \qquad y(p,w) = \frac{\partial \pi}{\partial p}, \qquad -z_i(p,w) = \frac{\partial \pi}{\partial w_i}$$

La matriz Hessiana de $\pi$ es **semidefinida positiva y simétrica** — el análogo exacto de la matriz de Slutsky. Esto produce restricciones testeables sobre el sistema de oferta: $\partial y/\partial w_i = -\partial z_i/\partial p$.

### 3.4 El problema de identificación de la función de producción

Este es el punto donde la teoría del productor se encuentra con la Semana 3 del curso, y el curso no lo menciona. **Es exactamente el mismo problema de simultaneidad.**

Queremos estimar
$$y_{it} = \beta_\ell \ell_{it} + \beta_k k_{it} + \omega_{it} + \eta_{it}$$
donde $\omega_{it}$ es **productividad observada por la firma pero no por el econometrista**. La firma elige $\ell_{it}$ **después** de observar $\omega_{it}$:
$$\text{Cov}(\ell_{it}, \omega_{it}) > 0 \implies \hat\beta_\ell^{OLS} \text{ sesgado al alza}$$

Es el mismo mecanismo que en S03: la variable de elección responde al shock no observado. (En demanda: el precio responde a $\xi$. En producción: el insumo responde a $\omega$.)

**Soluciones, en orden histórico:**

| Método | Idea | Problema |
|---|---|---|
| **Efectos fijos** | $\omega_i$ constante en el tiempo | Elimina la variación útil; $\omega$ sí varía |
| **IV (Blundell–Bond)** | Rezagos como instrumentos | Instrumentos débiles con series persistentes |
| **Olley–Pakes (1996)** | Inversión $i_{it}=f(\omega_{it},k_{it})$ es invertible → proxy para $\omega$ | Requiere $i>0$ (muchos ceros) |
| **Levinsohn–Petrin (2003)** | Usa insumos intermedios $m_{it}$ como proxy | Menos ceros, mismo problema de colinealidad |
| **Ackerberg–Caves–Frazer (2015)** | Corrige el problema de colinealidad funcional en la primera etapa de OP/LP | Estándar actual |
| **De Loecker–Warzynski (2012)** | **Recupera markups** sin datos de precios | Depende de la función de producción |

**El resultado que conecta con el Cap. 12:** De Loecker–Warzynski muestran que, con un insumo flexible $V$,
$$\boxed{\mu_{it} = \frac{p_{it}}{mc_{it}} = \theta_{it}^{V}\cdot \Big(\frac{P^V_{it} V_{it}}{P_{it}Y_{it}}\Big)^{-1}}$$
donde $\theta^V$ es la elasticidad de producción del insumo flexible (de la función de producción estimada) y el segundo término es la participación de ese insumo en los ingresos (observable en estados financieros).

**Esta es la fórmula del "markup del lado de la producción"**, alternativa a la del lado de la demanda (Cap. 07). Es la base de la literatura de markups agregados (Cap. 12). Que ambas rutas den respuestas distintas en los mismos datos es una de las controversias activas de la disciplina.

> **💡 Idea de investigación.** Estimar markups por ambas rutas en el mismo sector peruano: la ruta de demanda (BLP con datos de scanner o encuestas) y la ruta de producción (ACF + De Loecker–Warzynski con la Encuesta Económica Anual de Produce). La discrepancia es informativa sobre la especificación. Nadie lo ha hecho para Perú y casi nadie para América Latina.

---

## 4. Síntesis: el mapa de primitivas a estimables

| Primitiva | Objeto dual estimable | Datos requeridos | Capítulo |
|---|---|---|---|
| Utilidad $U(q)$ | Gasto $e(p,u)$ → AIDS | Precios + participaciones | 04 |
| Utilidad $U(x_j)$ (características) | Prob. de elección $P_j$ → Logit | Elecciones o shares | 05, 06 |
| Tecnología $V(y)$ | Costos $C(w,y)$ → Translog | Precios de insumos + costos | 01 §3 |
| Tecnología $F(\ell,k)$ | Producción + markup | Panel de firmas | 01 §3.4, 12 |
| Conducta $\theta$ | FOC de oferta | Lo anterior + rotadores de demanda | 02 §5, 07 |

**La regla general:** nunca estimamos la primitiva; estimamos su dual, que es función de variables observables (precios, gastos, participaciones), y recuperamos la primitiva por un teorema de dualidad. La validez de la recuperación es exactamente la validez de las condiciones de integrabilidad.

---

## 5. Lecturas

**Obligatorias**
- Mas-Colell, Whinston y Green (1995), *Microeconomic Theory*, caps. 2–3 (consumidor) y 5 (productor).
- Deaton y Muellbauer (1980), *Economics and Consumer Behavior*, caps. 1–3.

**Avanzadas**
- Hurwicz y Uzawa (1971), "On the Integrability of Demand Functions", en Chipman et al.
- Gorman (1961), "On a Class of Preference Fields", *Metroeconomica*.
- Banks, Blundell y Lewbel (1997), "Quadratic Engel Curves and Consumer Demand", *RESTAT* 79(4).
- Lewbel y Pendakur (2009), "Tricks with Hicks: The EASI Demand System", *AER* 99(3).
- Ackerberg, Caves y Frazer (2015), "Identification Properties of Recent Production Function Estimators", *Econometrica* 83(6).
- De Loecker y Warzynski (2012), "Markups and Firm-Level Export Status", *AER* 102(6).
- Hausman (1981), "Exact Consumer's Surplus and Deadweight Loss", *AER* 71(4).
