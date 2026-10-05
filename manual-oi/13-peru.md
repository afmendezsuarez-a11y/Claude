# 13 · El mercado peruano

> **Capítulo nuevo.** Aplicar OI empírica a Perú no es traducir un paper de EE.UU. El mercado peruano tiene rasgos estructurales —informalidad masiva, canal tradicional dominante, concentración regional, dolarización parcial, geografía que fragmenta mercados— que cambian qué modelo es apropiado, qué datos existen y qué supuestos se sostienen. Este capítulo es el mapa.
>
> **Advertencia.** Las cifras, umbrales y detalles de casos de este capítulo deben verificarse contra las fuentes primarias (resoluciones de INDECOPI, normas vigentes, publicaciones de INEI/BCRP) antes de usarse en trabajo formal, litigio o publicación. Las normas y los umbrales en UIT se actualizan.

---

## 1. Seis rasgos estructurales que cambian el análisis

### 1.1 Informalidad

Una fracción mayoritaria del empleo es informal, y una parte sustancial del comercio minorista ocurre fuera del canal formal.

**Consecuencias analíticas:**
- **Los datos de scanner cubren una fracción del mercado.** Si estimas demanda con datos de supermercados, estás estimando la demanda de un segmento (urbano, ingresos medios-altos), no del mercado.
- **El "bien externo" es enorme y heterogéneo.** $s_0$ incluye no solo "no compró" sino "compró en el canal informal", que es una alternativa con precio distinto.
- **La definición de mercado relevante debe incluir al informal.** Un análisis de concentración que solo mire el canal moderno sobreestima la concentración drásticamente.

### 1.2 El canal tradicional (bodegas)

El comercio minorista de consumo masivo está dominado por cientos de miles de bodegas, no por cadenas.

**Consecuencias:**
- **La estructura vertical es distinta:** el poder de negociación proveedor-minorista funciona al revés que en EE.UU. (donde Walmart domina). En Perú el productor de consumo masivo tiene más poder frente a la bodega atomizada, pero menos frente al retail moderno.
- **Precio al consumidor ≠ precio de lista.** La bodega fija su propio margen y no hay precio único observable.
- **La distribución es una barrera de entrada real.** La red de distribuidores que llega a 400,000 puntos de venta es un activo difícil de replicar. Esto es más importante que la publicidad para explicar la persistencia de cuota.

> Para un modelo de demanda, esto implica que **la "distribución numérica" (% de puntos de venta donde el producto está disponible) es una variable de demanda de primer orden**, probablemente más importante que la publicidad. Y es endógena.

### 1.3 Geografía y fragmentación de mercados

La cordillera y la selva fragmentan los mercados: los costos de transporte entre Lima y ciudades de sierra o selva son altos, los tiempos largos y las vías vulnerables a huaicos.

**Consecuencias:**
- **Los mercados geográficos relevantes son más pequeños** que en economías planas.
- **Hay dispersión de precios regional genuina** — lo que es una fuente de **variación útil para identificación**.
- Los **instrumentos Hausman funcionan mejor** aquí que en economías integradas, porque los shocks de demanda son más localizados. Pero cuidado con el caso de precio nacional único (Cap. 03 §3.3).

### 1.4 Dolarización parcial y exposición a commodities

Depósitos y créditos en dólares coexisten con la moneda local; el tipo de cambio responde a los términos de intercambio (cobre).

**Consecuencia para identificación:** como se advierte en el Cap. 03 §3.1, **el tipo de cambio no es un instrumento exógeno de costo** para bienes de consumo, porque el canal del ingreso nacional lo contamina.

### 1.5 Concentración en varios sectores clave

Varios mercados peruanos tienen estructuras de pocos jugadores: cerveza, bebidas gaseosas, cemento (con segmentación regional), banca, retail moderno, AFP, farmacias, telecomunicaciones.

**Consecuencia:** Perú es un **laboratorio natural para la OI**. Las estructuras son suficientemente simples para modelar y suficientemente concentradas para que el poder de mercado importe.

### 1.6 Datos administrativos ricos y subutilizados

Perú tiene datos administrativos de calidad poco explotados académicamente: SEACE (compras públicas), SUNAT (aduanas, planilla electrónica), SBS (sistema financiero), Osinergmin (precios de combustibles georreferenciados y diarios), DIGEMID (precios de medicamentos), Midagri (precios agrícolas diarios por mercado).

**Esta es la ventaja comparativa de un investigador en Perú:** los datos existen y están poco usados.

---

## 2. Marco institucional

### 2.1 Autoridad de competencia

**INDECOPI** — Instituto Nacional de Defensa de la Competencia y de la Protección de la Propiedad Intelectual.

| Órgano | Función |
|---|---|
| **Comisión de Defensa de la Libre Competencia (CLC)** | Investiga y sanciona conductas anticompetitivas; evalúa concentraciones |
| **Secretaría Técnica de la CLC** | Instrucción de los procedimientos |
| **Tribunal de Defensa de la Competencia** | Segunda instancia administrativa |
| Comisiones de Protección al Consumidor, Fiscalización de la Competencia Desleal, Dumping | Otras materias |

### 2.2 Normas principales

| Norma | Contenido |
|---|---|
| **D.L. 1034** (modificado por **D.L. 1205**) | Ley de Represión de Conductas Anticompetitivas |
| **Ley 31112** (2021) | Control previo de operaciones de concentración empresarial |
| **D.L. 807** | Facultades de INDECOPI |
| **Ley 29571** | Código de Protección y Defensa del Consumidor |

**Estructura del D.L. 1034:**
- **Art. 10 — Abuso de posición de dominio:** incluye negativa injustificada de trato, discriminación, cláusulas de atadura, y **precios predatorios**. Se analiza bajo regla de la razón.
- **Art. 11 — Prácticas colusorias horizontales:** acuerdos entre competidores. Las modalidades *hard-core* (fijación de precios, reparto de mercado, limitación de producción, **concertación en licitaciones**) están sujetas a **prohibición absoluta** — no requieren demostrar efectos.
- **Art. 12 — Prácticas colusorias verticales:** sujetas a prohibición relativa (regla de la razón); requieren posición de dominio de al menos una parte.

**Programa de Clemencia:** exoneración total de multa para el primero que aporte información determinante sobre un cártel; reducciones para los siguientes. Ha sido la herramienta que destrabó los casos grandes.

### 2.3 Reguladores sectoriales

| Regulador | Sector | Datos y decisiones útiles |
|---|---|---|
| **OSIPTEL** | Telecomunicaciones | Tarifas, portabilidad, interconexión, encuestas de uso; estadísticas de suscriptores por operador y departamento |
| **Osinergmin** | Energía y minería | Precios de combustibles por grifo (Facilito), tarifas eléctricas (VAD), fijaciones tarifarias con documentos técnicos públicos |
| **Sunass** | Agua y saneamiento | Estudios tarifarios de EPS |
| **Ositran** | Infraestructura de transporte | Concesiones, tarifas de puertos/aeropuertos/carreteras |
| **SBS** | Banca, seguros, AFP | Tasas de interés por producto y entidad, comisiones, estados financieros |
| **SMV** | Mercado de valores | Estados financieros, estructura de propiedad, hechos de importancia |

**Para un investigador, los reguladores sectoriales son la mejor fuente de datos de precios con alta frecuencia y cobertura.**

---

## 3. Fuentes de datos: el inventario

| Fuente | Contenido | Granularidad | Uso típico |
|---|---|---|---|
| **ENAHO** (INEI) | Gasto de hogares por producto, demografía, ingreso | Hogar, anual, panel rotativo | AIDS/QUAIDS, elasticidades por decil, Deaton |
| **ENDES** (INEI) | Salud, nutrición | Hogar | Outcomes de salud (impuestos a alimentos) |
| **IPC desagregado** (INEI) | Precios por variedad y ciudad | Variedad-ciudad-mes | Pass-through, dispersión de precios |
| **SUNAT – Aduanas** | Importaciones/exportaciones por partida, país, empresa | Operación | Instrumentos de costo, pass-through, competencia de importados |
| **SUNAT – planilla electrónica** | Empleo, salarios por firma | Firma-trabajador-mes | Productividad, markups, labor share |
| **SEACE / OSCE** | Licitaciones públicas completas | Convocatoria-postor | Subastas, bid rigging, GPV |
| **INFOBRAS** (Contraloría) | Ejecución de obras públicas, adicionales | Obra | Adicionales de obra (ver Cap. 08 §6.3) |
| **Produce – EEA** | Encuesta Económica Anual de empresas | Firma-año | Funciones de producción, markups |
| **BCRP – estadísticas** | Series macro, tipo de cambio, crédito | Mensual/trimestral | Controles macro, ERPT |
| **Osinergmin – Facilito** | Precios de combustibles | Grifo-día | Pass-through, competencia local, colusión |
| **DIGEMID – Observatorio** | Precios de medicamentos | Producto-establecimiento | Demanda farmacéutica, competencia de genéricos |
| **Midagri – SISAP** | Precios de productos agrícolas | Producto-mercado-día | Demanda de alimentos, transmisión de precios |
| **IMARPE** | Desembarques pesqueros, biomasa, vedas | Especie-puerto-periodo | **Instrumentos de oferta tipo Graddy** |
| **SMV** | Estados financieros, propiedad | Empresa-trimestre | Valuation, common ownership |
| **SBS** | Tasas, comisiones, cartera | Entidad-producto-mes | Competencia bancaria |
| **Censos (INEI)** | Población, empresas, bodegas | Distrito | Tamaño de mercado $M_t$, demografía para micro-momentos |

> **El dataset que falta: scanner data.** Perú no tiene un equivalente público al Dominick's o al Nielsen académico. Las consultoras (Kantar, NielsenIQ) tienen paneles de hogares y auditorías de retail, pero el acceso es comercial. **Conseguir un convenio de acceso académico a un panel de hogares peruano sería una contribución de infraestructura de investigación significativa**, que habilitaría toda la agenda estructural.

---

## 4. Perfiles sectoriales para investigación

### 4.1 Bebidas no alcohólicas

- **Estructura:** pocos embotelladores grandes con portafolios múltiples; marcas locales (Inca Kola, Kola Real/Big Cola) con fuerte identidad.
- **Por qué es interesante:** diferenciación de producto genuina, lealtad de marca fuerte, un caso histórico de entrada exitosa de un competidor de bajo precio (la trayectoria del grupo que creó Kola Real), y un cambio de política relevante (ISC + octógonos 2018-2019).
- **Método:** BLP o nested logit (nidos: cola/no-cola, o por tamaño de envase).
- **Identificación:** umbral de 6g de azúcar/100ml del ISC (RDD), variación regional de precios, costos de azúcar y PET.

### 4.2 Combustibles

- **Datos:** los mejores del país. Precios diarios por grifo, georreferenciados, públicos.
- **Preguntas:** pass-through asimétrico ("cohete y pluma"); efecto de la densidad de competidores sobre el margen; efecto del FEPC; colusión local.
- **Método:** panel con efectos fijos de grifo; análisis espacial (competidores dentro de $X$ km).
- **Por qué es la mejor apuesta para un primer paper:** los datos son públicos, limpios, de alta frecuencia y con variación espacial masiva. Un trabajo de calidad se puede hacer en un trimestre.

### 4.3 Farmacéutico

- **Estructura:** concentración alta en el retail de cadenas; mercado de genéricos y de marca; compras públicas de medicamentos (CENARES).
- **Preguntas:** competencia genéricos vs. marca; efecto de la entrada de genéricos sobre precios; concertación (hay precedente); eficiencia de las compras públicas de medicamentos.
- **Datos:** Observatorio de precios de DIGEMID + SEACE para compras públicas.

### 4.4 Telecomunicaciones

- **Estructura:** pocos operadores móviles, con entrada relativamente reciente de nuevos competidores que alteró la estructura.
- **Preguntas:** efecto de la entrada sobre precios y calidad; efecto de la portabilidad numérica sobre los costos de cambio; brecha de cobertura urbano-rural; margin squeeze en insumos mayoristas.
- **Método:** logit anidado con datos de participaciones de OSIPTEL; modelo de costos de cambio.
- **Oportunidad:** OSIPTEL publica datos de suscriptores por operador y departamento — suficiente para un modelo de demanda agregada tipo Berry.

### 4.5 Sistema financiero y AFP

- **Preguntas:** competencia en tasas de interés por segmento; efecto de la entrada de fintech; competencia entre AFP (que fue objeto de reforma con licitación de afiliados — un experimento de diseño de mecanismos); costos de cambio bancarios.
- **Datos:** SBS publica tasas por entidad y producto, con alta frecuencia.
- **La licitación de afiliados a las AFP es un diseño de mecanismo deliberado**, con asignación de nuevos afiliados al ganador de una subasta de comisión. Es un caso de estudio de diseño de mercado con datos públicos.

### 4.6 Cemento y materiales de construcción

- **Estructura:** productores con fuerte segmentación **geográfica** (norte, centro, sur), con costos de transporte que crean mercados regionales casi separados.
- **Por qué importa:** es el ejemplo de libro de mercados geográficos definidos por costos de transporte; y el cemento es el sector donde la literatura internacional de colusión es más densa.
- **Método:** modelo espacial de demanda; análisis de márgenes por región.

### 4.7 Pesca y alimentos frescos

- **Por qué:** es la réplica directa de Graddy (1995) con un instrumento aún mejor (El Niño + vedas de IMARPE).
- **Datos:** SISAP (precios diarios por mercado mayorista), IMARPE (desembarques, vedas), ENFEN (condiciones de El Niño).
- **Esta es, en mi lectura, la aplicación más limpia y de ejecución más rápida disponible en datos peruanos**, y conecta directamente con la sesión S03 del curso.

---

## 5. Diez proyectos listos para ejecutar

Ordenados por relación valor/esfuerzo. (La agenda extensa está en el [Cap. 15](15-agenda-investigacion.md).)

1. **Elasticidad de demanda de pescado en Lima con El Niño y vedas como instrumentos.** Réplica de Graddy con datos peruanos. Ejecutable en 6-8 semanas. Datos públicos.
2. **Pass-through asimétrico de combustibles por grifo.** Datos de Osinergmin. Pregunta de política viva.
3. **Screening sistemático de colusión en SEACE.** Aplicar los screens del Cap. 08 §4.4 a todo el universo de licitaciones. Producir un ranking de mercados sospechosos.
4. **Efecto del ISC a bebidas azucaradas usando el umbral de 6g/100ml (RDD).** Separa el impuesto del etiquetado.
5. **QUAIDS con ENAHO por decil + incidencia distributiva de impuestos a alimentos.** Corrige el método de Deaton para unit values.
6. **Entrada de aerolíneas low-cost y respuesta de precios en rutas domésticas.** Event study + test de predación (Cap. 09 §6).
7. **Adicionales de obra como margen oculto en licitaciones.** SEACE + INFOBRAS. Novedoso.
8. **Markups sectoriales peruanos por la ruta de producción (ACF + De Loecker–Warzynski) con la EEA de Produce.** Primera estimación sistemática para Perú.
9. **Efecto del control de concentraciones (Ley 31112) sobre precios y fusiones.** Diff-in-diff pre/post 2021 con comparación internacional.
10. **Common ownership de las AFP en la BVL.** Construir la matriz $H$ generalizada con datos de SMV.

---

## 6. Qué cambiar al aplicar los modelos del manual a Perú

| Modelo | Ajuste necesario |
|---|---|
| **Ecuación única (Cap. 03)** | Corregir unit values de ENAHO con el método de Deaton. No usar el tipo de cambio como instrumento sin controlar el canal de ingreso |
| **AIDS (Cap. 04)** | Usar **QUAIDS**: las curvas de Engel no son lineales en el rango de gasto peruano. Tratar la censura (muchos ceros) |
| **Logit / BLP (Caps. 05–06)** | **Definir $M_t$ con cuidado extremo**: la población no es el mercado si la informalidad y el poder adquisitivo varían mucho. Incluir distribución numérica como característica. El bien externo incluye el canal informal |
| **Markups (Cap. 07)** | Los márgenes contables peruanos incluyen la cadena de distribución; separar margen de productor del de bodega |
| **Colusión (Cap. 08)** | SEACE es la mejor fuente. Ajustar screens por la alta heterogeneidad de costos regionales (geografía) |
| **Valuation (Cap. 11)** | Betas de comparables locales son ruidosos por iliquidez de la BVL. Usar el canal de elasticidad-ingreso (Cap. 11 §5.1) |
| **Macro (Cap. 12)** | Informalidad masiva ⇒ la misallocation tiene un canal adicional (umbrales regulatorios) que no está en Hsieh–Klenow |

---

## 7. Advertencias de método para el contexto peruano

> **⚠️ El tamaño de mercado $M_t$ es el problema número uno.** En un estudio de EE.UU., "número de hogares" es una aproximación razonable del mercado potencial. En Perú, con dispersión de ingresos de un orden de magnitud y acceso diferencial a canales, el mercado potencial de un producto de marca puede ser una fracción pequeña de los hogares. **Definirlo mal arruina las elasticidades.** Reportar siempre sensibilidad a $\{0.5M, M, 2M\}$ y, mejor aún, construir $M_t$ con información de penetración de la categoría por decil de ENAHO.

> **⚠️ Agregación geográfica.** Tratar "Perú" como un mercado es casi siempre un error. Los mercados son ciudades o regiones. Agregar al nivel nacional promedia precios que no compiten entre sí y genera sesgos de agregación severos.

> **⚠️ Series cortas y quiebres.** Las series peruanas tienen quiebres metodológicos (cambios de año base, cambios de muestra de ENAHO, cambio de clasificadores). Verificar la continuidad antes de estimar modelos de series de tiempo largos.

> **⚠️ Cuidado con los datos de gremios.** Las asociaciones empresariales publican datos de participación de mercado. Son útiles pero no auditados, y la membresía del gremio determina la cobertura. Triangular siempre.

---

## 8. Lecturas y recursos

**Institucional**
- INDECOPI, *Lineamientos del Programa de Clemencia* y *Guía de control previo de concentraciones empresariales*.
- Resoluciones de la CLC y del Tribunal, disponibles en el portal de INDECOPI. **Leer dos o tres resoluciones completas es la mejor forma de entender qué evidencia convence a la autoridad.**
- OSIPTEL, Osinergmin: informes de evaluación de competencia sectorial.

**Datos**
- INEI, documentación metodológica de ENAHO.
- Plataforma Nacional de Datos Abiertos (datosabiertos.gob.pe).
- Portal de transparencia de OSCE/SEACE.

**Metodológico para países en desarrollo**
- Deaton (1997), *The Analysis of Household Surveys*. — la referencia para trabajar con encuestas de hogares.
- Atkin, Faber y González-Navarro (2018), "Retail Globalization and Household Welfare: Evidence from Mexico", *JPE* 126(1). — plantilla excelente para el efecto del retail moderno, directamente trasladable a Perú.
- Busso, Madrigal y Pagés (2013), "Productivity and Resource Misallocation in Latin America", *BE Journal*.
