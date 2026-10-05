# 04 · Sistemas de demanda: AIDS, QUAIDS y más allá

> **Extiende S05.** El curso deriva AIDS en un apéndice y lo estima. Aquí: la derivación completa desde PIGLOG paso a paso, la demostración de las tres elasticidades, el sesgo del índice de Stone, QUAIDS y EASI, separabilidad y presupuestación en dos etapas, censura, el test de todas las restricciones, y las simulaciones de política correctas.

---

## 1. La idea

Una ecuación única trata al bien como si viviera solo. Un sistema de demanda impone que los bienes **compitan por el mismo presupuesto**: la restricción $\sum_i w_i = 1$ ata todas las ecuaciones, y la teoría del consumidor impone simetría entre efectos cruzados. El costo es que hay que observar precios y gastos de **todos** los bienes del sistema; el beneficio es una matriz de sustitución completa, consistente, e interpretable en términos de bienestar.

**La decisión de diseño es el número de bienes.** Con $n$ bienes, AIDS tiene $n(n+2)$ parámetros sin restricciones. Con $n=4$: 24. Con $n=10$: 120. Con $n=50$: 2,600. Por eso el sistema se usa para **categorías agregadas** (carnes, lácteos, cereales) y la elección discreta para **variedades** (Cap. 05–06).

---

## 2. Derivación completa de AIDS

### 2.1 El punto de partida: PIGLOG

Deaton y Muellbauer parten de la clase PIGLOG de funciones de gasto:
$$\ln e(u,p) = (1-u)\ln a(p) + u \ln b(p), \qquad u\in[0,1]$$

con
$$\ln a(p) = \alpha_0 + \sum_i \alpha_i \ln p_i + \tfrac{1}{2}\sum_i\sum_j \gamma^*_{ij}\ln p_i \ln p_j$$
$$\ln b(p) = \ln a(p) + \beta_0\prod_i p_i^{\beta_i}$$

**Interpretación.** $a(p)$ es el costo de subsistencia ($u=0$); $b(p)$ es el costo de la "vida de lujo" ($u=1$); la utilidad interpola logarítmicamente entre ambos. $\ln a(p)$ es una **translog**: una aproximación de segundo orden a *cualquier* función de precios. De ahí "almost ideal": flexible de segundo orden y con agregación exacta.

### 2.2 Paso 1 — Aplicar Shephard en logs

$$w_i = \frac{\partial \ln e(u,p)}{\partial \ln p_i}$$

Derivando:
$$\frac{\partial \ln e}{\partial \ln p_i} = (1-u)\frac{\partial \ln a}{\partial \ln p_i} + u\frac{\partial \ln b}{\partial \ln p_i}$$

Calculamos cada pieza:
$$\frac{\partial \ln a}{\partial \ln p_i} = \alpha_i + \tfrac12\sum_j(\gamma^*_{ij}+\gamma^*_{ji})\ln p_j \equiv \alpha_i + \sum_j \gamma_{ij}\ln p_j$$
donde definimos $\gamma_{ij}\equiv\tfrac12(\gamma^*_{ij}+\gamma^*_{ji})$ — **simétrico por construcción**.

$$\frac{\partial \ln b}{\partial \ln p_i} = \frac{\partial \ln a}{\partial \ln p_i} + \beta_i\,\beta_0\prod_k p_k^{\beta_k}$$

Sustituyendo:
$$w_i = \alpha_i + \sum_j \gamma_{ij}\ln p_j + u\,\beta_i\,\beta_0\prod_k p_k^{\beta_k}$$

### 2.3 Paso 2 — Eliminar la utilidad no observada

De la función de gasto, en el óptimo $e(u,p)=X$, por lo que
$$\ln X = \ln a(p) + u\,\beta_0\prod_k p_k^{\beta_k} \quad\Longrightarrow\quad u\,\beta_0\prod_k p_k^{\beta_k} = \ln X - \ln a(p)$$

Sustituyendo en la expresión de $w_i$:
$$\boxed{\ w_i = \alpha_i + \sum_j \gamma_{ij}\ln p_j + \beta_i\ln\!\Big(\frac{X}{a(p)}\Big)\ }$$

**Esta es la ecuación de participación de AIDS.** Observe que el argumento es el **gasto real** $X/a(p)$: ingreso nominal deflactado por un índice de precios que es él mismo función de los parámetros. $\blacksquare$

### 2.4 Paso 3 — Las restricciones como consecuencias

| Restricción | Deriva de | En parámetros |
|---|---|---|
| Adding-up | $\sum_i w_i = 1$ idénticamente en $(p,X)$ | $\sum_i\alpha_i=1$; $\sum_i\gamma_{ij}=0\ \forall j$; $\sum_i\beta_i=0$ |
| Homogeneidad | $e(u,\lambda p)=\lambda e(u,p)$ | $\sum_j\gamma_{ij}=0\ \forall i$ |
| Simetría | $\partial^2 e/\partial p_i\partial p_j$ simétrica (Young) | $\gamma_{ij}=\gamma_{ji}$ |

**Demostración de homogeneidad.** Si todos los precios y el gasto se multiplican por $\lambda$:
$$w_i' = \alpha_i + \sum_j\gamma_{ij}(\ln p_j + \ln\lambda) + \beta_i\big[\ln X + \ln\lambda - \ln a(\lambda p)\big]$$
Como $\ln a(\lambda p) = \ln a(p) + \ln\lambda$ (homogeneidad de grado 1 de $a$, que a su vez requiere $\sum_i\alpha_i=1$ y $\sum_j\gamma_{ij}=0$), el término de $\beta_i$ no cambia. Queda $w_i' = w_i + \ln\lambda\sum_j\gamma_{ij}$, que es igual a $w_i$ si y solo si $\sum_j\gamma_{ij}=0$. $\blacksquare$

**Esto es "ausencia de ilusión monetaria"**: duplicar todos los precios y el ingreso no debe cambiar nada real. Un sistema estimado que rechaza la homogeneidad está diciendo que el consumidor sufre de ilusión monetaria, o —más probablemente— que la especificación está mal (variables omitidas, dinámica no modelada, agregación inapropiada).

---

## 3. El índice de precios y el sesgo de la aproximación lineal

### 3.1 El problema

El índice exacto
$$\ln a(p) = \alpha_0 + \sum_i\alpha_i\ln p_i + \tfrac12\sum_i\sum_j\gamma_{ij}\ln p_i\ln p_j$$
contiene los parámetros que queremos estimar → el modelo es **no lineal en parámetros**.

### 3.2 La aproximación de Stone y su sesgo

**Índice de Stone:** $\ln P^* = \sum_k w_k \ln p_k$. Con él, el modelo es lineal y se estima por SUR. Esto es LA-AIDS.

> **⚠️ El sesgo que S05 no menciona.** $w_k$ aparece en el índice y es la **variable dependiente** del sistema. Esto introduce **simultaneidad mecánica**: el error de la ecuación $i$ está correlacionado con $\ln P^*$ a través de $w_i$. El sesgo resultante (documentado por Moschini 1995, Buse 1994) puede ser sustancial, especialmente en $\hat\beta_i$.

**Soluciones, en orden de preferencia:**

1. **Estimar el AIDS exacto por NLSUR.** Hoy es computacionalmente trivial (`nlsur` en Stata, `micEconAids` con `priceIndex="T"` en R). **No hay excusa moderna para LA-AIDS.**
2. **Índice de Stone corregido (Moschini 1995):** usar participaciones **medias** $\bar w_k$ (fijas, no por observación): $\ln P^* = \sum_k \bar w_k\ln p_k$. Elimina la simultaneidad a costa de una aproximación peor.
3. **Índice de Laspeyres o Tornqvist** con participaciones del periodo base.
4. **Rezagar las participaciones** en el índice: $\ln P^*_t = \sum_k w_{k,t-1}\ln p_{kt}$.

**La recomendación:** estimar el exacto, reportar LA-AIDS como robustez, y mostrar que las elasticidades no cambian materialmente. Si cambian, el paper tiene que reportar el exacto.

---

## 4. De parámetros a elasticidades: las tres demostraciones

Las fórmulas de S05 se dan sin derivar. Aquí están.

### 4.1 Elasticidad-gasto

Partimos de $w_i = p_i q_i / X$, es decir $\ln w_i = \ln p_i + \ln q_i - \ln X$. Derivando respecto de $\ln X$ a precios constantes:
$$\frac{\partial \ln w_i}{\partial \ln X} = \frac{\partial \ln q_i}{\partial \ln X} - 1 = \eta_i - 1$$

Por otro lado, de la ecuación AIDS, $\partial w_i/\partial \ln X = \beta_i$, y como $\partial \ln w_i/\partial\ln X = (1/w_i)\,\partial w_i/\partial\ln X$:
$$\frac{\partial\ln w_i}{\partial \ln X} = \frac{\beta_i}{w_i}$$

Igualando:
$$\boxed{\ \eta_i = 1 + \frac{\beta_i}{w_i}\ } \qquad \blacksquare$$

**Lectura:** $\beta_i > 0$ significa que la participación sube con el gasto real → **bien de lujo** ($\eta_i > 1$). En S05, el pollo tiene $\beta = 0.093 > 0$ y $\bar w = 0.15$, dando $\eta = 1 + 0.093/0.15 = 1.62$. La "revolución del pollo" en EE.UU. aparece en el parámetro.

### 4.2 Elasticidad-precio no compensada (Marshalliana)

De $\ln q_i = \ln w_i + \ln X - \ln p_i$, derivando respecto de $\ln p_j$:
$$\varepsilon_{ij} = \frac{\partial \ln w_i}{\partial \ln p_j} - \delta_{ij}$$
donde $\delta_{ij}$ es la delta de Kronecker (el término $-\ln p_i$ solo aparece cuando $j=i$).

Ahora, $\partial w_i/\partial \ln p_j$ de la ecuación AIDS tiene **dos** términos: el directo $\gamma_{ij}$, y el indirecto vía el índice de precios dentro de $\ln(X/a(p))$:
$$\frac{\partial w_i}{\partial \ln p_j} = \gamma_{ij} + \beta_i\cdot\frac{\partial\big[\ln X - \ln a(p)\big]}{\partial \ln p_j} = \gamma_{ij} - \beta_i\,\frac{\partial \ln a(p)}{\partial\ln p_j} = \gamma_{ij} - \beta_i\, w_j$$

(usando que $\partial\ln a/\partial\ln p_j \approx w_j$ en el óptimo).

Dividiendo por $w_i$ y restando $\delta_{ij}$:
$$\boxed{\ \varepsilon_{ij} = -\delta_{ij} + \frac{\gamma_{ij}}{w_i} - \beta_i\frac{w_j}{w_i}\ }$$

Para el caso propio ($j=i$): $\varepsilon_{ii} = -1 + \gamma_{ii}/w_i - \beta_i$. $\blacksquare$

**De dónde viene el "$-1$":** del término $-\ln p_i$ en $\ln q_i = \ln w_i + \ln X - \ln p_i$. Si la participación se mantuviera constante ante un alza de precio, la cantidad caería exactamente en proporción inversa al precio — elasticidad unitaria. Las desviaciones de $-1$ vienen del ajuste de la participación.

### 4.3 Elasticidad compensada (Hicksiana) vía Slutsky

Aplicando la ecuación de Slutsky en elasticidades (Cap. 01 §2.2):
$$\varepsilon^H_{ij} = \varepsilon_{ij} + \eta_i w_j = -\delta_{ij} + \frac{\gamma_{ij}}{w_i} - \beta_i\frac{w_j}{w_i} + \Big(1+\frac{\beta_i}{w_i}\Big)w_j = -\delta_{ij} + \frac{\gamma_{ij}}{w_i} + w_j$$

$$\boxed{\ \varepsilon^H_{ij} = -\delta_{ij} + \frac{\gamma_{ij}}{w_i} + w_j\ }$$

Y el elemento de la matriz de Slutsky en participaciones es $s_{ij} = w_i\varepsilon^H_{ij}/\,$… en la forma que se usa para testear negatividad:
$$s_{ij} = \gamma_{ij} + w_i w_j - \delta_{ij}w_i \ (+\ \beta_i\beta_j\ln(X/P) \text{ en la versión exacta})$$

> **⚠️ Para análisis antimonopolio esto es decisivo.** Un informe que concluya "son sustitutos" basándose en $\varepsilon_{ij}>0$ Marshalliana está usando el concepto correcto para un test SSNIP. Pero si la pregunta es sobre **sustituibilidad en bienestar** (¿pierde mucho el consumidor si desaparece un producto?), hay que usar la Hicksiana. En S05, la res y el pollo tienen $\varepsilon_{ij}$ Marshalliana ligeramente positiva (0.01–0.08) pero $\varepsilon^H_{ij}$ sustancialmente más positiva (al sumar $w_j \approx 0.15$–$0.42$). **La conclusión sobre sustituibilidad cambia de "casi independientes" a "sustitutos claros".**

---

## 5. QUAIDS: cuando las curvas de Engel no son lineales

### 5.1 El modelo

Banks, Blundell y Lewbel (1997) añaden un término cuadrático manteniendo integrabilidad:
$$w_i = \alpha_i + \sum_j\gamma_{ij}\ln p_j + \beta_i\ln\!\Big(\frac{X}{a(p)}\Big) + \frac{\lambda_i}{b(p)}\Big[\ln\!\Big(\frac{X}{a(p)}\Big)\Big]^2$$

donde $b(p)=\prod_i p_i^{\beta_i}$ es el agregador de Cobb–Douglas.

**Restricción adicional:** $\sum_i\lambda_i=0$.

**Interpretación de $\lambda_i$:** permite que un bien sea de lujo en niveles bajos de ingreso y necesidad en niveles altos (o viceversa). Es exactamente lo que ocurre con la carne, el transporte y la educación en países de ingreso medio.

### 5.2 Elasticidades en QUAIDS

$$\mu_i \equiv \frac{\partial w_i}{\partial \ln X} = \beta_i + \frac{2\lambda_i}{b(p)}\ln\Big(\frac{X}{a(p)}\Big)$$
$$\eta_i = 1 + \frac{\mu_i}{w_i}$$
$$\mu_{ij} \equiv \frac{\partial w_i}{\partial\ln p_j} = \gamma_{ij} - \mu_i\Big(\alpha_j+\sum_k\gamma_{jk}\ln p_k\Big) - \frac{\lambda_i\beta_j}{b(p)}\Big[\ln\frac{X}{a(p)}\Big]^2$$
$$\varepsilon_{ij} = \frac{\mu_{ij}}{w_i} - \delta_{ij}$$

**Nota clave:** $\eta_i$ ahora **depende del nivel de gasto**. Esto permite calcular elasticidades por decil — lo que es exactamente lo que necesita un análisis distributivo de un impuesto.

### 5.3 Test de la restricción

$H_0: \lambda_i = 0\ \forall i$ es un test de Wald o LR estándar. **En datos de hogares de países en desarrollo, se rechaza casi siempre.**

> **🇵🇪 Perú.** Estimar QUAIDS con ENAHO por decil, y calcular la incidencia distributiva del ISC a bebidas azucaradas, del IGV a alimentos procesados, o del subsidio al GLP (FISE), es un trabajo directo, de política pública relevante, y con resultados que serían nuevos. El código `quaids` de Stata (Poi 2012) lo hace con pesos muestrales.

---

## 6. Separabilidad y presupuestación en dos etapas

### 6.1 El problema de escala

Un sistema completo necesita precios de **todos** los bienes. Imposible con 200 categorías. La solución es la **separabilidad débil**:

$$U(q) = F\big(U_1(q^1), U_2(q^2), \dots, U_G(q^G)\big)$$

donde $q^g$ es el subvector de bienes del grupo $g$.

> **Teorema (Strotz 1957; Gorman 1959).** Si las preferencias son débilmente separables, la asignación **dentro** de cada grupo depende solo de los precios de ese grupo y del gasto total del grupo. Entonces se puede estimar:
> - **Etapa 1:** asignación del presupuesto total entre grupos (AIDS sobre índices de precios de grupo).
> - **Etapa 2:** asignación dentro de cada grupo (AIDS sobre precios del grupo).

### 6.2 Las elasticidades totales

La elasticidad total combina ambas etapas (Edgerton 1997):
$$\varepsilon^{\text{total}}_{ij} = \underbrace{\varepsilon^{\text{within}}_{ij}}_{\text{dentro del grupo}} + \underbrace{w_j^{g}\,\eta_i^{g}\,\big(1+\varepsilon^{\text{between}}_{gg}\big)}_{\text{vía reasignación entre grupos}}$$

**Error frecuente:** reportar solo la elasticidad within como si fuera la total. Subestima sistemáticamente la respuesta a cambios de precio grandes porque ignora que el consumidor también reasigna presupuesto entre categorías.

### 6.3 ¿Es testeable la separabilidad?

Parcialmente. La separabilidad débil implica restricciones no lineales sobre la matriz de Slutsky:
$$s_{ij} = \mu_g\, s_{ik} \cdot (\text{factor}) \quad \text{para } i\in g,\ j,k\notin g$$
Es decir, **todos los bienes de fuera del grupo deben afectar a los de dentro de forma proporcional**. Testeable pero con poca potencia. En la práctica se justifica con argumento económico (los grupos son categorías de consumo coherentes: alimentos, vivienda, transporte, ocio).

---

## 7. Estimación: detalles que importan

### 7.1 SUR, 3SLS y endogeneidad

**SUR (Zellner).** Explota la correlación de errores entre ecuaciones (que es necesariamente alta: $\sum_i u_i = 0$ por adding-up). Gana eficiencia sobre OLS ecuación por ecuación **solo si** los regresores difieren entre ecuaciones. En AIDS con las mismas variables en todas las ecuaciones y sin restricciones cruzadas, SUR = OLS. **Con restricciones de simetría impuestas (que son cruzadas), SUR sí gana.**

**El problema de la singularidad.** La matriz de covarianza de los errores es singular porque $\sum_i u_{it}=0$. **Solución: eliminar una ecuación**, estimar las $n-1$ restantes, y recuperar los parámetros de la eliminada por adding-up. Los resultados son **invariantes** a cuál se elimine (si se usa SUR iterado hasta convergencia / ML).

**3SLS para endogeneidad de precios.** S05 lo señala correctamente: SUR no resuelve la endogeneidad. Si los precios responden a shocks de demanda,
$$\text{Cov}(\ln p_j, u_i)\ne 0 \implies \hat\gamma_{ij}\ \text{sesgado}$$
La solución es 3SLS (= SUR + IV) con **un instrumento por cada precio endógeno**. En un sistema de 4 bienes, son 4 instrumentos. Esta es la razón práctica por la que la mayoría de los AIDS publicados no instrumentan: conseguir 4 instrumentos válidos es difícil.

> **Argumento para no instrumentar (y cuándo es válido).** Con datos de **hogares**, el hogar individual es tomador de precios: su shock de demanda idiosincrásico no mueve el precio de mercado. La endogeneidad desaparece. **Con datos agregados de mercado, no hay excusa: hay que instrumentar.** Declarar esto explícitamente en el paper es la diferencia entre un referee satisfecho y un rechazo.

### 7.2 Censura (ceros en datos de hogares)

Con microdatos, muchas $w_i=0$. El sistema de participaciones no está definido en el régimen de esquina.

**Método de Shonkwiler–Yen (1999), de dos pasos:**
1. Probit de participación: $\Pr(w_i>0) = \Phi(z_i'\theta_i)$ para cada bien.
2. Estimar el sistema con la corrección:
$$w_i = \Phi(z_i'\hat\theta_i)\Big[\alpha_i+\sum_j\gamma_{ij}\ln p_j+\beta_i\ln(X/P)\Big] + \delta_i\,\phi(z_i'\hat\theta_i)$$

Errores estándar por bootstrap. Implementado en `aidsills` (Stata).

**Alternativa moderna:** máxima verosimilitud simulada del sistema censurado completo (Yen, Lin y Smallwood 2003). Más correcto, más caro.

---

## 8. Simulación de política: cómo hacerlo bien

S05 presenta dos métodos para el shock de 25% al precio de la res. Aquí el procedimiento completo y sus trampas.

### 8.1 Procedimiento

```
Dado: parámetros estimados (α̂, γ̂, β̂), shares base w⁰, precios base p⁰, gasto X
Shock: p_beef sube 25% ⇒ ln p¹_beef = ln p⁰_beef + ln(1.25)

1. Actualizar el índice de precios:
   Δ ln P* = Σ_k w⁰_k · Δ ln p_k = w⁰_beef · ln(1.25)
   [con índice exacto: Δ ln a(p) = Σ_k(α_k + Σ_j γ_kj ln p_j)Δln p_k + términos cuadráticos]

2. Nuevas participaciones:
   w¹_i = α̂_i + Σ_j γ̂_ij ln p¹_j + β̂_i (ln X - ln P*¹)

3. Nuevas cantidades (de la definición de participación):
   q¹_i / q⁰_i = (w¹_i / w⁰_i) · (p⁰_i / p¹_i)

4. Para los bienes no afectados (p¹ = p⁰): %Δq_i = %Δw_i
```

### 8.2 Las tres trampas

> **⚠️ Trampa 1 — usar 0.25 en vez de ln(1.25).** La ecuación AIDS tiene $\ln p$. Un alza de 25% es $\Delta\ln p = \ln(1.25) = 0.2231$, no 0.25. Usar 0.25 **sobreestima la respuesta en ~12%**. S05 lo advierte; es el error más común en los ejercicios.

> **⚠️ Trampa 2 — olvidar el canal del gasto real.** Un alza del precio de un bien con participación grande (la res, con $w=0.42$ en S05) reduce el gasto real del sistema completo, lo que desplaza **todas** las participaciones vía $\beta_i$. Por eso en S05 el pollo cae ($-3.2\%$) a pesar de ser sustituto de la res: el efecto ingreso domina al de sustitución. Una simulación de ecuación única nunca habría visto esto.

> **⚠️ Trampa 3 — confundir $\Delta w$ con $\Delta q$.** La participación de la res **sube** (+0.006) mientras su cantidad **cae** 19%. No hay contradicción: demanda inelástica → el gasto sube. Reportar "la participación de la res aumentó" como si fuera un aumento de consumo es un error de lectura grave.

### 8.3 Bienestar del cambio

$$CV \approx X\cdot\Big[\exp\Big(\sum_i \bar w_i\,\Delta\ln p_i + \tfrac12\sum_i\sum_j \bar w_i\varepsilon^H_{ij}\Delta\ln p_i\Delta\ln p_j\Big) - 1\Big]$$

El primer término es la pérdida de primer orden (transferencia); el segundo, la pérdida de eficiencia por sustitución (siempre negativa en magnitud por negatividad de Slutsky). **Para cuantificar daño de cartel, el primer término es la transferencia a los coludidos y el segundo la pérdida social pura.**

---

## 9. Código completo

```r
library(micEconAids); library(systemfit)

# --- AIDS EXACTO (preferido) ----------------------------------------
aids <- aidsEst(
  priceNames = c("pBeef","pPork","pChicken","pOther"),
  shareNames = c("wBeef","wPork","wChicken","wOther"),
  totExpName = "xFood",
  data       = d,
  priceIndex = "T",        # "T" = translog exacto (iterativo); "S" = Stone
  method     = "IL",       # Iterated Linear Least Squares
  hom = TRUE, sym = TRUE   # imponer homogeneidad y simetría
)
summary(aids)
aidsElas(aids$coef, shares = colMeans(d[,shareNames]), method = "Ch")

# --- TEST DE RESTRICCIONES -------------------------------------------
a_u   <- aidsEst(..., hom = FALSE, sym = FALSE)   # irrestricto
a_h   <- aidsEst(..., hom = TRUE,  sym = FALSE)   # solo homogeneidad
a_hs  <- aidsEst(..., hom = TRUE,  sym = TRUE)    # ambas
aidsTestConsist(a_hs$coef, ...)                   # consistencia con la teoría
# LR: 2*(logLik(a_u) - logLik(a_hs)) ~ chi2(gl)

# --- NEGATIVIDAD (el test que nadie hace) ---------------------------
g <- aids$coef$gamma; b <- aids$coef$beta; w <- colMeans(d[,shareNames])
n <- length(w); S <- matrix(0,n,n)
for (i in 1:n) for (j in 1:n)
  S[i,j] <- g[i,j] + w[i]*w[j] - ifelse(i==j, w[i], 0)
round(eigen(S)$values, 4)       # deben ser ≤ 0
```

```stata
* QUAIDS con ENAHO, con pesos y por decil
quaids w1 w2 w3 w4, anot(10) prices(p1 p2 p3 p4) expenditure(gasto) ///
       demographics(nmiembros educjefe urbano) [pw = factor]
quaids_elas, atmeans
* Elasticidades por decil:
forvalues d = 1/10 {
    quaids_elas if decil == `d', atmeans
}
```

---

## 10. Cuándo NO usar AIDS

| Situación | Usar en su lugar |
|---|---|
| $J > 8$ productos | Elección discreta (Cap. 05–06) |
| Productos entran/salen | Elección discreta (dimensión fija se rompe) |
| Muchos ceros por hogar | QUAIDS censurado o elección discreta |
| Curvas de Engel no lineales | QUAIDS o EASI |
| Heterogeneidad de preferencias central | Mixed logit / BLP |
| Solo se observan market shares | Logit agregado (Cap. 06) |
| Bienes durables / decisión única | Elección discreta dinámica |

**EASI (Lewbel y Pendakur 2009)** merece mención: permite curvas de Engel de **cualquier forma** (polinomios de orden arbitrario), mantiene integrabilidad exacta, y es lineal en parámetros condicional al gasto real implícito. Es la frontera para análisis distributivo serio y está infrautilizado.

---

## 11. Lecturas

- Deaton y Muellbauer (1980), "An Almost Ideal Demand System", *AER* 70(3). **← el paper**
- Deaton y Muellbauer (1980), *Economics and Consumer Behavior*, caps. 1–5.
- Banks, Blundell y Lewbel (1997), "Quadratic Engel Curves and Consumer Demand", *RESTAT* 79(4).
- Lewbel y Pendakur (2009), "Tricks with Hicks: The EASI Demand System", *AER* 99(3).
- Moschini (1995), "Units of Measurement and the Stone Index in Demand System Estimation", *AJAE* 77(1).
- Shonkwiler y Yen (1999), "Two-Step Estimation of a Censored System of Equations", *AJAE* 81(4).
- Edgerton (1997), "Weak Separability and the Estimation of Elasticities in Multistage Demand Systems", *AJAE* 79(1).
- Poi (2012), "Easy Demand-System Estimation with quaids", *Stata Journal* 12(3).
