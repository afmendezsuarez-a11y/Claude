# `data/raw/` — insumos del pipeline

El pipeline **no descarga nada** y **no simula datos**. Todas las series las
provee el usuario aquí. Si falta una serie obligatoria, el pipeline se detiene
con un mensaje que dice exactamente qué falta.

## Archivos que hay que colocar

### 1. `eldu_demanda.xlsx` (o `.csv`) — obligatorio

Una fila por mes, clave `fecha` en formato `YYYY-MM-01`, sin huecos.
Esquema exacto en `PLANTILLA_eldu_demanda.csv`.

| Columna | Descripción | Unidad | Oblig. | Fuente típica |
|---|---|---|---|---|
| `fecha` | mes (primer día) | date | sí | — |
| `mwh_bt` | ventas de energía BT regulado | MWh | sí | SICOM-Osinergmin / Memoria |
| `mwh_mt` | ventas de energía MT regulado | MWh | sí | SICOM / Memoria |
| `mwh_libres` | ventas a clientes libres | MWh | sí | SICOM / Memoria |
| `cli_bt` | n.º de suministros BT | # | sí | SICOM / Memoria |
| `cli_mt` | n.º de suministros MT | # | sí | SICOM / Memoria |
| `cli_libres` | n.º de clientes libres | # | sí | SICOM / Memoria |
| `pbi_ica` | PBI/VAB real de Ica | índice o S/ const. | sí | INEI / BCRP |
| `tarifa_bt` | tarifa media BT (nominal) | S/·kWh | sí | pliegos Osinergmin |
| `tarifa_mt` | tarifa media MT (nominal) | S/·kWh | sí | pliegos Osinergmin |
| `tarifa_libres` | precio medio libres (nominal) | S/·kWh | sí | contratos / pliegos |
| `ipc` | IPC Perú (deflactor, base=100) | índice | sí | INEI / BCRP |
| `vab_agro_ica` | VAB agropecuario Ica | índice o S/ const. | no | INEI |
| `vab_manuf_ica` | VAB manufactura Ica | índice o S/ const. | no | INEI |
| `nino34` | anomalía ENSO Niño 3.4 | °C | no | NOAA / ENFEN |
| `max_dem_kw` | máxima demanda ELDU | kW | no | SICOM / COES |

Notas:

- **Frecuencia de `pbi_ica`.** Si solo existe en frecuencia trimestral o anual,
  deja en blanco los meses sin dato: `01_load_clean.R` los interpola con el
  método declarado en `config.yml` (`spline` por defecto, `denton`
  alternativo) **solo dentro del rango observado** (no extrapola) y marca esas
  observaciones con la bandera `pbi_interp`.
- **Ceros al inicio.** Un segmento puede tener `0` en energía/clientes antes de
  existir; esos meses quedan fuera de su muestra de estimación y se reportan en
  `output/00_data_check.html`. Huecos *internos* sí detienen el pipeline.
- `nino34` y los VAB desagregados son opcionales: si no están, ENSO queda fuera
  de los modelos — **no se imputa ningún valor**.

### 2. `escenarios.csv` — obligatorio para `07_forecast.R`

Supuestos de proyección (crecimientos **reales anuales**, en fracción: `0.035`
= 3,5 %). Esquema en `PLANTILLA_escenarios.csv`. Debe cubrir cada año desde el
primero proyectado hasta el año de `forecast$fin` en `config.yml`.

| Columna | Descripción |
|---|---|
| `escenario` | etiqueta (`base`, `optimista`, `pesimista`, …) |
| `anio` | año calendario |
| `g_pbi_ica` | crecimiento real anual de la actividad de Ica |
| `g_tarifa_real_bt` | crecimiento anual de la **tarifa real** BT |
| `g_tarifa_real_mt` | crecimiento anual de la **tarifa real** MT |
| `g_tarifa_real_libres` | crecimiento anual del **precio real** libres |
| `nino34` | anomalía Niño 3.4 asumida (°C) para ese año |

El crecimiento anual se reparte mensualmente de forma compuesta:
`(1 + g)^(1/12) − 1`, aplicado al último nivel observado.
