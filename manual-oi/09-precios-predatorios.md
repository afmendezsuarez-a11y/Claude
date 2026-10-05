# 09 · Precios predatorios y estrategias de exclusión

> **Capítulo nuevo.** La predación es el caso donde la teoría económica y el derecho de competencia están más en tensión, y donde la econometría de demanda del manual se vuelve decisiva: distinguir predación de competencia agresiva requiere estimar costos marginales, que es exactamente lo que los Caps. 06–07 permiten hacer sin observarlos.

---

## 1. La idea y la objeción de Chicago

**La historia intuitiva:** la firma dominante baja el precio por debajo del costo, el rival pequeño pierde dinero y sale, la dominante sube el precio y recupera las pérdidas con creces.

**La objeción de Chicago (McGee 1958, sobre Standard Oil):** esa historia no es un equilibrio.

1. El predador tiene **más** cuota, así que pierde **más** dinero por unidad de daño infligido.
2. Si la salida del rival implica precios futuros altos, **alguien entrará** a aprovecharlos; la recuperación no ocurre.
3. Los activos del rival que sale **no desaparecen**: se venden barato y vuelven al mercado en manos de un operador con menor costo hundido.
4. Si el rival es eficiente y tiene acceso a crédito, **puede esperar** más tiempo del que el predador puede quemar dinero.
5. **Comprar al rival es más barato** que destruirlo mediante una guerra de precios.

**Conclusión de Chicago:** la predación es irracional y rara. Las bajas de precio son competencia, y castigarlas protege competidores, no competencia.

**La respuesta moderna (teoría de juegos con información asimétrica y fricciones financieras):** la predación **sí** es un equilibrio bajo condiciones identificables. Las tres teorías que lo demuestran son la base del análisis actual.

---

## 2. Las tres teorías modernas de predación racional

### 2.1 Predación por reputación (Kreps–Wilson, Milgrom–Roberts 1982)

**Setup.** Un incumbente enfrenta entrantes potenciales en secuencia (varios mercados geográficos, o el mismo mercado a lo largo del tiempo). Los entrantes **no saben** si el incumbente es de costo bajo (para quien pelear es barato) o de costo alto.

**Resultado.** Existe un equilibrio en el que un incumbente de costo **alto** pelea de todos modos en los primeros mercados, para **construir la reputación** de ser de costo bajo y disuadir a los entrantes siguientes. El costo de pelear hoy es una inversión en disuasión futura.

**Condiciones para que funcione:**
- Multiplicidad de mercados o de periodos (horizonte largo).
- Información incompleta genuina sobre el tipo del incumbente.
- Los entrantes observan el comportamiento pasado.

**Predicción empírica distintiva:** la predación debería observarse **más en los primeros mercados** de una secuencia y menos en los últimos. Y debería ocurrir incluso en mercados pequeños donde "no vale la pena" en términos estáticos — precisamente porque el objetivo es la señal.

### 2.2 Predación financiera (long purse / deep pocket; Bolton–Scharfstein 1990)

**Setup.** El entrante tiene restricciones financieras: su financiamiento externo depende de su desempeño observado (problema de agencia con el financista). El incumbente tiene bolsillos profundos.

**Resultado.** El incumbente baja el precio para **deteriorar el desempeño observable del entrante**, lo que hace que el financista corte el crédito y el entrante salga, aunque sea igual de eficiente.

**La clave:** la predación no funciona por "quemar más caja" sino por **manipular la información que usa el financista**. El contrato óptimo del financista inevitablemente deja espacio a esta manipulación.

**Predicción empírica:** la predación se dirige a rivales **financieramente restringidos**, no a los ineficientes. Debería observarse correlación entre el apalancamiento del rival y la agresividad del incumbente.

> **🇵🇪 Relevancia peruana.** El acceso diferencial al crédito entre empresas grandes (que acceden a crédito bancario y mercado de capitales a tasas bajas) y pymes (que enfrentan tasas muy superiores o financiamiento informal) hace que el canal financiero de Bolton–Scharfstein sea **particularmente potente en Perú**. La asimetría de costo de capital es un multiplicador de poder de mercado que el análisis antimonopolio local rara vez considera.

### 2.3 Predación por señalización de costos (Milgrom–Roberts 1982, *limit pricing*)

El incumbente fija un precio bajo **antes** de la entrada para señalizar que su costo es bajo, disuadiendo la entrada sin necesidad de pelear. Es predación "preventiva", y es difícil de distinguir de competencia porque nunca se observa la guerra.

### 2.4 Otras estrategias de exclusión

La predación de precios es solo una de varias estrategias excluyentes. En la práctica regulatoria moderna, las otras son más frecuentes:

| Estrategia | Mecanismo | Caso de referencia |
|---|---|---|
| **Descuentos por fidelidad / retroactivos** | El descuento se pierde si se compra algo del rival ⇒ el precio efectivo marginal puede ser negativo | *Intel*, *Michelin* |
| **Ventas atadas (tying)** | Apalancar dominancia de un mercado al adyacente | *Microsoft* |
| **Estrechamiento de márgenes (margin squeeze)** | Integrado verticalmente fija un precio mayorista alto y uno minorista bajo ⇒ el rival aguas abajo no puede competir | *Deutsche Telekom*, *Telefónica* |
| **Exclusividades** | Contratos que impiden al distribuidor trabajar con rivales | Bebidas, cerveza |
| **Denegación de insumo esencial** | Negar acceso a infraestructura necesaria | Interconexión en telecom |
| **Aumento del costo del rival** (RRC) | Lobby regulatorio, acaparamiento de insumos, estándares | Regulación capturada |

> **🇵🇪 Perú.** El **margin squeeze** es el caso más relevante para OSIPTEL, dado que el operador históricamente integrado provee insumos mayoristas (interconexión, acceso a ductos, backhaul) a operadores que compiten con él aguas abajo. El test económico es: ¿puede un competidor igual de eficiente cubrir sus costos pagando el precio mayorista regulado y cobrando el precio minorista del integrado? Es un cálculo directo que usa exactamente la estimación de costos del Cap. 07.

---

## 3. Los tests legales y su economía

### 3.1 Areeda–Turner (1975)

**La regla:** un precio por debajo del **costo marginal** (aproximado por el **costo variable medio, AVC**) se presume predatorio; por encima, se presume legal.

**La lógica económica:** en competencia, ninguna firma fija precio por debajo del costo marginal salvo para expulsar rivales (no hay otra razón racional de corto plazo, salvo excepciones conocidas: introducción de producto, perecibles, efectos de red, aprendizaje).

**Las críticas:**
1. **El costo marginal no es observable.** Se aproxima con AVC, pero la distinción fijo/variable es contable y manipulable.
2. **Costos hundidos y aprendizaje.** Vender por debajo del costo hoy puede ser óptimo si hay *learning-by-doing* o efectos de red — es inversión, no predación.
3. **La predación por encima del costo existe.** Las teorías de §2 producen exclusión con precios por encima del costo marginal (reputación, señalización). Areeda–Turner los deja pasar.
4. **Ignora la recuperación.** Un precio bajo sin posibilidad de recuperar es solo un regalo al consumidor.

### 3.2 Brooke Group (EE.UU., 1993): el estándar de dos partes

> Para probar predación se requiere: **(1)** precio por debajo de una medida apropiada de costo, **y (2)** una **probabilidad peligrosa de recuperación** (*recoupment*).

**El segundo requisito es el filtro que mata la mayoría de los casos**, y es económicamente correcto: sin recuperación, la conducta no daña al consumidor en ningún horizonte.

**Cómo se prueba la recuperación empíricamente:**
- ¿Existen barreras de entrada que impidan la re-entrada tras la salida del rival?
- ¿La cuota del predador post-salida es suficiente para subir precios?
- ¿El valor presente de los beneficios post-exclusión supera las pérdidas de la fase predatoria?

$$\text{Recuperación viable} \iff \sum_{t=T+1}^{\infty}\frac{\Delta\pi_t}{(1+r)^t} > \sum_{t=0}^{T}\frac{L_t}{(1+r)^t}$$

**Este cálculo es un DCF** y conecta directamente con el Cap. 11.

### 3.3 El enfoque europeo: AKZO y el competidor igualmente eficiente

- Precio **< AVC**: presunción de abuso (casi irrefutable).
- **AVC < Precio < ATC**: abuso **si** hay plan de eliminar al competidor (requiere evidencia de intención).
- Precio **> ATC**: en principio lícito.

**Test del competidor igualmente eficiente (*as-efficient competitor*, AEC):** ¿podría un rival con los mismos costos que el dominante competir rentablemente al precio practicado? Si no, es exclusionario. Este es el test que se aplica a descuentos de fidelidad y margin squeeze, y es el más usado en la práctica europea moderna.

### 3.4 Perú

El D.L. 1034 tipifica los **precios predatorios** como una modalidad de abuso de posición de dominio. El análisis requiere: (i) posición de dominio previa, (ii) precio por debajo de costos, (iii) efecto o aptitud de exclusión. **La carga de probar la estructura de costos recae sobre el análisis económico**, y es exactamente donde la estimación estructural aporta valor: permite estimar $mc$ sin depender de la contabilidad de la investigada, que es la parte interesada.

---

## 4. Cómo se testea empíricamente, usando el aparato del manual

Este es el aporte distintivo de este capítulo: **mostrar que los capítulos anteriores dan las herramientas exactas para los dos elementos del test Brooke Group.**

### 4.1 Elemento 1 — ¿el precio está por debajo del costo?

**Ruta A (contable):** usar los estados de costos de la empresa. Problema: la asignación fijo/variable y la imputación de costos conjuntos son manipulables, y la empresa investigada tiene incentivo.

**Ruta B (estructural, la que recomienda este manual):**

```
1. Estimar demanda con BLP o nested logit  [Cap. 06]
2. Para el periodo NO sospechoso (antes de la entrada del rival),
   invertir la FOC de Bertrand-Nash para recuperar mc  [Cap. 07 §2]
3. Modelar mc como función de shifters de costo observables:
       mc_jt = γ'w_t + ν_jt
   Estimar γ en el periodo no sospechoso.
4. Proyectar mc al periodo sospechoso usando ŵ_t
5. Comparar p_jt observado con mc_jt proyectado
```

**La ventaja decisiva:** el costo marginal se estima de la **conducta previa de la propia empresa en un periodo en que no tenía incentivo a predar**, no de su contabilidad. Es mucho más difícil de atacar.

**La objeción a anticipar:** si la empresa estaba coludiendo en el periodo "no sospechoso", el $mc$ recuperado está sesgado. Hay que argumentar (o testear, Cap. 02 §6.5) que la conducta era Bertrand.

### 4.2 Elemento 2 — ¿es viable la recuperación?

```
1. Simular el equilibrio post-salida: quitar el producto del rival
   de la matriz de demanda y re-resolver precios  [Cap. 07 §5]
2. Calcular Δπ del predador por periodo
3. Calcular las pérdidas de la fase predatoria: (mc − p)·q acumulado
4. VPN(Δπ) vs. VPN(pérdidas), con la tasa de descuento de la industria
5. Evaluar barreras de entrada: ¿cuánto dura la ventana antes de re-entrada?
```

### 4.3 Elemento 3 — diseño cuasi-experimental (el más persuasivo)

Si hay múltiples mercados geográficos y la entrada del rival ocurrió en algunos y no en otros:

$$p_{jmt}=\alpha + \beta\,\big(\text{Entrada}_m\times \text{Post}_t\big)+\gamma_m+\delta_t+\varepsilon_{jmt}$$

$\hat\beta<0$ y grande indica que el incumbente **bajó el precio específicamente donde entró el rival**. Combinado con la evidencia de costos, es el argumento más fuerte posible.

**Chequeos obligatorios:**
- **Tendencias paralelas** antes de la entrada (event study con leads).
- **Reversión post-salida**: si el precio vuelve a subir tras la salida del rival, es evidencia muy fuerte de recuperación. **Este es el patrón diagnóstico más contundente: caída selectiva seguida de recuperación selectiva.**
- Descartar explicaciones alternativas: ¿la entrada ocurrió donde la demanda estaba creciendo? ¿Hubo shocks de costo diferenciales?

**El estudio canónico:** Genesove y Mullin (1997, 2006) sobre el cartel del azúcar; y los trabajos sobre aerolíneas (Southwest y las respuestas de las incumbentes), donde el patrón de caída selectiva y recuperación post-salida es visible en datos públicos.

---

## 5. Guía de diagnóstico: ¿predación o competencia?

| Evidencia | Apunta a predación | Apunta a competencia |
|---|---|---|
| Precio vs. costo marginal estimado | $p < mc$ | $p > mc$ |
| Selectividad geográfica | Baja solo donde entró el rival | Baja en todos los mercados |
| Selectividad de producto | Baja solo en los SKU que compiten con el rival | Baja en toda la línea |
| Trayectoria post-salida | Precio **sube** tras la salida | Precio se mantiene |
| Duración | Prolongada sin justificación | Corta, promocional |
| Barreras de entrada | Altas (recuperación viable) | Bajas |
| Capacidad | Expansión de capacidad previa a la entrada | Sin cambio |
| Documentos internos | Objetivo explícito de "sacar" al rival | Objetivo de ganar cuota |
| Rival objetivo | Financieramente restringido | Cualquiera |

> **⚠️ La asimetría de errores.** Un falso positivo (condenar competencia agresiva como predación) **desalienta las bajas de precio**, que es precisamente lo que la política de competencia quiere fomentar. Un falso negativo permite exclusión. La doctrina de Brooke Group refleja un juicio explícito de que el primer error es más costoso. Un análisis económico honesto debe reconocer esta asimetría y exigir evidencia robusta en ambos elementos del test.

---

## 6. Idea de investigación aplicada a Perú

> **💡 Entrada de aerolíneas de bajo costo y respuesta de precios.**
>
> La entrada de operadores low-cost en rutas domésticas peruanas desde 2017-2019 generó variación: unas rutas recibieron entrada, otras no, en momentos distintos. Con datos de tarifas (publicados por la DGAC/MTC, o raspados de sistemas de reserva) se puede:
> 1. Estimar demanda de rutas con logit anidado (nidos: horario, aerolínea).
> 2. Recuperar costos marginales por ruta en el periodo pre-entrada.
> 3. Hacer event study de la respuesta de precios de la incumbente, por ruta.
> 4. Testear si la caída fue por debajo del $mc$ estimado y si hubo reversión tras salidas.
>
> Es replicable con datos públicos, tiene diseño cuasi-experimental creíble y es directamente relevante para INDECOPI. **No existe un estudio académico peruano de este tipo.**

> **💡 Expansión de retail moderno y bodegas.**
>
> La expansión de tiendas de descuento y supermercados a barrios con alta densidad de bodegas ofrece variación geográfica y temporal. ¿Bajan los precios de forma selectiva donde hay competencia informal fuerte? ¿Suben después? El censo de bodegas y los datos de ubicación de tiendas (georreferenciadas, públicas) permiten un diseño de diferencias en diferencias con anillos de distancia. **Relevante también para el Cap. 13: la competencia formal-informal es el rasgo distintivo del retail peruano.**

---

## 7. Lecturas

- McGee (1958), "Predatory Price Cutting: The Standard Oil (N.J.) Case", *JLE* 1. — la crítica de Chicago.
- Areeda y Turner (1975), "Predatory Pricing and Related Practices under Section 2 of the Sherman Act", *Harvard Law Review* 88(4).
- Milgrom y Roberts (1982), "Predation, Reputation, and Entry Deterrence", *JET* 27(2).
- Kreps y Wilson (1982), "Reputation and Imperfect Information", *JET* 27(2).
- Bolton y Scharfstein (1990), "A Theory of Predation Based on Agency Problems in Financial Contracting", *AER* 80(1).
- Bolton, Brodley y Riordan (2000), "Predatory Pricing: Strategic Theory and Legal Policy", *Georgetown Law Journal* 88. — el puente teoría-derecho.
- Genesove y Mullin (1997), "Testing Static Oligopoly Models: Conduct and Cost in the Sugar Industry", *RAND* 28(2).
- Salop y Scheffman (1983), "Raising Rivals' Costs", *AER* 73(2).
- Rey y Tirole (2007), "A Primer on Foreclosure", *Handbook of IO* vol. 3.
- Whinston (1990), "Tying, Foreclosure, and Exclusion", *AER* 80(4).
