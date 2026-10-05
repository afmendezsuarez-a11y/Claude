# 00 · Guía de uso y rutas de lectura

---

## 1. Cómo está construido cada capítulo

Cada capítulo sigue la misma arquitectura de cuatro niveles. Si solo tienes 20 minutos, lee el nivel 1 y el 4.

| Nivel | Qué es | Para quién |
|---|---|---|
| **1. La idea** | El argumento económico en prosa, sin álgebra | Todos |
| **2. La teoría** | Modelo formal, supuestos explícitos, resultados | Investigador / estudiante de doctorado |
| **3. Las demostraciones** | Pruebas completas, paso a paso | Quien va a escribir el paper |
| **4. La práctica** | Datos, código, diagnósticos, errores típicos | Quien tiene un deadline |

Además, tres cajas recurrentes:

> **⚠️ Trampa.** Error que aparece sistemáticamente en seminarios y reportes.

> **🇵🇪 Perú.** Cómo se ve esto en el mercado peruano.

> **💡 Idea de investigación.** Pregunta abierta, con datos y estrategia sugeridos.

---

## 2. Rutas de lectura

### Ruta A — Tesis doctoral en OI empírica (12 semanas)

```
01 (consumidor/productor) → 02 (identificación) → 05 (elección discreta)
→ 06 (BLP) → 07 (oferta) → [08 o 09 o 10 según tema] → 15 (agenda)
→ A (demostraciones) en paralelo
```
Objetivo: una pregunta, un dataset, una estrategia de identificación defendible en un *job market seminar*.

**Entregables intermedios recomendados:**
- Semana 2: una página con el modelo estructural y la lista de parámetros a identificar.
- Semana 4: tabla de datos con dimensiones $(J, T, N)$ y definición explícita de $M_t$.
- Semana 6: resultados de forma reducida (OLS + IV ingenuo) — tu "antes" del paper.
- Semana 9: estimación estructural y contrafactual principal.
- Semana 11: análisis de sensibilidad (3 valores de $M_t$, 2 formas funcionales, 2 conjuntos de instrumentos).

### Ruta B — Consultoría de pricing / estrategia (1 semana)

```
03 (ecuación única) → 07 §2 (markups y Lerner) → 10 (marketing)
→ 11 (valuation) → 14 (playbook)
```
Objetivo: una elasticidad creíble, un markup implícito y una recomendación de precio con su impacto en EBITDA.

### Ruta C — Litigio de competencia / defensa ante INDECOPI (2 semanas)

```
02 (identificación) → 04 o 06 (demanda según datos) → 07 (fusiones, UPP/GUPPI)
→ 08 (colusión y screens) → 09 (predación) → 13 (marco peruano)
```
Objetivo: definición de mercado relevante, cálculo de diversion ratios, test SSNIP implementable, y argumento de daño.

### Ruta D — Valuation / equity research (3 días)

```
11 (completo) → 03 §4 (elasticidades) → 07 §2 (Lerner) → 12 §3 (pass-through)
→ 13 (sector peruano relevante)
```
Objetivo: traducir estructura de mercado en supuestos de margen y crecimiento del DCF, defendibles ante un comité de inversión.

### Ruta E — Macroeconomista interesado en poder de mercado (1 semana)

```
01 §3 (productor) → 12 (completo) → 07 §2 → 06 §5 (agregación)
```

---

## 3. Mapa de dependencias entre capítulos

```
                        01 Consumidor / Productor
                         │              │
            ┌────────────┘              └────────────┐
            ▼                                        ▼
      02 Identificación                      07 Oferta y markups
            │                                   │    │    │
   ┌────────┼────────┐                          │    │    └──► 11 Valuation
   ▼        ▼        ▼                          │    │              │
03 Única  04 AIDS  05 Logit                     │    └──► 12 Macro ─┘
                      │                         │
                      ▼                         ├──► 08 Colusión / Licitaciones
                 06 BLP ────────────────────────┤
                                                ├──► 09 Predación
                                                └──► 10 Marketing

            13 Perú  ·  14 Playbook  ·  15 Agenda   (transversales)
```

**Reglas de precedencia estrictas:**
- No se puede hacer 06 sin 05 (la inversión de Berry presupone la fórmula logit).
- No se puede hacer 07 sin 05 o 06 (los markups salen de la matriz de derivadas de demanda).
- No se puede hacer 11 ni 12 sin 07 (el valor y la macro dependen de markups).
- 02 es prerrequisito de todo lo empírico. Sin identificación no hay nada.

---

## 4. Qué decidir antes de empezar cualquier proyecto

Estas seis preguntas, respondidas por escrito, ahorran meses. Son la versión extendida del checklist de S04/S05.

**Q1. ¿Cuál es la unidad de observación?**
Consumidor-alternativa (micro) → Cap. 05. Producto-mercado (agregado) → Cap. 06. Categoría-periodo (presupuesto) → Cap. 04. Un bien aislado → Cap. 03.

**Q2. ¿Cuántos productos hay y entran/salen?**
$J \le 6$ y estable → AIDS es viable. $J > 10$ o entrada/salida → elección discreta obligatoria (recordar: AIDS necesita $J(J-1)/2$ parámetros $\gamma_{ij}$; con $J=50$ son 1,225).

**Q3. ¿Qué variación exógena tengo?**
Si no puedes nombrar, en una frase, el shock que mueve el precio sin mover la demanda, no tienes proyecto. Tenerlo *después* de ver los datos es *p*-hacking de identificación.

**Q4. ¿Cuál es el bien externo y cuál es $M_t$?**
La decisión más consecuente y menos discutida de toda la OI empírica (S07 lo advierte). Debe ser **exógena** al precio: hogares, población, adultos elegibles —nunca "ventas totales de la categoría", que se mueve con $\xi$.

**Q5. ¿Qué contrafactual quiero correr?**
El contrafactual determina qué parámetros necesitas identificar bien. Si vas a simular una fusión, necesitas elasticidades cruzadas correctas → el logit puro no sirve. Si solo quieres el impacto de un impuesto uniforme, la elasticidad agregada basta.

**Q6. ¿Qué pasaría si mi supuesto clave es falso?**
Escribe la respuesta antes de estimar. Esto es el análisis de sensibilidad del paper, y define si el resultado es robusto o frágil.

---

## 5. Software: qué usar para qué

| Tarea | R | Stata | Python |
|---|---|---|---|
| IV / 2SLS | `fixest::feols` | `ivreghdfe` | `linearmodels.IV2SLS` |
| Instrumentos débiles | `ivmodel` | `weakivtest`, `ivreg2` | `linearmodels` (AR, CLR) |
| AIDS / QUAIDS | `micEconAids` | `quaids` (SSC) | manual + `statsmodels` |
| SUR / 3SLS | `systemfit` | `sureg`, `reg3` | `linearmodels.SUR` |
| Logit condicional | `mlogit` | `asclogit`, `cmclogit` | `xlogit`, `pylogit` |
| Mixed logit | `mlogit`, `gmnl` | `mixlogit`, `cmxtmixlogit` | `xlogit` (GPU) |
| BLP | `BLPestimatoR` | — | **`pyblp`** (estándar de facto) |
| Subastas (GPV) | manual | — | manual + `scipy` |
| Screens de colusión | manual | — | manual |
| Simulación de fusiones | `antitrust` | — | `pyblp` |

**Recomendación operativa:** `pyblp` para todo lo estructural de demanda agregada; `fixest` para forma reducida rápida (es el más veloz para paneles con muchos efectos fijos); Stata solo si el equipo ya está ahí.

---

## 6. Glosario de siglas

| Sigla | Significado |
|---|---|
| **AIDS** | Almost Ideal Demand System (Deaton–Muellbauer 1980) |
| **QUAIDS** | Quadratic AIDS (Banks–Blundell–Lewbel 1997) |
| **LA-AIDS** | Linear Approximate AIDS (índice de Stone) |
| **EASI** | Exact Affine Stone Index demands (Lewbel–Pendakur 2009) |
| **RUM** | Random Utility Model |
| **IIA** | Independence of Irrelevant Alternatives |
| **GEV** | Generalized Extreme Value (McFadden 1978) |
| **BLP** | Berry–Levinsohn–Pakes (1995) |
| **GMM** | Generalized Method of Moments |
| **UPP / GUPPI** | Upward Pricing Pressure / Gross UPP Index |
| **SSNIP** | Small but Significant Non-transitory Increase in Price |
| **GPV** | Guerre–Perrigne–Vuong (2000) |
| **IPV / CV** | Independent Private Values / Common Values |
| **CLC** | Comisión de Defensa de la Libre Competencia (INDECOPI) |
| **SEACE** | Sistema Electrónico de Contrataciones del Estado (Perú) |
| **UIT** | Unidad Impositiva Tributaria (Perú) |
