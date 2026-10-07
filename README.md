# Electro Dunas (ELDU) — elasticidad-ingreso de la demanda y proyección de volúmenes

Pipeline reproducible en R para **reemplazar las elasticidades a dedo del DCF
(0.8 BT / 0.9 MT) por una estimación real, trazable y con su incertidumbre**,
usando sólo datos obtenibles sin trámites (APIs públicas, descargas abiertas y
PDFs de las Memorias Anuales).

Alcance deliberado: modelo de **alto nivel para una valorización DCF de comité**,
no una tesis econométrica. Frecuencia **anual** (el SICOM mensual de Osinergmin
requiere solicitud formal y no se usa). Cuando llegue el SICOM, se migra al
pipeline ARDL/ECM completo.

---

## Estado: corre completo con data real (n = 8, FY2018–FY2025)

`Rscript run_all.R` termina con **código 0** y produce estimación, proyección e
informe. Insumos efectivamente usados (todos en `data/raw/`, registrados con
SHA256 en [`data/raw/SOURCES.md`](data/raw/SOURCES.md)):

| Insumo | Archivo | Rol |
|---|---|---|
| Energía distribuida y clientes de ELDU, 2018–2025 | `eldu_demanda_memorias.csv` | **variable dependiente** |
| VAB real de Ica a precios constantes, 2007–2025 (INEI) | `inei_vab_ica.xlsx` | **driver de ingreso** (regional, no proxy) |
| PBI nacional, var. % interanual (BCRP `PN01728AM`) | `bcrp_pbi_nacional_yoy.csv` | driver alternativo (robustez) |
| IPC Lima (BCRP `PN38705PM`) | `bcrp_ipc_lima.csv` | control, **no entra a la regresión** |
| Tipo de cambio venta (BCRP `PD04638PD`) | `bcrp_tc_venta.csv` | control, **no entra a la regresión** |

El IPC y el tipo de cambio quedan registrados pero no se usan como regresores: la
energía es una magnitud física y el VAB entra real, así que no hay nada que
deflactar, y con n = 8 agregarlos sería sobre-ajustar. Los índices ENSO quedaron
fuera de alcance por pedido.

### El hallazgo principal no es el número de η, es la fórmula

El crecimiento del volumen de ELDU se parte así (CAGR 2018–2025):

| Componente | CAGR |
|---|---|
| Clientes (conexiones nuevas) | **2.65%** |
| Energía por cliente | **1.52%** |
| **Total energía distribuida** | **4.17%** |
| _(driver)_ VAB real de Ica | _3.94%_ |

**Las conexiones explican ~64% del crecimiento.** Por eso el modelo pasó de una
elasticidad única a una **descomposición**: η se estima sobre el **consumo por
cliente** y el crecimiento de conexiones entra como supuesto explícito.

La regla original `Q(1+η·g)` no tiene término de conexiones, así que asume que el
volumen sólo crece si crece el ingreso. Comparado sobre el escenario base:

| Regla de proyección | CAGR implícito | GWh FY2035 |
|---|---|---|
| Observado 2018–2025 | **4.17%** | — |
| Dos términos (clientes + η por cliente) | **3.63%** | 1 580 |
| Una sola elasticidad, sin clientes | 0.96% | 1 217 |
| Supuesto DCF vigente (η≈0.85), sin clientes | 2.55% | 1 423 |

El 0.8/0.9 del DCF **acierta de casualidad**: es un número inflado que compensa
un término de conexiones que falta. Se parece al histórico por la razón
equivocada, y deja de funcionar en cuanto el ritmo de conexiones cambie — que es
justo lo que una valorización a 10 años necesita poder mover.

**Recomendación:** usar los dos términos, con η en el rango estimado aplicado al
consumo por cliente, y el ritmo de conexiones como supuesto del comité.

### Lo que esta data NO permite

- **El desagregado BT/MT/libres.** Las ventas por segmento existen sólo desde 2022
  (4 años). El objetivo original —reemplazar 0.8 BT y 0.9 MT por *dos*
  elasticidades estimadas— **no es alcanzable**: sólo se entrega una η agregada.
- **ADF, cointegración, ECM y validación out-of-sample.** Con n = 8 no hay grados
  de libertad; se omiten en vez de forzarse (ver la escalera más abajo).
- **Un punto creíble para η.** Se entrega como **rango**, porque η varía entre
  especificaciones razonables más que el umbral configurado.

### Si consigue más data

| Insumo | Dónde ponerlo | Qué habilita |
|---|---|---|
| Anuario MINEM (serie larga ~2000–2024) | `data/raw/minem_anuario_01.xlsx` | n≈20 → ADF, cointegración, ECM, out-of-sample |
| Memorias ELDU en PDF | `data/raw/pdf/*.pdf` | extracción con traza (script `04`) |
| Pesos de ingreso BT/MT/libres | `CFG$segment_weights` | reparto por segmento |
| Escenarios propios de PBI | `data/raw/escenarios.csv` (`escenario,year,g_pbi[,g_clientes]`) | reemplaza los defaults (hoy marcados como supuesto) |

Abrir el egreso de red a `estadisticas.bcrp.gob.pe`, `www.gob.pe`,
`www.inei.gob.pe` y `www.cpc.ncep.noaa.gov` hace que los scripts 01–04 bajen todo
solos; hoy esos hosts responden `403` por política de egreso del contenedor y la
data llegó cargada a mano.

---

## Regla dura anti-invención

El fallo de la corrida previa (uso de `data/demo/`, elasticidades irreales y
saltos de volumen de +87% en un año) está atacado por diseño, no por disciplina:

1. **No existe ninguna ruta de datos sintéticos** en el repositorio. No hay
   `data/demo/`, ni modo demo, ni fallback simulado. Si falta un insumo
   obligatorio, `05_build_panel.R` llama a `stop_missing()` y la corrida termina
   con **código de salida 2**.
2. **Cada archivo crudo queda registrado** en [`data/raw/SOURCES.md`](data/raw/SOURCES.md)
   con URL, fecha de descarga, tamaño y SHA256. Toda cifra del informe es
   trazable a un archivo de `data/raw/`.
3. **Nada se imputa en silencio.** `assert_no_silent_imputation()` aborta si
   aparece un `NA` en una columna crítica del panel.
4. **Validación de plausibilidad de la serie de energía** antes de estimar
   (`CFG$validate_energy`): rango de magnitud, mínimo de observaciones y
   **salto interanual máximo de 60%**. Una extracción mal alineada —el origen del
   +87%— se rechaza y detiene la corrida en lugar de propagarse.
5. **La extracción de PDF no se auto-ingiere.** `04` emite candidatos *con su
   línea literal de origen y su página* a
   `output/tables/memorias_extraccion_candidatos.csv` para revisión humana
   (`CFG$memorias$auto_ingest = FALSE`).
6. **Lo que es supuesto se rotula como supuesto** en el informe y en la hoja
   `supuestos` del Excel: escenarios por defecto, uso del PBI nacional como
   proxy, pesos por segmento.

---

## Uso

```bash
Rscript run_all.R            # corrida completa
Rscript tests/integration_smoke.R   # prueba del código (ver nota abajo)
```

Códigos de salida de `run_all.R`:

| Código | Significado |
|---|---|
| `0` | pipeline completo: estimación + proyección + informe con resultados |
| `2` | **bloqueado en datos**: faltan insumos obligatorios. Escribe `output/BLOCKERS.md` y un informe que documenta el bloqueo. No genera datos sintéticos. |
| `1` | error inesperado |

### Estructura

```
run_all.R                  orquestador
config/config.R            TODO lo configurable: fuentes, umbrales, supuestos
R/utils.R                  logging, descarga con reintentos, registro de fuentes
R/make_renv_lock.R         genera renv.lock desde la librería instalada
scripts/01_fetch_bcrp.R         SOLO descarga  -> data/raw/
scripts/02_fetch_noaa.R         SOLO descarga  -> data/raw/
scripts/03_fetch_minem_inei.R   SOLO descarga  -> data/raw/
scripts/04_extract_memorias.R   SOLO extracción -> data/raw/pdf_text/ + candidatos
scripts/04b_prepare_eldu_memorias.R  serie anual canónica; excluye periodos parciales
scripts/05_build_panel.R        panel anual; SE DETIENE si falta lo obligatorio
scripts/06_estimate.R           estimación
scripts/07_forecast.R           proyección
scripts/08_report.Rmd           informe (rinde con y sin resultados)
tests/integration_smoke.R  prueba de integración end-to-end
```

Salidas: `output/tables/elasticidad.csv`, `output/forecast_volumenes.xlsx`,
`output/informe_demanda_ELDU.html`, `output/tables/diagnosticos.csv`,
`data/raw/SOURCES.md`, `output/fetch_log.txt`, `output/sessionInfo.txt`,
`renv.lock`.

---

## Modelo: descomposición, no una elasticidad única

```
  Q = clientes x (energia por cliente)
  ln(Q/clientes) = a + eta*ln(VAB) + d*t     <- de aqui sale eta
  g_clientes                                  <- supuesto explicito
```

Las conexiones responden a política de expansión y demografía, no al PBI, así que
no se estiman contra él. Si no hay número de clientes, el pipeline cae a la
elasticidad sobre energía total y lo dice.

**El método reportado corresponde al n disponible**:

| Paso | Qué | Condición |
|---|---|---|
| 1 | descomposición del crecimiento (clientes vs por-cliente) | siempre |
| 2 | ADF sobre `ln(Q)`, `ln(VAB)`, `ln(Q/clientes)` | `n ≥ 12` |
| 3 | **OLS log-log** con y sin tendencia, EE **HAC/Newey-West** | siempre |
| 4 | **Diferencias**: `Δln(Q/cl) = c + η·Δln(VAB)`, HAC | siempre |
| 5 | Engle-Granger + **ECM** de una ecuación | `n ≥ 15` **y** cointegración |
| 6 | R², Durbin-Watson, Breusch-Godfrey, influencia leave-one-out | siempre |
| 7 | Out-of-sample: deja fuera los últimos 2 años, MAPE | `n ≥ 12` |
| 8 | robustez: volumen alternativo, exclusión del choque COVID, driver nacional | siempre |

Cuatro cosas que el pipeline reporta en vez de esconder:

- **Qué especificación es la principal, y por qué.** Si `n < 12`, la separación
  ingreso/tendencia en niveles es frágil, así que se reporta la de **diferencias**
  y los niveles quedan como corroboración. Si `VIF(ln_ingreso~t) > 20`, se prefiere
  la versión sin tendencia.
- **La constante de la ecuación en diferencias**, que es el crecimiento
  **autónomo** del volumen: la pieza que una regla `Q(1+η·g)` sin término de
  conexiones tira a la basura.
- **Regla de prudencia.** η se reporta como **rango** si el IC 95% es más ancho que
  `CFG$est$wide_ci_width`, si incluye cero, **o** si η varía entre especificaciones
  razonables más que `CFG$est$spec_spread_range`. Esto último es clave: a n chico
  la incertidumbre real es de **especificación**, no sólo de muestreo.
- **Que los IC son optimistas.** Los errores HAC son asintóticos y sub-cubren con
  n de un dígito; el informe lo dice explícitamente.

### Proyección

```
  Q_{t+1} = Q_t * (1 + g_clientes) * (1 + eta * g_ingreso)
```

Por escenario, hasta **FY2035**. Las bandas vienen del intervalo de η. Se calculan
además, para comparar, la regla de una sola elasticidad y la del supuesto DCF
vigente (`output/tables/comparacion_reglas.csv`).

Sostener el ritmo de conexiones hasta FY2035 es **el supuesto más fuerte de toda
la proyección** y mueve el resultado más que η. Se cambia en `CFG$clientes`:
`g_override` para fijar una tasa, o `taper_to` + `taper_years` para que converja
a una tasa menor. El reparto BT/MT/libres **sólo** se hace si se cargan pesos en
`CFG$segment_weights`: no se inventan.

---

## Reproducibilidad

- Semilla `20261007`; un único punto de entrada `run_all.R`; rutas vía `here::here()`.
- `output/sessionInfo.txt` con las versiones exactas.
- `renv.lock` generado por `R/make_renv_lock.R`.

**Nota honesta sobre `renv`:** este contenedor tampoco tiene salida a CRAN
(`cloud.r-project.org` da 403), así que `renv::init()` no puede resolver nada.
`renv.lock` se generó leyendo las versiones **realmente instaladas**; por eso sus
entradas no llevan `Hash` (renv los resuelve al restaurar). Los paquetes se
instalaron desde los repositorios de Ubuntu 24.04:

```bash
apt-get install -y r-base-core r-cran-tidyverse r-cran-httr r-cran-jsonlite \
  r-cran-rvest r-cran-readxl r-cran-pdftools r-cran-tseries r-cran-urca \
  r-cran-sandwich r-cran-lmtest r-cran-broom r-cran-knitr r-cran-rmarkdown \
  r-cran-openxlsx r-cran-writexl r-cran-here r-cran-renv r-cran-zoo pandoc
```

En una máquina con CRAN: `renv::restore()`.

### Sobre `tests/integration_smoke.R`

Ese test construye una serie **artificial con una elasticidad conocida** para
verificar que el código corre y que la estimación recupera el parámetro que se le
metió — es la única forma de probar la cadena sin acceso a las fuentes reales.
Esa serie vive en un directorio **temporal**, nunca en `data/`, nunca entra al
informe, y **el pipeline no tiene ninguna ruta que la use**. Es una prueba de
código, no un modo demo.

El test cubre tres casos —n=20, n=9, y n=8 **con** número de clientes— y verifica,
además de que η se recupere y que las bandas encierren al central:

- que **el método reportado corresponda al n**: con n=9 el ADF, el ECM y la
  validación out-of-sample se omiten en lugar de forzarse;
- que con clientes η se estime sobre el **consumo por cliente** y la energía total
  quede como comparación, y sin clientes pase a ser el bloque principal;
- que la descomposición recupere el crecimiento de conexiones del fixture y que
  clientes + por-cliente sume el crecimiento total;
- que la regla de dos términos proyecte por encima de la de una sola elasticidad.

La cobertura del IC 95% se exige **sólo** en el caso de muestra larga: los errores
HAC sub-cubren con n de un dígito, y exigirlo ahí sería pedirle al estimador algo
que la teoría no promete — es la misma razón por la que el pipeline reporta rango.
