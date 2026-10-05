# 02 · El problema de identificación, en serio

> **Extiende S03.** El curso presenta el problema con el mercado de pescado de Fulton y la condición "relevancia + exclusión". Aquí: la demostración completa del sesgo, las condiciones de orden y rango, IV como caso particular de GMM, la teoría de instrumentos débiles con inferencia robusta, la **identificación de la conducta** (el paso que S03 no da y que es el corazón de la OI), y los resultados modernos de identificación no paramétrica.

---

## 1. La idea

Identificación es una pregunta sobre el **mapa de parámetros a distribuciones**, no sobre estimación. Formalmente:

> Un parámetro $\theta_0 \in \Theta$ está **identificado** si para todo $\theta \ne \theta_0$, la distribución de los datos implicada por $\theta$ difiere de la implicada por $\theta_0$:
> $$P_\theta \ne P_{\theta_0} \quad \forall\, \theta \ne \theta_0$$

Si dos valores de parámetros generan exactamente los mismos datos, **ninguna cantidad de observaciones los distingue**. El problema no se resuelve con más datos, ni con mejores algoritmos, ni con machine learning. Se resuelve con **variación exógena** o con **supuestos adicionales**.

La frase de S03 —"relevance you can test, exclusion you must argue"— es correcta pero incompleta. La versión completa es:

> **La identificación no es una propiedad de los datos. Es una propiedad del par (datos, supuestos). Cambiar los supuestos cambia qué está identificado.**

---

## 2. El problema de simultaneidad: demostración completa

### 2.1 El sistema estructural

$$\begin{aligned}
\text{(D)}\quad Q_t &= \alpha + \beta P_t + \varepsilon_t, &\beta < 0\\
\text{(S)}\quad Q_t &= \gamma + \delta P_t + \eta_t, &\delta > 0
\end{aligned}$$

con $E[\varepsilon]=E[\eta]=0$, $\text{Var}(\varepsilon)=\sigma^2_\varepsilon$, $\text{Var}(\eta)=\sigma^2_\eta$, $\text{Cov}(\varepsilon,\eta)=\sigma_{\varepsilon\eta}$.

### 2.2 La forma reducida

Igualando (D) y (S) y despejando:
$$P_t = \frac{(\gamma-\alpha) + (\eta_t - \varepsilon_t)}{\beta - \delta}, \qquad
Q_t = \frac{(\beta\gamma - \alpha\delta) + (\beta\eta_t - \delta\varepsilon_t)}{\beta-\delta}$$

**Observación crucial:** la forma reducida tiene 2 ecuaciones y la estructura tiene 4 parámetros $(\alpha,\beta,\gamma,\delta)$ más 3 de la matriz de covarianza. La forma reducida identifica a lo sumo $2$ intercepto $+ 3$ varianzas $= 5$ objetos. **El sistema está subidentificado: 7 incógnitas, 5 ecuaciones.**

Esta es la forma precisa del "problema de identificación" de S03: no es que OLS sea sesgado, es que **ningún estimador puede recuperar $\beta$** sin información adicional.

### 2.3 El sesgo de OLS, derivado

$$\text{Cov}(P_t, \varepsilon_t) = \text{Cov}\!\left(\frac{\eta_t-\varepsilon_t}{\beta-\delta},\ \varepsilon_t\right) = \frac{\sigma_{\varepsilon\eta} - \sigma^2_\varepsilon}{\beta-\delta}$$

$$\text{Var}(P_t) = \frac{\sigma^2_\eta + \sigma^2_\varepsilon - 2\sigma_{\varepsilon\eta}}{(\beta-\delta)^2}$$

Por el teorema de Slutsky:
$$\hat\beta^{OLS} \xrightarrow{p} \beta + \frac{\text{Cov}(P,\varepsilon)}{\text{Var}(P)} = \beta + (\beta-\delta)\cdot\frac{\sigma^2_\varepsilon - \sigma_{\varepsilon\eta}}{\sigma^2_\eta + \sigma^2_\varepsilon - 2\sigma_{\varepsilon\eta}}$$

**Con shocks independientes ($\sigma_{\varepsilon\eta}=0$):**
$$\boxed{\ \hat\beta^{OLS} \xrightarrow{p} \ \beta + (\beta-\delta)\cdot\underbrace{\frac{\sigma^2_\varepsilon}{\sigma^2_\eta + \sigma^2_\varepsilon}}_{\equiv\, \lambda\, \in [0,1]} \ = \ (1-\lambda)\beta + \lambda\delta\ }$$

**Interpretación (este es el resultado central y S03 no lo escribe así):** OLS converge a una **media ponderada de la pendiente de demanda y la pendiente de oferta**, con pesos dados por la importancia relativa de los shocks.

- Si solo la oferta se mueve ($\sigma^2_\varepsilon = 0 \Rightarrow \lambda=0$): $\hat\beta \to \beta$. OLS recupera demanda. (Escenario A de S03.)
- Si solo la demanda se mueve ($\sigma^2_\eta = 0 \Rightarrow \lambda=1$): $\hat\beta \to \delta$. OLS recupera **oferta**. (Escenario B.)
- En general: $\hat\beta$ está **entre** $\beta$ y $\delta$, y no es ninguna de las dos. (Escenario C.)

Como $\delta > 0 > \beta$, el estimador OLS está sesgado **hacia arriba** (hacia cero o hacia valores positivos), que es exactamente lo que se observa en Fulton: OLS da $+0.18$ cuando la verdad es $-0.92$.

**El cociente de varianzas $\lambda$ es la medida exacta de cuánto sesgo esperar.** En mercados agrícolas con clima volátil, $\lambda$ es bajo y OLS no está tan mal. En mercados de consumo con promociones y estacionalidad fuerte (gaseosas, retail), $\lambda \to 1$ y OLS es inútil o peor.

---

## 3. Condiciones de orden y rango

### 3.1 El sistema con exógenas

$$\begin{aligned}
\text{(D)}\quad Q_t &= \alpha + \beta P_t + \Gamma_D' X^D_t + \varepsilon_t\\
\text{(S)}\quad Q_t &= \gamma + \delta P_t + \Gamma_S' X^S_t + \eta_t
\end{aligned}$$

> **Condición de orden (necesaria).** La ecuación de demanda está identificada si el número de variables exógenas **excluidas** de ella (es decir, que están en oferta pero no en demanda) es **al menos igual** al número de variables endógenas del lado derecho.
>
> $$\#\{X^S \setminus X^D\} \ \ge\ \#\{\text{endógenas}\} = 1$$

> **Condición de rango (necesaria y suficiente).** Sea $\Pi$ la matriz de coeficientes de la forma reducida de las endógenas sobre todas las exógenas. La demanda está identificada si y solo si la submatriz de $\Pi$ correspondiente a los instrumentos excluidos tiene **rango completo**.
>
> $$\text{rank}\big(E[Z_t X_t']\big) = \dim(X_t)$$

**Traducción práctica:** la condición de orden es "contar instrumentos"; la condición de rango es "que los instrumentos realmente muevan el precio de forma linealmente independiente". **Instrumentos débiles son una violación aproximada de la condición de rango** — ver §5.

### 3.2 Caso de sobreidentificación

Si $\#\{X^S\setminus X^D\} > 1$, la ecuación está **sobreidentificada**: hay más momentos que parámetros. Esto permite:
- Testear la validez conjunta (Sargan–Hansen $J$).
- Ganar eficiencia (GMM óptimo).
- Pero **no** testear la validez de cada instrumento por separado — si todos son inválidos en la misma dirección, el test $J$ pasa alegremente. S04 lo advierte y es correcto.

---

## 4. IV como GMM: la estructura unificadora

### 4.1 La condición de momento

Todo lo que hacemos en este manual es GMM con la condición de momento
$$E[Z_t' \,\varepsilon_t(\theta_0)] = 0$$

| Modelo | $\varepsilon_t(\theta)$ | $Z_t$ |
|---|---|---|
| Demanda ecuación única (S04) | $\ln Q_t - \alpha - \beta \ln P_t$ | costo, clima, impuesto |
| AIDS (S05) | $w_{it} - \alpha_i - \sum\gamma_{ij}\ln p_j - \beta_i\ln(X/P)$ | precios en otros mercados |
| Logit agregado (S07) | $\ln s_{jt}-\ln s_{0t} - x'\beta + \alpha p_{jt}$ | Hausman, BLP |
| Nested logit (S07) | ídem $- \sigma \ln s_{j|g}$ | + conteo de productos en nest |
| BLP (Cap. 06) | $\xi_{jt}(\theta_2)$ vía contracción | BLP + diferenciación |
| Markup/conducta (Cap. 07) | residual de la FOC de oferta | rotadores de demanda |

**Estimador GMM:**
$$\hat\theta = \arg\min_\theta\ \Big[\tfrac1T\sum_t Z_t'\varepsilon_t(\theta)\Big]' \,W\, \Big[\tfrac1T\sum_t Z_t'\varepsilon_t(\theta)\Big]$$

Con $W = (Z'Z)^{-1}$ y $\varepsilon$ lineal en $\theta$, esto **es exactamente 2SLS**:
$$\hat\theta_{2SLS} = (X'P_Z X)^{-1}X'P_Z y, \qquad P_Z = Z(Z'Z)^{-1}Z'$$

**Peso óptimo:** $W^* = \big(E[Z'\varepsilon\varepsilon'Z]\big)^{-1} = \hat\Omega^{-1}$, que da GMM de dos etapas. Bajo homocedasticidad coinciden con 2SLS; bajo heterocedasticidad, GMM óptimo es más eficiente (pero con sesgo de muestra finita peor — hay un trade-off real y en muestras de menos de ~500 observaciones es común preferir 2SLS).

### 4.2 Distribución asintótica
$$\sqrt{T}(\hat\theta - \theta_0) \xrightarrow{d} N\big(0, (G'WG)^{-1}G'W\Omega W G (G'WG)^{-1}\big)$$
con $G = E[\partial \varepsilon/\partial\theta' \cdot Z]$. Con $W=\Omega^{-1}$ esto colapsa a $(G'\Omega^{-1}G)^{-1}$, la cota de eficiencia.

> **⚠️ Trampa.** Hacer 2SLS "a mano" en dos regresiones da los coeficientes correctos pero **errores estándar incorrectos** (la segunda etapa no sabe que $\hat P$ fue estimado). S03 lo menciona; la razón es que la varianza correcta usa el residual estructural $Q - \alpha - \beta P$ (con $P$ real), no $Q - \alpha - \beta\hat P$. Usar siempre `ivreg2`/`feols`/`IV2SLS`.

---

## 5. Instrumentos débiles: la teoría que S03 resume en "F > 10"

### 5.1 Por qué es un problema serio

Con un instrumento y una endógena, el estimador IV es un **cociente de dos estimadores**:
$$\hat\beta_{IV} = \frac{\widehat{\text{Cov}}(Z,Q)}{\widehat{\text{Cov}}(Z,P)}$$

Si el denominador es cercano a cero, el estimador tiene una distribución con **colas pesadas**; de hecho, cuando $\pi_1 = 0$ exactamente, $\hat\beta_{IV}$ sigue una distribución de **Cauchy**, que no tiene media ni varianza. La aproximación normal falla catastróficamente.

**Resultado de sesgo (Bound, Jaeger y Baker 1995; Staiger y Stock 1997):**
$$\frac{E[\hat\beta_{IV}] - \beta}{E[\hat\beta_{OLS}]-\beta} \approx \frac{1}{F + 1}$$

donde $F$ es el estadístico $F$ de la primera etapa. **Con $F=1$, el sesgo de IV es la mitad del de OLS. Con $F=10$, es ~9%.** De ahí la regla de dedo de S03.

### 5.2 La regla de 10 ya no es el estándar

> **Resultado (Lee, McCrary, Moreira y Porter 2022, *AER*).** Para que un test $t$ convencional al 5% tenga tamaño correcto bajo instrumentos potencialmente débiles, se necesita
> $$\boxed{F > 104.7}$$

Esto no es una curiosidad: significa que una fracción grande de los papers publicados con $F \in (10, 100)$ reportan intervalos de confianza con cobertura real muy por debajo del 95%.

**Qué hacer en la práctica (jerarquía recomendada):**

1. **Reportar siempre el $F$ efectivo de Montiel Olea–Pflueger (2013)**, que es robusto a heterocedasticidad y clustering. En Stata: `weakivtest`. Es lo que piden los referees hoy.
2. **Si $F < 100$**, reportar inferencia robusta a instrumentos débiles:
   - **Anderson–Rubin (AR):** test de $H_0: \beta=\beta_0$ regresando $(Q - \beta_0 P)$ sobre $Z$ y testeando que los coeficientes sean cero. **Tiene tamaño correcto con cualquier fuerza de instrumento**, incluso $\pi=0$. Su desventaja es poca potencia con muchos instrumentos.
   - **Conditional Likelihood Ratio (Moreira 2003):** óptimo en el caso de un endógeno.
   - El intervalo de confianza AR se construye invirtiendo el test; puede ser **vacío** (señal de rechazo del modelo) o **toda la recta real** (señal de instrumento sin información). Ambos resultados son informativos y deben reportarse.
3. **LIML en lugar de 2SLS** si hay muchos instrumentos: LIML es mediana-insesgado y menos sensible al sesgo de muchos instrumentos, aunque tiene colas más pesadas.

```stata
* Protocolo completo de diagnóstico de IV
ivreg2 lnq (lnp = z1 z2) x1 x2, robust first
weakivtest                    // F efectivo Montiel Olea-Pflueger
weakiv, strong                // AR y CLR con intervalos robustos
estat overid                  // Hansen J (solo si sobreidentificado)
estat endogenous              // Durbin-Wu-Hausman
```

```r
library(ivmodel); library(fixest)
m  <- feols(lnq ~ x1 + x2 | 0 | lnp ~ z1 + z2, data = d)
fitstat(m, c("ivf", "ivwald", "sargan"))
# Anderson-Rubin:
iv <- ivmodel(Y = d$lnq, D = d$lnp, Z = cbind(d$z1, d$z2), X = cbind(d$x1, d$x2))
AR.test(iv)            # intervalo robusto a instrumentos débiles
```

### 5.3 El problema de **muchos** instrumentos

En BLP (Cap. 06) es común tener 20–50 instrumentos. Entonces aparece un sesgo distinto: con $K$ instrumentos y $N$ observaciones, si $K/N \not\to 0$ el 2SLS es inconsistente (sesgo hacia OLS). Soluciones: LIML, JIVE, o la recomendación moderna de **Gandhi–Houde (2019)**: usar pocos instrumentos pero *bien construidos* (diferencias de características), no muchos arbitrarios.

---

## 6. Identificación de la **conducta**: el paso que falta en S03

Esto es lo que distingue la OI de la econometría de demanda. Supongamos que ya identificamos la demanda. ¿Podemos identificar si el mercado es competitivo, de Cournot o colusivo?

### 6.1 El modelo de parámetro de conducta

$$P = c(Q) + \theta\cdot\frac{Q}{|dQ/dP|} \quad\Longleftrightarrow\quad \frac{P - mc}{P} = \frac{\theta}{|\varepsilon|}$$

| $\theta$ | Conducta |
|---|---|
| $0$ | Competencia perfecta ($P = mc$) |
| $1/N$ | Cournot con $N$ firmas simétricas |
| $1$ | Monopolio / cartel perfecto |

La pregunta: ¿está $\theta$ identificado?

### 6.2 El resultado de imposibilidad (Bresnahan 1982; Lau 1982)

> **Teorema.** Con demanda de la forma $Q = \alpha_0 + \alpha_1 P + \alpha_2 Y + \varepsilon$ (sin interacciones), el parámetro de conducta $\theta$ **no está identificado** por separado del costo marginal: toda combinación $(\theta, mc)$ que produzca el mismo precio observado es observacionalmente equivalente.

**Demostración (intuición).** La ecuación de oferta estimada es
$$P = c_0 + c_1 Q + \frac{\theta Q}{-\alpha_1}$$
El coeficiente estimado sobre $Q$ es $c_1 + \theta/(-\alpha_1)$. Como $c_1$ es desconocido, no se puede separar de $\theta$. **Un markup alto puede ser poder de mercado o costos marginales crecientes.** $\blacksquare$

### 6.3 La solución: rotadores de demanda

> **Teorema (Bresnahan 1982).** Si la demanda incluye una **interacción** entre precio y un shifter exógeno $Z$,
> $$Q = \alpha_0 + \alpha_1 P + \alpha_2 Y + \alpha_3 (P\cdot Z) + \varepsilon$$
> entonces $\theta$ **sí** está identificado.

**Por qué funciona.** Ahora la pendiente de la demanda depende de $Z$: $\partial Q/\partial P = \alpha_1 + \alpha_3 Z$. La ecuación de oferta es
$$P = c_0 + c_1 Q - \frac{\theta Q}{\alpha_1 + \alpha_3 Z}$$
El término de markup varía con $Z$ de forma **no lineal**, mientras que el costo marginal $c_1 Q$ no. Esa diferencia en la forma funcional es lo que separa ambos.

**Intuición geométrica:** un *shifter* de demanda desplaza la curva paralelamente —y genera una sola ecuación nueva, que no basta. Un **rotador** cambia la pendiente, y con ella el markup óptimo, manteniendo el costo. Observar cómo responde el precio a la rotación revela $\theta$.

**Qué sirve como rotador en la práctica:**
- Variables que cambian la elasticidad: presencia de un sustituto cercano, entrada de un competidor, cambio de la composición de compradores.
- Cambios regulatorios que afectan la sensibilidad al precio (etiquetado, información).
- En paneles: interacción precio × demografía del mercado.

> **🇵🇪 Perú.** La entrada escalonada de cadenas de farmacias a ciudades intermedias, o la expansión de supermercados a provincias, rota la demanda local (aumenta la elasticidad al haber alternativas) sin cambiar el costo mayorista. Es un rotador casi ideal y está documentado en registros de SUNAT/Produce.

### 6.4 La crítica de Corts (1999)

> **Corts (1999)** muestra que si las firmas sostienen colusión mediante estrategias dinámicas (castigos), el $\theta$ estimado **no corresponde a ningún concepto de equilibrio estático**. Un cartel que ajusta su markup a lo largo del ciclo (Rotemberg–Saloner, Cap. 08) genera un $\theta$ estimado sesgado hacia abajo: parece más competitivo de lo que es.

**Conclusión metodológica:** el parámetro de conducta es una medida descriptiva útil, no un test de colusión. Para detectar colusión se usan los métodos del Cap. 08 (screens, cambios de régimen, estructura de pujas).

### 6.5 El enfoque moderno: testear modelos, no estimar $\theta$

**Berry y Haile (2014), "Identification in Differentiated Products Markets Using Market Level Data" (*Econometrica*)**: con instrumentos adecuados, la demanda está identificada **no paramétricamente**. Y luego:

**Berry y Haile (2014) / Backus, Conlon y Sinkinson (2021):** en lugar de estimar $\theta$, se **testean modelos específicos** (Bertrand vs. cartel vs. Cournot) comparando los costos marginales implicados por cada uno con shifters de costo observados. El modelo correcto es el que produce $mc$ que se correlaciona apropiadamente con los costos observados.

```
Para cada modelo de conducta m ∈ {Bertrand, Cournot, Cartel}:
  1. Estimar demanda (independiente de m)
  2. Invertir la FOC de m para obtener mc^m_jt
  3. Regresar mc^m_jt sobre shifters de costo observados w_t
  4. Testear si los residuales son ortogonales a instrumentos de rotación
El modelo que no se rechaza es el consistente con los datos.
```

Esto es el estándar actual y es lo que haría un informe económico sólido ante INDECOPI.

---

## 7. Control functions: la alternativa a 2SLS

Cuando el modelo es **no lineal en la endógena** (logit, probit, demanda con precios en logs e interacciones), 2SLS no funciona: "sustituir $\hat P$" es inválido en modelos no lineales (el *forbidden regression* problem).

**Enfoque de función de control (Petrin y Train 2010):**

1. Primera etapa: $P_{jt} = \pi' Z_{jt} + \nu_{jt}$ → guardar residuales $\hat\nu_{jt}$.
2. Segunda etapa: incluir $\hat\nu_{jt}$ **como regresor adicional** en el modelo no lineal.
3. La endogeneidad se absorbe en el control; el coeficiente de precio queda consistente.

**Supuesto adicional requerido:** $\xi_{jt} = \lambda \nu_{jt} + \tilde\xi_{jt}$ con $\tilde\xi \perp (Z,\nu)$. Es decir, la endogeneidad entra de forma **separable**. Esto es más fuerte que el supuesto de momentos de IV, y es el precio de poder usar un modelo no lineal.

**Errores estándar:** hay que bootstrapear (o usar la corrección de dos etapas de Murphy–Topel) porque $\hat\nu$ es generado.

| | IV / 2SLS | Control Function |
|---|---|---|
| Supuesto | $E[Z\varepsilon]=0$ (débil) | Separabilidad del error (fuerte) |
| Modelos | Lineales | Lineales y **no lineales** |
| Errores estándar | Analíticos | Bootstrap |
| Uso en OI | BLP, logit agregado | Mixed logit con micro-datos, demanda con precios endógenos no lineales |

---

## 8. Taxonomía completa de estrategias de identificación

| Estrategia | Supuesto clave | Ejemplo en OI | Capítulo |
|---|---|---|---|
| **IV / instrumentos de costo** | Exclusión | Fulton (altura de olas); precios de insumos | 03 |
| **Instrumentos Hausman** | Shocks de demanda no correlacionados entre mercados | Nevo (2001), cereales | 03, 06 |
| **Instrumentos BLP** | Características de rivales exógenas | BLP (1995), autos | 06 |
| **Instrumentos de diferenciación** | ídem, mejor construidos | Gandhi–Houde (2019) | 06 |
| **Diferencias en diferencias** | Tendencias paralelas | Entrada de un competidor | 09, 13 |
| **Discontinuidad en regresión** | Continuidad en el umbral | Umbrales regulatorios, UIT | 13, 15 |
| **Experimento de campo** | Aleatorización | Pruebas A/B de precios | 10, 14 |
| **Variación de panel + efectos fijos** | Shocks idiosincrásicos no correlacionados con FE | Scanner data | 06 |
| **Restricciones de equilibrio** | El modelo es correcto | BLP: FOC de oferta como momento adicional | 06, 07 |
| **Identificación por conjuntos (set id.)** | Desigualdades de momentos | Modelos de entrada (Ciliberto–Tamer) | 15 |

---

## 9. Checklist de identificación para cualquier paper

Antes de estimar, responde por escrito:

- [ ] ¿Cuál es exactamente el parámetro que quiero identificar? (Escríbelo.)
- [ ] ¿Cuál es la fuente de variación que lo identifica? (Una frase, sin jerga.)
- [ ] ¿Qué historia tendría que ser cierta para que mi instrumento falle? ¿Es plausible?
- [ ] ¿Cuál es el $F$ efectivo (Montiel Olea–Pflueger) de la primera etapa?
- [ ] Si $F < 100$: ¿reporté intervalos Anderson–Rubin?
- [ ] ¿El signo y la magnitud de la primera etapa tienen sentido económico?
- [ ] Si sobreidentificado: ¿pasa Hansen $J$? (Y entiendo que pasarlo no prueba validez.)
- [ ] ¿Comparé OLS vs. IV y la dirección del sesgo es la que la teoría predice?
- [ ] ¿Probé un instrumento alternativo y los resultados son similares?
- [ ] ¿Un crítico hostil podría proponer un canal directo $Z \to Q$? ¿Qué le respondo?

> **La prueba del seminario.** Si no puedes responder a "¿por qué ese instrumento?" en 30 segundos, sin fórmulas y convenciendo a un economista escéptico, no tienes identificación. Tienes una regresión.

---

## 10. Lecturas

**Fundamentales**
- Angrist y Pischke (2009), *Mostly Harmless Econometrics*, cap. 4.
- Wooldridge (2010), *Econometric Analysis of Cross Section and Panel Data*, caps. 5, 6, 9.

**Instrumentos débiles**
- Staiger y Stock (1997), *Econometrica* 65(3).
- Moreira (2003), "A Conditional Likelihood Ratio Test for Structural Models", *Econometrica* 71(4).
- Montiel Olea y Pflueger (2013), "A Robust Test for Weak Instruments", *JBES* 31(3).
- Lee, McCrary, Moreira y Porter (2022), "Valid *t*-ratio Inference for IV", *AER* 112(10).

**Identificación de conducta**
- Bresnahan (1982), "The Oligopoly Solution Concept is Identified", *Economics Letters* 10.
- Lau (1982), "On Identifying the Degree of Competitiveness", *Economics Letters* 10.
- Corts (1999), "Conduct Parameters and the Measurement of Market Power", *Journal of Econometrics* 88.
- Berry y Haile (2014), "Identification in Differentiated Products Markets", *Econometrica* 82(5).
- Backus, Conlon y Sinkinson (2021), "Common Ownership and Competition in the Ready-to-Eat Cereal Industry", NBER WP.

**Control functions**
- Petrin y Train (2010), "A Control Function Approach to Endogeneity in Consumer Choice Models", *JMR* 47(1).
