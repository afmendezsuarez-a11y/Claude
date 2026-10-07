# Electro Dunas (ELDU) — Modelo de demanda eléctrica

Estimación de la demanda de energía de **Electro Dunas S.A.A.** por segmento
(baja tensión regulado, media tensión regulado, clientes libres) con un enfoque
**ARDL / modelo de corrección de errores (ECM)**, para obtener:

- **elasticidades de largo plazo** de ingreso (η) y precio (ρ) con intervalos de
  confianza,
- una **proyección mensual y anual de volúmenes** por escenario que alimenta un
  modelo de valorización DCF,
- un contraste explícito entre esas elasticidades y los **supuestos “a dedo”**
  del modelo de valorización.

Todo es reproducible en R con un único comando.

---

## El modelo

La energía de cada segmento se descompone en clientes por consumo unitario:

```
Q[k,t] = N[k,t] · q[k,t]            q[k,t] = MWh[k,t] / N[k,t]
```

**Clientes**

```
Δ ln N[k,t] = α[k] + β[k] · Δ ln ACT[t] + ε[t]
```

**Consumo unitario** (ECM condicional, reparametrización UECM de un ARDL)

```
Δ ln q[k,t] = γ[k] + Σ_j δ[k,j] Δ ln Y[t-j] + θ[k] Δ ln p̃[k,t] + φ[k] ENSO[t]
              − λ[k] ( ln q[k,t-1] − μ[k] − η[k] ln Y[t-1] − ρ[k] ln p̃[k,t-1] ) + u[t]
```

donde `Y` es la actividad regional de Ica, `p̃` la tarifa real, `η` la
elasticidad-ingreso de largo plazo, `ρ` la elasticidad-precio de largo plazo y
`λ` la velocidad de ajuste.

En la forma estimada los coeficientes de los niveles rezagados son `π_y` y
`π_j`, con `λ = −π_y` y `η_j = −π_j/π_y`. Las elasticidades y sus intervalos se
obtienen por **delta-method** sobre ese cociente, con matriz de covarianzas
**HAC (Newey-West)**.

---

## Instalación

Requiere **R ≥ 4.3** y **pandoc** (para el informe HTML).

```bash
R -e 'if (!requireNamespace("renv", quietly=TRUE)) install.packages("renv"); renv::restore(prompt = FALSE)'
# o: make setup
```

`renv.lock` fija las dependencias (incluido `ARDL`, que provee el bounds
test de Pesaran-Shin-Smith). `run_all.R` verifica las dependencias antes de
empezar y, si falta alguna, se detiene indicando qué instalar.

En Debian/Ubuntu la mayoría de los paquetes están también como binarios del
sistema, que instalan mucho más rápido que compilar desde fuente:

```bash
sudo apt-get install -y r-base-core pandoc r-cran-tidyverse r-cran-urca \
  r-cran-tseries r-cran-lmtest r-cran-sandwich r-cran-strucchange r-cran-dynlm \
  r-cran-readxl r-cran-writexl r-cran-here r-cran-zoo \
  r-cran-rmarkdown r-cran-kableextra r-cran-broom r-cran-yaml r-cran-gridextra \
  r-cran-msm
R -e 'install.packages(c("ARDL","tempdisagg"))'
```

---

## Datos de entrada

El pipeline **no descarga nada y no simula datos**. Las series las provee el
usuario en `data/raw/`:

| Archivo | Contenido |
|---|---|
| `data/raw/eldu_demanda.xlsx` (o `.csv`) | panel mensual de energía, clientes, tarifas, actividad, IPC, ENSO |
| `data/raw/escenarios.csv` | supuestos de proyección por escenario y año |

El esquema completo, columna por columna, con unidades, fuentes y qué es
obligatorio está en **[`data/raw/LEEME.md`](data/raw/LEEME.md)**. Las plantillas
vacías son `data/raw/PLANTILLA_eldu_demanda.csv` y
`data/raw/PLANTILLA_escenarios.csv`.

Si falta una serie obligatoria el pipeline **se detiene** con un mensaje que
dice qué falta y dónde colocarlo. Nunca imputa supuestos en silencio.

---

## Uso

```bash
Rscript run_all.R                 # pipeline completo (pasos 01 a 08)
Rscript run_all.R 05 06 07        # solo algunos pasos
make all                          # equivalente a Rscript run_all.R
make clean                        # borra output/ y data/processed/
```

Para verificar que el pipeline corre de punta a punta **antes** de tener los
insumos reales hay un generador de datos **sintéticos** (claramente marcados,
escribe en `data/demo/`, nunca en `data/raw/`):

```bash
make demo
# equivale a:
#   Rscript R/99_make_demo_data.R
#   ELDU_DATA_DIR=data/demo Rscript run_all.R
```

Los datos sintéticos se generan desde un DGP con elasticidades conocidas
(`data/demo/PARAMETROS_VERDADEROS.csv`), así que la corrida también verifica que
el estimador recupera los parámetros verdaderos.

La variable de entorno `ELDU_DATA_DIR` permite apuntar a otro directorio de
insumos sin tocar `config.yml`.

---

## Pipeline

| Paso | Script | Qué hace |
|---|---|---|
| 01 | `R/01_load_clean.R` | Valida el contrato de datos (esquema, continuidad mensual, positividad), deflacta tarifas, construye `q_k` y los logaritmos, interpola la actividad si viene en baja frecuencia, crea las 11 dummies estacionales y la dummy COVID |
| 02 | `R/02_eda.R` | Descriptivos, series en nivel y log, estacionalidad, correlaciones en diferencias |
| 03 | `R/03_unit_roots.R` | ADF (`urca::ur.df`, con y sin tendencia, rezagos por AIC) y KPSS; veredicto I(0)/I(1) |
| 04 | `R/04_cointegration.R` | Engle-Granger (residuo + ADF con valores críticos de MacKinnon) y Johansen (traza y máx-eigen, vector cointegrante normalizado) |
| 05 | `R/05_ardl_ecm.R` | Selección de órdenes por AIC/BIC sobre muestra común, bounds test PSS, estimación del UECM, elasticidades de largo plazo por delta-method con HAC, modelo de clientes (ECM y en diferencias), relevancia de ENSO, actividad alternativa |
| 06 | `R/06_diagnostics.R` | Breusch-Godfrey, Breusch-Pagan, White, Jarque-Bera, Ramsey RESET, CUSUM y CUSUM² |
| 07 | `R/07_forecast.R` | Proyección recursiva mensual por escenario, bandas por bootstrap, backtest pseudo-fuera-de-muestra, agregación anual, contraste contra los supuestos del DCF |
| 08 | `R/08_report.Rmd` | Informe HTML; **toda cifra se lee de los CSV generados**, ninguna está escrita a mano |

---

## Entregables

```
output/
├── informe_demanda_ELDU.html          informe reproducible (autocontenido)
├── forecast_volumenes.xlsx            9 hojas: mensual, anual, histórico,
│                                      escenarios, metodología, diagnóstico,
│                                      consistencia, backtest, supuestos
├── 00_data_check.html                 reporte de validación del insumo
├── sessionInfo.txt                    entorno de ejecución
├── tables/
│   ├── elasticidades.csv              η, ρ, λ con IC 95%, EE HAC, R², n
│   ├── elasticidades_resumen.csv      una fila por modelo
│   ├── unit_roots.csv
│   ├── cointegration.csv              (+ engle_granger, johansen_beta, johansen_stats)
│   ├── bounds_test.csv
│   ├── diagnostics.csv
│   ├── backtest.csv
│   ├── supuestos_vs_estimado.csv
│   ├── forecast_anual.csv / forecast_mensual.csv / forecast_consistencia.csv
│   └── …
└── figs/                              series, ajuste, CUSUM, forecast con bandas
```

---

## Reproducibilidad

- **Un solo punto de entrada:** `Rscript run_all.R` regenera todo `output/`
  desde cero. Cada paso corre en su propio entorno; ninguno hereda estado de
  otro.
- **Semilla fija** (`config.yml → project.seed`, por defecto `20261007`) al
  inicio de cada script con componente aleatorio.
- **Rutas relativas** siempre, vía `here::here()`.
- **Sin efectos de red** durante la estimación: todo corre offline desde
  `data/raw/`.
- **Dependencias fijadas** en `renv.lock`; el entorno de la última corrida
  queda en `output/sessionInfo.txt`.
- **Parámetros en `config.yml`**, no en el código: segmentos, órdenes máximos
  del ARDL, criterio de selección, caso del bounds test, ventana COVID,
  horizonte, réplicas bootstrap y los supuestos del DCF a contrastar.

---

## Decisiones metodológicas

- **Órdenes del ARDL.** La selección por AIC/BIC se hace sobre la **muestra
  común** del modelo con órdenes máximos, para que los criterios sean
  comparables; el modelo elegido se re-estima luego sobre su muestra completa.
  Ambos tamaños se reportan.
- **Inferencia.** Elasticidades e intervalos con HAC Newey-West. El **bounds
  test** se reporta con la matriz de covarianzas convencional, que es la que usa
  la derivación de PSS (2001).
- **Elasticidades de largo plazo.** Delta-method sobre `−π_x/π_y` a partir del
  UECM, que es exactamente la parametrización del ECM planteado. Se reporta
  además el contraste contra los multiplicadores del paquete `ARDL`
  (`output/tables/control_multiplicadores_ARDL_vs_delta.csv`).
- **Interpolación de la actividad.** Solo dentro del rango observado, nunca
  extrapolando, con bandera `pbi_interp` y el método documentado
  (`spline` o `denton`).
- **Clientes.** Regla determinística: se proyecta con el ECM solo si `λ_N > 0` y
  es significativo al 10 %; en caso contrario con el modelo en diferencias. Lo
  usado en cada caso queda en la hoja `diagnostico_proyeccion`.
- **Estabilidad de la recursión.** Si `λ` no cae en el intervalo configurado
  `(0, 2)` la recursión del ECM es explosiva: se usa la solución de largo plazo
  estática y se marca el método. Las réplicas bootstrap con `λ*` fuera de ese
  rango se descartan y se reporta cuántas.
- **Contrafactual de supuestos.** Para imponer `η = η₀` se fija
  `π_x = −η₀·π_y` **y se reajusta la constante** de modo que el equilibrio de
  largo plazo en el último mes observado no cambie. Así la diferencia de
  volúmenes mide solo la distinta respuesta al crecimiento de la actividad, no
  un salto de nivel.

## Limitaciones conocidas

- **Clientes libres:** su demanda depende de contratos bilaterales y de la
  migración entre mercados, no solo de la actividad. Las bandas reportadas
  subestiman su incertidumbre.
- **Escenarios deterministas:** las bandas reflejan incertidumbre de estimación
  y de los choques, no de los supuestos macro. El rango entre escenarios es la
  medida de ese riesgo.
- **Réplicas de `q` y `N` independientes:** si los errores de consumo unitario y
  de clientes estuvieran correlacionados, las bandas de `Q` estarían mal
  calibradas.
- **Valores críticos de Engle-Granger** (`data/reference/eg_mackinnon_cv.csv`)
  son asintóticos; con muestras cortas son conservadores. Los del bounds test
  vienen del paquete `ARDL`, réplica verificada de PSS (2001).
