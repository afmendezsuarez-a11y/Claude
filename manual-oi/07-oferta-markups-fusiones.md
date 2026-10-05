# 07 · El lado de la oferta: markups, pass-through y fusiones

> **Extiende S07 Block 5.** El curso da la fórmula de markup $p-mc=-(\partial s/\partial p \odot H)^{-1}s$ y la matriz de propiedad. Aquí: la derivación completa de la CPO multiproducto, el álgebra del Lerner con diversion ratios, la teoría de pass-through (incluido el resultado de Weyl–Fabinger), UPP/GUPPI y el test SSNIP implementable, el procedimiento paso a paso de simulación de fusiones, y Nash-in-Nash para mercados con negociación.

---

## 1. La idea

Estimar demanda es la mitad del trabajo. La otra mitad es que **la demanda, más un supuesto de conducta, revela el costo marginal sin observarlo**. Esa es la alquimia central de la OI empírica moderna:

$$\underbrace{\text{elasticidades estimadas}}_{\text{datos}} + \underbrace{\text{Bertrand--Nash}}_{\text{supuesto}} \ \Longrightarrow\ \underbrace{mc_{jt}}_{\text{nunca observado}}$$

Con $mc$ en mano, todo contrafactual es posible: cambiar la propiedad (fusión), cambiar el costo (impuesto, arancel, shock cambiario), cambiar el conjunto de productos (entrada, retiro).

**El precio de esa alquimia** es que todo depende del supuesto de conducta. Si las firmas no juegan Bertrand–Nash, los $mc$ recuperados están mal, y los contrafactuales también. De ahí la importancia del Cap. 02 §6 (identificación de conducta).

---

## 2. Derivación de la fórmula de markup multiproducto

### 2.1 El problema de la firma

La firma $f$ posee el conjunto de productos $\mathcal{F}_f$ y resuelve:
$$\max_{\{p_j\}_{j\in\mathcal{F}_f}}\ \Pi_f=\sum_{j\in\mathcal{F}_f}(p_j-mc_j)\,M\,s_j(\boldsymbol{p})$$

donde $M$ es el tamaño de mercado y $s_j(\boldsymbol p)$ la participación.

### 2.2 Condición de primer orden

$$\frac{\partial \Pi_f}{\partial p_k}=M\Big[s_k(\boldsymbol p)+\sum_{j\in\mathcal{F}_f}(p_j-mc_j)\frac{\partial s_j}{\partial p_k}\Big]=0, \qquad \forall k\in\mathcal{F}_f$$

**Lectura de los tres términos:**
- $s_k$: el beneficio de vender una unidad más al margen (efecto volumen positivo de bajar el precio es simétrico).
- $(p_k-mc_k)\partial s_k/\partial p_k$: el costo de que subir el precio reduce la propia demanda. Negativo.
- $\sum_{j\ne k, j\in\mathcal{F}_f}(p_j-mc_j)\partial s_j/\partial p_k$: **el término de canibalización**. Subir $p_k$ desvía consumidores hacia los *otros productos de la misma firma*, que la firma recaptura. Positivo. **Este término es el que falta en el monopolio de un solo producto y es el que hace que las firmas multiproducto cobren más.**

### 2.3 Forma matricial

Definimos la **matriz de propiedad** $H$ con $H_{jk}=1$ si $j,k$ pertenecen a la misma firma, 0 si no. Y la matriz de derivadas $\Delta$ con $\Delta_{jk}=\partial s_j/\partial p_k$.

El sistema de CPOs para todos los productos de todas las firmas se escribe:
$$\boldsymbol{s}+\big(\boldsymbol\Delta'\odot \boldsymbol H\big)(\boldsymbol p-\boldsymbol{mc})=\boldsymbol 0$$

$$\boxed{\ \boldsymbol p-\boldsymbol{mc}=-\big(\boldsymbol\Delta'\odot\boldsymbol H\big)^{-1}\boldsymbol s\ }$$

donde $\odot$ es el producto de Hadamard (elemento a elemento). **El producto de Hadamard con $H$ es lo que "apaga" las derivadas cruzadas entre productos de firmas distintas**: la firma $f$ internaliza la canibalización dentro de su cartera y ignora el daño a los rivales.

### 2.4 Casos particulares

**Monopolista de un producto.** $H=1$, $\Delta=\partial s/\partial p$:
$$p-mc=-\frac{s}{\partial s/\partial p}\quad\Longrightarrow\quad \frac{p-mc}{p}=\frac{1}{|\varepsilon|}$$
La regla del índice de Lerner. Y como $\mathcal L\le 1$, el monopolista **nunca opera donde $|\varepsilon|<1$** — un chequeo de consistencia obligatorio.

**Logit con firma monoproducto.** $\partial s_j/\partial p_j = -\alpha s_j(1-s_j)$:
$$p_j-mc_j=\frac{s_j}{\alpha s_j(1-s_j)}=\frac{1}{\alpha(1-s_j)}$$

**Consecuencias notables:**
- El markup **no depende de $mc$**: con logit, el pass-through de costos es exactamente 1 para firmas monoproducto (ver §4).
- El markup **crece con la participación**: productos grandes cobran más.
- $\alpha$ pequeño (consumidores insensibles al precio) ⇒ markup grande. **Si $\hat\alpha$ está sesgado hacia cero por endogeneidad (OLS), el markup implícito está sesgado hacia arriba.** Esto es exactamente lo que S07 señala: markups inversamente sesgados.

**Logit con firma multiproducto.** Para la firma $f$ con productos $\mathcal{F}$, resolviendo el sistema:
$$p_j-mc_j=\frac{1}{\alpha\big(1-\sum_{k\in\mathcal{F}}s_k\big)}$$

**El markup depende de la participación total de la firma, no del producto.** Una firma con 60% del mercado repartido en 5 marcas cobra el markup de una firma con 60% en una sola marca. Esto es exactamente lo que hace que las fusiones suban precios.

---

## 3. Diversion ratios: el puente a la política de competencia

### 3.1 Definición

$$D_{jk}=\frac{\partial s_k/\partial p_j}{-\partial s_j/\partial p_j}$$

**Interpretación:** de cada 100 consumidores que abandonan $j$ cuando sube su precio, $100\cdot D_{jk}$ van a $k$.

**Propiedad:** $\sum_{k\ne j} D_{jk} + D_{j0}=1$ (incluyendo la fuga al bien externo).

### 3.2 En logit (y por qué es un problema)

$$D_{jk}=\frac{\alpha p_k s_k \cdot(\cdot)}{\alpha s_j(1-s_j)}\cdot(\cdot)=\frac{s_k}{1-s_j}$$

**El diversion ratio depende solo de las participaciones.** Si Coca-Cola y Agua San Luis tienen la misma participación, el logit dice que son sustitutos igual de cercanos de Pepsi. Absurdo — y es exactamente por qué el logit puro no sirve para análisis de fusiones.

En **nested logit**: $D_{jk}$ es mayor dentro del nido. En **BLP**: $D_{jk}$ depende del solapamiento de los conjuntos de consumidores.

> **Los diversion ratios son el output más útil de un modelo de demanda para competencia.** Las autoridades los piden directamente. Son más robustos que las elasticidades (son cocientes, y parte del sesgo se cancela) y se interpretan sin jerga.

### 3.3 Diversion ratios sin estimar demanda

En la práctica regulatoria se obtienen de:
- **Encuestas de desvío** ("si este producto subiera 10%, ¿qué compraría?"). Usadas por la CMA británica rutinariamente.
- **Experimentos naturales**: cuando un producto se agota o se retira, ¿a dónde van las ventas?
- **Datos de panel de hogares**: observar sustitución real tras cambios de precio.

---

## 4. Pass-through: cuánto de un shock de costo llega al precio

### 4.1 Por qué importa

El pass-through responde: ¿quién paga un impuesto? ¿Cuánto del shock cambiario llega al consumidor? ¿Qué parte del ahorro de una sinergia de fusión se transfiere?

### 4.2 Monopolio: el resultado general

Con demanda $q(p)$ y costo marginal constante $c$, la CPO es $p = c + q/|q'|$. Diferenciando totalmente respecto de $c$:
$$\rho\equiv\frac{dp}{dc}=\frac{1}{2+\dfrac{q\,q''}{(q')^2}}=\frac{1}{1+\dfrac{\partial \ln|\varepsilon|}{\partial \ln p}\cdot(\cdot)}$$

Más útil, en términos de la **curvatura de la demanda** $\kappa \equiv -q q''/(q')^2$ (el "superelasticidad" de Bulow–Pfleiderer):
$$\boxed{\ \rho=\frac{1}{2-\kappa}\ }$$

| Forma de demanda | $\kappa$ | $\rho$ |
|---|---|---|
| **Lineal** ($q''=0$) | 0 | **1/2** |
| **Elasticidad constante** ($q=Ap^{-\eta}$) | $(\eta+1)/\eta$ | $\dfrac{\eta}{\eta-1}>1$ ⇒ **sobre-traslado** |
| **Logit** (monoproducto, $s\to 0$) | → 1 | **→ 1** |
| Exponencial | 1 | 1 |

> **Resultado contraintuitivo clave.** Con demanda de elasticidad constante, el pass-through es **mayor que 1**: un impuesto de S/ 1 sube el precio en más de S/ 1. Esto no es un error: con elasticidad constante, el markup es proporcional al costo ($p = c\cdot\eta/(\eta-1)$), así que un aumento de costo multiplica el markup también.

**Implicación práctica masiva:** la forma funcional de la demanda determina el pass-through **más que la elasticidad**. Dos modelos con la misma elasticidad al punto medio pueden predecir pass-through de 50% o 120%. **Reportar pass-through sin reportar la curvatura de la demanda es irresponsable.**

### 4.3 El resultado de Weyl y Fabinger (2013)

> **Teorema.** La incidencia de un impuesto (reparto entre consumidores y productores) en un mercado imperfectamente competitivo es
> $$\frac{\text{Incidencia en consumidores}}{\text{Incidencia en productores}}=\frac{\rho}{1-\rho}\cdot\frac{1}{\theta}$$
> donde $\theta$ es el parámetro de conducta.

Esto unifica el análisis de incidencia fiscal, pass-through de costos y poder de mercado en un solo marco. Es el puente formal entre la OI y la hacienda pública.

### 4.4 Estimación empírica del pass-through

```r
# Diseño estándar: shock de costo exógeno con efectos fijos
feols(log(precio) ~ log(costo_insumo) | producto + mercado + tiempo,
      data = d, cluster = ~mercado)
# El coeficiente es la elasticidad de pass-through.
# Para pass-through en niveles (soles por sol), usar niveles.

# Dinámica: ¿cuánto tarda?
feols(log(precio) ~ l(log(costo), 0:6) | producto + tiempo, data = pd)
# La suma de coeficientes es el pass-through de largo plazo.
# Asimetría ("rockets and feathers"):
feols(d(log(precio)) ~ d_pos + d_neg | producto + tiempo, data = pd)
# d_pos = max(Δlog c, 0); d_neg = min(Δlog c, 0). Testear d_pos = -d_neg.
```

> **🇵🇪 Perú — aplicación directa.** El pass-through del tipo de cambio a precios de bienes importados, y la **asimetría** del pass-through de precios internacionales a precios de combustibles (el fenómeno "sube como cohete, baja como pluma"), son preguntas de política muy debatidas. Con datos de Osinergmin (precios de grifos, diarios, georreferenciados, públicos vía Facilito) y precios internacionales, es una estimación que se puede hacer en una semana y tiene audiencia inmediata. **El Fondo de Estabilización de Precios de Combustibles (FEPC) genera además discontinuidades regulatorias explotables.**

---

## 5. Simulación de fusiones

### 5.1 El procedimiento completo

```
ENTRADA: demanda estimada (α̂, β̂, σ̂ o θ̂₂), precios y shares observados

PASO 1 — Recuperar costos marginales pre-fusión
  Δ⁰ = matriz de derivadas en (p⁰, s⁰)
  mc = p⁰ + (Δ⁰' ⊙ H⁰)⁻¹ s⁰
  ✓ VERIFICAR: todos los mc > 0. Si no, parar: el modelo está mal.

PASO 2 — Modificar la matriz de propiedad
  H¹ = H⁰ con los bloques de las firmas fusionadas unidos

PASO 3 — Aplicar eficiencias (si las hay)
  mc¹ = mc · (1 − e),  e = reducción porcentual de costo

PASO 4 — Resolver el nuevo equilibrio (punto fijo)
  Resolver en p:  p = mc¹ − (Δ(p)' ⊙ H¹)⁻¹ s(p)
  Iterar hasta convergencia (o usar un solver de sistemas no lineales)

PASO 5 — Reportar
  Δp por producto y promedio ponderado
  ΔCS = (1/α)·[ln Σexp(δ¹) − ln Σexp(δ⁰)] · M     [Cap. 05 §6.2]
  Δπ de las fusionadas y de los rivales
  Eficiencia de compensación: ¿qué e hace Δp = 0?
```

```python
# En pyblp es directo
costs = results.compute_costs()
changed_ownership = build_ownership(product_data, merger_rule)
prices_post = results.compute_prices(firm_ids=changed_ownership, costs=costs)
shares_post = results.compute_shares(prices_post)

delta_p = (prices_post - product_data['prices']) / product_data['prices']
cs_change = results.compute_consumer_surpluses(prices_post) - \
            results.compute_consumer_surpluses()

# Eficiencia de compensación: buscar e tal que Δp promedio = 0
from scipy.optimize import brentq
f = lambda e: np.average(results.compute_prices(firm_ids=changed_ownership,
                                                costs=costs*(1-e)) -
                         product_data['prices'], weights=shares) 
e_star = brentq(f, 0, 0.5)
```

### 5.2 UPP y GUPPI: el atajo que usan las autoridades

Simular una fusión completa requiere estimar demanda. Las autoridades necesitan un filtro rápido. Farrell y Shapiro (2010) proponen:

**Upward Pricing Pressure** para el producto 1 tras fusionar las firmas de 1 y 2:
$$UPP_1 = \underbrace{D_{12}\cdot(p_2-mc_2)}_{\text{ganancia por desvío recapturado}}-\underbrace{e\cdot mc_1}_{\text{eficiencia}}$$

**GUPPI** (versión normalizada, la que se usa en la práctica):
$$\boxed{\ GUPPI_1 = D_{12}\times \frac{p_2-mc_2}{p_2}\times\frac{p_2}{p_1} = D_{12}\cdot \mathcal{L}_2\cdot \frac{p_2}{p_1}\ }$$

**Interpretación:** es el aumento del costo de oportunidad de vender una unidad de producto 1, expresado como fracción del precio de 1.

**Umbrales usados en la práctica:**
- GUPPI < 5%: típicamente no preocupa.
- 5%–10%: zona gris, requiere análisis adicional.
- \> 10%: señal fuerte, se pasa a simulación completa.

**Ventaja decisiva:** solo requiere **diversion ratio** y **margen**. Ambos pueden obtenerse de encuestas y de contabilidad de la empresa, **sin estimar demanda**. Por eso es la herramienta de filtro estándar.

### 5.3 El test SSNIP, implementado

La definición de mercado relevante pregunta: ¿podría un monopolista hipotético de este conjunto de productos subir el precio 5–10% de forma rentable?

**Criterio de pérdida crítica (critical loss):**
$$\text{Pérdida crítica} = \frac{\Delta p}{\Delta p + \mathcal{L}}$$

donde $\Delta p$ es el aumento propuesto (5% o 10%) y $\mathcal L$ el margen actual.

**Pérdida real** $= |\varepsilon|\cdot\Delta p$ (aproximadamente).

**Regla:** si pérdida real < pérdida crítica, el aumento es rentable ⇒ el conjunto de productos **es** un mercado relevante. Si no, hay que ampliar el mercado e iterar.

**Ejemplo numérico.** Margen $\mathcal L = 40\%$, SSNIP $= 5\%$.
Pérdida crítica $= 0.05/(0.05+0.40)=11.1\%$.
Si la elasticidad del agregado es $-1.5$, la pérdida real es $1.5\times 5\% = 7.5\% < 11.1\%$ ⇒ el aumento es rentable ⇒ **mercado relevante confirmado**.

> **⚠️ La falacia del celofán.** Si el precio actual ya es de monopolio, la elasticidad al precio actual es alta por construcción (el monopolista opera donde $|\varepsilon|>1$), y el test SSNIP concluye erróneamente que el mercado es más amplio de lo que es. **Esto hace que el test SSNIP sea inapropiado para casos de abuso de posición de dominio** (donde el precio ya puede ser supracompetitivo) y apropiado para fusiones (donde el precio pre-fusión es el competitivo relevante).

---

## 6. Nash-in-Nash: mercados con negociación

Cuando los precios no se fijan unilateralmente sino que se **negocian** (proveedor–retailer, aseguradora–hospital, farmacéutica–EPS), Bertrand–Nash no aplica.

**Solución de Nash en pares (Horn y Wolinsky 1988; Collard-Wexler, Gowrisankaran y Lee 2019):** cada par $(i,j)$ negocia bilateralmente su precio tomando como dados todos los demás acuerdos, y el resultado maximiza el producto de Nash:
$$\max_{\tau_{ij}}\ \big[\pi_i(\tau_{ij})-\pi_i^{\text{sin }j}\big]^{b}\cdot\big[\pi_j(\tau_{ij})-\pi_j^{\text{sin }i}\big]^{1-b}$$

donde $b$ es el **poder de negociación** y los términos de desacuerdo son los beneficios si la negociación falla.

**CPO:**
$$b\cdot\frac{\partial \pi_j/\partial \tau}{\pi_j - d_j}=-(1-b)\cdot\frac{\partial\pi_i/\partial\tau}{\pi_i-d_i}$$

**Aplicaciones:** seguros de salud vs. clínicas, cadenas de supermercados vs. proveedores de consumo masivo, operadores de telecom vs. proveedores de contenido.

> **🇵🇪 Perú.** La relación entre EPS/aseguradoras y clínicas privadas, y entre las cadenas de supermercados (Cencosud, Falabella, Supermercados Peruanos) y los proveedores de consumo masivo, son casos de libro para Nash-in-Nash. La concentración del retail moderno en Perú hace que el poder de negociación sea un tema de política activa, y no hay trabajo estructural publicado sobre ello.

---

## 7. Checklist del lado de la oferta

- [ ] ¿Todos los $mc$ recuperados son positivos?
- [ ] ¿Los $mc$ se correlacionan sensatamente con shifters de costo observados? (Este es el test de conducta de Berry–Haile, Cap. 02 §6.5.)
- [ ] ¿Los márgenes implícitos se parecen a los márgenes contables reportados por las empresas? (Diferencias grandes señalan problemas.)
- [ ] ¿Todas las elasticidades propias son $<-1$? (Consistencia con la CPO.)
- [ ] ¿Probé modelos alternativos de conducta (Cournot, cartel) y comparé los $mc$?
- [ ] En la simulación: ¿reporté la eficiencia de compensación y no solo $\Delta p$?
- [ ] ¿Reporté el efecto sobre los **rivales** (que también suben precios)?

---

## 8. Lecturas

- Nevo (2001), "Measuring Market Power in the Ready-to-Eat Cereal Industry", *Econometrica* 69(2). — markups de BLP en la práctica.
- Farrell y Shapiro (2010), "Antitrust Evaluation of Horizontal Mergers: An Economic Alternative to Market Definition", *BE Journal* 10(1). — UPP.
- Weyl y Fabinger (2013), "Pass-Through as an Economic Tool", *JPE* 121(3).
- Bulow y Pfleiderer (1983), "A Note on the Effect of Cost Changes on Prices", *JPE* 91(1).
- Miller, Remer, Ryan y Sheu (2017), "Upward Pricing Pressure as a Predictor of Merger Price Effects", *IJIO* 52.
- Collard-Wexler, Gowrisankaran y Lee (2019), "'Nash-in-Nash' Bargaining: A Microfoundation for Applied Work", *JPE* 127(1).
- Björnerstedt y Verboven (2016), "Does Merger Simulation Work? Evidence from the Swedish Analgesics Market", *AEJ: Applied* 8(3). — validación ex post.
