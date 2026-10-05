# 10 · Marketing cuantitativo

> **Capítulo nuevo.** El marketing académico moderno *es* organización industrial aplicada con datos de empresa. Comparte el modelo (logit, BLP), la econometría (IV, GMM) y el objeto (elasticidades, sustitución). Lo que añade: publicidad, promociones, lealtad, atención, búsqueda, segmentación y el valor del cliente. Este capítulo conecta ambos mundos y da las herramientas que convierten una estimación de demanda en una decisión de negocio.

---

## 1. La idea

La demanda que estimamos en los Caps. 03–06 toma como dados los precios y las características. El marketing pregunta: **¿y si la firma puede mover la demanda misma?**

$$s_j = f(\underbrace{p_j}_{\text{precio}},\ \underbrace{x_j}_{\text{producto}},\ \underbrace{a_j}_{\text{publicidad}},\ \underbrace{d_j}_{\text{distribución}},\ \underbrace{\xi_j}_{\text{marca}})$$

Las "4 P" clásicas (producto, precio, plaza, promoción) son exactamente los argumentos de la función de demanda estructural. La diferencia con la OI tradicional es que tres de ellas son **variables de decisión endógenas de la firma**, lo que multiplica los problemas de identificación.

---

## 2. Publicidad: la regla de Dorfman–Steiner

### 2.1 El resultado

> **Teorema (Dorfman y Steiner 1954).** El monopolista que elige precio y publicidad óptimamente satisface:
> $$\boxed{\ \frac{A}{pQ}=\frac{\varepsilon_A}{|\varepsilon_p|}\ }$$
> donde $A$ es el gasto en publicidad, $\varepsilon_A=\partial\ln Q/\partial\ln A$ la elasticidad publicidad de la demanda y $\varepsilon_p$ la elasticidad precio.

**Demostración.**
$$\max_{p,A}\ \pi=(p-c)\,Q(p,A)-A$$

CPO respecto de $A$:
$$(p-c)\frac{\partial Q}{\partial A}-1=0\ \Longrightarrow\ (p-c)\frac{\partial Q}{\partial A}=1$$

Multiplicando por $A/(pQ)$:
$$\frac{p-c}{p}\cdot\frac{A}{Q}\frac{\partial Q}{\partial A}=\frac{A}{pQ}\ \Longrightarrow\ \mathcal{L}\cdot\varepsilon_A=\frac{A}{pQ}$$

CPO respecto de $p$ (regla de Lerner): $\mathcal L = 1/|\varepsilon_p|$. Sustituyendo:
$$\frac{A}{pQ}=\frac{\varepsilon_A}{|\varepsilon_p|}\qquad\blacksquare$$

### 2.2 Por qué es la fórmula más útil del capítulo

**Es un diagnóstico inmediato.** Dada la intensidad publicitaria observada ($A/pQ$) y la elasticidad precio estimada, la regla **implica** la elasticidad publicitaria que justificaría ese gasto:
$$\varepsilon_A^{\text{implícita}}=\frac{A}{pQ}\times|\varepsilon_p|$$

**Ejemplo.** Una empresa de consumo masivo gasta 8% de ventas en publicidad y su elasticidad precio de marca es $-3$. Entonces $\varepsilon_A^{\text{implícita}}=0.08\times 3=0.24$.

**¿Es plausible 0.24?** Las meta-análisis de la literatura (Sethuraman, Tellis y Briesch 2011) encuentran elasticidades publicitarias de corto plazo con **mediana alrededor de 0.05–0.12** y de largo plazo alrededor de 0.2–0.25. Una elasticidad de corto plazo de 0.24 estaría muy por encima de lo típico.

**Conclusión del diagnóstico:** o la empresa sobre-invierte en publicidad, o está comprando efectos de largo plazo (construcción de marca) que el cálculo estático no captura. **En cualquier caso, es una conversación de board que la fórmula abre en 30 segundos.**

### 2.3 Generalización con competencia

En oligopolio con publicidad, la regla se modifica por el **efecto de robo de negocio** y la posibilidad de que la publicidad expanda la categoría:

$$\frac{A_j}{p_jQ_j}=\frac{\varepsilon_{A_j}}{|\varepsilon_{p_j}|}\cdot\frac{1}{1+\theta\cdot(\text{reacción de rivales})}$$

**Si la publicidad es puramente de robo de negocio (suma cero), el gasto agregado de la industria es socialmente derrochador** — un dilema del prisionero clásico. Si expande la categoría (publicidad informativa), puede ser socialmente valiosa. **Distinguir ambos empíricamente es la pregunta central de la economía de la publicidad.**

---

## 3. Publicidad persuasiva vs. informativa: cómo distinguirlas

| | Persuasiva | Informativa | Complementaria |
|---|---|---|---|
| Mecanismo | Cambia $\beta$ (las preferencias) | Cambia el conjunto de consideración | Entra en $U$ junto con el bien |
| Autor | Kaldor (1950) | Nelson (1974), Butters (1977) | Becker y Murphy (1993) |
| Efecto en elasticidad | **Reduce** $|\varepsilon|$ (lealtad) | **Aumenta** $|\varepsilon|$ (más comparación) | Ambiguo |
| Bienestar | Negativo (manipulación) | Positivo (reduce fricción) | Neutral (es un bien) |
| Test empírico | $\partial|\varepsilon|/\partial A<0$ | $\partial|\varepsilon|/\partial A>0$ | — |

**El test operativo:** interactuar publicidad con precio en la demanda estimada.
$$\ln Q = \alpha + \beta \ln P + \gamma \ln A + \underbrace{\lambda(\ln P\times\ln A)}_{\text{el parámetro clave}} + u$$

- $\lambda > 0$: la publicidad hace la demanda **menos elástica** ⇒ persuasiva.
- $\lambda < 0$: más elástica ⇒ informativa.

**En elección discreta**, el equivalente es permitir que la publicidad entre en $\delta_{jt}$ (nivel) y en el coeficiente de precio (pendiente).

### 3.1 La endogeneidad de la publicidad

**El problema es severo:** la firma gasta más publicidad cuando espera demanda alta (lanzamientos, estacionalidad). $\text{Cov}(A, \xi)>0$ ⇒ el efecto de la publicidad está **sobreestimado**.

**Soluciones:**

| Estrategia | Mecanismo |
|---|---|
| **Discontinuidad de mercados de TV** (Shapiro 2018) | Los *designated market areas* de TV no coinciden con fronteras administrativas; hogares vecinos reciben dosis publicitarias muy distintas |
| **Experimentos de campo** | La empresa aleatoriza exposición (la opción más limpia y cada vez más factible con publicidad digital) |
| **Costos de la publicidad** | Precio del espacio publicitario, variación en el costo por mil impresiones |
| **Spillovers de publicidad nacional** | Campañas diseñadas para un mercado que derraman a mercados vecinos sin targeting |
| **Super Bowl / eventos** | Variación exógena en audiencia |

> **⚠️ La advertencia de Lewis y Rao (2015).** El ROI de la publicidad digital es **extremadamente difícil de medir** porque la relación señal/ruido es pésima: la varianza de las ventas individuales es enorme comparada con el efecto de la publicidad. Muestran que detectar un ROI de 50% con potencia razonable requiere **millones** de observaciones. **La mayoría de los estudios de ROI publicitario de la industria están sub-potenciados y sus "hallazgos" son ruido.** Esta es la crítica más importante del campo y hay que conocerla antes de leer cualquier reporte de atribución de marketing.

---

## 4. Promociones y precios dinámicos

### 4.1 La descomposición del efecto de una promoción

Una caída temporal del precio genera un pico de ventas que se descompone en cuatro fuentes. **Solo una es valor nuevo:**

$$\Delta Q = \underbrace{\text{Switching}}_{\text{de rivales}} + \underbrace{\text{Stockpiling}}_{\text{compra futura adelantada}} + \underbrace{\text{Aceleración}}_{\text{consumo adelantado}} + \underbrace{\text{Expansión}}_{\text{consumo nuevo}}$$

**Hallazgo robusto de la literatura (Van Heerde, Leeflang y Wittink 2004; Hendel y Nevo 2006):** típicamente **solo el 10–30% del pico de ventas es incremento real de consumo**. El resto es sustitución entre marcas y, sobre todo, **desplazamiento temporal de compras del mismo consumidor**.

**Implicación brutal para el negocio:** la elasticidad promocional medida semana a semana **sobreestima masivamente** el valor de la promoción. Una promoción con elasticidad aparente de $-4$ puede tener elasticidad de consumo real de $-0.8$.

### 4.2 Cómo medirlo correctamente

```r
# El test del valle post-promoción
feols(log(ventas) ~ l(promo, -2:4) | tienda + semana, data = d)
# Leads (-2,-1): ¿hay anticipación? (los consumidores esperan la promo)
# Lag 0: el pico
# Lags (1:4): ¿hay valle? Si sí, hubo stockpiling.
# Efecto neto real = suma de TODOS los coeficientes, no solo el del lag 0.
```

**Con datos de panel de hogares** se puede hacer mejor: modelar explícitamente el inventario del hogar (Hendel y Nevo 2006) y separar demanda de consumo de demanda de compra.

### 4.3 Precios dinámicos y personalizados

**Discriminación de tercer grado** (segmentos observables): precio óptimo por segmento con la regla de Lerner segmento a segmento,
$$\frac{p_s - c}{p_s}=\frac{1}{|\varepsilon_s|}$$

**Discriminación de primer grado aproximada** (personalización algorítmica): con datos individuales, $p_i^*$ que extrae el excedente individual.

**El resultado de bienestar es ambiguo y poco intuitivo:** la discriminación de precios aumenta el bienestar total si **expande la cantidad total** (Varian 1985; Schmalensee 1981). Con demandas lineales y sin expansión de output, la discriminación de tercer grado **reduce** el bienestar total aunque aumente el beneficio.

> **⚠️ Riesgo regulatorio.** La personalización algorítmica de precios basada en datos personales está en el radar regulatorio global (protección de datos, prácticas desleales, discriminación). En Perú, la Ley de Protección de Datos Personales (Ley 29733) y el Código de Protección y Defensa del Consumidor imponen límites. **Un análisis que recomiende personalización debe incluir la evaluación de riesgo regulatorio y reputacional, no solo el cálculo de margen.**

---

## 5. Búsqueda y conjuntos de consideración

### 5.1 El problema con el modelo de elección estándar

El logit de los Caps. 05–06 supone que el consumidor **evalúa todas las alternativas**. Falso: la gente considera 3–5 marcas de un conjunto de 30.

**Consecuencia para la estimación:** si el conjunto de consideración es endógeno al precio o a la publicidad, la elasticidad estimada está sesgada y las **elasticidades cruzadas están muy mal** (se atribuye sustitución entre productos que el consumidor nunca comparó).

### 5.2 El modelo de búsqueda secuencial de Weitzman (1979)

El consumidor decide secuencialmente qué alternativa inspeccionar, pagando un costo $c_j$ por inspección.

> **Regla del índice de reserva.** Para cada alternativa, calcular $z_j$ que resuelve
> $$E\big[\max(u_j - z_j, 0)\big]=c_j$$
> Entonces: **(i)** buscar en orden descendente de $z_j$; **(ii)** parar cuando el máximo valor ya encontrado supere el mayor $z_j$ restante; **(iii)** elegir el mejor de los inspeccionados.

Esta regla —sorprendentemente— es óptima y **convierte un problema dinámico complejo en un ranking estático**. Es la base de toda la econometría de búsqueda moderna (Honka 2014; Honka y Chintagunta 2017; De los Santos, Hortaçsu y Wildenbeest 2012).

**Dato que lo identifica:** clickstream, datos de navegación, orden de visualización, resultados de encuestas de conjunto de consideración.

### 5.3 Posición y atención

El efecto de la posición (en góndola, en resultados de búsqueda, en una app) es grande y endógeno: los productos buenos obtienen mejores posiciones. Identificación:
- Experimentos de aleatorización de posición (lo hacen las plataformas).
- Cambios exógenos de algoritmo.
- Variación de la posición por razones ajenas al producto (orden alfabético, rotación programada).

> **🇵🇪 Perú.** El espacio en góndola en bodegas y supermercados, y la posición en apps de delivery (que han crecido enormemente), son variables de decisión con efectos de demanda grandes. Un experimento de campo con una cadena o un repartidor sería un paper de marketing publicable y de alto valor para la empresa.

---

## 6. Valor del cliente (CLV) y el puente a finanzas

$$CLV=\sum_{t=0}^{T}\frac{\big(m_t\cdot r^{t}\big)}{(1+d)^{t}} - CAC$$

donde $m_t$ es el margen por periodo, $r$ la tasa de retención y $d$ la de descuento.

**Con retención y margen constantes y horizonte infinito:**
$$\boxed{\ CLV=\frac{m\cdot r}{1+d-r}-CAC\ }$$

**Comparativa estática que todo analista debe conocer:**
$$\frac{\partial CLV}{\partial r}=\frac{m(1+d)}{(1+d-r)^2}>0$$

Con $d=0.10$ y $r=0.80$: $\partial CLV/\partial r = m\cdot 1.1/0.09 = 12.2\,m$. **Un punto porcentual de retención adicional vale 0.12 márgenes mensuales.** Esta es la aritmética que justifica la obsesión del SaaS con el churn.

**El puente con la OI:** la tasa de retención $r$ **es** una función de las elasticidades estimadas y del comportamiento de los rivales. Un modelo de demanda con estado (lealtad, costos de cambio) permite derivar $r$ estructuralmente en lugar de extrapolarla:
$$r = \Pr(\text{elegir } j \text{ en } t+1 \mid \text{eligió } j \text{ en } t) = s_j(\boldsymbol p_{t+1}; \text{estado}=j)$$

**Costos de cambio (switching costs).** Si incluir un *dummy* de "compró esta marca el periodo anterior" en el logit es significativo, hay dependencia de estado — pero **ojo con la heterogeneidad espuria**: consumidores con preferencia persistente por una marca generan el mismo patrón sin ningún costo de cambio. Distinguirlos requiere panel largo y el tratamiento de la condición inicial (Heckman 1981; Dubé, Hitsch y Rossi 2010).

→ El CLV agregado es la base del valor de la empresa. Ver [Cap. 11 §4](11-valuation-finanzas.md).

---

## 7. El puente formal OI ↔ Marketing

| Concepto de OI | Nombre en marketing | Mismo objeto |
|---|---|---|
| Elasticidad precio propia | Sensibilidad al precio | $\varepsilon_{jj}$ |
| Elasticidad cruzada | Competencia entre marcas | $\varepsilon_{jk}$ |
| Diversion ratio | **Mapa de switching** | $D_{jk}$ |
| Bien externo | No compra de categoría | $s_0$ |
| $\xi_{jt}$ | **Brand equity** | calidad no observada |
| Markup de Lerner | Margen de contribución | $\mathcal L$ |
| Pérdida de bienestar | Excedente no capturado | — |
| Nido | **Segmento / categoría percibida** | $g$ |
| Coeficiente aleatorio | **Segmentación latente** | $\sigma_k$ |

> **El punto más importante del capítulo:** $\xi_{jt}$ — el término que en OI es "el error estructural molesto que causa endogeneidad" — **es exactamente el brand equity**. Es el valor que el consumidor asigna a la marca más allá de sus características observables. Un BLP estimado produce, como subproducto, una medida de brand equity por marca y mercado, defendible y comparable. **Las empresas pagan mucho dinero a consultoras por estimaciones de brand equity con metodologías muy inferiores.**

---

## 8. Checklist de aplicación en una empresa

1. **¿Cuál es la elasticidad de marca y cuál la de categoría?** (Si las confunde, todo lo demás está mal. Cap. 03 §4.4.)
2. **¿Cuál es el markup implícito en el precio actual?** $\mathcal L = 1/|\varepsilon|$ si optimiza monoproducto; corregir por canibalización si hay cartera (Cap. 07 §2.4).
3. **¿El precio actual es óptimo?** Comparar $\mathcal L$ observado con $1/|\varepsilon|$. Si $\mathcal L < 1/|\varepsilon|$, el precio está **por debajo** del óptimo.
4. **¿El gasto publicitario es coherente con Dorfman–Steiner?** (§2.2.)
5. **¿Las promociones generan consumo o lo desplazan?** (Test del valle, §4.2.)
6. **¿Hacia dónde se van mis clientes cuando subo el precio?** (Diversion ratios, Cap. 07 §3.)
7. **¿Cuánto vale un cliente y cuánto puedo pagar por adquirirlo?** (§6.)

---

## 9. Lecturas

- Dorfman y Steiner (1954), "Optimal Advertising and Optimal Quality", *AER* 44(5).
- Becker y Murphy (1993), "A Simple Theory of Advertising as a Good or Bad", *QJE* 108(4).
- Bagwell (2007), "The Economic Analysis of Advertising", *Handbook of IO* vol. 3. — el survey definitivo.
- Lewis y Rao (2015), "The Unfavorable Economics of Measuring the Returns to Advertising", *QJE* 130(4). — **crítico**.
- Shapiro (2018), "Positive Spillovers and Free Riding in Advertising of Prescription Pharmaceuticals", *JPE* 126(1).
- Sethuraman, Tellis y Briesch (2011), "How Well Does Advertising Work? Generalizations from a Meta-Analysis", *JMR* 48(3).
- Hendel y Nevo (2006), "Measuring the Implications of Sales and Consumer Inventory Behavior", *Econometrica* 74(6).
- Weitzman (1979), "Optimal Search for the Best Alternative", *Econometrica* 47(3).
- Honka (2014), "Quantifying Search and Switching Costs in the US Auto Insurance Industry", *RAND* 45(4).
- Dubé, Hitsch y Rossi (2010), "State Dependence and Alternative Explanations for Consumer Inertia", *RAND* 41(3).
- Varian (1985), "Price Discrimination and Social Welfare", *AER* 75(4).
