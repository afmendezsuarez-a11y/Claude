# BLOCKERS — por qué la corrida no pudo estimar

Generado: 2026-10-07 06:58:59 UTC

## Mensaje del pipeline

```

=========================================================================
  PIPELINE DETENIDO — falta un insumo OBLIGATORIO
=========================================================================
  Falta        : serie de ingreso (PBI de Ica del INEI, o PBI nacional del BCRP como proxy)
  Se buscó en  : data/raw/inei_pbi_departamental*.xlsx
                 data/raw/bcrp_pbi_real.json
  Cómo proveerlo:
    - abrir el egreso de red a estadisticas.bcrp.gob.pe y www.inei.gob.pe, y re-correr `Rscript run_all.R`
    - o descargar a mano el PBI departamental del INEI a data/raw/inei_pbi_departamental_01.xlsx
    - o pegar una URL directa en CFG$inei$direct_urls / CFG$bcrp (config/config.R)
-------------------------------------------------------------------------
  NO se generan datos sintéticos para continuar. Ver output/fetch_log.txt
=========================================================================
```

## Qué hay hoy en `data/raw/`

- `SOURCES.md`

## Las dos vías para desbloquear

### A) Abrir el egreso de red y re-correr

El contenedor de esta sesión bloquea por política de egreso los hosts de las
fuentes. Habilitarlos y re-correr `Rscript run_all.R` hace que 01–04 bajen todo:

| Host | Para qué |
|---|---|
| `estadisticas.bcrp.gob.pe` | PBI real, IPC, tipo de cambio (API pública BCRP) |
| `www.gob.pe` / `cdn.www.gob.pe` | Anuario Estadístico de Electricidad (MINEM), Osinergmin |
| `www.inei.gob.pe` | PBI departamental de Ica |
| `www.cpc.ncep.noaa.gov` | ONI / Niño 3.4 (opcional) |

### B) Cargar los archivos a mano

1. **Energía de ELDU (obligatoria).** Cualquiera de estas sirve:
   - el Excel del Anuario MINEM en `data/raw/minem_anuario_01.xlsx`, o
   - las Memorias Anuales ELDU en `data/raw/pdf/` (luego revisar
     `output/tables/memorias_extraccion_candidatos.csv` contra el PDF), o
   - la serie ya verificada en `data/raw/eldu_energia_anual.csv`, con columnas `year,energia_gwh[,clientes]`.
2. **Ingreso (obligatorio).** `data/raw/inei_pbi_departamental_01.xlsx` (Ica) o,
   como proxy marcado, el PBI nacional vía la API del BCRP.
3. **Escenarios (opcional).** `data/raw/escenarios.csv` con columnas `escenario,year,g_pbi`.
   Si falta, se usan los defaults y se marcan como SUPUESTO.

## Lo que NO se hizo

No se generó ninguna serie sintética, de demo, simulada ni imputada para que la
corrida "pasara". Esa es la causa raíz del resultado irreal de la corrida previa
(elasticidades y saltos de volumen como +87% en un año) y está deshabilitada por
diseño: no existe ninguna ruta de datos falsos en este repositorio.

