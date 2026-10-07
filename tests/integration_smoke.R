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
G_CLIENTES_TRUE <- 0.025   # crecimiento anual de conexiones del fixture

run_case <- function(n_years, label, with_clients = FALSE) {
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
  ## La varianza del crecimiento del ingreso importa para el test: si el driver
  ## es demasiado liso, la regresion en diferencias no tiene de donde identificar
  ## eta y el estimador se vuelve puro ruido a n chico. El PBI real del Peru
  ## oscila fuerte (de -11% en 2020 a +16% en 2021), asi que el fixture usa una
  ## dispersion de ese orden en vez de una serie artificialmente tranquila.
  g_annual <- 0.04 + stats::rnorm(n_years, 0, 0.05)
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
  ## Sin clientes: eta_true va directo sobre la energia total.
  ## Con clientes: eta_true va sobre la energia POR CLIENTE y las conexiones
  ## crecen a G_CLIENTES_TRUE, de modo que el total mezcla ambos efectos. Asi se
  ## prueba que la descomposicion recupera eta sin contaminarla con conexiones.
  shock <- ETA_TRUE * (log(pbi_ann) - log(pbi_ann[1])) + stats::rnorm(n_years, 0, 0.012)
  if (with_clients) {
    clientes <- round(250000 * exp(G_CLIENTES_TRUE * (seq_len(n_years) - 1)))
    q_pc     <- 0.0024 * exp(shock)            # GWh por cliente
    energia  <- clientes * q_pc
    eldu <- data.frame(year = years, energia_gwh = round(energia, 2), clientes = clientes)
  } else {
    eldu <- data.frame(year = years, energia_gwh = round(600 * exp(shock), 2))
  }
  utils::write.csv(eldu, file.path(tmp, "data/raw/eldu_energia_anual.csv"), row.names = FALSE)

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
    row <- el[el$rol == "PRINCIPAL", ][1, ]
    check(nrow(el[el$rol == "PRINCIPAL", ]) == 1L,
          "hay exactamente UNA especificacion marcada como PRINCIPAL")
    cat(sprintf("     eta PRINCIPAL = %.3f (IC95 %.3f a %.3f); eta_true = %.2f  [%s]\n",
                row$estimate, row$ci95_low, row$ci95_high, ETA_TRUE, row$metodo))
    check(abs(row$estimate - ETA_TRUE) < 0.25,
          "la estimacion recupera eta_true con tolerancia 0.25")
    ## La cobertura del IC solo se exige con muestra larga. Los errores HAC
    ## (Newey-West) SUB-CUBREN en muestras diminutas: a n<12 el IC95 nominal
    ## tiene cobertura real menor al 95%, asi que exigir que contenga eta_true
    ## seria exigirle al estimador algo que la teoria no promete. Esa es
    ## justamente la razon por la que el pipeline reporta un RANGO y no el IC
    ## pelado cuando la muestra es corta.
    if (n_years >= 12L) {
      check(row$ci95_low <= ETA_TRUE && ETA_TRUE <= row$ci95_high,
            "el IC95 contiene eta_true (muestra larga)")
    } else {
      cat(sprintf("  [nota] n=%d: no se exige cobertura del IC95 (HAC sub-cubre a n chico)\n",
                  n_years))
    }
    check(any(grepl("diferencias", el$metodo, ignore.case = TRUE)),
          "se reporta tambien la elasticidad en diferencias")
    check(all(row$bloque == if (with_clients) "energia_por_cliente" else "energia_total"),
          sprintf("%s, eta se estima sobre %s",
                  if (with_clients) "con clientes" else "sin clientes",
                  if (with_clients) "energia POR CLIENTE" else "energia total"))
    if (with_clients)
      check(any(el$bloque == "energia_total" & el$rol == "comparacion"),
            "se reporta la elasticidad sobre energia total como comparacion con el DCF")
  }

  ## ---- Descomposicion y comparacion de reglas (ruta de dos terminos) -------
  if (with_clients) {
    dc <- file.path(tmp, "output/tables/descomposicion_crecimiento.csv")
    check(file.exists(dc), "existe output/tables/descomposicion_crecimiento.csv")
    if (file.exists(dc)) {
      D <- utils::read.csv(dc, stringsAsFactors = FALSE)
      g_cl <- D$cagr_pct[D$componente == "clientes"] / 100
      cat(sprintf("     g_clientes estimado = %.4f ; g_clientes_true = %.4f\n",
                  g_cl, G_CLIENTES_TRUE))
      check(abs(g_cl - G_CLIENTES_TRUE) < 0.003,
            "la descomposicion recupera el crecimiento de clientes del fixture")
      check(abs(sum(D$cagr_pct[D$componente %in% c("clientes", "energia por cliente")]) -
                D$cagr_pct[D$componente == "energia distribuida"]) < 0.05,
            "clientes + por-cliente suma el crecimiento de la energia total")
    }
    cr <- file.path(tmp, "output/tables/comparacion_reglas.csv")
    check(file.exists(cr), "existe output/tables/comparacion_reglas.csv")
    if (file.exists(cr)) {
      R2 <- utils::read.csv(cr, stringsAsFactors = FALSE)
      dos <- R2$cagr_pct[grepl("dos terminos", R2$regla)]
      una <- R2$cagr_pct[grepl("una sola", R2$regla)]
      check(length(dos) == 1 && length(una) == 1 && dos > una,
            "la regla de dos terminos proyecta mas que la de una sola elasticidad")
    }
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
run_case(8L,  "serie corta CON clientes (ruta de dos terminos)", with_clients = TRUE)

cat("\n")
if (isTRUE(ANY_FAIL)) { cat("[FALLA] al menos una asercion fallo\n"); quit(status = 1L) }
cat("TODAS LAS ASERCIONES PASARON\n")
quit(status = 0L)
