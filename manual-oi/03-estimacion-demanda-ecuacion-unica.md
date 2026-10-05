# 03 · Demanda de ecuación única

> **Extiende S04.** El curso da el flujo de trabajo (especificar → identificar → OLS → IV → diagnosticar → interpretar) y las tres formas funcionales. Aquí: la derivación de cada forma funcional desde preferencias, el álgebra exacta de elasticidades y cómo se rompen en simulaciones grandes, selección formal de forma funcional (Box–Cox, Davidson–MacKinnon), el problema de los precios agregados (unit values), errores estándar correctos en paneles, y la economía de cada familia de instrumentos.

---

## 1. La idea

La demanda de ecuación única es el caballo de batalla porque es **barata**: necesita datos de un solo bien y un solo instrumento. Su límite es que **no sabe nada sobre sustitución**: si el precio del pollo sube, la demanda de res reacciona, pero una ecuación única del pollo no tiene dónde poner esa información. Se usa cuando:

- el bien es relativamente aislado o se analiza en el agregado (gasolina, electricidad, tabaco);
- se quiere una elasticidad agregada de categoría para un impuesto o una tarifa;
- se necesita una respuesta rápida y defendible;
- es la etapa superior de un sistema de dos etapas (Cap. 04 §6).

---

## 2. De preferencias a formas funcionales: qué utilidad genera qué demanda

El curso presenta tres especificaciones como opciones de conveniencia. En realidad cada una **es** una familia de preferencias, con implicaciones que uno acepta implícitamente al elegirla.

### 2.1 Log-lineal (elasticidad constante) ← Cobb–Douglas generalizada

$$\ln Q = \alpha + \beta \ln P + \gamma \ln Y + u$$

**Preferencias que la generan.** Cobb–Douglas $U = \prod_i q_i^{a_i}$ da $q_i = a_i Y/p_i$, es decir $\beta = -1$ y $\gamma = 1$ exactamente. Para $\beta \ne -1$ se necesita CES con el resto del presupuesto:
$$U = \Big[\sum_i a_i q_i^{\rho}\Big]^{1/\rho} \ \Longrightarrow\ \ln q_i = \text{const} - \sigma \ln p_i + \sigma \ln P^{CES} + \ln Y$$
con $\sigma = 1/(1-\rho)$ la elasticidad de sustitución. **La log-lineal es la demanda CES condicional al índice de precios del resto.**

**Implicación que se acepta sin saberlo:** elasticidad de sustitución constante entre este bien y *todos* los demás, igual para todos. Esto es exactamente IIA del Cap. 05, en versión continua. (La conexión CES ↔ logit es exacta: ver [Apéndice A §6](A-apendice-demostraciones.md).)

**Elasticidad:** $\varepsilon = \beta$, constante. Directo, pero:

> **⚠️ Trampa (la gran trampa de S04, formalizada).** Con elasticidad constante y $\beta < -1$, el gasto $PQ = e^{\alpha}P^{1+\beta}Y^{\gamma}$ **tiende a infinito cuando $P \to 0$**. La extrapolación a precios bajos es absurda. Y con $\beta > -1$, $Q \to \infty$ cuando $P\to 0$ sin límite de saciedad. La log-lineal es una aproximación *local*: válida en el rango de la muestra, no más allá.

### 2.2 Lineal ← Cuasi-lineal cuadrática

$$Q = \alpha + \beta P + \gamma Y + u$$

**Preferencias:** $U = v(q) + m$ con $v$ cuadrática, $v(q) = aq - \tfrac{b}{2}q^2$. La CPO $v'(q)=p$ da $q = (a-p)/b$: lineal, **sin efecto ingreso** (de ahí que $\gamma$ deba ser pequeño si la forma es correcta).

**Elasticidad:** $\varepsilon = \beta\cdot P/Q$, **varía con el punto**. Crece en valor absoluto a medida que sube $P$.

**Virtudes subestimadas:**
- Admite $Q = 0$ (soluciones de esquina), lo que la log-lineal no puede.
- Es la forma correcta para **datos de conteo** y para bienes con compra discreta.
- El excedente del consumidor tiene forma cerrada triangular — conveniente para cálculos rápidos de daño.

### 2.3 Semi-log ← Preferencias con saciedad exponencial

$$\ln Q = \alpha + \beta P + \gamma \ln Y + u$$

**Elasticidad:** $\varepsilon = \beta P$, crece linealmente con el precio. Es la forma natural cuando el instrumento de política es un **impuesto específico** (soles por unidad), porque el efecto de $\Delta P$ en soles es constante en términos porcentuales.

**Uso canónico:** estudios de dosis-respuesta en salud (tabaco, alcohol, bebidas azucaradas). El impuesto selectivo al consumo (ISC) peruano sobre bebidas azucaradas es específico+ad valorem, lo que hace a la semi-log particularmente apropiada.

### 2.4 Comparación cuantitativa: el error de extrapolación

Retomando el ejemplo de café de S04 ($\bar P = 5$, $\bar Q = 200$, $\varepsilon = -1.25$ al medio) y extendiéndolo:

| $P$ | Lineal ($\beta=-50$) | Log-lineal ($\beta=-1.4$) | Semi-log ($\beta=-0.25$) |
|---|---|---|---|
| 2 | 350 | **397** | 423 |
| 3 | 300 | 311 | 330 |
| 5 | 200 | 200 | 200 |
| 8 | 50 | 68 | 94 |
| 10 | **−50** ✗ | 48 | 57 |
| 15 | −300 ✗ | 27 | 16 |

**Lecciones:**
1. La lineal **se rompe** (cantidades negativas) fuera del rango — inaceptable para simulaciones grandes.
2. La semi-log es la más conservadora para subidas de precio y la más agresiva para bajadas.
3. En el rango ±20% del precio medio, las tres coinciden dentro de pocos puntos porcentuales. **Si tu contrafactual está dentro de ese rango, la forma funcional no es tu problema principal. Si está fuera, es tu problema principal.**

### 2.5 Selección formal de la forma funcional

**Box–Cox.** Estimar
$$\frac{Q^{\lambda_1}-1}{\lambda_1} = \alpha + \beta\,\frac{P^{\lambda_2}-1}{\lambda_2} + u$$
por máxima verosimilitud. $\lambda=0$ → log; $\lambda=1$ → nivel. Testear $H_0:\lambda=0$ con un LR.

**Davidson–MacKinnon (test J) para modelos no anidados.** Estimar el modelo A, obtener $\hat Q_A$, incluirlo en el modelo B; si es significativo, B no abarca a A. Hacer lo inverso. Posibles resultados: A gana, B gana, ambos rechazados (especificación mal), ninguno rechazado (los datos no distinguen).

**RESET de Ramsey** para no linealidad omitida.

**Criterio práctico:** para la publicación, log-lineal como base y las otras como robustez. Para una simulación de política con cambios > 30%, correr las tres y **reportar el rango**. Un número único de una sola forma funcional, en un contrafactual grande, es una falsa precisión.

---

## 3. La economía de cada familia de instrumentos

S04 presenta la tabla. Aquí, la lógica económica y las condiciones precisas bajo las que falla cada una.

### 3.1 Desplazadores de costo

$$Z = \text{precio de insumos, salarios, flete, energía, tipo de cambio de insumos importados}$$

**Condición de exclusión formal:** $Z$ entra en $C(w,y)$ pero no en $U(q)$.

**Cuándo falla:**
- **Calidad endógena.** Si un insumo más caro lleva a la firma a reducir calidad, y la calidad afecta la demanda, hay un canal directo $Z \to Q$. Ejemplo: harina más cara → menos relleno en galletas → menor demanda independiente del precio.
- **Costos correlacionados con demanda.** El precio del petróleo afecta el costo de transporte *y* el ingreso disponible de los hogares (vía inflación), que afecta la demanda. En economías pequeñas y abiertas como Perú, los shocks de commodities son **macro**: tocan ambos lados.

> **🇵🇪 Perú — un aviso importante.** El tipo de cambio es tentador como instrumento de costo para bienes importados (la mayoría de los bienes manufacturados de consumo). Pero el tipo de cambio en Perú se mueve con el precio del cobre, que mueve el ingreso nacional, que mueve la demanda. **El tipo de cambio NO es un instrumento válido en Perú para bienes de consumo masivo sin controlar explícitamente el canal de ingreso.** Este es un error que aparece con frecuencia en tesis locales.

### 3.2 Impuestos

Variación de impuestos entre jurisdicciones o en el tiempo.

**Cuándo falla:** los impuestos se introducen *porque* el consumo es alto o está creciendo (endogeneidad política), y suelen acompañarse de campañas de información que desplazan la demanda directamente. Ejemplo: impuesto a bebidas azucaradas + campaña de salud pública + etiquetado de octógonos.

**🇵🇪 Perú.** El ISC a bebidas azucaradas (2018, elevado a 25% para bebidas con ≥6g de azúcar/100ml) coincidió casi exactamente con la **Ley de Alimentación Saludable y los octógonos** (reglamento 2018-2019). Un diseño ingenuo que use el ISC como instrumento está capturando también el efecto del etiquetado. Diseño correcto: explotar el **umbral de 6g/100ml** como una **discontinuidad en regresión** sobre el contenido de azúcar, lo que separa el efecto del impuesto de la campaña general. **Esta es una de las mejores oportunidades de identificación disponibles en datos peruanos y, hasta donde se sabe, está infraexplotada.**

### 3.3 Instrumentos Hausman (precios en otros mercados)

$$Z_{jt} = \frac{1}{|\mathcal{M}|-1}\sum_{m\ne t} p_{jm}$$

**Lógica:** el precio del mismo producto en otra ciudad comparte el shock de costo común (nacional) pero no el shock de demanda local.

**Cuándo falla (y es frecuente):**
1. **Publicidad nacional.** Una campaña de Coca-Cola mueve la demanda en Lima y en Arequipa simultáneamente → $\text{Cov}(p_{j,\text{Areq}}, \xi_{j,\text{Lima}}) \ne 0$.
2. **Shocks macro.** Una recesión afecta la demanda en todas las ciudades.
3. **Preferencias regionales correlacionadas.** Las preferencias por Inca Kola correlacionan entre ciudades del norte.
4. **Precios nacionales uniformes.** Si la empresa fija un precio único nacional, el instrumento es **mecánicamente idéntico** al precio de interés — relevancia perfecta, exclusión nula. Este caso es letal y sorprendentemente común en Perú (donde muchas empresas de consumo masivo fijan listas nacionales).

**Mitigación:** incluir efectos fijos de marca × tiempo (absorben publicidad nacional y shocks macro), y efectos fijos de región. Lo que queda identificando es variación de costo **local** idiosincrásica.

### 3.4 Clima y desastres naturales

Lógica de Fulton. En Perú: **El Niño** es el shock de oferta más potente disponible.

**Cuándo falla:** cuando el clima también afecta la demanda (helados, bebidas, electricidad por aire acondicionado). La tabla de S03 (helado ✗, arroz ✓, electricidad ✗) es exactamente el criterio correcto.

**🇵🇪 Perú.** El Niño Costero afecta la pesca (anchoveta, pota, bonito), la agricultura costera (arroz, caña, mango, espárrago), la infraestructura vial (huaicos → costos de transporte). Para el **pescado**, El Niño es un instrumento de libro de texto: afecta la biomasa disponible, no el apetito del consumidor limeño. Las vedas de anchoveta de IMARPE añaden variación adicional casi experimental. **Replicar Graddy (1995) con el Terminal Pesquero de Villa María del Triunfo es un ejercicio obvio y valioso que nadie ha publicado.**

### 3.5 Instrumentos regulatorios

Licencias, cuotas, aranceles, restricciones de horario.

**Cuándo falla:** la regulación responde a condiciones del mercado (endogeneidad política). Una licencia que se otorga porque hay demanda insatisfecha no es exógena.

---

## 4. Elasticidades: el álgebra exacta

### 4.1 Definiciones y conversiones

$$\varepsilon = \frac{\partial \ln Q}{\partial \ln P} = \frac{\partial Q}{\partial P}\cdot\frac{P}{Q}$$

| Forma | $\varepsilon$ | Evaluada en |
|---|---|---|
| $Q = \alpha+\beta P$ | $\beta P/Q$ | medias o punto de interés |
| $\ln Q = \alpha+\beta\ln P$ | $\beta$ | constante |
| $\ln Q = \alpha + \beta P$ | $\beta P$ | medias |
| $Q = \alpha + \beta\ln P$ | $\beta/Q$ | medias |

### 4.2 El cálculo correcto de un cambio discreto

> **⚠️ La trampa más común de todo el curso.** Con elasticidad $\varepsilon$ y un aumento de precio del 25%, el cambio de cantidad **no** es $\varepsilon \times 25\%$.

El cálculo correcto con elasticidad constante:
$$\frac{Q_1}{Q_0} = \left(\frac{P_1}{P_0}\right)^{\varepsilon} \quad\Longrightarrow\quad \%\Delta Q = \big[(1+\%\Delta P)^{\varepsilon} - 1\big]\times 100$$

Para $\varepsilon=-0.77$ y $\%\Delta P = 25\%$ (el ejemplo de res de S05):
- **Aproximación lineal:** $-0.77\times 25 = -19.25\%$
- **Exacto:** $(1.25)^{-0.77}-1 = e^{-0.77\times 0.2231}-1 = -15.9\%$

La diferencia es de 3.3 puntos — en una simulación de daño por cartel sobre S/ 100 millones de ventas, son millones. Para cambios de precio > 10%, usar siempre la fórmula exacta.

### 4.3 Elasticidad de ingreso y clasificación

$$\eta = \frac{\partial \ln Q}{\partial \ln Y}: \quad \eta > 1 \text{ (lujo)},\quad 0<\eta<1 \text{ (necesidad)},\quad \eta<0 \text{ (inferior)}$$

**Ley de Engel y su test:** la participación presupuestal de alimentos cae con el ingreso. Es la regularidad empírica más robusta de la economía y un chequeo de sanidad obligatorio: si tu estimación da alimentos como bien de lujo, hay un error.

### 4.4 Rangos de referencia para validar estimaciones

Si tu estimación cae muy fuera de estos rangos, probablemente hay un problema de identificación, no un descubrimiento.

| Categoría | $\varepsilon$ típica | Fuente |
|---|---|---|
| Gasolina (corto plazo) | −0.2 a −0.3 | Espey (1998) |
| Gasolina (largo plazo) | −0.6 a −0.8 | Espey (1998) |
| Alimentos (agregado) | −0.3 a −0.8 | Andreyeva et al. (2010) |
| Bebidas azucaradas | −0.8 a −1.3 | Colchero et al. (2016), México |
| Tabaco | −0.3 a −0.5 | Chaloupka y Warner (2000) |
| Electricidad residencial (CP) | −0.2 a −0.4 | — |
| Marca individual (no categoría) | **−2 a −5** | BLP, Nevo (2001) |

> **La regla de oro:** las elasticidades de **categoría** son inelásticas; las de **marca** son muy elásticas. Confundirlas es el error conceptual más caro en consultoría de pricing. La categoría "gaseosas" tiene $\varepsilon\approx -1$; la marca "Coca-Cola 500ml" tiene $\varepsilon \approx -3$ o −4 porque el consumidor cambia de marca, no de categoría.

---

## 5. Problemas de datos que aparecen siempre

### 5.1 Unit values vs. precios

Con datos de encuestas de hogares (ENAHO), no se observa el precio: se observa gasto y cantidad, y se construye $p = \text{gasto}/\text{cantidad}$. Esto es un **unit value**, no un precio, y tiene dos problemas:

1. **Sesgo de calidad (Deaton 1988).** Hogares ricos compran variedades más caras dentro de la misma categoría. El unit value sube con el ingreso por composición, no por precio. Esto **sesga la elasticidad-ingreso hacia arriba y la elasticidad-precio hacia cero**.
2. **Error de medición → sesgo de atenuación amplificado.** Si la cantidad tiene error de medición $\nu$, entonces $p = \text{gasto}/(q\cdot e^{\nu})$ y $q$ aparecen con errores **negativamente correlacionados**: una sobreestimación de $q$ baja $p$ mecánicamente. Esto **crea una correlación negativa espuria** y hace que la demanda parezca más elástica de lo que es.

**Solución (Deaton 1988, 1990):** usar la variación de precios **entre clusters geográficos** (el precio medio del cluster como instrumento del unit value del hogar), lo que purga el componente de calidad individual. Deaton desarrolló este método precisamente para encuestas de países en desarrollo; es directamente aplicable a ENAHO.

> **🇵🇪 Perú.** ENAHO tiene estructura de conglomerados geográficos. El método de Deaton es implementable *tal cual* y casi nadie lo usa en la literatura peruana aplicada, que típicamente regresa cantidad sobre unit value sin corrección. Es una crítica válida a buena parte del trabajo publicado localmente y una oportunidad de corrección.

### 5.2 Agregación temporal y promociones

Datos semanales de scanner tienen un problema de **almacenamiento (stockpiling)**: una promoción genera un pico de compras seguido de un valle (el consumidor adelantó compras futuras). La elasticidad estimada semana a semana **sobreestima** la respuesta de consumo real.

**Soluciones:** agregar a nivel mensual/trimestral; incluir rezagos y adelantos del precio (si los adelantos son significativos, hay anticipación); modelar explícitamente el inventario del hogar (Hendel y Nevo 2006).

### 5.3 Ceros

En datos de hogares, muchas observaciones tienen $q=0$ (el hogar no compró esa categoría en el periodo). Opciones:
- **Tobit** si el cero es solución de esquina (quiere pero no le alcanza).
- **Doble valla (Cragg)** si la decisión de participar y la de cuánto son distintas.
- **Heckman** si hay selección.
- **Poisson pseudo-ML (PPML)** si la variable es no negativa con muchos ceros y se quiere interpretación log — **es la opción moderna preferida** y es robusta a heterocedasticidad (Santos Silva y Tenreyro 2006).

---

## 6. Errores estándar: hacerlos bien

| Estructura de datos | Clustering correcto |
|---|---|
| Serie de tiempo de un mercado | Newey–West (HAC) |
| Panel producto × mercado × tiempo | Cluster por **mercado** (o por producto, el nivel del tratamiento) |
| Variación de política a nivel región | Cluster por **región** (nivel del tratamiento) |
| Pocos clusters (< 40) | Wild cluster bootstrap (Cameron, Gelbach y Miller 2008) |
| Datos de encuesta con diseño complejo | Pesos muestrales + estratos + conglomerados |

> **⚠️ Trampa.** Clusterizar al nivel del producto cuando la variación del instrumento es a nivel de región subestima los errores estándar fuertemente. **La regla: clusterizar al nivel donde varía el tratamiento.** Con pocos clusters (ej. 24 departamentos del Perú), usar wild bootstrap: la aproximación asintótica falla.

---

## 7. Flujo de trabajo completo, con código

```r
library(fixest); library(modelsummary)

# 0. INSPECCIÓN ---------------------------------------------------------
summary(d[, c("q","p","y")]);  plot(log(d$p), log(d$q))
# ¿La nube tiene pendiente positiva? → sospecha de simultaneidad (S03)

# 1. OLS BASELINE (sabemos que está sesgado; es el punto de comparación)
m_ols <- feols(log(q) ~ log(p) + log(y) | mercado + periodo, data = d,
               cluster = ~mercado)

# 2. PRIMERA ETAPA EXPLÍCITA (ver signo, magnitud y F)
m_fs  <- feols(log(p) ~ z + log(y) | mercado + periodo, data = d,
               cluster = ~mercado)
# ¿El signo es el que la historia económica predice? Si no, para y piensa.

# 3. IV
m_iv  <- feols(log(q) ~ log(y) | mercado + periodo | log(p) ~ z, data = d,
               cluster = ~mercado)
fitstat(m_iv, c("ivf1", "ivwald1", "sargan", "wh"))
#  ivf1   = F primera etapa
#  sargan = sobreidentificación (si hay >1 instrumento)
#  wh     = Wu-Hausman (endogeneidad)

# 4. ROBUSTEZ DE FORMA FUNCIONAL
m_lin <- feols(q ~ y | mercado + periodo | p ~ z, data = d)
m_sl  <- feols(log(q) ~ log(y) | mercado + periodo | p ~ z, data = d)

# 5. ELASTICIDADES COMPARABLES
e_ll  <- coef(m_iv)["fit_log(p)"]
e_lin <- coef(m_lin)["fit_p"] * mean(d$p)/mean(d$q)
e_sl  <- coef(m_sl)["fit_p"]  * mean(d$p)
c(loglineal = e_ll, lineal = e_lin, semilog = e_sl)

# 6. SIMULACIÓN DE POLÍTICA (¡fórmula exacta!)
pct_dp <- 0.25
pct_dq <- (1 + pct_dp)^e_ll - 1          # correcto
pct_dq_malo <- e_ll * pct_dp             # incorrecto - para mostrar la brecha

modelsummary(list(OLS = m_ols, "Primera etapa" = m_fs, IV = m_iv),
             stars = TRUE, gof_map = c("nobs","r.squared"))
```

---

## 8. La tabla que debe ir en el paper

| | OLS | IV | Lineal (IV) | Semi-log (IV) |
|---|---|---|---|---|
| ln(precio) | 0.18 (0.24) | **−0.92\*\*\*** (0.31) | — | — |
| precio | — | — | −0.0X (·) | −0.XX (·) |
| Elasticidad implícita | 0.18 | **−0.92** | −0.88 | −0.95 |
| $F$ primera etapa | — | 18.4 | 18.4 | 18.4 |
| $F$ efectivo (MOP) | — | **report!** | | |
| IC Anderson–Rubin | — | [−1.6, −0.4] | | |
| Hansen $J$ ($p$) | — | 0.41 | | |
| Wu–Hausman ($p$) | — | 0.01 | | |
| $N$ | 111 | 111 | 111 | 111 |

Las filas en negrita son las que un referee busca primero y las que faltan en la mayoría de los borradores.

---

## 9. Lecturas

- Angrist y Pischke (2009), cap. 4.
- Deaton (1988), "Quality, Quantity, and Spatial Variation of Price", *AER* 78(3). **← esencial para datos peruanos**
- Deaton (1997), *The Analysis of Household Surveys*, caps. 3–5.
- Espey (1998), "Gasoline Demand Revisited: A Meta-Analysis", *Energy Economics* 20.
- Andreyeva, Long y Brownell (2010), "The Impact of Food Prices on Consumption", *AJPH* 100(2).
- Colchero et al. (2016), "Beverage Purchases from Stores in Mexico under the Excise Tax", *BMJ* 352.
- Hendel y Nevo (2006), "Measuring the Implications of Sales and Consumer Inventory Behavior", *Econometrica* 74(6).
- Santos Silva y Tenreyro (2006), "The Log of Gravity", *RESTAT* 88(4).
