# 11 · Valuation: de elasticidades a valor

> **Capítulo nuevo.** El eslabón que nunca se enseña. Un modelo de demanda produce elasticidades; un DCF requiere supuestos de margen, crecimiento y riesgo. Este capítulo construye el puente formal entre ambos y muestra que los supuestos que un analista financiero escribe "a ojo" en una celda de Excel son objetos estimables con el aparato de los Caps. 03–07.

---

## 1. La idea

Un DCF típico tiene cuatro supuestos que determinan ~90% del valor:

```
V = Σ_t  FCF_t / (1+WACC)^t  +  TV_T / (1+WACC)^T

      ┌──────────────────────────────────────────────────┐
      │  (1) crecimiento de ingresos  g                   │
      │  (2) margen operativo          m                  │
      │  (3) costo de capital          WACC               │
      │  (4) crecimiento terminal      g_∞  (y duración   │
      │      de la ventaja competitiva)                   │
      └──────────────────────────────────────────────────┘
```

**Cada uno de los cuatro es un objeto de organización industrial:**

| Supuesto del DCF | Objeto de OI | Capítulo |
|---|---|---|
| Margen operativo $m$ | Índice de Lerner $=1/\|\varepsilon\|$, ajustado por cartera | 07 §2 |
| Crecimiento $g$ | Demanda de categoría + ganancia de participación | 03, 06 |
| WACC / riesgo | Volatilidad del flujo = f(elasticidad, pass-through) | 11 §5 |
| Duración de la ventaja | Barreras de entrada, costos de cambio, escala | 07, 09 |
| Valor de sinergias (M&A) | Simulación de fusión | 07 §5 |

**La tesis del capítulo:** un analista que estima la elasticidad de demanda tiene una base empírica para el margen de estado estacionario; uno que no, está extrapolando el margen histórico y rezando.

---

## 2. Del Lerner al margen EBITDA

### 2.1 La traducción

La regla de Lerner da el margen de **contribución** sobre costo marginal:
$$\mathcal{L}=\frac{p-mc}{p}=\frac{1}{|\varepsilon|}\quad\text{(monoproducto)};\qquad \mathcal{L}_j=\frac{1}{\alpha p_j\big(1-\sum_{k\in\mathcal{F}}s_k\big)}\cdot\frac{1}{p_j}\ \text{(logit multiproducto)}$$

El margen **EBITDA** resta además los costos fijos de operación:
$$\text{Margen EBITDA}=\mathcal{L}-\frac{CF}{\text{Ventas}}$$

$$\boxed{\ \text{Margen EBITDA}\approx \frac{1}{|\varepsilon|}-\frac{\text{Costos fijos}}{\text{Ventas}}\ }$$

### 2.2 Usar esto como test de consistencia

**Ejemplo.** Empresa de bebidas con margen EBITDA reportado de 22% y costos fijos (SG&A + depreciación) de 18% de ventas.

$$\frac{1}{|\varepsilon|}=0.22+0.18=0.40 \quad\Longrightarrow\quad |\varepsilon|=2.5$$

**La pregunta diagnóstica:** ¿es $-2.5$ una elasticidad plausible para esta empresa?
- Para una **marca** de bebidas: sí, está en el rango típico (−2 a −5, Cap. 03 §4.4).
- Para una empresa que **es** la categoría (monopolio local): no; implicaría que la categoría es muy elástica, lo cual contradice la evidencia.

**Si el margen implícito requiere una elasticidad implausible, el margen no es sostenible.** O la empresa tiene poder de mercado que atraerá entrada o regulación, o hay un error en los números. **Este cálculo de 30 segundos es la mejor prueba de sanidad que existe para un supuesto de margen terminal.**

### 2.3 El margen en el valor terminal: el error más caro de la valuación

El valor terminal suele ser 60–80% del valor total del DCF. Y el supuesto implícito más común —"el margen actual se mantiene a perpetuidad"— es económicamente insostenible si no hay barreras de entrada.

**El marco correcto:**

$$m_t = m^{\text{comp}} + \big(m_0 - m^{\text{comp}}\big)\cdot e^{-\lambda t}$$

donde $m^{\text{comp}}$ es el margen competitivo (el que deja retorno igual al costo de capital) y $\lambda$ la tasa de **erosión de la ventaja competitiva**.

**¿De dónde sale $\lambda$?** De la OI:
- Alta entrada observada en el sector ⇒ $\lambda$ alta.
- Costos de cambio altos, efectos de red, escala mínima eficiente grande ⇒ $\lambda$ baja.
- Evidencia empírica directa: la **persistencia de los beneficios anormales**. La literatura (Mueller 1986; Waring 1996) encuentra que el ROA anormal tiene una vida media de **3 a 7 años** en la industria típica, pero mucho más larga en industrias con activos intangibles y barreras regulatorias.

> **La implicación práctica:** usar $\lambda$ tal que la vida media sea 5 años salvo que haya una razón de OI documentada para lo contrario. Un DCF que asume margen constante a perpetuidad en un sector sin barreras está **sobrevalorando sistemáticamente**.

---

## 3. Crecimiento: descomposición estructural

$$g_{\text{ingresos}} = \underbrace{g_{\text{categoría}}}_{\text{macro + demografía}} + \underbrace{\Delta s}_{\text{participación}} + \underbrace{\Delta p}_{\text{precio}}$$

**Cada componente es estimable:**

| Componente | Fuente | Método |
|---|---|---|
| $g_{\text{categoría}}$ | Elasticidad-ingreso × crecimiento del PBI per cápita + crecimiento poblacional | Cap. 03 §4.3 / Cap. 04 §4.1 |
| $\Delta s$ | Modelo de demanda + supuestos de acción competitiva | Cap. 06 |
| $\Delta p$ | Pass-through de inflación de costos + poder de fijación | Cap. 07 §4 |

**Ejemplo con números peruanos.** Categoría de alimentos procesados:
- Elasticidad-ingreso estimada (QUAIDS, ENAHO): $\eta = 0.9$.
- Crecimiento esperado del PBI per cápita: 2.0% anual.
- Crecimiento poblacional: 1.0%.
- ⇒ $g_{\text{categoría}} = 0.9\times 2.0 + 1.0 = 2.8\%$ real.
- Si la empresa mantiene participación y hace pass-through pleno de la inflación (3%): $g_{\text{nominal}} \approx 5.9\%$.

**Un modelo de ingresos que proyecte 12% nominal a 10 años para esta empresa está asumiendo ganancia sostenida de participación.** Eso requiere una historia competitiva explícita: ¿a quién se la quita y por qué no reacciona? **Este es el tipo de pregunta que la OI responde y el modelo financiero suele evadir.**

---

## 4. Valor por la vía del cliente

Para negocios de suscripción, retail con lealtad, telecom, seguros:

$$V = N_0\cdot CLV + \sum_{t}\frac{N_t^{\text{nuevos}}\cdot CLV_t}{(1+d)^t} - \text{Costos fijos}$$

Con el CLV del Cap. 10 §6:
$$CLV=\frac{m\cdot r}{1+d-r}-CAC$$

**La conexión clave:** $m$ y $r$ **no son parámetros libres**: $m$ viene del Lerner (§2) y $r$ del modelo de elección con dependencia de estado (Cap. 10 §6). **Un modelo de demanda estimado da ambos.**

**Análisis de sensibilidad que importa.** Con $d=10\%$:

| $r$ | Multiplicador $r/(1+d-r)$ | Lectura |
|---|---|---|
| 0.60 | 1.20 | Negocio transaccional |
| 0.70 | 1.75 | |
| 0.80 | 2.67 | |
| 0.90 | 4.50 | Negocio de suscripción sano |
| 0.95 | 6.33 | Casi utility |

**La no linealidad es brutal.** Pasar de 80% a 90% de retención **duplica** el valor del cliente. Por eso las valuaciones de SaaS son tan sensibles al churn y por eso los costos de cambio son la variable estratégica más valiosa. **Y los costos de cambio son estimables** (Cap. 10 §6).

---

## 5. Riesgo: por qué la elasticidad afecta el WACC

### 5.1 El canal del apalancamiento operativo

$$\text{EBIT} = (p-c)\cdot Q - CF$$

$$\frac{d\,\text{EBIT}}{\text{EBIT}} = \underbrace{\frac{(p-c)Q}{\text{EBIT}}}_{\text{DOL}}\cdot\frac{dQ}{Q}$$

El **grado de apalancamiento operativo (DOL)** amplifica la volatilidad de la demanda hacia los beneficios. Y la volatilidad de $Q$ depende de la elasticidad y del pass-through:

$$\text{Var}(\Delta\ln Q) = \varepsilon^2\,\text{Var}(\Delta \ln p) + \eta^2\,\text{Var}(\Delta\ln Y) + 2\varepsilon\eta\,\text{Cov}(\cdot)$$

**Cadena completa:**
$$\text{Elasticidad-ingreso alta} \Rightarrow \text{demanda cíclica} \Rightarrow \beta \text{ alto} \Rightarrow \text{WACC alto}$$

**Esto explica regularidades conocidas:**
- Bienes de lujo ($\eta > 1$): betas altos (1.2–1.6).
- Bienes básicos / staples ($\eta < 1$): betas bajos (0.5–0.8).
- Utilities reguladas (demanda muy inelástica, precio fijado): betas más bajos aún.

**Y da un camino de estimación independiente del beta de mercado:** para una empresa sin historial bursátil (privada, pre-IPO), estimar $\eta$ con datos de demanda del sector permite **inferir el beta** sin necesitar comparables líquidos. Es un aporte real a la valuación de empresas peruanas, donde la BVL tiene muy pocos comparables líquidos y los betas de mercados desarrollados se trasladan con ajustes ad hoc.

### 5.2 Pass-through y riesgo inflacionario

Una empresa con pass-through $\rho \approx 1$ está protegida contra shocks de costo; una con $\rho\approx 0.4$ absorbe el 60% de cualquier shock en su margen.

$$\frac{\partial\,\text{margen}}{\partial c}=\frac{\rho-1}{p}\cdot(\cdot)$$

**Para valorar en un contexto de inflación volátil (relevante en la región), el pass-through es tan importante como el margen.** Es estimable con los métodos del Cap. 07 §4.4.

---

## 6. M&A: valuación de sinergias con simulación de fusión

### 6.1 El marco

$$V_{\text{combinada}} = V_A + V_B + \underbrace{S_{\text{costo}}}_{\text{eficiencias}} + \underbrace{S_{\text{precio}}}_{\text{poder de mercado}} - \underbrace{\text{Costos de integración}}_{} - \underbrace{\text{Riesgo regulatorio}}_{}$$

**Lo que la mayoría de los modelos de M&A ignoran:** $S_{\text{precio}}$ **es cuantificable** con la simulación del Cap. 07 §5.

```
1. Estimar demanda del sector (o usar diversion ratios de encuesta)
2. Recuperar mc pre-fusión
3. Cambiar H y resolver el nuevo equilibrio
4. Δπ de la entidad combinada = S_precio
5. ΔCS = el daño al consumidor = lo que mirará la autoridad
```

### 6.2 El cálculo que previene la sorpresa regulatoria

**El mismo cálculo que usa el banquero para justificar el precio de la adquisición es el que usará la autoridad para bloquearla.**

$$\text{Si } S_{\text{precio}} \gg S_{\text{costo}}\ \Longrightarrow\ \Delta CS < 0 \text{ grande}\ \Longrightarrow\ \text{riesgo de bloqueo o remedios}$$

**Protocolo recomendado en una due diligence:**
1. Calcular el GUPPI (Cap. 07 §5.2). Solo requiere diversion ratio y margen.
2. Si GUPPI > 10%, **asumir que habrá revisión sustantiva** y descontar el valor por probabilidad de bloqueo y por el costo de remedios (desinversiones).
3. Calcular la **eficiencia de compensación**: ¿qué reducción de costo haría que los precios no subieran? Si es mayor que las sinergias creíbles, el caso regulatorio es difícil.
4. Modelar escenarios: aprobación limpia / aprobación con remedios / bloqueo, con probabilidades.

> **🇵🇪 Perú — nuevo desde 2021.** Con la Ley 31112, las operaciones que superan los umbrales (expresados en UIT, sobre ventas o activos conjuntos y sobre el valor individual de al menos dos de las partes) requieren **autorización previa de INDECOPI**. Esto cambió materialmente la estructura de las transacciones en Perú: hay plazos, hay condicionamientos posibles, y hay riesgo de bloqueo. **Toda valuación de M&A en Perú posterior a 2021 debe incluir el análisis de competencia como línea del modelo, no como nota al pie.** Verificar los umbrales vigentes, que se actualizan.

---

## 7. Opciones reales: cuando el DCF no basta

El DCF asume un plan fijo. La realidad tiene flexibilidad, y la flexibilidad vale:

| Opción | Analogía financiera | Cuándo domina |
|---|---|---|
| Expandir | Call | Mercado creciente e incierto |
| Abandonar | Put | Alta incertidumbre, activos recuperables |
| Diferir | Call americana | Irreversibilidad + información que llega |
| Escalar / contraer | Spread | Capacidad modular |

**El resultado central (Dixit y Pindyck 1994):** con irreversibilidad e incertidumbre, **la regla de "invertir si VPN > 0" es incorrecta**. El umbral correcto es VPN > valor de la opción de esperar, que puede ser 2–3 veces el costo de inversión.

**Conexión con la OI:** la incertidumbre relevante es la de la **demanda** y la de la **respuesta competitiva**. La volatilidad $\sigma$ que entra en la fórmula de la opción es estimable del modelo de demanda. Y la **competencia erosiona el valor de esperar**: si un rival puede moverse primero, la opción de diferir vale menos (juegos de opciones reales; Grenadier 2002).

---

## 8. Empresas reguladas: valuación con tarifas

Para distribución eléctrica, agua, telecomunicaciones reguladas, infraestructura de transporte — sectores grandes en la BVL y en el mercado de infraestructura peruano.

$$V = \sum_t\frac{\text{RAB}_t\cdot \text{WACC}_{\text{reg}} + \text{OPEX recuperable}_t}{(1+\text{WACC})^t}$$

**El valor lo determina el marco regulatorio, no la demanda:**
- **RAB** (base de activos regulados) y su valorización.
- **WACC regulatorio** fijado por el regulador (Osinergmin, Sunass, Ositran, OSIPTEL).
- Factor de eficiencia $X$ en esquemas price-cap: $\Delta p \le \text{IPC} - X$.
- Periodicidad de la revisión tarifaria (típicamente 4-5 años).

**El riesgo principal es regulatorio, no de mercado.** La valuación debe modelar escenarios de revisión tarifaria.

> **🇵🇪 Perú.** Los procesos de fijación tarifaria de Osinergmin (distribución eléctrica, VAD) y Sunass son públicos, con documentos técnicos detallados. El WACC regulatorio es un parámetro explícito y discutido. **Modelar la valuación de una distribuidora peruana requiere leer el documento de fijación tarifaria vigente, no proyectar la demanda.** Es un error común de analistas que aplican el marco de empresa competitiva a una regulada.

---

## 9. El workflow completo: de los datos al valor

```
┌─ DATOS ──────────────────────────────────────────────┐
│ Precios, cantidades/shares, características,         │
│ costos de insumos, estados financieros               │
└──────────────────────┬───────────────────────────────┘
                       ▼
┌─ ESTIMACIÓN (Caps. 03-06) ───────────────────────────┐
│ Demanda con IV → ε_jj, ε_jk, η                       │
└──────────────────────┬───────────────────────────────┘
                       ▼
┌─ OFERTA (Cap. 07) ───────────────────────────────────┐
│ mc, markups, diversion ratios, pass-through          │
└──────────────────────┬───────────────────────────────┘
                       ▼
┌─ SUPUESTOS DEL MODELO FINANCIERO ────────────────────┐
│ m  = 1/|ε| − CF/Ventas          (§2)                 │
│ g  = η·g_PBI + g_pob + Δs + ρ·π (§3)                 │
│ λ  = tasa de erosión de margen  (§2.3)               │
│ β  = f(η, DOL, ρ)               (§5)                 │
│ CLV, retención                  (§4)                 │
└──────────────────────┬───────────────────────────────┘
                       ▼
┌─ VALOR ──────────────────────────────────────────────┐
│ DCF + opciones reales + ajuste por riesgo regulatorio│
│ Sensibilidad a ε, λ, ρ — NO solo a WACC y g          │
└──────────────────────────────────────────────────────┘
```

> **El cambio de práctica que propone este capítulo.** Los análisis de sensibilidad estándar varían WACC y $g$ terminal, que son los parámetros sobre los que el analista tiene **menos** información causal. **Variar la elasticidad, la tasa de erosión del margen y el pass-through es más informativo**, porque son los parámetros que la economía del sector determina y que un modelo estimado acota con un intervalo de confianza real.

---

## 10. Checklist para un comité de inversión

- [ ] ¿Qué elasticidad implica el margen que estoy proyectando? ¿Es plausible para este mercado?
- [ ] ¿Qué justifica que el margen se mantenga? ¿Cuál es la barrera concreta?
- [ ] ¿Cuánto del crecimiento proyectado es categoría y cuánto es ganancia de participación? ¿A quién se la quita?
- [ ] ¿Cuál es el pass-through histórico de esta empresa? ¿Sobrevive a un shock de costos?
- [ ] Si es una adquisición: ¿cuál es el GUPPI? ¿Hay riesgo de INDECOPI?
- [ ] ¿La sensibilidad incluye la elasticidad y la erosión de margen, o solo WACC y $g$?
- [ ] Si es regulada: ¿leí el último documento de fijación tarifaria?

---

## 11. Lecturas

- Damodaran (2012), *Investment Valuation*, 3ª ed. — la referencia de valuación; leer junto con este capítulo, no en lugar de él.
- Koller, Goedhart y Wessels, *Valuation* (McKinsey), caps. sobre ROIC y ventaja competitiva.
- Mueller (1986), *Profits in the Long Run*. — persistencia de beneficios anormales.
- Dixit y Pindyck (1994), *Investment under Uncertainty*.
- Grenadier (2002), "Option Exercise Games", *RFS* 15(3).
- Weyl y Fabinger (2013), "Pass-Through as an Economic Tool", *JPE* 121(3).
- Farrell y Shapiro (2010), "Antitrust Evaluation of Horizontal Mergers", *BE Journal* 10(1).
- Corts (1999) y Nevo (2001) para el escepticismo necesario sobre markups estimados.
