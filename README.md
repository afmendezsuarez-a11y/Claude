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

## ⚠️ Estado de esta corrida: BLOQUEADO EN LA ETAPA DE DATOS

El código está completo y probado, pero **en este contenedor no se obtuvo ni una
sola serie**: la política de egreso de red rechaza con `403` el `CONNECT` a
**todos** los hosts de las fuentes, y tampoco se proveyeron los PDFs ni
`escenarios.csv`.

| Host | Para qué | Estado |
|---|---|---|
| `estadisticas.bcrp.gob.pe` | PBI real, IPC, tipo de cambio | ⛔ 403 |
| `www.gob.pe` / `cdn.www.gob.pe` | Anuario MINEM, Osinergmin | ⛔ 403 |
| `www.inei.gob.pe` | PBI departamental de Ica | ⛔ 403 |
| `www.cpc.ncep.noaa.gov` | ONI / Niño 3.4 (opcional) | ⛔ 403 |
| `data/raw/pdf/*.pdf` | Memorias Anuales ELDU | ausente |
| `data/raw/escenarios.csv` | Escenarios de PBI | ausente |

Por la **regla dura anti-invención**, el pipeline se detuvo y lo reportó en vez
de rellenar: ver [`output/BLOCKERS.md`](output/BLOCKERS.md) (qué falta y las dos
vías para desbloquearlo) y [`output/fetch_log.txt`](output/fetch_log.txt) (cada
URL intentada, con su error).

**Consecuencia para el comité:** el supuesto vigente (η = 0.8 / 0.9) **no fue
validado ni reemplazado**. Sigue siendo *a dedo* y debe tratarse como tal. No hay
en este repositorio ninguna cifra de elasticidad ni de volúmenes, porque
producirla sin data sería inventarla.

### Cómo desbloquear

**A) Abrir el egreso de red** a los cuatro hosts de arriba y correr
`Rscript run_all.R`. Los scripts 01–04 bajan todo solos.

**B) Cargar los archivos a mano** en `data/raw/` — basta con energía + ingreso:

| Insumo | Dónde ponerlo | Obligatorio |
|---|---|---|
| Energía anual ELDU (GWh) | `data/raw/minem_anuario_01.xlsx`, o `data/raw/pdf/*.pdf`, o `data/raw/eldu_energia_anual.csv` (`year,energia_gwh[,clientes]`) | **sí** |
| Ingreso | `data/raw/inei_pbi_departamental_01.xlsx` (Ica) o PBI nacional del BCRP (proxy, se marca) | **sí** |
| IPC, tipo de cambio | API BCRP | no |
| ONI / Niño 3.4 | `data/raw/noaa_oni.ascii.txt` | no |
| Escenarios de PBI | `data/raw/escenarios.csv` (`escenario,year,g_pbi`) — ver `config/escenarios.csv.ejemplo` | no (hay defaults, marcados como supuesto) |

También se puede pegar una URL directa en `CFG$minem$direct_urls`,
`CFG$inei$direct_urls` u `CFG$osinergmin$direct_urls` (`config/config.R`).

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

## Modelo: el mínimo viable, no un ARDL forzado

Con data anual el n es chico (~8 si sólo hay Memorias, ~20 si el Anuario MINEM da
serie larga). **El método reportado corresponde al n disponible**:

| Paso | Qué | Condición |
|---|---|---|
| 1 | logs, deflactado, gráficos | siempre |
| 2 | ADF sobre `ln(Q)` y `ln(PBI)` | `n ≥ 12` |
| 3 | **OLS log-log**: `ln(Q) = α + η·ln(PBI) + δ·t`, EE **HAC/Newey-West** | siempre |
| 4 | **Diferencias**: `Δln(Q) = c + η_CP·Δln(PBI)`, HAC | siempre |
| 5 | Engle-Granger + **ECM** de una ecuación | `n ≥ 15` **y** cointegración |
| 6 | R², Durbin-Watson, Breusch-Godfrey, influencia leave-one-out | siempre |
| 7 | Out-of-sample: deja fuera los últimos 2 años, reporta MAPE | `n ≥ 12` |

Dos cosas que el pipeline reporta en vez de esconder:

- **Colinealidad ln(PBI) ↔ tendencia.** En una serie corta y creciente, el PBI y
  el tiempo son casi la misma variable. Se calcula `cor` y `VIF`; si `VIF > 20`
  la especificación preferida pasa a ser **sin tendencia** y el informe lo dice.
- **Regla de prudencia.** Si el IC 95% de η es más ancho que
  `CFG$est$wide_ci_width` (1.0) o incluye el cero, η se reporta como **rango**,
  no como punto, con la recomendación de mantener el supuesto del DCF dentro de
  ese rango. No se fuerza una precisión que la data no da.

### Proyección

`Q_{t+1} = Q_t · (1 + η · g_PBI_{t+1})`, por escenario, hasta **FY2035**. Las
bandas vienen del **IC 95% de η**, no de un supuesto. El reparto BT/MT/libres
**sólo** se hace si se cargan pesos en `CFG$segment_weights`: no se inventan.

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

El test cubre dos tamaños de muestra (n=20 y n=9) y verifica, además de que η se
recupere y que las bandas encierren al central, que **el método reportado
corresponda al n**: con n=9 el ADF, el ECM y la validación out-of-sample se
omiten en lugar de forzarse.
