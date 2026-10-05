# 08 · Colusión y licitaciones públicas

> **Capítulo nuevo.** El curso termina en markups de Bertrand–Nash estático. Pero el markup más alto no viene de la diferenciación: viene del acuerdo. Este capítulo cubre la teoría de la colusión (juegos repetidos), su detección econométrica (screens), la teoría de subastas necesaria para analizar compras públicas, la identificación no paramétrica de costos a partir de pujas, y la detección de concertación en licitaciones del Estado.
>
> **Enfoque:** todo el material está orientado a **detección y enforcement** — es la perspectiva del regulador, el investigador y el perito. Es la aplicación con mayor retorno social del aparato de este manual.

---

## 1. La idea

Un cartel es un **equilibrio de un juego repetido** sostenido por la amenaza de castigo futuro. Esta caracterización tiene tres consecuencias empíricas directas:

1. La colusión requiere **monitoreo** → los carteles se forman donde las desviaciones son observables (mercados transparentes, pocos compradores, licitaciones públicas con resultados publicados).
2. La colusión requiere **paciencia** → es más probable con interacción frecuente y horizonte largo.
3. La colusión deja **huellas estadísticas** en los datos: menos varianza de precios, correlación anómala entre participantes, patrones de rotación de ganadores.

La tercera es lo que hace posible la detección econométrica.

---

## 2. Teoría: cuándo es sostenible la colusión

### 2.1 El modelo básico con estrategias de gatillo

$N$ firmas simétricas, interacción infinita, factor de descuento $\delta$. Estrategia: cobrar el precio de monopolio; si alguien desvía, revertir a Nash (Bertrand: $p=c$) para siempre.

**Pagos por periodo:**
- Colusión: $\pi^M/N$
- Desviación (hoy): $\pi^D \approx \pi^M$ (en Bertrand, al bajar $\epsilon$ se lleva todo el mercado)
- Castigo (desde mañana): $\pi^N = 0$ (Bertrand)

**Condición de incentivos (IC):**
$$\underbrace{\frac{\pi^M/N}{1-\delta}}_{\text{valor de coludir}}\ \ge\ \underbrace{\pi^D+\frac{\delta\,\pi^N}{1-\delta}}_{\text{valor de desviar}}$$

Con $\pi^D=\pi^M$ y $\pi^N=0$:
$$\frac{\pi^M/N}{1-\delta}\ge \pi^M \quad\Longleftrightarrow\quad \boxed{\ \delta\ \ge\ 1-\frac{1}{N}=\frac{N-1}{N}\ }$$

**Lecturas inmediatas:**
- $N=2$: $\delta\ge 0.5$. Fácil.
- $N=5$: $\delta\ge 0.8$.
- $N=10$: $\delta\ge 0.9$. Difícil.

**Más firmas ⇒ colusión más difícil.** Este es el fundamento teórico del uso de índices de concentración (HHI) como *screen* inicial.

### 2.2 El rol de la frecuencia de interacción

Si las firmas interactúan cada $\Delta$ unidades de tiempo con tasa de interés $r$, entonces $\delta = e^{-r\Delta}$. La condición IC se vuelve:
$$e^{-r\Delta}\ge \frac{N-1}{N}\quad\Longleftrightarrow\quad \Delta\le \frac{1}{r}\ln\frac{N}{N-1}$$

**Interacción más frecuente (menor $\Delta$) facilita la colusión.** Por eso las licitaciones mensuales son más vulnerables que las anuales, y por eso la publicación de precios en tiempo real es un facilitador.

### 2.3 El Folk Theorem

> **Teorema (Friedman 1971; Fudenberg y Maskin 1986).** Para $\delta$ suficientemente cercano a 1, **cualquier** vector de pagos individualmente racional y factible puede sostenerse como equilibrio perfecto en subjuegos del juego repetido.

**Consecuencia metodológica incómoda:** la teoría de juegos repetidos **no hace predicciones puntuales**. Cualquier nivel de precio entre el competitivo y el de monopolio es un equilibrio. Por eso la detección de colusión no puede basarse solo en "el precio es alto" — necesita evidencia estructural adicional.

### 2.4 Green–Porter: guerras de precios en equilibrio

Green y Porter (1984) estudian colusión cuando las firmas **no observan** las cantidades de los rivales, solo el precio de mercado, que también depende de un shock de demanda no observado.

**El problema:** un precio bajo puede significar (a) alguien se desvió, o (b) la demanda fue débil. No se distinguen.

**El equilibrio:** las firmas acuerdan un umbral $\bar p$. Si el precio cae por debajo, entran en una "guerra de precios" de $T$ periodos **aunque sepan que probablemente nadie se desvió**. El castigo en el camino de equilibrio es el precio de mantener la disciplina.

**Predicciones empíricas testeables:**
1. Los precios siguen un proceso de **cambio de régimen**: periodos colusivos y periodos de guerra.
2. Las guerras ocurren tras shocks de demanda negativos.
3. Las guerras son **ineficientes en equilibrio** — se observan carteles reales con guerras periódicas.

**Esta es la base del test de cambio de régimen de Porter (1983)** sobre el cartel ferroviario Joint Executive Committee (1880–1886), uno de los grandes clásicos de la OI empírica: estimó un modelo de cambio de régimen y encontró que los periodos de guerra correspondían a los documentados históricamente.

### 2.5 Rotemberg–Saloner: colusión contracíclica

Rotemberg y Saloner (1986) invierten la intuición: cuando la demanda está **alta**, la tentación de desviar es grande (el premio de llevarse todo el mercado hoy es mayor), mientras que el castigo futuro es el mismo. Por tanto:

$$\text{IC: } \frac{\pi^M_t}{N}+\frac{\delta}{1-\delta}\overline{\pi^M/N}\ \ge\ \pi^M_t + 0$$

Con demanda alta hoy ($\pi^M_t$ alto) y demanda esperada normal, la restricción se aprieta. Para mantener la disciplina, el cartel debe **bajar el markup en los booms**.

> **Predicción contraintuitiva: los márgenes del cartel son contracíclicos.** Un boom reduce el markup colusivo. Esto se ha documentado en cemento y en mercados de commodities. **Y tiene implicaciones macro directas** (Cap. 12): si los markups son contracíclicos, amplifican el ciclo de forma distinta a lo que supone el modelo neokeynesiano estándar.

### 2.6 Abreu: castigos óptimos

Abreu (1986, 1988) muestra que el castigo óptimo no es Nash para siempre, sino un **"stick and carrot"**: un periodo de precios muy por debajo del costo (el palo) seguido del retorno a la colusión (la zanahoria). Esto sostiene la colusión con $\delta$ mucho menores que la estrategia de gatillo.

**Implicación empírica:** observar un episodio breve de precios por debajo del costo **no es evidencia de competencia**; puede ser la fase de castigo de un cartel. Esto complica enormemente la distinción entre predación (Cap. 09) y disciplina de cartel.

---

## 3. Factores facilitadores: la lista operativa

Esta es la checklist que usa cualquier autoridad de competencia al evaluar el riesgo de un mercado.

| Factor | Dirección | Por qué |
|---|---|---|
| Pocas firmas | ↑ colusión | IC más laxa |
| Barreras de entrada | ↑ | La entrada destruye el cartel |
| Homogeneidad del producto | ↑ | Fácil acordar el "precio" |
| Transparencia de precios | ↑ | Monitoreo barato |
| Interacción frecuente | ↑ | Castigo rápido |
| Simetría de costos/capacidad | ↑ | Fácil repartir |
| Demanda estable | ↑ | Menos ruido para esconder desviaciones |
| Asociación gremial activa | ↑ | Canal de comunicación |
| Contratos MFN / "cláusula del cliente más favorecido" | ↑ | Compromete a no descontar |
| Publicación de precios obligatoria | ↑ | Facilita monitoreo (!) |
| Compradores grandes y sofisticados | ↓ | Pueden inducir desviaciones |
| Innovación rápida | ↓ | Desestabiliza el acuerdo |

> **⚠️ La paradoja de la transparencia.** Políticas bien intencionadas de transparencia de precios (publicar precios de medicamentos, de combustibles, de licitaciones) **facilitan el monitoreo del cartel** tanto como informan al consumidor. El caso danés del cemento (1993) es el ejemplo canónico: la autoridad publicó precios de transacción para ayudar a los compradores y los márgenes **subieron**. Es un trade-off real y poco discutido en el diseño regulatorio peruano.

---

## 4. Screens: detección econométrica

Un *screen* es un estadístico que distingue datos colusivos de competitivos. No prueban colusión — **generan sospecha que justifica investigación**.

### 4.1 Screens de varianza

**Screen de varianza (Abrantes-Metz et al. 2006).** Los carteles producen precios **más estables** que la competencia: el acuerdo suprime la variación idiosincrásica de costos y la rivalidad.

$$CV = \frac{\sigma_p}{\mu_p}$$

**Hallazgo empírico:** en el caso del cartel de gasolina de Long Island, el coeficiente de variación saltó de 0.01 (cartel) a 0.05 (post-colapso) y el precio medio cayó 16%. **Baja varianza + nivel alto = señal.**

**Screen de asimetría y curtosis.** Los precios colusivos tienden a tener distribuciones más simétricas y platicúrticas; los competitivos tienen asimetría negativa (rebajas esporádicas).

### 4.2 Screens de correlación

- **Correlación anómala entre firmas:** en competencia, los precios responden a costos comunes; en colusión, se mueven juntos *más allá* de lo que los costos comunes explican. Test: regresar precios de la firma A sobre costos y precios de B; si el coeficiente de B es significativo controlando por costos, es señal.
- **Correlación negativa de pujas en licitaciones:** en un esquema de rotación, cuando A gana, B puja alto. La correlación entre pujas de A y B es negativa — lo opuesto a lo que predice un modelo competitivo con costos correlacionados.

### 4.3 Screens de cambio estructural

Aplicar tests de quiebre estructural (Bai–Perron, Chow, cambio de régimen de Markov) a series de precios o márgenes. Un cartel que se forma o colapsa deja un quiebre.

```r
library(strucchange); library(MSwM)
# Quiebres endógenos
bp <- breakpoints(log(precio) ~ log(costo), data = d, h = 0.15)
summary(bp); plot(bp)

# Cambio de régimen de Markov (Porter 1983)
m  <- lm(log(precio) ~ log(costo) + demanda, data = d)
ms <- msmFit(m, k = 2, sw = c(TRUE, TRUE, TRUE, TRUE))   # 2 regímenes
plotProb(ms, which = 2)   # probabilidad suavizada de estar en régimen colusivo
```

### 4.4 Screens para licitaciones (bid rigging)

Son los más desarrollados porque los datos de pujas son ricos y públicos.

| Screen | Estadístico | Señal de colusión |
|---|---|---|
| **Diferencia relativa de pujas** | $(b_{(2)}-b_{(1)})/b_{(1)}$ | Valores **altos y estables** (los perdedores pujan deliberadamente alto) |
| **Coeficiente de variación de pujas** | $\sigma_b/\mu_b$ dentro de licitación | **Bajo** en competencia, patrón anómalo en colusión |
| **Kurtosis / normalidad** | Test sobre la distribución de pujas | Las pujas de cobertura generan distribuciones no normales |
| **Rotación de ganadores** | Test $\chi^2$ sobre la frecuencia de victoria | Más uniforme de lo que predice el azar ⇒ reparto |
| **Participación condicional** | ¿Quién puja cuándo? | Patrones de no-participación sistemática en ciertos lotes/regiones |
| **Dígitos terminales** | Distribución del último dígito | Pujas acordadas muestran patrones no uniformes |
| **Bajas porcentuales** | Distribución de $b/\text{valor referencial}$ | Agrupamiento sospechoso justo debajo del referencial |

**El screen de Bajari–Ye (2003).** Formaliza dos condiciones que debe cumplir un conjunto de pujas competitivas:

1. **Intercambiabilidad condicional:** controlando por costos observables, la distribución de las pujas debe ser intercambiable entre firmas. Colusión con reparto la rompe.
2. **Independencia condicional:** los residuos de pujas de firmas distintas, controlando por costos comunes, deben ser independientes. Colusión los correlaciona.

```r
# Implementación básica del test de Bajari-Ye
# 1) Regresión de pujas sobre costos observables
m <- feols(log(puja) ~ log(distancia) + log(capacidad_usada) + log(tamano_obra) +
             backlog | firma + anio, data = pujas)
pujas$resid <- resid(m)

# 2) Matriz de correlación de residuos entre pares de firmas
#    (sobre licitaciones donde ambas participaron)
pares <- combn(unique(pujas$firma), 2)
cors  <- apply(pares, 2, function(p) {
  sub <- merge(subset(pujas, firma==p[1]), subset(pujas, firma==p[2]), by="licitacion")
  if (nrow(sub) < 10) return(NA)
  cor.test(sub$resid.x, sub$resid.y)$estimate
})
# Correlaciones significativamente positivas o negativas entre pares específicos
# = candidatos a investigación
```

> **⚠️ Advertencia crítica de interpretación.** Un screen positivo **no es prueba de colusión**. Los falsos positivos son frecuentes: costos comunes no observados, regulación que comprime precios, mercados naturalmente concentrados. El screen **prioriza dónde mirar**; la prueba viene de evidencia directa (comunicaciones, delación) o de evidencia estructural mucho más fuerte. Presentar un screen como prueba en un procedimiento sancionador es un error técnico y legal.

---

## 5. Teoría de subastas: lo mínimo necesario

### 5.1 Los cuatro formatos y la equivalencia de ingresos

| Formato | Regla |
|---|---|
| **Primer precio sellado** | Gana la mejor oferta, paga lo que ofertó |
| **Segundo precio (Vickrey)** | Gana la mejor, paga la segunda mejor |
| **Inglesa (ascendente)** | Puja abierta creciente |
| **Holandesa (descendente)** | Precio baja hasta que alguien acepta |

> **Teorema de Equivalencia de Ingresos (Vickrey 1961; Myerson 1981; Riley–Samuelson 1981).** Bajo (i) valores privados independientes, (ii) postores neutrales al riesgo, (iii) simetría, (iv) el bien va al postor de mayor valor, y (v) el postor de menor valor obtiene excedente cero — **todos los formatos generan el mismo ingreso esperado**.

**Demostración (esquema).** Sea $v\sim F$ i.i.d. con $n$ postores. Para cualquier mecanismo que satisfaga (iv), la probabilidad de ganar del postor con valor $v$ es $F(v)^{n-1}$. Por el principio de revelación y el lema de envolvente, el pago esperado de ese postor es
$$m(v)=\int_0^{v} y\,dF(y)^{n-1}$$
independientemente del formato. Integrando sobre $F$ y multiplicando por $n$ se obtiene el ingreso esperado. Como la expresión no depende del formato, los ingresos coinciden. $\blacksquare$

**Por qué importa en la práctica:** la equivalencia **se rompe** cuando falla cualquier supuesto, y es ahí donde está la economía interesante:
- **Aversión al riesgo** ⇒ primer precio recauda más.
- **Valores comunes** ⇒ *maldición del ganador*; la subasta inglesa recauda más (revela información).
- **Asimetría** ⇒ todo cambia; el formato óptimo depende de la asimetría.
- **Colusión** ⇒ **la subasta de segundo precio y la inglesa son mucho más vulnerables** (el cartel solo necesita que uno puje alto y los demás se abstengan; no hay incentivo a desviar porque el precio pagado es el segundo). **El primer precio sellado es más robusto a la colusión** porque el desvío es rentable e inmediato.

> **Recomendación de diseño que se deriva de esto:** en mercados con riesgo alto de concertación (obras públicas, suministros con pocos proveedores), **primer precio sellado** domina a formatos abiertos. La subasta inversa electrónica con pujas en tiempo real, popular por transparencia, es **más vulnerable a la colusión** por la misma razón que el cemento danés.

### 5.2 La estrategia de equilibrio en primer precio (IPV)

Con $n$ postores simétricos, valores $v\sim F$ en $[\underline v,\bar v]$, la puja de equilibrio es:
$$\boxed{\ b(v)=v-\frac{\int_{\underline v}^{v}F(y)^{n-1}dy}{F(v)^{n-1}}\ }$$

**Demostración.** El postor con valor $v$ que puja como si tuviera $z$ obtiene
$$U(z,v)=(v-b(z))F(z)^{n-1}$$
CPO en $z=v$: $-b'(v)F(v)^{n-1}+(v-b(v))(n-1)F(v)^{n-2}f(v)=0$.
Reordenando: $b'(v)F(v)^{n-1}+b(v)(n-1)F^{n-2}f = v(n-1)F^{n-2}f$, es decir
$$\frac{d}{dv}\big[b(v)F(v)^{n-1}\big]=v\,\frac{d}{dv}F(v)^{n-1}$$
Integrando de $\underline v$ a $v$ con $b(\underline v)=\underline v$ e integrando por partes se obtiene el resultado. $\blacksquare$

**Comparativa estática clave:** $\partial b/\partial n>0$. **Más postores ⇒ pujas más agresivas (más cerca del valor).** De ahí que el número de postores sea la variable de política más importante en compras públicas: cada postor adicional baja el precio esperado.

### 5.3 Identificación no paramétrica: Guerre–Perrigne–Vuong (2000)

**El problema:** observamos pujas $b$, queremos la distribución de costos $F_c$ (para medir el markup y evaluar el mecanismo).

**El resultado (el más elegante de la econometría de subastas):**

De la CPO del postor, con $G$ la distribución de la puja máxima de los rivales y $g$ su densidad:
$$v = b + \frac{G(b)}{(n-1)g(b)}$$

Más precisamente, en una subasta inversa (de compras, donde gana el más barato) con costos $c$:
$$\boxed{\ c_i = b_i - \frac{1-G(b_i)}{(n-1)g(b_i)}\ }$$

**Ambos términos del lado derecho son estimables de los datos observados**: $G$ y $g$ son la distribución y densidad de las pujas, estimables no paramétricamente con kernels. Por tanto:

```
PASO 1: Estimar Ĝ (empírica) y ĝ (kernel) de las pujas observadas
PASO 2: Para cada puja observada b_i, construir el pseudo-costo
        ĉ_i = b_i − [1 − Ĝ(b_i)] / [(n−1) ĝ(b_i)]
PASO 3: Estimar F̂_c no paramétricamente de los pseudo-costos {ĉ_i}
```

**Esto es identificación no paramétrica de la primitiva (costos) sin suponer forma funcional alguna.** Y da directamente:
- El **markup** de cada puja: $b_i - \hat c_i$.
- La **eficiencia del mecanismo**: ¿se adjudicó al de menor costo?
- El **contrafactual**: ¿cuánto ahorraría el Estado con un precio de reserva óptimo, o con un postor más?
- El **sobreprecio del cartel**: comparar $F_c$ estimada en periodo sospechoso vs. periodo competitivo.

```r
# GPV en la práctica
library(np)
b <- pujas$monto_normalizado      # pujas normalizadas por valor referencial
n <- pujas$n_postores

G_hat <- ecdf(b)
g_hat <- density(b, bw = "SJ")    # Sheather-Jones; la elección de bw importa
g_at  <- approx(g_hat$x, g_hat$y, xout = b)$y

c_hat <- b - (1 - G_hat(b)) / ((n - 1) * g_at)
markup <- (b - c_hat) / b
summary(markup)

# Trimming: GPV es inconsistente en las colas (el kernel tiene sesgo de frontera).
# Descartar el 5% superior e inferior es práctica estándar.
```

> **⚠️ Trampas de GPV.** (1) El estimador es sensible al ancho de banda — reportar robustez. (2) Es inconsistente cerca de los bordes del soporte; hacer *trimming*. (3) Requiere observar **todas** las pujas, no solo la ganadora. (4) Requiere valores privados independientes; con valores comunes (obras donde el costo real es incierto para todos) el modelo está mal especificado y hay que usar los métodos de Hendricks–Porter o Li–Perrigne–Vuong para valores afiliados.

---

## 6. Compras públicas: el caso peruano

### 6.1 Por qué las compras públicas son el mejor laboratorio disponible

- **Datos públicos, completos y estructurados.** SEACE publica cada convocatoria, cada postor, cada propuesta económica, cada adjudicación.
- **Mecanismo conocido.** No hay que inferir cómo se fija el precio: está en las bases.
- **Volumen enorme.** Las compras públicas son del orden del 8-12% del PBI en países de la región.
- **Relevancia de política inmediata.** Cualquier hallazgo tiene usuario.

### 6.2 El dato peruano: SEACE

| Campo disponible | Uso |
|---|---|
| Valor referencial | Normalizador de pujas; base para la "baja" |
| Propuestas económicas de todos los postores | GPV, screens, análisis de rotación |
| Identidad del postor (RUC) | Redes de co-participación, detección de vínculos |
| Objeto de contratación (CUBSO) | Definición de mercado producto |
| Entidad convocante | Efectos fijos de comprador |
| Modalidad (LP, AS, Subasta Inversa, Comparación de Precios) | Comparación de mecanismos |
| Fechas (convocatoria, buena pro, contrato) | Dinámica, series de tiempo |
| Adicionales y ampliaciones | **El margen oculto** (ver abajo) |

**Acceso:** portal SEACE (datos abiertos del OSCE), descargas masivas por año. Además, la Plataforma Nacional de Datos Abiertos tiene datasets consolidados.

### 6.3 El diseño de investigación que haría yo

```
PREGUNTA: ¿Cuánto paga de más el Estado peruano por concertación en obras públicas?

DATOS: SEACE 2015-2025, licitaciones de obras ≥ cierto umbral,
       con todas las propuestas económicas.

PASO 1 — Descriptivo
  Distribución de la "baja" (1 − adjudicado/referencial) por región,
  tipo de obra y número de postores.
  Mirar: ¿hay agrupamiento en bajas específicas? ¿Pujas idénticas?

PASO 2 — Screens
  - Diferencia relativa entre primera y segunda puja
  - Rotación de ganadores (test χ² por grupo de postores habituales)
  - Correlación de residuos de pujas (Bajari-Ye)
  - Red de co-participación: ¿qué conjuntos de firmas aparecen siempre juntos?

PASO 3 — Estructural (GPV)
  Estimar F_c y markups por región-tipo de obra.
  Comparar markups en grupos con screens positivos vs. negativos.

PASO 4 — Identificación causal
  Opciones:
  (a) Umbrales de modalidad de contratación (RD): el régimen cambia
      discretamente en ciertos montos en UIT → RDD sobre el valor referencial
  (b) Casos sancionados por INDECOPI: diff-in-diff pre/post detección,
      comparando mercados afectados con mercados similares no afectados
  (c) Variación en el número de postores inducida por cambios en requisitos
      de las bases

PASO 5 — Contrafactual
  Ahorro del Estado bajo: un postor adicional; precio de reserva óptimo;
  cambio de modalidad; agregación de demanda (compra corporativa)
```

> **🇵🇪 La variable que nadie analiza: los adicionales de obra.** En Perú, una práctica documentada es ganar con baja agresiva y recuperar margen vía **adicionales y ampliaciones de plazo**. Esto implica que el precio adjudicado **no es el precio final**, y que todo análisis de pujas basado solo en la adjudicación está midiendo el objeto equivocado.
>
> **Esto es una oportunidad de investigación de primer orden:** modelar la puja como una opción sobre adicionales futuros. La puja óptima entonces es $b = c - E[\text{valor de los adicionales}]$, lo que explica bajas por debajo del costo sin necesidad de predación ni de error. Un paper que estime empíricamente la relación entre baja inicial y adicionales finales con datos de SEACE + INFOBRAS sería novedoso, metodológicamente interesante y de impacto de política inmediato. **No conozco trabajo publicado que lo haga para Perú.**

### 6.4 Casos peruanos de referencia

Los siguientes casos son públicamente conocidos y han sido objeto de resoluciones de INDECOPI o de procesos judiciales. **Las cifras y calificaciones específicas deben verificarse contra las resoluciones originales antes de citarse en trabajo formal.**

| Caso | Mercado | Mecanismo reportado | Lección analítica |
|---|---|---|---|
| **Papel higiénico** (Kimberly-Clark / Protisa) | Consumo masivo | Concertación de precios y condiciones comerciales, durante varios años | Cartel en bien homogéneo con pocos productores; primer gran caso con programa de clemencia en Perú |
| **Oxígeno medicinal** | Insumo hospitalario | Concertación en licitaciones de EsSalud y hospitales públicos | Bid rigging clásico en compras del Estado; mercado con 2-3 proveedores |
| **Cadenas de farmacias** | Retail farmacéutico | Concertación de precios de medicamentos | Coordinación en mercado con productos múltiples y precios observables |
| **"Club de la Construcción"** | Obras viales (MTC) | Reparto de obras y pujas de cobertura | El caso más grande; la lógica de rotación es exactamente la de §4.4 |
| **Avícolas** (histórico) | Pollo | Coordinación de producción vía gremio | Rol de la asociación gremial como facilitador |
| **GLP envasado** | Energía residencial | Investigaciones por coordinación regional | Mercados regionales segmentados |
| **Hemodiálisis** | Servicios de salud | Concertación en licitaciones públicas | Mismo patrón que oxígeno: comprador único estatal |

**El patrón que emerge:** la mayoría de los casos peruanos de colusión detectados son (i) en mercados con pocos proveedores, (ii) con el Estado como comprador principal, (iii) en bienes o servicios homogéneos. **Esto es exactamente lo que predice la teoría de §2–3** y sugiere que el screening sistemático de SEACE tendría alta tasa de aciertos.

### 6.5 Marco institucional peruano

| Instrumento | Contenido |
|---|---|
| **D.L. 1034** (Ley de Represión de Conductas Anticompetitivas), modificado por D.L. 1205 | Prohibición de prácticas colusorias horizontales (art. 11) y verticales (art. 12); abuso de posición de dominio (art. 10) |
| **Prácticas colusorias horizontales** | Son **prohibición absoluta** cuando son entre competidores y consisten en fijación de precios, reparto de mercado, limitación de producción o concertación en licitaciones (*hard-core cartels*) — no requieren análisis de efectos |
| **Programa de Clemencia** | Exoneración total para el primero que delata con información suficiente; reducción para los siguientes. Es la herramienta que ha destrabado los casos grandes |
| **Ley 31112** (2021) | Control previo de concentraciones empresariales; INDECOPI evalúa fusiones que superan umbrales en UIT |
| **Autoridad** | Comisión de Defensa de la Libre Competencia (CLC) de INDECOPI; apelación ante el Tribunal |

> **Nota sobre el control de fusiones.** Perú es uno de los países de la región que adoptó control previo de concentraciones más tarde (2021). Esto significa que **existe un periodo pre-2021 sin control y uno post-2021 con control**, lo que es una fuente de identificación tipo diff-in-diff para evaluar el efecto del régimen de control sobre precios y concentración. **Es un experimento natural de política de competencia que está sin explotar.**

---

## 7. Cuantificación de daño (para litigio)

La pregunta: ¿cuánto pagó de más el comprador?

**Método del "but-for price":**
$$\text{Daño} = \sum_t \big(p_t^{\text{observado}}-p_t^{\text{but-for}}\big)\cdot q_t$$

**Cómo estimar el but-for price:**

| Método | Idea | Requisito |
|---|---|---|
| **Antes-después** | Comparar con periodo pre/post cartel | El cartel tiene fechas conocidas; no hay otros cambios |
| **Comparación geográfica (yardstick)** | Mercado similar no afectado | Existe un control creíble |
| **Diff-in-diff** | Combina ambos | Tendencias paralelas |
| **Reducida con costos** | Regresión de precio sobre costos en periodo competitivo, proyectada al periodo de cartel | Especificación correcta de costos |
| **Estructural** | Estimar demanda + simular Bertrand–Nash sin cartel | Todo el aparato de los Caps. 06–07 |

**La ventaja del método estructural:** da también la **pérdida de eficiencia** (no solo la transferencia), permite calcular el daño a los compradores indirectos (*pass-on*), y es robusto a cambios de composición. **La desventaja:** es atacable en cada supuesto.

**Recomendación de perito:** reportar al menos dos métodos y mostrar que coinciden en orden de magnitud. Un rango defendible vence a un número preciso indefendible.

---

## 8. Lecturas

**Teoría**
- Tirole (1988), *The Theory of Industrial Organization*, cap. 6.
- Green y Porter (1984), "Noncooperative Collusion under Imperfect Price Information", *Econometrica* 52(1).
- Rotemberg y Saloner (1986), "A Supergame-Theoretic Model of Price Wars during Booms", *AER* 76(3).
- Abreu (1988), "On the Theory of Infinitely Repeated Games with Discounting", *Econometrica* 56(2).

**Detección**
- Porter (1983), "A Study of Cartel Stability: The Joint Executive Committee", *Bell Journal* 14(2).
- Bajari y Ye (2003), "Deciding Between Competition and Collusion", *RESTAT* 85(4).
- Abrantes-Metz, Froeb, Geweke y Taylor (2006), "A Variance Screen for Collusion", *IJIO* 24(3).
- Harrington (2008), "Detecting Cartels", en Buccirossi (ed.), *Handbook of Antitrust Economics*.
- Chassang, Kawai, Nakabayashi y Ortner (2022), "Robust Screens for Noncompetitive Bidding in Procurement Auctions", *Econometrica* 90(1). — **el estado del arte**.

**Subastas**
- Krishna (2009), *Auction Theory*, 2ª ed.
- Guerre, Perrigne y Vuong (2000), "Optimal Nonparametric Estimation of First-Price Auctions", *Econometrica* 68(3).
- Hendricks y Porter (2007), "An Empirical Perspective on Auctions", *Handbook of IO* vol. 3.
- Athey, Levin y Seira (2011), "Comparing Open and Sealed Bid Auctions: Evidence from Timber Auctions", *QJE* 126(1).
- Kawai y Nakabayashi (2022), "Detecting Large-Scale Collusion in Procurement Auctions", *JPE* 130(5).
