# Manual Avanzado de Organización Industrial Empírica

### De la identificación a la valuación: demanda, conducta, colusión y mercados peruanos

**Nivel:** doctorado / investigación aplicada avanzada
**Base:** notas de *Topics in Empirical Industrial Organization* (Universidad del Pacífico, Semanas 3–7)
**Extensión:** teoría del consumidor y del productor avanzada, marketing, precios predatorios, licitaciones públicas, colusión, valuation financiero, vínculos macroeconómicos, agenda de investigación y aplicación al mercado peruano.

---

## 1. Qué es este manual y qué problema resuelve

Las cinco sesiones del curso (S03 Identificación, S04 Estimación de demanda, S05 Sistemas de demanda, S06 Logit e IIA, S07 Logit agregado) son, cada una por separado, excelentes. Pero están escritas como *slides*: enuncian resultados sin demostrarlos, presentan el logit sin el GEV que lo contiene, llegan a markups de Bertrand–Nash sin la teoría del productor que los justifica, y se detienen justo antes de las preguntas que un investigador o un practicante realmente tiene que responder:

- ¿Cómo sé que mi estimación de demanda *identifica* conducta y no solo preferencias?
- ¿Qué hago con una elasticidad de −2.6 cuando el cliente pregunta cuánto vale la empresa?
- ¿Cómo distingo un precio predatorio de una guerra de precios competitiva?
- ¿Cómo detecto colusión en licitaciones del Estado peruano con los datos de SEACE?
- ¿Qué tiene que ver todo esto con la inflación, el pass-through cambiario y el poder de mercado agregado?

Este manual cierra esos huecos. La columna vertebral es la misma del curso —**identificación → demanda → conducta → contrafactual**— pero extendida hasta donde la literatura de frontera la lleva, con las demostraciones completas, las aplicaciones a casos peruanos, y un uso operativo diario.

---

## 2. El hilo conductor en una página

Todo lo que sigue es una variación sobre un solo problema:

> **Observamos equilibrios. Queremos recuperar primitivas.**

Un equilibrio $(p^*, q^*)$ es el punto fijo de dos objetos que no observamos: preferencias (demanda) y tecnología + conducta (oferta). Toda la OI empírica es el arte de romper esa simultaneidad.

```
                    PRIMITIVAS (no observadas)
          ┌─────────────────────┬─────────────────────┐
          │  Preferencias U(·)  │  Costos C(·) + Conducta θ │
          └──────────┬──────────┴──────────┬──────────┘
                     │                     │
             Demanda q(p,x,ξ)       Oferta: FOC de π
                     │                     │
                     └──────────┬──────────┘
                                ▼
                     EQUILIBRIO: (p*, q*, s*)  ← esto es lo único que vemos
                                │
                     ┌──────────┴───────────┐
                     │  Variación exógena   │  ← instrumentos, experimentos,
                     │  (lo que rompe el    │     discontinuidades, shocks
                     │   punto fijo)        │
                     └──────────┬───────────┘
                                ▼
            Elasticidades → Markups → Contrafactuales → Valor
```

Las cinco sesiones del curso cubren la ruta de la demanda. Este manual añade la ruta de la oferta (conducta, colusión, licitaciones, predación), la traducción a dinero (valuation), la agregación (macro) y el contexto institucional (Perú).

---

## 3. Estructura

| # | Capítulo | Qué añade sobre el curso |
|---|---|---|
| [00](00-guia-de-uso.md) | **Guía de uso y rutas de lectura** | Cómo leerlo según el objetivo: tesis, consultoría, litigio, valuation |
| [01](01-teoria-consumidor-productor.md) | **Fundamentos: consumidor y productor avanzado** | Dualidad completa, integrabilidad, Gorman/PIGLOG, bienestar exacto, dualidad de costos, subaditividad, identificación de funciones de producción |
| [02](02-identificacion.md) | **El problema de identificación, en serio** | Condiciones de orden/rango, demostración del sesgo de simultaneidad, IV como GMM, instrumentos débiles (Stock–Yogo, Anderson–Rubin), identificación de **conducta** (Bresnahan, Lau), control functions |
| [03](03-estimacion-demanda-ecuacion-unica.md) | **Demanda de ecuación única** | Formas funcionales con derivaciones, elasticidades exactas vs. aproximadas, Box–Cox, panel, errores estándar correctos, diagnóstico completo |
| [04](04-sistemas-de-demanda.md) | **Sistemas de demanda** | Derivación completa de AIDS desde PIGLOG, QUAIDS, EASI, separabilidad en dos etapas, censura, demostración de todas las elasticidades |
| [05](05-eleccion-discreta.md) | **Elección discreta** | Demostración completa de la fórmula logit, teoría GEV, nested/mixed logit, teorema de aproximación universal de McFadden–Train, WTP y bienestar en RUM |
| [06](06-logit-agregado-blp.md) | **Logit agregado y BLP** | Demostración de la inversión de Berry, prueba de que el mapa BLP es contracción, GMM óptimo, instrumentos de diferenciación (Gandhi–Houde), micro-momentos |
| [07](07-oferta-markups-fusiones.md) | **Oferta: markups, fusiones, pass-through** | Derivación de la fórmula de markup multiproducto, UPP/GUPPI, pass-through, Nash-in-Nash, simulación de fusiones paso a paso |
| [08](08-colusion-y-licitaciones.md) | **Colusión y licitaciones públicas** | Juegos repetidos (Folk, Green–Porter, Rotemberg–Saloner), screens de detección, teoría de subastas con demostraciones, Guerre–Perrigne–Vuong, bid rigging en SEACE |
| [09](09-precios-predatorios.md) | **Precios predatorios y estrategias de exclusión** | Milgrom–Roberts, long purse, Areeda–Turner, Brooke Group, cómo se testea empíricamente con el aparato de los capítulos 3–7 |
| [10](10-marketing.md) | **Marketing cuantitativo** | Dorfman–Steiner demostrado, publicidad persuasiva vs. informativa, promociones, targeting, pricing personalizado, búsqueda del consumidor, CLV |
| [11](11-valuation-finanzas.md) | **Valuation: de elasticidades a valor** | Puente formal elasticidad → margen → EBITDA → DCF, moat y WACC, valuación de sinergias, opciones reales, empresas reguladas |
| [12](12-macro.md) | **Vínculos macroeconómicos** | Markups agregados (De Loecker et al.), demanda Kimball y NK, pass-through cambiario, misallocation, concentración y labor share |
| [13](13-peru.md) | **El mercado peruano** | Marco institucional (INDECOPI, OSIPTEL, Osinergmin, OSCE), casos, fuentes de datos, peculiaridades (informalidad, bodegas, concentración regional) |
| [14](14-uso-diario.md) | **Uso diario: el playbook** | Flujos de trabajo de 1 día / 1 semana / 1 trimestre, código, checklists, errores frecuentes, cómo presentar |
| [15](15-agenda-investigacion.md) | **Agenda de investigación** | 60 ideas con datos, estrategia de identificación y contribución marginal explícita |
| [A](A-apendice-demostraciones.md) | **Apéndice: demostraciones extendidas** | Todas las pruebas largas, reunidas |
| [B](B-apendice-codigo.md) | **Apéndice: código** | R, Stata y Python ejecutables para cada método |

---

## 4. Convenciones de notación

| Símbolo | Significado |
|---|---|
| $j = 1,\dots,J$ | productos; $j=0$ es el bien externo |
| $t = 1,\dots,T$ | mercados (tienda-semana, ciudad-año, país-trimestre) |
| $i$ | consumidor |
| $p_{jt}, q_{jt}, s_{jt}$ | precio, cantidad y participación de mercado |
| $x_{jt}$ | características observadas |
| $\xi_{jt}$ | calidad no observada (el error estructural) |
| $\delta_{jt} = x_{jt}'\beta - \alpha p_{jt} + \xi_{jt}$ | utilidad media |
| $\varepsilon_{jk}$ | elasticidad de $q_j$ respecto de $p_k$ |
| $w_i = p_i q_i / X$ | participación presupuestal |
| $\mathcal{L}_j = (p_j - mc_j)/p_j$ | índice de Lerner |
| $\boldsymbol{H}$ | matriz de propiedad |
| $\theta$ | parámetro de conducta |

Convención de signos: escribimos $\alpha > 0$ como **desutilidad** del precio, de modo que $-\alpha p_j$ entra en la utilidad. Las elasticidades propias son negativas.

---

## 5. Advertencia metodológica

Tres principios gobiernan todo el manual:

1. **La relevancia se testea; la exclusión se argumenta.** Ningún estadístico salva un instrumento sin historia económica. Esto es de S03 y es lo más importante del curso.
2. **El modelo tiene que coincidir con el patrón de sustitución del mundo.** S07 lo demuestra brutalmente: logit IV con instrumentos *válidos* no recupera la verdad cuando el DGP es anidado. Un instrumento correcto no arregla un modelo mal especificado.
3. **Todo contrafactual es una extrapolación.** Un markup, una simulación de fusión, una valuación: todos dependen de parámetros estimados fuera de la muestra del contrafactual. Reportar la elasticidad sin reportar su sensibilidad al tamaño de mercado $M_t$, a la forma funcional y al instrumento es mala práctica.

---

*Documento de trabajo. Las cifras de casos peruanos deben verificarse contra las resoluciones originales de INDECOPI y los organismos reguladores antes de usarse en un trabajo formal o litigio.*
