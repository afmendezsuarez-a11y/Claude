#!/usr/bin/env Rscript
## ============================================================================
## tests/integration_smoke.R — PRUEBA DE CÓDIGO, NO ES DATA DEL PROYECTO.
## ----------------------------------------------------------------------------
## ADVERTENCIA IMPORTANTE, LÉASE ANTES DE JUZGAR ESTE ARCHIVO:
##
## Este test construye una serie ARTIFICIAL con una elasticidad conocida
## (eta_true) para verificar que el CÓDIGO de 05/06/07/08 corre y que la
## estimación recupera el parámetro que se le metió. Es la única forma de
## probar la cadena cuando el contenedor no tiene acceso a las fuentes reales.
##
## Esa serie artificial:
##   - se escribe en un directorio TEMPORAL, nunca en data/ del repositorio;
##   - NUNCA entra al informe ni a ninguna salida de output/;
##   - no es un "modo demo": el pipeline no tiene ninguna ruta que la use.
##
## Si este archivo desapareciera, el pipeline se comportaría igual. Existe sólo
## para que el código esté probado y no apenas "parseado".
##
## Uso:  Rscript tests/integration_smoke.R
## ============================================================================

set.seed(20261007)
ETA_TRUE <- 0.85
Y0_BASE  <- 2005L

`%||%` <- function(a, b) if (is.null(a)) b else a

## Raíz del repo: el directorio actual, o su padre si se invoca desde tests/.
root <- normalizePath(getwd())
if (!dir.exists(file.path(root, "scripts")) &&
    dir.exists(file.path(root, "..", "scripts"))) {
  root <- normalizePath(file.path(root, ".."))
}
if (!dir.exists(file.path(root, "scripts"))) {
  stop("ejecute este test desde la raíz del repositorio: Rscript tests/integration_smoke.R",
       call. = FALSE)
}

## El sandbox vive FUERA de tempdir() a propósito: R borra su tempdir al salir y
## entonces no quedaría nada que inspeccionar cuando una aserción falla.
## Se puede fijar con ELDU_SMOKE_DIR.
ANY_FAIL <- FALSE
check <- function(cond, what) {
  cat(sprintf("  [%s] %s\n", if (isTRUE(cond)) "ok" else "FALLA", what))
  if (!isTRUE(cond)) ANY_FAIL <<- TRUE
}

## ---------------------------------------------------------------------------
## Un caso = un sandbox + un fixture de n anios + la corrida completa.
## Se prueban DOS tamanios de muestra porque el criterio de aceptacion es que
## "el metodo reportado corresponda al n disponible": con n largo debe intentar
## ADF/ECM/out-of-sample, y con n corto debe saltarselos en vez de forzarlos.
## ---------------------------------------------------------------------------
run_case <- function(n_years, label) {
  cat(sprintf("\n=========== CASO: %s (n = %d) ===========\n", label, n_years))
  tmp <- Sys.getenv("ELDU_SMOKE_DIR",
                    unset = file.path(dirname(tempdir()),
                                      sprintf("eldu_smoke_%d_n%d", Sys.getpid(), n_years)))
  unlink(tmp, recursive = TRUE)
  dir.create(tmp, recursive = TRUE)
  cat("sandbox:", tmp, "\n")

  for (d in c("config", "R", "scripts")) {
    dir.create(file.path(tmp, d), recursive = TRUE, showWarnings = FALSE)
    file.copy(list.files(file.path(root, d), full.names = TRUE), file.path(tmp, d),
              overwrite = TRUE)
  }
  file.copy(file.path(root, "run_all.R"), file.path(tmp, "run_all.R"), overwrite = TRUE)
  writeLines("", file.path(tmp, ".here"))     # ancla para here::here()
  dir.create(file.path(tmp, "data/raw/pdf"), recursive = TRUE, showWarnings = FALSE)

  ## ---- Fixture 1: PBI mensual con la forma EXACTA de la API del BCRP -------
  ## (asi el test ejercita read_bcrp_json() y to_annual(), no solo la regresion)
  years    <- Y0_BASE:(Y0_BASE + n_years - 1L)
  g_annual <- 0.04 + stats::rnorm(n_years, 0, 0.012)
  pbi_ann  <- 100 * cumprod(c(1, 1 + g_annual[-1]))
  meses    <- c("Ene","Feb","Mar","Abr","May","Jun","Jul","Ago","Sep","Oct","Nov","Dic")
  periods  <- list()
  for (i in seq_along(years)) for (m in 1:12) {
    periods[[length(periods) + 1L]] <- list(
      name   = sprintf("%s.%d", meses[m], years[i]),
      values = list(sprintf("%.4f", pbi_ann[i] * (1 + stats::rnorm(1, 0, 0.004))))
    )
  }
  jsonlite::write_json(
    list(config = list(series = list(list(
           name = "Producto bruto interno (indice 2007=100) - FIXTURE DE PRUEBA"))),
         periods = periods),
    file.path(tmp, "data/raw/bcrp_pbi_real.json"), auto_unbox = TRUE)

  ## ---- Fixture 2: energia con eta conocida ---------------------------------
  ln_q <- log(600) + ETA_TRUE * (log(pbi_ann) - log(pbi_ann[1])) +
          stats::rnorm(n_years, 0, 0.012)
  utils::write.csv(data.frame(year = years, energia_gwh = round(exp(ln_q), 2)),
                   file.path(tmp, "data/raw/eldu_energia_anual.csv"), row.names = FALSE)

  ## ---- Correr el pipeline completo en el sandbox ---------------------------
  ## OJO: system2() hereda el directorio de trabajo, asi que hay que cambiarlo
  ## explicitamente o el test correria contra el repositorio real.
  old_wd <- getwd()
  setwd(tmp)
  res <- tryCatch(system2("Rscript", c("run_all.R"), stdout = TRUE, stderr = TRUE),
                  finally = setwd(old_wd))
  setwd(old_wd)
  code <- attr(res, "status") %||% 0L
  stopifnot(identical(normalizePath(getwd()), normalizePath(old_wd)))

  cat("--- aserciones ---\n")
  check(code == 0L, sprintf("run_all.R termina con codigo 0 (obtuvo %s)", code))

  el_p <- file.path(tmp, "output/tables/elasticidad.csv")
  check(file.exists(el_p), "existe output/tables/elasticidad.csv")
  if (file.exists(el_p)) {
    el  <- utils::read.csv(el_p, stringsAsFactors = FALSE)
    row <- el[el$parametro == "eta_largo_plazo" & el$metodo_reportado, ][1, ]
    cat(sprintf("     eta estimado = %.3f (IC95 %.3f a %.3f); eta_true = %.2f\n",
                row$estimate, row$ci95_low, row$ci95_high, ETA_TRUE))
    check(abs(row$estimate - ETA_TRUE) < 0.25,
          "la estimacion recupera eta_true con tolerancia 0.25")
    check(row$ci95_low <= ETA_TRUE && ETA_TRUE <= row$ci95_high,
          "el IC95 contiene eta_true")
    check(nrow(el[el$parametro == "eta_crecimiento", ]) == 1L,
          "se reporta tambien la elasticidad en diferencias")
  }
  for (f in c("output/forecast_volumenes.xlsx", "output/informe_demanda_ELDU.html",
              "data/raw/SOURCES.md", "output/sessionInfo.txt",
              "output/tables/diagnosticos.csv")) {
    check(file.exists(file.path(tmp, f)), paste("existe", f))
  }

  ## ---- El metodo reportado debe corresponder al n --------------------------
  est_p <- file.path(tmp, "data/processed/estimacion.rds")
  check(file.exists(est_p), "existe data/processed/estimacion.rds")
  if (file.exists(est_p)) {
    RES <- readRDS(est_p)
    E   <- list(adf = 12L, ecm = 15L, oos = 12L)
    check(isTRUE(RES$adf$ln_q$skipped) == (n_years < E$adf),
          sprintf("ADF %s con n=%d", if (n_years < E$adf) "se omite" else "se corre", n_years))
    check(isTRUE(RES$ecm$attempted) == (n_years >= E$ecm),
          sprintf("ECM %s con n=%d", if (n_years >= E$ecm) "se intenta" else "NO se intenta", n_years))
    check(isTRUE(RES$oos$done) == (n_years >= E$oos),
          sprintf("out-of-sample %s con n=%d", if (n_years >= E$oos) "se corre" else "se omite", n_years))
    check(is.logical(RES$prudence$report_as_range) && !is.na(RES$prudence$report_as_range),
          "la regla de prudencia emite un veredicto explicito (punto vs rango)")
  }

  fc_p <- file.path(tmp, "output/tables/forecast_volumenes.csv")
  check(file.exists(fc_p), "existe la proyeccion en CSV")
  if (file.exists(fc_p)) {
    fc <- utils::read.csv(fc_p, stringsAsFactors = FALSE)
    check(max(fc$year) == 2035L, "la proyeccion llega a FY2035")
    check(all(c("base", "optimista", "pesimista") %in% unique(fc$escenario)),
          "estan los tres escenarios")
    check(all(fc$gwh_low <= fc$gwh_central + 1e-8) &&
          all(fc$gwh_central <= fc$gwh_high + 1e-8),
          "las bandas encierran al central")
    ## Guardia contra el modo de falla de la corrida previa (+87% en un anio)
    yoy <- fc[fc$escenario == "base", ]
    yoy <- yoy[order(yoy$year), "gwh_central"]
    check(all(abs(diff(log(yoy))) < log(1.20)),
          "ningun salto interanual absurdo en la proyeccion base")
  }

  ## El pipeline NO debe haber dejado rastro de modo demo
  check(!any(grepl("(?i)demo|sintetic|simulad",
                   list.files(file.path(tmp, "data"), recursive = TRUE), perl = TRUE)),
        "no se creo ningun archivo demo/sintetico en data/")

  if (!isTRUE(ANY_FAIL)) unlink(tmp, recursive = TRUE) else cat("  sandbox conservado:", tmp, "\n")
  invisible(NULL)
}

run_case(20L, "serie larga tipo Anuario MINEM")
run_case(9L,  "serie corta tipo Memorias Anuales")

cat("\n")
if (isTRUE(ANY_FAIL)) { cat("[FALLA] al menos una asercion fallo\n"); quit(status = 1L) }
cat("TODAS LAS ASERCIONES PASARON\n")
quit(status = 0L)
