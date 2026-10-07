#!/usr/bin/env Rscript
# ============================================================================
# run_all.R — Punto de entrada UNICO del pipeline ELDU
#
#   Rscript run_all.R                      # corre todo con data/raw/
#   Rscript run_all.R 03 04 05             # corre solo esos pasos
#   ELDU_DATA_DIR=data/demo Rscript run_all.R   # corre con otro set de insumos
#
# Regenera por completo output/ desde data/raw/.
# ============================================================================

t0 <- Sys.time()
options(warn = 1)

if (!requireNamespace("here", quietly = TRUE)) {
  stop("Falta el paquete 'here'. Ver README.md (seccion Instalacion).", call. = FALSE)
}
ROOT <- here::here()
setwd(ROOT)

# ---------------------------------------------------------------------------
# Chequeo de dependencias ANTES de empezar
# ---------------------------------------------------------------------------
PKGS <- c("yaml", "dplyr", "tidyr", "readr", "purrr", "stringr", "tibble",
          "ggplot2", "lubridate", "readxl", "writexl", "zoo", "tempdisagg",
          "urca", "tseries", "ARDL", "dynlm", "lmtest", "sandwich",
          "strucchange", "broom", "knitr", "kableExtra", "rmarkdown", "here")
falta <- PKGS[!vapply(PKGS, requireNamespace, logical(1), quietly = TRUE)]
if (length(falta) > 0) {
  cat("\n", strrep("=", 76), "\n",
      "FALTAN PAQUETES R (", length(falta), "): ",
      paste(falta, collapse = ", "), "\n", strrep("=", 76), "\n\n",
      "QUE HACER:\n",
      "  R -e 'renv::restore()'      # instala las versiones de renv.lock\n",
      "  # o bien, sin renv:\n",
      "  R -e 'install.packages(c(",
      paste(paste0('"', falta, '"'), collapse = ", "),
      "))'\n\n", sep = "")
  quit(status = 1)
}

# ---------------------------------------------------------------------------
# Pasos
# ---------------------------------------------------------------------------
PASOS <- tibble::tribble(
  ~id,   ~script,               ~descripcion,
  "01",  "01_load_clean.R",     "Carga, validacion y construccion del panel",
  "02",  "02_eda.R",            "Analisis exploratorio",
  "03",  "03_unit_roots.R",     "Raices unitarias (ADF / KPSS)",
  "04",  "04_cointegration.R",  "Cointegracion (Engle-Granger / Johansen)",
  "05",  "05_ardl_ecm.R",       "ARDL / ECM y elasticidades de largo plazo",
  "06",  "06_diagnostics.R",    "Diagnosticos y estabilidad (CUSUM)",
  "07",  "07_forecast.R",       "Proyeccion de volumenes por escenario",
  "08",  "08_report.Rmd",       "Informe reproducible"
)

args <- commandArgs(trailingOnly = TRUE)
sel <- if (length(args) == 0) PASOS$id else args
desconocidos <- setdiff(sel, PASOS$id)
if (length(desconocidos) > 0) {
  stop(sprintf("Paso(s) desconocido(s): %s. Validos: %s",
               paste(desconocidos, collapse = ", "),
               paste(PASOS$id, collapse = ", ")), call. = FALSE)
}
PASOS <- PASOS[PASOS$id %in% sel, ]

cfg_file <- file.path(ROOT, "config.yml")
cfg <- yaml::yaml.load(paste(readLines(cfg_file, encoding = "UTF-8", warn = FALSE),
                             collapse = "\n"))
out_dir <- file.path(ROOT, cfg$paths$output_dir)

banner <- function(txt) {
  cat("\n", strrep("-", 76), "\n", txt, "\n", strrep("-", 76), "\n", sep = "")
}

cat(strrep("=", 76), "\n",
    "ELDU — pipeline de estimacion de demanda electrica\n",
    "inicio: ", format(t0, "%Y-%m-%d %H:%M:%S"), "\n",
    "datos : ", Sys.getenv("ELDU_DATA_DIR", unset = cfg$paths$data_dir), "\n",
    "pasos : ", paste(PASOS$id, collapse = " "), "\n",
    strrep("=", 76), "\n", sep = "")

tiempos <- list()
for (i in seq_len(nrow(PASOS))) {
  p <- PASOS[i, ]
  banner(sprintf("[%s/%s] %s — %s", i, nrow(PASOS), p$id, p$descripcion))
  ti <- Sys.time()
  if (grepl("\\.Rmd$", p$script)) {
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    if (!rmarkdown::pandoc_available()) {
      stop(paste0("pandoc no esta disponible y es necesario para el informe.\n",
                  "Instalar pandoc, o correr los pasos 01-07 y omitir el 08:\n",
                  "  Rscript run_all.R 01 02 03 04 05 06 07"), call. = FALSE)
    }
    rmarkdown::render(
      file.path(ROOT, "R", p$script),
      output_file = "informe_demanda_ELDU.html",
      output_dir = out_dir,
      intermediates_dir = tempdir(),
      # El knit root es output/ para que las figuras de output/figs/ queden
      # referenciadas de forma relativa al HTML; los scripts usan here::here()
      # y no dependen del directorio de trabajo.
      knit_root_dir = out_dir,
      envir = new.env(), quiet = TRUE)
    cat("  -> ", file.path(cfg$paths$output_dir, "informe_demanda_ELDU.html"), "\n")
  } else {
    # Cada script corre en su propio entorno: ningun paso hereda estado de otro.
    source(file.path(ROOT, "R", p$script), local = new.env(), echo = FALSE)
  }
  tiempos[[p$id]] <- as.numeric(difftime(Sys.time(), ti, units = "secs"))
}

# ---------------------------------------------------------------------------
# sessionInfo + resumen
# ---------------------------------------------------------------------------
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
si <- file.path(out_dir, "sessionInfo.txt")
writeLines(c(
  "ELDU — entorno de ejecucion del pipeline",
  paste("generado:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  paste("semilla :", cfg$project$seed),
  paste("datos   :", Sys.getenv("ELDU_DATA_DIR", unset = cfg$paths$data_dir)),
  paste("pasos   :", paste(PASOS$id, collapse = " ")),
  paste("locale  :", Sys.getlocale("LC_CTYPE")),
  paste("pandoc  :", tryCatch(as.character(rmarkdown::pandoc_version()),
                              error = function(e) "no disponible")),
  "", strrep("-", 76), "",
  capture.output(sessionInfo())), si)
cat("\n  -> ", file.path(cfg$paths$output_dir, "sessionInfo.txt"), "\n", sep = "")

banner("RESUMEN")
tt <- data.frame(paso = names(tiempos), segundos = round(unlist(tiempos), 1))
print(tt, row.names = FALSE)
cat(sprintf("\nTOTAL: %.1f s\n", as.numeric(difftime(Sys.time(), t0, units = "secs"))))
cat("\nEntregables en ", cfg$paths$output_dir, "/:\n", sep = "")
for (f in c("informe_demanda_ELDU.html", "forecast_volumenes.xlsx",
            "00_data_check.html", "sessionInfo.txt")) {
  pth <- file.path(out_dir, f)
  if (file.exists(pth)) cat(sprintf("  %-32s %8.1f KB\n", f,
                                    file.size(pth) / 1024))
}
nt <- length(list.files(file.path(out_dir, "tables"), pattern = "\\.csv$"))
nf <- length(list.files(file.path(out_dir, "figs")))
cat(sprintf("  %-32s %8d\n  %-32s %8d\n", "tables/*.csv", nt, "figs/*", nf))
cat("\nOK\n")
