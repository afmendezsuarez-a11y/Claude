# 12 · Vínculos con la macroeconomía

> **Capítulo nuevo.** La OI y la macro se reunieron en la última década alrededor de una pregunta: **¿han subido los markups, y qué implica eso para la inflación, la inversión, la participación del trabajo y la política monetaria?** Este capítulo conecta el aparato de los Caps. 06–07 con los modelos macro, y muestra dónde las elasticidades que estimamos entran en una ecuación de Phillips.

---

## 1. La idea

El modelo macro estándar (neokeynesiano) contiene un supuesto de OI que casi nunca se discute: **competencia monopolística con elasticidad de demanda constante (Dixit–Stiglitz)**, lo que implica markup constante:
$$\mu = \frac{\varepsilon}{\varepsilon-1}$$

Si los markups son **constantes**, entonces:
- El pass-through de costos a precios es 1 a 1.
- Las fluctuaciones de markup no amplifican ni amortiguan shocks.
- La participación del trabajo es constante.
- La curva de Phillips es la estándar.

**Las tres cosas que la OI empírica ha mostrado y que rompen ese supuesto:**
1. Los markups **varían** — entre firmas, en el tiempo y con el ciclo.
2. Los markups **han subido** en economías avanzadas desde ~1980.
3. La **mala asignación** de recursos entre firmas con markups distintos es una fuente de pérdida de productividad agregada.

---

## 2. Markups agregados: la literatura De Loecker–Eeckhout

### 2.1 La metodología

Del Cap. 01 §3.4, el markup del lado de la producción:
$$\mu_{it}=\theta^V_{it}\cdot\Big(\frac{P^V_{it}V_{it}}{P_{it}Y_{it}}\Big)^{-1}$$

donde $\theta^V$ es la elasticidad de producción del insumo variable (estimada con ACF o similar) y el paréntesis es la participación del insumo en los ingresos, directamente leíble de estados financieros.

**El markup agregado es el promedio ponderado:**
$$\mu_t = \sum_i \omega_{it}\,\mu_{it}$$

### 2.2 Los hallazgos y la controversia

**De Loecker, Eeckhout y Unger (2020, QJE):** el markup agregado en EE.UU. pasó de ~1.21 en 1980 a ~1.61 en 2016. El aumento es impulsado por la **reasignación** hacia firmas de markup alto (el percentil 90 de la distribución subió mucho; la mediana casi no se movió).

**Las objeciones (importantes, y hay que conocerlas):**

| Crítica | Argumento |
|---|---|
| **Costos fijos crecientes** (Traina 2018; Basu 2019) | Si se usa COGS como insumo variable, se excluye SG&A. Las empresas modernas tienen mucho SG&A (marketing, I+D, software). Incluyéndolo, el aumento del markup es mucho menor |
| **Elasticidad de producción constante** | Si $\theta^V$ varía en el tiempo o entre firmas y se estima un solo valor, el markup estimado absorbe esa variación |
| **Sesgo de selección de Compustat** | La muestra son empresas cotizadas, que se han vuelto más grandes y concentradas; no representan la economía |
| **Markups vs. mark-ups de precio-costo medio** | El aumento del *margen* puede reflejar cambio de la estructura de costos (más fijos, menos variables), no más poder de mercado |
| **Discrepancia con la vía de demanda** | Los markups estimados con BLP en industrias específicas no muestran el mismo aumento dramático |

> **La posición defendible:** ha habido un aumento del poder de mercado medido, concentrado en el extremo superior de la distribución y asociado a intangibles. La magnitud exacta es muy sensible al tratamiento de los costos fijos. **Para una tesis, la contribución honesta es hacer el ejercicio con ambos tratamientos y con las dos rutas (producción y demanda) en un mismo sector.**

---

## 3. Markups en el modelo neokeynesiano

### 3.1 Dónde entra el markup

En el modelo NK estándar, la curva de Phillips neokeynesiana es:
$$\pi_t = \beta E_t\pi_{t+1} + \kappa\,\widehat{mc}_t$$
$$\widehat{mc}_t = \widehat{w}_t - \widehat{\text{prod}}_t = -\hat\mu_t$$

**El markup es el inverso del costo marginal real.** Toda la dinámica inflacionaria del modelo NK pasa por fluctuaciones del markup.

**Consecuencia:** si los markups son **contracíclicos** (suben en recesión), amortiguan la caída de la inflación; si son **procíclicos**, la amplifican. La evidencia empírica es mixta y depende del sector — **y aquí es donde la OI tiene algo que decirle a la macro que la macro no puede obtener de sus propios datos**.

**Recordar Rotemberg–Saloner (Cap. 08 §2.5):** en industrias con colusión tácita, los markups son **contracíclicos** por la lógica del incentivo a desviar. Es una microfundamentación de la ciclicidad del markup que viene directamente de la OI.

### 3.2 Demanda Kimball: markups variables microfundamentados

El problema con Dixit–Stiglitz es que fuerza $\mu$ constante. La **agregación de Kimball (1995)** permite que la elasticidad de demanda dependa de la participación relativa:
$$\sum_i \Psi\!\left(\frac{y_i}{Y}\right)=1$$

Esto genera **"superelasticidad"**: la elasticidad percibida crece cuando la firma sube su precio relativo, de modo que:
$$\frac{\partial \mu_i}{\partial (p_i/P)}<0$$

**Consecuencias macro de Kimball:**
1. **Complementariedades estratégicas en precios:** una firma no quiere alejar su precio del de los rivales ⇒ **mayor rigidez real** ⇒ la curva de Phillips se aplana ⇒ el dinero tiene efectos reales más persistentes.
2. **Pass-through incompleto** de costos idiosincrásicos.
3. La "nueva curva de Phillips plana" observada desde los 90 es consistente con mayor complementariedad estratégica.

> **La conexión directa con los Caps. 05–07:** el logit, el nested logit y BLP **generan endógenamente** markups que dependen de la participación:
> $$\mathcal{L}_j = \frac{1}{\alpha p_j(1-s_j)}\ \text{(logit monoproducto)}$$
> **El logit es una microfundamentación de la demanda Kimball.** Un producto con participación mayor tiene markup mayor; un producto que sube su precio pierde participación y ve caer su markup. La "superelasticidad" de Kimball sale directamente del término $(1-s_j)$.
>
> **Esto es un puente teórico real y poco explotado:** calibrar la superelasticidad de un modelo macro con parámetros estimados de BLP en lugar de elegirla para ajustar momentos agregados.

---

## 4. Pass-through cambiario: donde la OI es indispensable

### 4.1 La pregunta

¿Cuánto de una depreciación de 10% llega a los precios al consumidor? La respuesta determina la política monetaria en economías pequeñas y abiertas.

**Estructura del pass-through (ERPT):**
$$\underbrace{\text{Tipo de cambio}}_{\Delta e}\ \xrightarrow{\rho_1}\ \underbrace{\text{Precio de importación}}_{\text{en frontera}}\ \xrightarrow{\rho_2}\ \underbrace{\text{Precio mayorista}}_{}\ \xrightarrow{\rho_3}\ \underbrace{\text{Precio al consumidor}}_{\text{IPC}}$$

$$ERPT_{\text{total}} = \rho_1\cdot\rho_2\cdot\rho_3$$

**Cada $\rho$ es un pass-through de la Cap. 07 §4**, determinado por la curvatura de la demanda, la estructura de mercado y la proporción de costos locales (distribución, margen minorista).

### 4.2 Por qué el ERPT es incompleto

| Factor | Efecto sobre ERPT |
|---|---|
| **Pricing to market** | El exportador ajusta su margen para no perder participación ⇒ ↓ |
| **Costos locales de distribución** | Diluyen el componente importado ⇒ ↓ |
| **Moneda de facturación** (Gopinath) | Si se factura en USD y el USD no se mueve, no hay pass-through ⇒ ↓ |
| **Curvatura de la demanda** | Elasticidad constante ⇒ ERPT alto; Kimball/logit ⇒ ERPT bajo |
| **Competencia de productos locales** | Más sustitutos locales ⇒ menos pass-through |
| **Credibilidad / anclaje de expectativas** | ↓ |

> **🇵🇪 Perú — el caso de libro.** Perú tiene **dolarización parcial**, es importador neto de bienes manufacturados y alimentos (trigo, maíz, aceite, soya), y exportador de minerales. El ERPT es una de las preguntas centrales de política del BCRP, que publica estimaciones. Pero **la estimación estándar es macro-agregada (VAR, ECM) y no distingue por estructura de mercado**.
>
> **💡 La oportunidad:** estimar ERPT a nivel **producto-mercado**, usando la estructura de competencia de cada categoría. Hipótesis testeable: *el ERPT es mayor en categorías más concentradas* (donde la demanda es menos elástica para la firma) **o menor** (donde hay más margen para absorber). El signo es una pregunta empírica abierta y la respuesta tiene implicaciones directas para la política monetaria. Datos: precios del IPC a nivel de variedad (INEI), aranceles y precios de importación (SUNAT), tipo de cambio (BCRP), concentración sectorial (Produce, censos económicos).

### 4.3 Estimación

```r
# ERPT con estructura de mercado
feols(d(log(precio_jt)) ~ d(log(tc_t)):share_importado_j +
                          d(log(tc_t)):HHI_j +
                          d(log(costo_local_t)) |
                          producto + tiempo,
      data = d, cluster = ~producto)
# El coeficiente de interacción con HHI es la pregunta de investigación.
```

---

## 5. Concentración, participación del trabajo y misallocation

### 5.1 La caída del labor share

Autor, Dorn, Katz, Patterson y Van Reenen (2020) — hipótesis de las **"superstar firms"**:
1. La competencia global y tecnológica favorece a las firmas más productivas.
2. Esas firmas tienen **markups altos** y, por tanto, **menor participación del trabajo en el valor agregado** (un markup alto significa que los ingresos exceden los costos, incluidos los laborales).
3. La reasignación hacia ellas **baja el labor share agregado** sin que baje en ninguna firma individual.

**Aritmética del vínculo markup-labor share.** Con un insumo trabajo flexible:
$$\text{labor share}_i = \frac{wL_i}{P_iY_i}=\frac{\theta^L_i}{\mu_i}$$

**El labor share es la elasticidad de producción del trabajo dividida por el markup.** Markups que suben ⇒ labor share que cae, mecánicamente. **Esta identidad es el puente exacto entre la OI y la macro distributiva.**

### 5.2 Misallocation

Hsieh y Klenow (2009): la dispersión de productividad marginal entre firmas (medida como dispersión de $TFPR$) implica que los recursos están mal asignados. **Los markups dispersos son una fuente de esa dispersión**: una firma con markup alto produce menos de lo socialmente óptimo.

**Pérdida de TFP agregada:**
$$\frac{\text{TFP}}{\text{TFP}^{\text{eficiente}}}=\Big[\sum_i\Big(\frac{\mu_i}{\bar\mu}\Big)^{-\sigma}\cdot(\cdot)\Big]^{\frac{1}{\sigma-1}}$$

Hsieh y Klenow estiman que igualar la TFPR al nivel de EE.UU. aumentaría la TFP manufacturera en 30–50% en China e India.

> **🇵🇪 Perú — la pregunta de investigación más importante del capítulo.** Perú tiene **~70% de empleo informal** y una distribución de tamaño de empresa extremadamente sesgada hacia las microempresas. La dispersión de productividad es enorme. La pregunta es qué fracción de la brecha de productividad de Perú con la frontera se debe a:
> - **misallocation por poder de mercado** (markups dispersos),
> - **misallocation por fricciones financieras** (acceso al crédito),
> - **misallocation por informalidad y distorsiones regulatorias** (umbrales de tamaño que crean incentivos a no crecer).
>
> Separar estos canales requiere datos de panel de firmas (Encuesta Económica Anual de Produce, planilla electrónica de SUNAT) y el aparato de los Caps. 01 §3.4 y 07. **Es una agenda de varios papers y de relevancia de política de primer orden.** El canal de los umbrales regulatorios (la "trampa de la microempresa": regímenes tributarios y laborales que cambian al cruzar umbrales de ventas o empleo) da además identificación por **discontinuidad en regresión**.

---

## 6. Common ownership: la frontera (y la polémica)

**Hipótesis (Azar, Schmalz y Tecu 2018):** cuando los mismos fondos indexados son accionistas principales de firmas rivales, las firmas internalizan parcialmente el efecto de sus precios sobre los rivales, lo que **eleva los precios sin ningún acuerdo explícito**.

**Formalización:** generalizar la matriz de propiedad del Cap. 07:
$$H_{jk}=\frac{\sum_s \gamma_{sf(j)}\,\beta_{sf(k)}}{\sum_s \gamma_{sf(j)}\,\beta_{sf(j)}}$$
donde $\gamma$ son los derechos de control y $\beta$ los derechos de flujo de caja de cada accionista $s$.

**Con common ownership, $H$ deja de ser binaria**: tiene entradas entre 0 y 1 entre firmas distintas. El resto del aparato del Cap. 07 funciona **sin cambios** — los markups suben mecánicamente.

**La polémica:** los estudios empíricos (aerolíneas, bancos) han sido fuertemente cuestionados por problemas de medición y endogeneidad (Dennis, Gerardi y Schenone 2022; Backus, Conlon y Sinkinson 2021). La teoría es sólida; la magnitud empírica está en disputa.

> **🇵🇪 Perú.** La estructura de propiedad en Perú está dominada por **grupos económicos familiares con participaciones cruzadas** y por las **AFP**, que son accionistas significativas de muchas empresas de la BVL simultáneamente. Esto es estructuralmente análogo a la hipótesis de common ownership, con la diferencia de que las participaciones de las AFP son más grandes y más concentradas que las de los fondos indexados en EE.UU. **Construir la matriz $H$ generalizada para la BVL con datos públicos de la SMV y testear si los márgenes son mayores donde la propiedad cruzada es más densa es un ejercicio factible y novedoso.**

---

## 7. Tabla de puentes OI ↔ Macro

| Objeto de OI | Objeto macro | Conexión |
|---|---|---|
| Elasticidad de demanda $\varepsilon$ | Elasticidad de sustitución Dixit–Stiglitz | $\mu=\varepsilon/(\varepsilon-1)$ |
| Markup $\mathcal L$ | Costo marginal real en la NKPC | $\widehat{mc}=-\hat\mu$ |
| Logit $(1-s_j)$ | Superelasticidad de Kimball | Complementariedad estratégica |
| Pass-through $\rho$ | ERPT, incidencia fiscal | Weyl–Fabinger |
| Markups dispersos | Misallocation, pérdida de TFP | Hsieh–Klenow |
| Markup $\mu_i$ | Labor share $=\theta^L/\mu$ | Identidad contable |
| Matriz de propiedad $H$ | Common ownership | $H$ generalizada |
| Rotemberg–Saloner | Ciclicidad del markup | Microfundamentación |
| Barreras de entrada | Dinámica de firmas, crecimiento | Modelos de entrada/salida |

---

## 8. Lecturas

- De Loecker, Eeckhout y Unger (2020), "The Rise of Market Power and the Macroeconomic Implications", *QJE* 135(2).
- Basu (2019), "Are Price-Cost Markups Rising in the United States?", *JEP* 33(3). — la crítica equilibrada.
- Traina (2018), "Is Aggregate Market Power Increasing?", Stigler Center WP.
- Autor, Dorn, Katz, Patterson y Van Reenen (2020), "The Fall of the Labor Share and the Rise of Superstar Firms", *QJE* 135(2).
- Hsieh y Klenow (2009), "Misallocation and Manufacturing TFP in China and India", *QJE* 124(4).
- Kimball (1995), "The Quantitative Analytics of the Basic Neomonetarist Model", *JMCB* 27(4).
- Klenow y Willis (2016), "Real Rigidities and Nominal Price Changes", *Economica* 83.
- Gopinath, Itskhoki y Rigobon (2010), "Currency Choice and Exchange Rate Pass-Through", *AER* 100(1).
- Burstein y Gopinath (2014), "International Prices and Exchange Rates", *Handbook of International Economics* vol. 4.
- Azar, Schmalz y Tecu (2018), "Anticompetitive Effects of Common Ownership", *Journal of Finance* 73(4).
- Backus, Conlon y Sinkinson (2021), "Common Ownership in America: 1980–2017", *AEJ: Micro* 13(3).
