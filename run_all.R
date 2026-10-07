#!/usr/bin/env Rscript
## ============================================================================
## run_all.R — corrida completa del estudio de demanda de Electro Dunas.
##
##   Rscript run_all.R
##
## Códigos de salida:
##   0 = pipeline completo (estimación + proyección + informe con resultados)
##   2 = BLOQUEADO en la etapa de datos: faltan insumos obligatorios. Se escribe
##       output/BLOCKERS.md y un informe que DOCUMENTA el bloqueo. Por diseño,
##       NO se generan datos sintéticos para poder "terminar".
##   1 = error inesperado.
## ============================================================================

options(stringsAsFactors = FALSE, warn = 1, encoding = "UTF-8")

## El informe y los logs están en castellano. Si el sistema arranca en locale C,
## los acentos se corrompen y R ni siquiera parsea identificadores acentuados,
## así que se intenta fijar un locale UTF-8 antes de cualquier otra cosa.
if (!isTRUE(l10n_info()[["UTF-8"]])) {
  for (loc in c("C.UTF-8", "C.utf8", "en_US.UTF-8", "es_PE.UTF-8")) {
    if (suppressWarnings(Sys.setlocale("LC_ALL", loc)) != "") break
  }
}

suppressPackageStartupMessages({ library(here); library(rmarkdown) })

source(here::here("config/config.R"))
source(here::here("R/utils.R"))

set.seed(CFG$seed)

for (d in c(CFG$paths$raw, CFG$paths$processed, CFG$paths$output,
            CFG$paths$tables, CFG$paths$figures,
            file.path(CFG$memorias$dir))) {
  dir.create(here::here(d), recursive = TRUE, showWarnings = FALSE)
}

init_log()
render_sources_md()   # SOURCES.md existe siempre, aunque quede en estado vacío
log_event("run_all", "INFO", sprintf("semilla = %d | R %s", CFG$seed, getRversion()))

## ---- Etapas de adquisición: se registran fallas y se continúa -------------
run_stage <- function(file, label, fatal = FALSE) {
  log_event("run_all", "INFO", sprintf(">>> %s (%s)", label, file))
  res <- tryCatch({ source(here::here(file), local = new.env()); TRUE },
                  error = function(e) e)
  if (inherits(res, "error")) {
    log_event("run_all", if (fatal) "BLOCKED" else "FAIL",
              sprintf("%s falló: %s", label, conditionMessage(res)))
    if (fatal) return(res)
    return(FALSE)
  }
  TRUE
}

run_stage("scripts/01_fetch_bcrp.R",      "01 — BCRP")
run_stage("scripts/02_fetch_noaa.R",      "02 — NOAA CPC")
run_stage("scripts/03_fetch_minem_inei.R","03 — MINEM / Osinergmin / INEI")
run_stage("scripts/04_extract_memorias.R","04 — Memorias ELDU (PDF)")

## ---- Barrera: 05 se detiene si falta un insumo obligatorio ----------------
write_blockers <- function(err_msg) {
  raw <- here::here(CFG$paths$raw)
  present <- list.files(raw, recursive = TRUE)
  lines <- c(
    "# BLOCKERS — por qué la corrida no pudo estimar",
    "",
    sprintf("Generado: %s UTC", format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC")),
    "",
    "## Mensaje del pipeline",
    "", "```", strsplit(err_msg, "\n", fixed = TRUE)[[1]], "```", "",
    "## Qué hay hoy en `data/raw/`",
    "",
    if (length(present)) paste0("- `", present, "`") else "- _(vacío)_",
    "",
    "## Las dos vías para desbloquear",
    "",
    "### A) Abrir el egreso de red y re-correr",
    "",
    "El contenedor de esta sesión bloquea por política de egreso los hosts de las",
    "fuentes. Habilitarlos y re-correr `Rscript run_all.R` hace que 01–04 bajen todo:",
    "",
    "| Host | Para qué |",
    "|---|---|",
    "| `estadisticas.bcrp.gob.pe` | PBI real, IPC, tipo de cambio (API pública BCRP) |",
    "| `www.gob.pe` / `cdn.www.gob.pe` | Anuario Estadístico de Electricidad (MINEM), Osinergmin |",
    "| `www.inei.gob.pe` | PBI departamental de Ica |",
    "| `www.cpc.ncep.noaa.gov` | ONI / Niño 3.4 (opcional) |",
    "",
    "### B) Cargar los archivos a mano",
    "",
    sprintf("1. **Energía de ELDU (obligatoria).** Cualquiera de estas sirve:"),
    "   - el Excel del Anuario MINEM en `data/raw/minem_anuario_01.xlsx`, o",
    "   - las Memorias Anuales ELDU en `data/raw/pdf/` (luego revisar",
    "     `output/tables/memorias_extraccion_candidatos.csv` contra el PDF), o",
    sprintf("   - la serie ya verificada en `%s`, con columnas `year,energia_gwh[,clientes]`.",
            CFG$eldu$manual_csv),
    "2. **Ingreso (obligatorio).** `data/raw/inei_pbi_departamental_01.xlsx` (Ica) o,",
    "   como proxy marcado, el PBI nacional vía la API del BCRP.",
    sprintf("3. **Escenarios (opcional).** `%s` con columnas `escenario,year,g_pbi`.", CFG$escenarios$path),
    "   Si falta, se usan los defaults y se marcan como SUPUESTO.",
    "",
    "## Lo que NO se hizo",
    "",
    "No se generó ninguna serie sintética, de demo, simulada ni imputada para que la",
    "corrida \"pasara\". Esa es la causa raíz del resultado irreal de la corrida previa",
    "(elasticidades y saltos de volumen como +87% en un año) y está deshabilitada por",
    "diseño: no existe ninguna ruta de datos falsos en este repositorio.",
    ""
  )
  writeLines(lines, here::here(CFG$paths$blockers))
  log_event("run_all", "INFO", sprintf("escrito %s", CFG$paths$blockers))
}

render_report <- function() {
  out <- here::here(CFG$paths$output, "informe_demanda_ELDU.html")
  ok <- tryCatch({
    rmarkdown::render(here::here("scripts/08_report.Rmd"),
                      output_file = out, quiet = TRUE,
                      envir = new.env())
    TRUE
  }, error = function(e) { log_event("08_report", "FAIL", conditionMessage(e)); FALSE })
  if (ok) log_event("08_report", "OK", "escrito output/informe_demanda_ELDU.html")
  ok
}

write_session_info <- function() {
  f <- here::here(CFG$paths$output, "sessionInfo.txt")
  writeLines(c(capture.output(utils::sessionInfo()),
               "", "## Semilla", as.character(CFG$seed)), f)
  log_event("run_all", "OK", "escrito output/sessionInfo.txt")
}

panel_res <- run_stage("scripts/05_build_panel.R", "05 — panel anual", fatal = TRUE)

if (inherits(panel_res, "error")) {
  write_blockers(conditionMessage(panel_res))
  render_sources_md()
  render_report()
  write_session_info()
  log_event("run_all", "BLOCKED",
            "corrida detenida en la etapa de datos — ver output/BLOCKERS.md. Sin datos sintéticos.")
  message("\n", conditionMessage(panel_res))
  message("Ver output/BLOCKERS.md y output/fetch_log.txt\n")
  quit(status = 2L)
}

ok6 <- run_stage("scripts/06_estimate.R", "06 — estimación", fatal = TRUE)
if (inherits(ok6, "error")) { write_session_info(); quit(status = 1L) }

ok7 <- run_stage("scripts/07_forecast.R", "07 — proyección", fatal = TRUE)
if (inherits(ok7, "error")) { write_session_info(); quit(status = 1L) }

render_report()
write_session_info()
render_sources_md()

log_event("run_all", "OK", "corrida completa")
cat("\n== Corrida completa ==\n",
    "  output/informe_demanda_ELDU.html\n",
    "  output/tables/elasticidad.csv\n",
    "  output/forecast_volumenes.xlsx\n",
    "  data/raw/SOURCES.md\n",
    "  output/fetch_log.txt\n", sep = "")
quit(status = 0L)
