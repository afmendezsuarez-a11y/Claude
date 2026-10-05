# 15 · Agenda de investigación: 60 ideas

> **Capítulo nuevo.** Cada idea viene con: la **pregunta**, los **datos**, la **estrategia de identificación** y la **contribución marginal** (qué agrega sobre lo que ya existe). Están ordenadas por bloque temático y marcadas por dificultad.
>
> **Leyenda de dificultad:** ◆ ejecutable en un trimestre con datos públicos · ◆◆ requiere construcción de datos o métodos avanzados · ◆◆◆ proyecto de tesis doctoral completa.

---

## Bloque A — Identificación y métodos

**A1 ◆◆ ¿Cuánto importa realmente la elección del instrumento?**
*Pregunta:* dado un mismo mercado, ¿cuánto varía la elasticidad estimada según se use costo, Hausman, BLP o diferenciación?
*Datos:* un panel de retail con las cuatro familias disponibles.
*Identificación:* comparación sistemática con el mismo modelo y la misma muestra.
*Contribución:* la literatura reporta un instrumento por paper; nadie ha hecho el ejercicio comparativo controlado. Un resultado de "la elección cambia la elasticidad en X%" es de alto valor metodológico.

**A2 ◆◆ Monte Carlo sobre el sesgo del índice de Stone en LA-AIDS bajo condiciones de países en desarrollo.**
*Contribución:* Moschini (1995) lo documentó para datos de países ricos con participaciones estables. Con la volatilidad de participaciones de ENAHO el sesgo puede ser mucho mayor. Un resultado que diga "no uses LA-AIDS en datos de hogares de ingreso medio" sería citado.

**A3 ◆◆◆ Identificación de conducta con rotadores de demanda en mercados latinoamericanos.**
*Datos:* entrada escalonada de cadenas de retail/farmacias a ciudades intermedias.
*Identificación:* Bresnahan (1982) con la entrada como rotador.
*Contribución:* casi toda la literatura de parámetros de conducta es de EE.UU. y Europa.

**A4 ◆◆ Instrumentos débiles en la práctica de la OI publicada.**
*Pregunta:* ¿qué fracción de las elasticidades publicadas en OI sobreviven al umbral de $F>104.7$ de Lee et al. (2022)?
*Datos:* meta-análisis de papers publicados con primera etapa reportada.
*Contribución:* un llamado de atención metodológico, con alta probabilidad de atención.

**A5 ◆◆◆ Comparación de markups por la ruta de demanda vs. la ruta de producción en el mismo sector.**
*Ver Cap. 01 §3.4.* La discrepancia entre De Loecker–Warzynski y BLP en los mismos datos es una pregunta abierta de primer orden.

**A6 ◆◆ Sensibilidad de las conclusiones de BLP a la definición de $M_t$: una revisión sistemática.**
*Contribución:* S07 señala que es la decisión más importante y menos discutida. Documentar cuántos papers la justifican y cuánto cambian sus conclusiones sería un servicio a la disciplina.

**A7 ◆◆◆ Identificación no paramétrica de demanda (Berry–Haile) implementada en datos reales.**
*Contribución:* el resultado teórico existe desde 2014; las implementaciones empíricas son pocas.

**A8 ◆◆ Función de control vs. 2SLS en demanda no lineal: ¿cuándo diverge?**
*Método:* Monte Carlo + aplicación.

---

## Bloque B — Demanda y bienestar

**B1 ◆ Elasticidad de demanda de pescado en Lima con El Niño y vedas de IMARPE.**
*Datos:* precios diarios de mercados mayoristas (SISAP), desembarques (IMARPE/Produce), índices de El Niño (ENFEN).
*Identificación:* condiciones oceánicas y vedas como desplazadores de oferta puros.
*Contribución:* réplica de Graddy (1995) con un instrumento posiblemente mejor y en un mercado de país en desarrollo. **La idea de ejecución más rápida del capítulo.**

**B2 ◆◆ QUAIDS con ENAHO e incidencia distributiva del ISC a bebidas azucaradas por decil.**
*Contribución:* la mayoría de los trabajos peruanos usan LA-AIDS sin corrección de unit values; QUAIDS por decil con el método de Deaton sería el estándar correcto y daría números distintos.

**B3 ◆◆ Efecto del ISC a bebidas azucaradas usando el umbral de 6g/100ml como discontinuidad.**
*Identificación:* RDD sobre el contenido de azúcar; separa el efecto del impuesto del efecto del etiquetado de octógonos, que es simultáneo.
*Contribución:* la literatura de impuestos a bebidas (México, Chile, Berkeley) no tiene un diseño que separe ambos canales tan limpiamente.

**B4 ◆◆ Elasticidad de demanda de alimentos por nivel de inseguridad alimentaria.**
*Datos:* ENAHO + módulo de seguridad alimentaria.
*Contribución:* la elasticidad relevante para política alimentaria es la de los hogares vulnerables, no la media.

**B5 ◆◆◆ Demanda de educación superior privada y retornos.**
*Datos:* SUNEDU, ENAHO, planilla electrónica (para salarios posteriores).
*Pregunta:* ¿cómo eligen los hogares entre instituciones? ¿Qué pagan por calidad vs. por señal?
*Método:* elección discreta con características de institución.

**B6 ◆◆ Demanda de transporte urbano y el efecto de la formalización.**
*Datos:* encuestas de movilidad de Lima, datos de corredores.
*Método:* logit anidado por modo.
*Contribución:* la reforma del transporte en Lima es un cambio de política grande sin evaluación estructural.

**B7 ◆◆ Demanda de energía doméstica y la "escalera energética" (leña → GLP → electricidad).**
*Datos:* ENAHO, precios de FISE.
*Contribución:* calcular la tasa de descuento implícita de hogares rurales (Cap. 05 §6.3) y el subsidio necesario para la transición.

**B8 ◆◆ ¿Cuánto vale la variedad? Beneficio de la entrada de nuevos productos en Perú.**
*Método:* el log-sum de Cap. 05 §6.2 antes y después de la entrada.
*Contribución:* aplicación de Petrin (2002) / Feenstra a un mercado emergente.

**B9 ◆◆◆ Demanda con conjuntos de consideración limitados en un mercado de alta informalidad.**
*Método:* Weitzman/Honka con datos de encuesta de conjunto de consideración.
*Contribución:* el supuesto de "el consumidor evalúa todas las alternativas" es especialmente falso en mercados con información escasa.

**B10 ◆◆ EASI vs. QUAIDS vs. AIDS en datos de hogares de América Latina.**
*Contribución:* EASI está infrautilizado y permite curvas de Engel arbitrarias, que es lo que estos datos requieren.

---

## Bloque C — Competencia, fusiones y conducta

**C1 ◆◆ Evaluación ex post de fusiones aprobadas en Perú pre-2021.**
*Identificación:* diff-in-diff con mercados de control.
*Contribución:* la literatura de evaluación ex post (Ashenfelter, Hosken) casi no tiene casos latinoamericanos. Y es directamente útil para INDECOPI.

**C2 ◆◆ Efecto de la introducción del control previo de concentraciones (Ley 31112).**
*Identificación:* diff-in-diff con países de la región sin cambio de régimen; o comparación de sectores con distinta exposición.
*Contribución:* evidencia causal del efecto de un régimen de control de fusiones — hay pocos experimentos de este tipo en el mundo.

**C3 ◆◆ Entrada de aerolíneas de bajo costo y respuesta de precios.**
*Ver Cap. 09 §6.* Diseño de event study por ruta + test de predación.

**C4 ◆◆ Competencia entre bancos: ¿cuánto bajan las tasas con un competidor más?**
*Datos:* SBS, tasas por entidad-producto-periodo; presencia de agencias por distrito.
*Identificación:* entrada de agencias; fusiones bancarias.

**C5 ◆◆◆ Competencia entre AFP y el diseño de la licitación de afiliados.**
*Pregunta:* ¿la licitación bajó las comisiones? ¿Fue un diseño óptimo?
*Método:* subastas + demanda con costos de cambio.
*Contribución:* es un diseño de mecanismo deliberado con datos públicos. Prácticamente no hay literatura académica sobre él.

**C6 ◆◆ Retail moderno vs. canal tradicional: efecto de la entrada de supermercados sobre bodegas y sobre el bienestar.**
*Plantilla:* Atkin, Faber y González-Navarro (2018) para México, directamente trasladable.
*Datos:* censo de establecimientos, ENAHO, ubicación georreferenciada de tiendas.
*Contribución:* el estudio de México es muy citado; Perú tiene mayor informalidad y daría un contraste informativo.

**C7 ◆◆ Common ownership de las AFP en la BVL.**
*Ver Cap. 12 §6.* Construcción de la matriz $H$ generalizada con datos de SMV.

**C8 ◆◆◆ Modelo de entrada de Ciliberto–Tamer para el retail peruano.**
*Método:* identificación por conjuntos con desigualdades de momentos.
*Pregunta:* ¿cuáles son los costos fijos de entrada por tipo de ciudad y cómo cambian con la presencia de rivales?

**C9 ◆◆ Margin squeeze en telecomunicaciones: test del competidor igualmente eficiente.**
*Datos:* tarifas mayoristas reguladas y minoristas (OSIPTEL).
*Contribución:* informe técnico directamente utilizable por el regulador.

**C10 ◆◆ Testear modelos de conducta (Bertrand vs. Cournot vs. cartel) en un sector concentrado peruano.**
*Método:* Backus–Conlon–Sinkinson / Berry–Haile: comparar los $mc$ implicados por cada modelo con shifters de costo observados.

---

## Bloque D — Colusión y compras públicas

**D1 ◆ Screening sistemático de SEACE: construcción de un índice de riesgo de colusión.**
*Datos:* todas las licitaciones de SEACE.
*Método:* los screens del Cap. 08 §4.4, aplicados masivamente.
*Entregable:* un ranking de mercados-regiones por riesgo, replicable y actualizable.
*Contribución:* herramienta de política de impacto inmediato. **Es probablemente la idea de mayor retorno social del capítulo.**

**D2 ◆◆◆ Estimación GPV de costos y markups en obras públicas peruanas.**
*Método:* Guerre–Perrigne–Vuong (Cap. 08 §5.3).
*Entregable:* cuánto paga de más el Estado y cuánto ahorraría con un postor adicional o con un precio de reserva óptimo.

**D3 ◆◆ Adicionales de obra como margen oculto: la puja como opción.**
*Ver Cap. 08 §6.3.* Datos: SEACE + INFOBRAS.
*Contribución:* formalización teórica nueva (la puja incorpora el valor de la opción de adicionales) + evidencia empírica. **La idea más original del capítulo.**

**D4 ◆◆ Efecto de la detección de un cartel sobre los precios: evidencia de casos peruanos.**
*Identificación:* event study alrededor de la fecha de inicio de investigación / resolución.
*Contribución:* cuantificación del sobreprecio ex post, útil para acciones de daños.

**D5 ◆◆ Comparación de modalidades de contratación pública: ¿la subasta inversa electrónica ahorra o facilita la colusión?**
*Identificación:* umbrales de monto que determinan la modalidad → RDD.
*Contribución:* la teoría (Cap. 08 §5.1) predice que los formatos abiertos son más vulnerables a la colusión. Testearlo con datos es una contribución al diseño de compras públicas.

**D6 ◆◆ Redes de co-participación en licitaciones: detección de carteles con métodos de redes.**
*Método:* grafos de co-postulación; detección de comunidades; comparación con casos sancionados conocidos como validación.

**D7 ◆◆◆ Aplicación de los screens robustos de Chassang et al. (2022) a datos peruanos.**
*Contribución:* es el estado del arte y no se ha aplicado fuera de Japón/EE.UU.

**D8 ◆◆ ¿La transparencia de precios facilita la colusión? El caso de los combustibles.**
*Identificación:* la introducción de plataformas públicas de comparación de precios de grifos.
*Contribución:* test directo de la "paradoja de la transparencia" (Cap. 08 §3), con un caso peruano identificado.

---

## Bloque E — Precios, pass-through y macro

**E1 ◆ Pass-through asimétrico en combustibles por grifo.**
*Datos:* Osinergmin, precios diarios georreferenciados + precios internacionales.
*Contribución:* el "cohete y pluma" está documentado internacionalmente; con datos a nivel de grifo se puede identificar el mecanismo (¿es búsqueda del consumidor? ¿colusión tácita? ¿costos de menú?).

**E2 ◆◆ ERPT a nivel producto-mercado y su relación con la estructura de competencia.**
*Ver Cap. 12 §4.2.* La pregunta —¿más concentración implica más o menos pass-through?— tiene respuesta teórica ambigua y relevancia directa para el BCRP.

**E3 ◆◆◆ Markups sectoriales en Perú: primera estimación sistemática.**
*Datos:* EEA de Produce, panel de firmas.
*Método:* ACF + De Loecker–Warzynski, con tratamiento explícito de costos fijos (la crítica de Basu/Traina).
*Contribución:* no existe. Y es insumo para toda la discusión de política de competencia.

**E4 ◆◆◆ Descomposición de la misallocation peruana: poder de mercado vs. fricciones financieras vs. informalidad.**
*Ver Cap. 12 §5.2.* Proyecto de tesis completo.

**E5 ◆◆ Umbrales regulatorios y la "trampa de la microempresa".**
*Identificación:* RDD sobre umbrales de ventas/empleo que cambian el régimen tributario y laboral.
*Pregunta:* ¿cuánto crecimiento empresarial se pierde por el salto discreto de costos al cruzar el umbral?
*Contribución:* evidencia causal sobre una distorsión de política muy discutida y poco medida.

**E6 ◆◆ Ciclicidad de los markups en Perú: ¿pro o contracíclicos?**
*Contribución:* el input que la macro necesita de la OI (Cap. 12 §3.1), y un test indirecto de Rotemberg–Saloner.

**E7 ◆◆ Rigidez de precios con microdatos del IPC.**
*Datos:* precios individuales que recoge INEI para el IPC.
*Preguntas:* frecuencia y tamaño de los cambios de precio; ¿son consistentes con Calvo o con costos de menú?; ¿cómo cambia con la inflación?
*Contribución:* es la base empírica de cualquier modelo NK calibrado para Perú y no está documentada públicamente.

**E8 ◆◆ Calibrar la superelasticidad de Kimball con parámetros de BLP.**
*Ver Cap. 12 §3.2.* Puente teórico OI-macro poco explotado.

---

## Bloque F — Marketing y comportamiento

**F1 ◆◆ Elasticidad publicitaria en un mercado emergente: ¿difiere de los benchmarks internacionales?**
*Identificación:* discontinuidades de cobertura de señal de TV o radio; spillovers geográficos de campañas.

**F2 ◆◆ Distribución numérica como característica de demanda.**
*Pregunta:* en el canal tradicional peruano, ¿cuánto de la participación de marca se explica por disponibilidad vs. por preferencia?
*Método:* BLP con disponibilidad como característica (endógena; instrumentar con costos logísticos y densidad de rutas).
*Contribución:* el modelo estándar supone que todas las alternativas están disponibles. En mercados con distribución fragmentada, es falso y probablemente la variable más importante.

**F3 ◆◆ Promociones: ¿cuánto del pico es consumo nuevo?**
*Método:* test del valle post-promoción (Cap. 10 §4.2) con panel de hogares.
*Contribución:* la descomposición nunca se ha hecho con datos peruanos y la respuesta cambia la estrategia comercial de cualquier empresa de consumo.

**F4 ◆◆ Costos de cambio en telecomunicaciones antes y después de la portabilidad numérica.**
*Identificación:* la introducción de la portabilidad como shock.
*Método:* demanda con dependencia de estado, distinguiendo costos de cambio de heterogeneidad (Dubé–Hitsch–Rossi).

**F5 ◆◆◆ Efecto de las plataformas de delivery sobre la competencia en restaurantes.**
*Preguntas:* ¿expanden el mercado o redistribuyen? ¿Cómo afecta la posición en el ranking a la demanda? ¿Cuál es la incidencia de la comisión?
*Datos:* raspado de plataformas; convenio con una plataforma.

**F6 ◆◆ Efecto de los octógonos de advertencia sobre la elección de productos.**
*Identificación:* el umbral de contenido que determina el octógono → RDD.
*Contribución:* la literatura de etiquetado frontal es grande (Chile) pero el diseño de RDD sobre el umbral es poco usado.

**F7 ◆◆ Brand equity estimado estructuralmente ($\xi_{jt}$) vs. métricas comerciales de marca.**
*Pregunta:* ¿la calidad no observada estimada con BLP correlaciona con los índices de brand equity que venden las consultoras?
*Contribución:* validación cruzada de dos metodologías que nunca se han comparado. De interés tanto académico como comercial.

---

## Bloque G — Finanzas y valuation

**G1 ◆◆ Elasticidad-ingreso sectorial como predictor del beta.**
*Ver Cap. 11 §5.1.*
*Contribución:* método alternativo de estimación de beta para empresas sin comparables líquidos — un problema real en la BVL.

**G2 ◆◆ Persistencia de beneficios anormales en empresas peruanas.**
*Método:* Mueller (1986) aplicado a estados financieros de la SMV.
*Entregable:* la tasa de erosión $\lambda$ empírica, insumo directo para valuaciones (Cap. 11 §2.3).

**G3 ◆◆ ¿Las fusiones peruanas crearon valor? Event study + evaluación ex post de márgenes.**

**G4 ◆◆ Efecto del WACC regulatorio sobre la inversión en sectores regulados peruanos.**
*Identificación:* revisiones tarifarias como shocks.

**G5 ◆◆◆ Poder de mercado y retornos accionarios: ¿el mercado valora correctamente el moat?**
*Método:* construir una medida de markup por empresa cotizada y testear si predice retornos futuros anormales.

---

## Bloque H — Preguntas abiertas de frontera

**H1 ◆◆◆ Precios algorítmicos y colusión tácita.**
*Pregunta:* ¿pueden algoritmos de pricing aprender a coludir sin comunicación? La evidencia de simulación (Calvano et al. 2020) dice que sí. ¿Ocurre en mercados reales?
*Datos candidatos:* precios de grifos (alta frecuencia, pocos jugadores locales), e-commerce.
*Contribución:* es la pregunta de política de competencia más importante de la década y la evidencia de campo es casi inexistente.

**H2 ◆◆◆ Demanda con atención limitada e inflación alta.**
*Pregunta:* cuando la inflación es alta, ¿los consumidores prestan más atención a los precios y la demanda se vuelve más elástica?
*Contribución:* une la literatura de atención racional con la de demanda; tiene implicaciones directas para la pendiente de la curva de Phillips.

**H3 ◆◆◆ Poder de mercado en el mercado laboral (monopsonio) en Perú.**
*Pregunta:* ¿cuál es la elasticidad de oferta laboral que enfrenta la firma? El markdown salarial es el espejo del markup.
*Datos:* planilla electrónica de SUNAT.
*Contribución:* la literatura de monopsonio ha explotado en años recientes; no hay evidencia latinoamericana significativa.

**H4 ◆◆◆ Cadenas de suministro y poder de mercado: pass-through a lo largo de la cadena vertical.**
*Datos:* facturación electrónica de SUNAT (si fuera accesible) permitiría ver transacciones firma-a-firma.
*Contribución:* la literatura de redes de producción (Acemoglu, Carvalho) carece de datos con estructura de mercado.

**H5 ◆◆◆ Sostenibilidad y demanda: ¿cuánto pagan realmente los consumidores por atributos ambientales?**
*Método:* experimentos de elección + datos de mercado; comparar WTP declarada vs. revelada.

**H6 ◆◆ Informalidad como "bien externo" endógeno.**
*Pregunta:* en los modelos de demanda peruanos, el canal informal es parte de $s_0$. Pero el informal responde a precios. Modelar el bien externo como una alternativa con precio propio.
*Contribución:* adaptación metodológica necesaria para toda la OI en economías con alta informalidad. **Podría ser una contribución metodológica de alcance regional.**

---

## Cómo elegir entre estas ideas

Tres criterios, en orden:

1. **¿Tengo (o puedo conseguir) los datos en 6 semanas?** Si no, el proyecto muere. Las ideas marcadas ◆ ya tienen los datos disponibles públicamente.
2. **¿Puedo nombrar la fuente de variación exógena en una frase?** Si no, no hay paper.
3. **¿Alguien cambia de opinión o de decisión con el resultado?** Si la respuesta es "no", es un ejercicio, no una investigación.

**Y un cuarto, informal pero decisivo:** ¿puedo explicarle la pregunta a alguien fuera de la economía y le parece interesante? Las mejores preguntas de OI aplicada pasan esa prueba.

---

## Las cinco que yo elegiría

Si tuviera que apostar por cinco, por relación entre factibilidad, originalidad e impacto:

| | Idea | Por qué |
|---|---|---|
| 1 | **D1** — Screening de SEACE | Datos listos, método claro, impacto social directo, replicable como herramienta permanente |
| 2 | **D3** — Adicionales de obra como opción | Contribución teórica genuina + datos peruanos únicos + relevancia de política |
| 3 | **B1** — Pescado con El Niño | Ejecución rápida, conecta directamente con el curso, bonito como primer paper |
| 4 | **H6** — Informalidad como bien externo endógeno | Contribución metodológica de alcance regional, no solo peruano |
| 5 | **E3** — Markups sectoriales peruanos | Es la pieza que falta para todo el debate de política de competencia en el país |
