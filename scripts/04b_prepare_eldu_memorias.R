## ============================================================================
## 04b_prepare_eldu_memorias.R — SOLO preparación.
## Convierte la tabla de Memorias Anuales de ELDU provista por el usuario en la
## serie anual canónica que consume 05 (data/raw/eldu_energia_anual.csv).
## ----------------------------------------------------------------------------
## Lo único que hace es SELECCIONAR y FILTRAR, dejando constancia de ambas
## decisiones en el log:
##   - elige la variable de volumen (CFG$eldu$memorias_variable) y arrastra la
##     alternativa de robustez y el número de clientes;
##   - descarta las filas cuyo año no es un entero de 4 dígitos, porque son
##     periodos PARCIALES (p.ej. "2026_U12M_jun", un año móvil a junio): mezclar
##     un año móvil con años completos es exactamente el tipo de error que
##     produce saltos interanuales irreales.
## No interpola, no completa y no reescala nada.
## ============================================================================

suppressPackageStartupMessages({ library(dplyr); library(readr); library(here) })

STAGE <- "04b_eldu"
log_event(STAGE, "INFO", "inicio — preparación de la serie anual de ELDU")

src <- here::here(CFG$eldu$memorias_csv)

if (!file.exists(src)) {
  log_event(STAGE, "FAIL",
            sprintf("no existe %s — 05 buscará la energía por las otras vías",
                    CFG$eldu$memorias_csv))
} else {
  raw <- suppressMessages(readr::read_csv(src, show_col_types = FALSE,
                                          col_types = readr::cols(.default = "c")))
  log_event(STAGE, "OK", sprintf("leído %s: %d filas, columnas: %s",
                                 CFG$eldu$memorias_csv, nrow(raw),
                                 paste(names(raw), collapse = ", ")))
  register_source(src, "",
                  "Electro Dunas — demanda y clientes por año, compilado de las Memorias Anuales",
                  notes = "tabla provista por el usuario; columna `fuente` indica la memoria de origen de cada fila")

  need <- c("anio", CFG$eldu$memorias_variable, CFG$eldu$memorias_clients)
  miss <- setdiff(need, names(raw))
  if (length(miss)) {
    stop(sprintf(paste0("%s no tiene la(s) columna(s) %s.\n",
                        "Columnas presentes: %s\n",
                        "Ajuste CFG$eldu$memorias_variable / memorias_clients en config/config.R."),
                 CFG$eldu$memorias_csv, paste(miss, collapse = ", "),
                 paste(names(raw), collapse = ", ")), call. = FALSE)
  }

  ## ---- Filtro de periodos parciales ---------------------------------------
  keep <- grepl(CFG$eldu$year_regex, trimws(raw$anio), perl = TRUE)
  if (any(!keep)) {
    log_event(STAGE, "WARN",
              sprintf("EXCLUIDA(S) %d fila(s) por ser periodo parcial o no anual: %s",
                      sum(!keep), paste(raw$anio[!keep], collapse = "; ")))
  }
  d <- raw[keep, , drop = FALSE]

  num <- function(x) suppressWarnings(as.numeric(gsub(",", "", trimws(x), fixed = TRUE)))
  rob_col <- CFG$eldu$memorias_robustness
  out <- tibble::tibble(
    year        = as.integer(trimws(d$anio)),
    energia_gwh = num(d[[CFG$eldu$memorias_variable]]),
    clientes    = num(d[[CFG$eldu$memorias_clients]]),
    energia_robustez_gwh =
      if (!is.null(rob_col) && rob_col %in% names(d)) num(d[[rob_col]]) else NA_real_
  ) %>% arrange(year)

  ## La variable elegida y los clientes NO pueden tener huecos: si los tienen,
  ## la serie no sirve y hay que arreglar la fuente, no imputar.
  bad <- out$year[is.na(out$energia_gwh)]
  if (length(bad)) {
    stop(sprintf(paste0("la columna '%s' está vacía en los años: %s.\n",
                        "El pipeline no imputa. Complete la fuente o elija otra variable."),
                 CFG$eldu$memorias_variable, paste(bad, collapse = ", ")), call. = FALSE)
  }
  if (any(is.na(out$clientes))) {
    log_event(STAGE, "WARN",
              sprintf("faltan clientes en %s: la especificación por cliente se omitirá",
                      paste(out$year[is.na(out$clientes)], collapse = ", ")))
  }

  dest <- here::here(CFG$eldu$manual_csv)
  readr::write_csv(out, dest)
  register_source(dest, "",
                  sprintf("Serie anual canónica de ELDU (variable: %s)", CFG$eldu$memorias_variable),
                  notes = sprintf("derivada de %s por 04b; %d años (%d-%d); periodos parciales excluidos",
                                  basename(src), nrow(out), min(out$year), max(out$year)))
  log_event(STAGE, "OK",
            sprintf("escrito %s — variable '%s', %d años (%d-%d), %.0f-%.0f GWh",
                    CFG$eldu$manual_csv, CFG$eldu$memorias_variable, nrow(out),
                    min(out$year), max(out$year),
                    min(out$energia_gwh), max(out$energia_gwh)))
  log_event(STAGE, "INFO", "fin")
}
