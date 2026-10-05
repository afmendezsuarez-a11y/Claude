# 14 · Uso diario: el playbook

> **Capítulo nuevo.** Todo lo anterior es inútil si vive solo en un paper. Este capítulo convierte el manual en herramienta operativa: qué hacer en un día, en una semana, en un trimestre; cómo responder las preguntas que te van a hacer; qué errores cometen todos; cómo presentar resultados a gente que no quiere ver una ecuación.

---

## 1. Los cinco cálculos que debes poder hacer de memoria

### 1.1 Elasticidad → margen óptimo

$$\mathcal{L}^*=\frac{1}{|\varepsilon|}$$

| $|\varepsilon|$ | Margen óptimo |
|---|---|
| 1.5 | 67% |
| 2 | 50% |
| 3 | 33% |
| 5 | 20% |
| 10 | 10% |

**Uso:** "Tu margen es 25% y me dices que la elasticidad es −2. O el precio está muy por debajo del óptimo, o la elasticidad está mal medida."

### 1.2 Margen → elasticidad implícita

$$|\varepsilon|^{\text{implícita}}=\frac{1}{\mathcal{L}}$$

**Uso:** diagnóstico instantáneo de cualquier estado de resultados. Si el margen de contribución es 40%, la empresa se está comportando como si la elasticidad fuera −2.5.

### 1.3 Cambio de precio → cambio de cantidad (exacto)

$$\%\Delta Q=\big[(1+\%\Delta P)^{\varepsilon}-1\big]\times 100$$

**Nunca** $\varepsilon\times\%\Delta P$ para cambios mayores a ~10%.

### 1.4 Cambio de precio → cambio de ingreso

$$\%\Delta \text{Ingreso}=\big[(1+\%\Delta P)^{1+\varepsilon}-1\big]\times100$$

**La regla:** si $|\varepsilon|<1$, subir el precio **aumenta** el ingreso. Si $|\varepsilon|>1$, lo reduce.

### 1.5 Punto de equilibrio de una promoción

¿Cuánto volumen adicional necesito para que un descuento sea rentable?

$$\%\Delta Q^{\text{breakeven}}=\frac{d}{\mathcal{L}-d}$$

donde $d$ es el descuento como fracción del precio.

| Margen $\mathcal L$ | Descuento 10% | Descuento 20% | Descuento 30% |
|---|---|---|---|
| 30% | +50% | +200% | — (imposible) |
| 40% | +33% | +100% | +300% |
| 50% | +25% | +67% | +150% |
| 60% | +20% | +50% | +100% |

> **Este cuadro es el más útil del manual en una reunión comercial.** Un descuento de 20% en un producto con margen de 30% requiere **triplicar** el volumen solo para empatar. Casi ninguna promoción hace eso (la elasticidad necesaria sería −10). Y recordar el Cap. 10 §4: buena parte del volumen aparente es desplazamiento temporal, no volumen nuevo.

---

## 2. El día tipo: responder una pregunta de negocio en 8 horas

**Pregunta:** "¿Deberíamos subir el precio 5%?"

```
HORA 1  — Entender la pregunta
  ¿Subir el precio de qué exactamente? ¿Un SKU, una línea, toda la marca?
  ¿Qué harán los competidores? ¿Hay contratos que limiten el movimiento?
  ¿Cuál es el objetivo: margen, volumen, participación, caja?

HORA 2  — Datos
  Serie histórica de precio y volumen por SKU-mercado.
  Precios de competidores si existen.
  Costos variables unitarios.
  Cualquier cambio de precio histórico: esos son tus "experimentos".

HORAS 3-4 — Estimación rápida
  1) Benchmark: ¿qué dice la literatura para esta categoría? (Cap. 03 §4.4)
  2) Regresión ingenua log-log con efectos fijos → sabes que está sesgada
  3) Buscar el mejor instrumento disponible en 1 hora:
     costo de insumo, precio en otra región, cambio de impuesto
  4) IV. Reportar F de primera etapa.
  5) Si no hay instrumento: usar eventos históricos de cambio de precio
     como cuasi-experimento (event study simple)

HORA 5  — Triangulación
  ¿La elasticidad estimada es consistente con el margen actual? (§1.2)
  ¿Está en el rango de la literatura?
  ¿Qué dice el equipo comercial por experiencia?
  Si las tres fuentes coinciden en orden de magnitud → confianza.
  Si no → reportar el rango, no un número.

HORA 6  — Simulación
  Δ volumen, Δ ingreso, Δ margen con la fórmula exacta.
  Escenarios: competidor sigue / no sigue.
  Punto de equilibrio: ¿qué caída de volumen anula la ganancia?

HORA 7  — Riesgos
  ¿Reacción competitiva? ¿Reacción del canal (bodegas, cadenas)?
  ¿Umbrales psicológicos de precio?
  ¿Riesgo regulatorio o reputacional?
  ¿Elasticidad de largo plazo > corto plazo? (casi siempre sí)

HORA 8  — Comunicar
  Una lámina: recomendación, número central, rango, supuesto crítico.
  Una lámina: cómo sabremos si nos equivocamos y cuándo revisar.
```

**La regla de oro:** si las tres fuentes (datos, literatura, experiencia) coinciden, actúa. Si no, el entregable es "necesitamos un experimento", y vale más que un número inventado.

---

## 3. La semana tipo: estimación seria

| Día | Actividad | Entregable |
|---|---|---|
| **1** | Definir la pregunta, el modelo y la estrategia de identificación **por escrito** | Una página: parámetro, fuente de variación, amenaza principal |
| **2** | Construir y limpiar los datos. Estadística descriptiva. Gráficos | Tabla 1 del paper/reporte |
| **3** | OLS, primera etapa, IV. Diagnósticos completos | Tabla 2 |
| **4** | Robustez: forma funcional, instrumentos alternativos, submuestras | Tablas de apéndice |
| **5** | Simulación del contrafactual. Presentación | Reporte |

> **No saltarse el día 1.** El 80% de los proyectos que fracasan lo hacen porque nunca se escribió la estrategia de identificación. Escribirla fuerza a descubrir que no existe.

---

## 4. El trimestre tipo: proyecto estructural completo

```
SEMANAS 1-2   Revisión de literatura + definición de la pregunta
              Entregable: 5 papers más cercanos, y qué agrega el tuyo

SEMANAS 3-5   Construcción de datos
              Entregable: panel limpio, documentado, con diccionario
              (Esto siempre toma el doble de lo planeado)

SEMANA 6      Forma reducida
              Entregable: los hechos estilizados. Si no hay patrones
              interesantes en forma reducida, el modelo estructural
              no los va a inventar

SEMANAS 7-9   Estimación estructural
              Logit → nested → BLP, en ese orden. Nunca empezar por BLP

SEMANA 10     Validación
              Ajuste fuera de muestra; comparar con evidencia externa;
              ¿los mc son positivos?; ¿los márgenes se parecen a los reales?

SEMANAS 11-12 Contrafactuales y escritura
              Entregable: el contrafactual principal + sensibilidad completa
```

> **La regla del orden creciente de complejidad.** Empezar por el modelo más simple y añadir complejidad solo cuando el simple falla visiblemente. Un BLP que no replica los resultados del logit en su caso límite ($\theta_2\to 0$) tiene un bug. Empezar por BLP significa no tener forma de saber si el código está bien.

---

## 5. Los quince errores que comete todo el mundo

| # | Error | Consecuencia | Antídoto |
|---|---|---|---|
| 1 | Regresar $Q$ sobre $P$ sin instrumentar | Elasticidad sesgada hacia cero o positiva | Cap. 02–03 |
| 2 | Usar $\varepsilon\times\%\Delta P$ para cambios grandes | Error de 10-25% | Fórmula exacta (§1.3) |
| 3 | Confundir elasticidad de marca con la de categoría | Error de factor 3-5× | Cap. 03 §4.4 |
| 4 | Olvidar el bien externo | Participaciones mal normalizadas, elasticidades mal | Cap. 06 |
| 5 | $M_t$ mal definido o endógeno | Todo mal | Cap. 06, Cap. 13 §7 |
| 6 | Usar logit puro para simular una fusión | Subestima el efecto de precio | Cap. 06 §6, Cap. 07 |
| 7 | No reportar el $F$ de primera etapa | El referee lo pide; o peor, no lo pide y publicas basura | Cap. 02 §5 |
| 8 | Creer que pasar el test $J$ valida los instrumentos | Falsa seguridad | Cap. 02 §3.2 |
| 9 | Clusterizar al nivel equivocado | Errores estándar muy pequeños | Cap. 03 §6 |
| 10 | Tolerancia laxa en la contracción de BLP | Resultados no replicables | Cap. 06 §4.5 |
| 11 | Reportar solo $\Delta w$ en una simulación AIDS | Conclusión invertida | Cap. 04 §8.2 |
| 12 | Extrapolar log-lineal fuera de la muestra | Predicciones absurdas | Cap. 03 §2.1 |
| 13 | Asumir pass-through de 100% | Incidencia mal calculada | Cap. 07 §4 |
| 14 | Asumir margen constante a perpetuidad en un DCF | Sobrevaluación sistemática | Cap. 11 §2.3 |
| 15 | Presentar un screen de colusión como prueba | Error técnico y legal | Cap. 08 §4.4 |

---

## 6. Las preguntas que te van a hacer y cómo responderlas

**"¿Por qué no simplemente regresas cantidad sobre precio?"**
> "Porque el precio que observo es el de equilibrio: se mueve cuando se mueve la demanda y cuando se mueve la oferta. Si solo se moviera la oferta, la regresión daría la demanda. Pero cuando se mueve la demanda —una temporada alta, una promoción de la competencia— el precio y la cantidad suben juntos, y la regresión me da una pendiente positiva que no es demanda. Necesito variación de precio que venga solo del lado de la oferta."

**"¿Cómo sé que tu instrumento es válido?"**
> "No lo puedo probar estadísticamente, y nadie puede. Lo que puedo hacer es tres cosas: mostrar que mueve el precio con la fuerza y el signo que la economía predice; argumentar por qué no afecta la demanda directamente, y dejar que me ataquen el argumento; y mostrar que con un instrumento distinto la respuesta no cambia mucho."

**"¿Por qué tu elasticidad es tan distinta de la que tenemos internamente?"**
> "Probablemente miden cosas distintas. La elasticidad de corto plazo con promociones incluye desplazamiento temporal de compras; la de largo plazo, no. La de marca es mucho mayor que la de categoría. Veamos cuál de las dos necesitan para la decisión que están tomando."

**"¿Esto predice lo que va a pasar?"**
> "Predice el movimiento del equilibrio si el mundo se comporta como en el periodo que estimé. Si los competidores reaccionan de forma distinta a como lo hicieron históricamente, o si el cambio es mucho mayor que lo que vi en los datos, la predicción se degrada. Por eso te doy un rango y los supuestos, no un punto."

**"¿Cuánto confías en esto, del 1 al 10?"**
> Respuesta honesta y útil: "7 para la dirección y el orden de magnitud. 4 para el segundo decimal. La decisión no debería depender del segundo decimal; si depende, necesitamos un experimento."

---

## 7. Cómo presentar: la estructura de 5 láminas

```
LÁMINA 1 — LA RESPUESTA
  Una frase. "Subir el precio 5% aumenta el margen en S/ X millones,
  con un rango de S/ Y a S/ Z."
  (No empieces por la metodología. Nadie te contrató por tu metodología.)

LÁMINA 2 — DE DÓNDE SALE
  El gráfico: precio vs. cantidad, con la línea OLS y la línea IV.
  Una frase sobre por qué difieren.

LÁMINA 3 — EL NÚMERO Y SU INCERTIDUMBRE
  La elasticidad con intervalo de confianza.
  Comparación con benchmarks de la literatura y con la experiencia interna.

LÁMINA 4 — LO QUE PASA SI ME EQUIVOCO
  Sensibilidad: resultado bajo elasticidad alta/baja.
  ¿En qué punto cambia la recomendación?

LÁMINA 5 — QUÉ HARÍA FALTA PARA ESTAR MÁS SEGURO
  El experimento o los datos que resolverían la duda, y qué costarían.

APÉNDICE — todo lo demás
```

> **La prueba de la lámina 1.** Si no puedes escribir la respuesta en una frase sin jerga, no tienes la respuesta todavía.

---

## 8. Snippets de código listos para usar

### 8.1 Elasticidad rápida con IV

```r
library(fixest)
m <- feols(log(q) ~ log(ingreso) | mercado + mes | log(p) ~ z,
           data = d, cluster = ~mercado)
e <- coef(m)["fit_log(p)"]; se <- se(m)["fit_log(p)"]
cat(sprintf("Elasticidad: %.2f  [%.2f, %.2f]   F1 = %.1f\n",
            e, e - 1.96*se, e + 1.96*se, fitstat(m, "ivf1")$ivf1$stat))
```

### 8.2 Simulación de precio con fórmula exacta

```r
simular <- function(e, p0, q0, mc, dp) {
  p1 <- p0 * (1 + dp)
  q1 <- q0 * (1 + dp)^e
  data.frame(
    pct_dq      = 100*(q1/q0 - 1),
    pct_dingreso= 100*(p1*q1/(p0*q0) - 1),
    margen0     = (p0-mc)*q0,
    margen1     = (p1-mc)*q1,
    pct_dmargen = 100*(((p1-mc)*q1)/((p0-mc)*q0) - 1)
  )
}
simular(e = -1.8, p0 = 10, q0 = 1000, mc = 6, dp = 0.05)
```

### 8.3 Punto de equilibrio de un descuento

```r
breakeven <- function(margen, descuento) descuento / (margen - descuento)
outer(c(.3,.4,.5,.6), c(.05,.10,.15,.20,.30), breakeven)
```

### 8.4 Markups logit a partir de participaciones

```r
markup_logit <- function(alpha, shares_firma) 1/(alpha*(1 - sum(shares_firma)))
# Ejemplo: firma con 3 marcas de 12%, 8% y 5%; alpha estimado = 1.5
markup_logit(1.5, c(0.12, 0.08, 0.05))
```

### 8.5 GUPPI

```r
guppi <- function(diversion, margen2, p2, p1) diversion * margen2 * (p2/p1)
guppi(diversion = 0.25, margen2 = 0.40, p2 = 12, p1 = 10)   # 0.12 → revisar
```

### 8.6 Pipeline completo de BLP

```python
import pyblp, numpy as np, pandas as pd
pyblp.options.digits = 3; pyblp.options.verbose = True

# 1. Instrumentos
iv = pyblp.build_differentiation_instruments(
    pyblp.Formulation('0 + x1 + x2'), product_data, version='local')
for i in range(iv.shape[1]):
    product_data[f'demand_instruments{i}'] = iv[:, i]

# 2. Logit simple primero (SIEMPRE)
logit = pyblp.Problem(pyblp.Formulation('1 + prices + x1 + x2'), product_data)
print(logit.solve())

# 3. Random coefficients
problem = pyblp.Problem(
    (pyblp.Formulation('1 + prices + x1 + x2'),
     pyblp.Formulation('0 + prices + x1')),
    product_data, agent_formulation=pyblp.Formulation('0 + income'),
    agent_data=agent_data)

# 4. Multi-start: la diferencia entre resultados replicables y no
best, best_obj = None, np.inf
for seed in range(20):
    rng = np.random.default_rng(seed)
    try:
        r = problem.solve(sigma=np.diag(rng.uniform(0, 1, 2)),
                          optimization=pyblp.Optimization('trust-constr'),
                          iteration=pyblp.Iteration('squarem', {'atol': 1e-14}),
                          method='1s')
        if r.objective < best_obj: best, best_obj = r, r.objective
    except Exception as e:
        print(f'seed {seed}: {e}')

# 5. Diagnósticos
assert (best.compute_costs() > 0).all(), "mc negativos: revisar el modelo"
print(best.compute_elasticities().mean(axis=0))
print(best.compute_markups().mean())
```

---

## 9. Checklist universal pre-entrega

**Antes de mandar cualquier resultado:**

- [ ] ¿El signo es el que la economía predice? Si no, **explica por qué** antes de enviarlo.
- [ ] ¿La magnitud está en el rango de la literatura? Si no, ídem.
- [ ] ¿Reporté el $F$ de primera etapa y los intervalos de confianza?
- [ ] ¿Probé al menos una especificación alternativa?
- [ ] ¿La conclusión cambia con la especificación alternativa?
- [ ] ¿Usé la fórmula exacta para los cambios discretos?
- [ ] ¿El código corre de cero en una máquina limpia?
- [ ] ¿Alguien que no conoce el proyecto puede leer la tabla sin explicación?
- [ ] ¿Escribí explícitamente el supuesto que, si es falso, invalida todo?
- [ ] ¿Puedo explicar el resultado en una frase sin jerga?

---

## 10. Hábitos que separan a los buenos de los demás

1. **Escribir la estrategia de identificación antes de ver los datos.** Previene el *p*-hacking propio y el ajeno.
2. **Correr el modelo más simple primero, siempre.** Es tu test de regresión contra bugs.
3. **Mirar los datos crudos.** Graficar antes de regresar. La mitad de los errores se ven en un scatter.
4. **Tener benchmarks en la cabeza.** Saber que la gasolina es −0.3 y que una marca es −3 te hace detectar errores en segundos.
5. **Reportar el rango, no el punto.** La precisión falsa destruye la credibilidad cuando se descubre.
6. **Guardar el código que no funcionó.** La mitad del valor de un proyecto es saber qué no funciona.
7. **Preguntar "¿qué decisión cambia con este número?"** antes de estimarlo. Si ninguna, no lo estimes.
