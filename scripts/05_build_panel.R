## ============================================================================
## 05_build_panel.R — construye el panel anual. SE DETIENE si falta un
## insumo obligatorio (energía ELDU + ingreso). No imputa, no simula.
## ============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(jsonlite)
  library(readxl); library(here); library(ggplot2)
})

STAGE <- "05_panel"
log_event(STAGE, "INFO", "inicio — construcción del panel anual")

raw_dir <- here::here(CFG$paths$raw)
PROV <- list()   # procedencia de cada variable del panel (va al informe)

## ---------------------------------------------------------------------------
## Utilidades de parseo
## ---------------------------------------------------------------------------
MESES_ES <- c(ene=1,feb=2,mar=3,abr=4,may=5,jun=6,
              jul=7,ago=8,sep=9,set=9,oct=10,nov=11,dic=12)

#' Convierte el nombre de periodo del BCRP ("Ene.2010", "2010", "T1.2010") a
#' año y mes. Devuelve NA en mes si la serie no es mensual.
parse_bcrp_period <- function(x) {
  yr <- suppressWarnings(as.integer(regmatches(x, regexpr("(19|20)\\d{2}", x))))
  mo_txt <- tolower(substr(regmatches(x, regexpr("(?i)^[A-Za-z]{3}", x, perl = TRUE)), 1, 3))
  mo <- rep(NA_integer_, length(x))
  got <- nzchar(mo_txt) & !is.na(mo_txt)
  if (any(got)) mo[got] <- unname(MESES_ES[mo_txt[got]])
  data.frame(year = yr, month = mo)
}

#' Lee un JSON de la API del BCRP y lo devuelve como data.frame largo.
read_bcrp_json <- function(path) {
  j <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  if (is.null(j$periods) || !length(j$periods)) return(NULL)
  nm <- tryCatch(j$config$series[[1]]$name, error = function(e) NA_character_)
  rows <- lapply(j$periods, function(p) {
    v <- suppressWarnings(as.numeric(p$values[[1]]))
    data.frame(period = p$name, value = v, stringsAsFactors = FALSE)
  })
  d <- do.call(rbind, rows)
  d <- cbind(d, parse_bcrp_period(d$period))
  d$series_name <- nm %||% NA_character_
  d[!is.na(d$value) & !is.na(d$year), , drop = FALSE]
}

`%||%` <- function(a, b) if (is.null(a)) b else a

#' Lee un CSV exportado de BCRPData.
#' Formato: línea 1 = código, línea 2 = nombre de la serie, luego `periodo,valor`.
#' Los periodos vienen como "Ene91" (mensual) o "02Ene97" (diario); los
#' faltantes como "n.d.". La codificación es latin1.
read_bcrp_csv <- function(path) {
  hdr <- readLines(path, n = 2, warn = FALSE, encoding = "latin1")
  code <- gsub('"', '', trimws(sub("^,*", "", sub('^"",?', '', hdr[1]))))
  name <- gsub('"', '', sub('^"",?', '', hdr[2]))
  d <- utils::read.csv(path, skip = 2, header = FALSE, stringsAsFactors = FALSE,
                       fileEncoding = "latin1", col.names = c("period", "value"))
  d$value <- suppressWarnings(as.numeric(d$value))   # "n.d." -> NA
  per <- trimws(d$period)
  ## día opcional + mes de 3 letras + año de 2 dígitos
  mo_txt <- tolower(sub("^\\d{0,2}([A-Za-z]{3}).*$", "\\1", per))
  yy     <- suppressWarnings(as.integer(sub("^.*?(\\d{2})$", "\\1", per)))
  d$year  <- ifelse(is.na(yy), NA_integer_, ifelse(yy >= 50L, 1900L + yy, 2000L + yy))
  d$month <- unname(MESES_ES[mo_txt])
  d$series_name <- name
  d$series_code <- code
  d[!is.na(d$year) & !is.na(d$value), , drop = FALSE]
}

#' Encadena una serie de variación % interanual a un índice de nivel.
#' Honestidad: el crecimiento ANUAL se aproxima por el promedio de las 12
#' variaciones interanuales del año. El cálculo exacto exige los NIVELES
#' mensuales (la suma del año sobre la del año previo), que esta serie no trae.
#' El sesgo es de centésimas de punto, pero queda anotado.
chain_yoy_to_index <- function(d, min_months = 12L, label = "") {
  g <- d %>% group_by(year) %>%
    summarise(n_obs = sum(!is.na(value)),
              g_pct = mean(value[!is.na(value)]), .groups = "drop") %>%
    filter(n_obs >= min_months) %>% arrange(year)
  if (!nrow(g)) return(NULL)
  g$value <- 100 * cumprod(c(1, 1 + g$g_pct[-1] / 100))
  log_event(STAGE, "INFO",
            sprintf("[%s] %d variaciones anuales encadenadas a índice (%d-%d); el crecimiento anual es el promedio de las 12 var. interanuales (aproximación)",
                    label, nrow(g), min(g$year), max(g$year)))
  g %>% select(year, value, n_obs)
}

#' Agrega una serie mensual (o ya anual) a frecuencia anual.
#' Exige al menos `min_months` meses para no promediar un año incompleto.
to_annual <- function(d, fun = mean, min_months = 12L, label = "") {
  ## OJO: `summarise()` evalúa las expresiones EN ORDEN, así que n_obs debe
  ## calcularse ANTES de sobrescribir `value`; si no, cuenta 1 por grupo y el
  ## filtro de meses completos descarta todos los años en silencio.
  if (all(is.na(d$month))) {                       # ya es anual
    out <- d %>% group_by(year) %>%
      summarise(n_obs = sum(!is.na(value)),
                value = fun(value[!is.na(value)]), .groups = "drop")
  } else {
    out <- d %>% group_by(year) %>%
      summarise(n_obs = sum(!is.na(value)),
                value = fun(value[!is.na(value)]), .groups = "drop") %>%
      filter(n_obs >= min_months)
  }
  out <- out %>% select(year, value, n_obs)
  if (nzchar(label)) log_event(STAGE, "INFO",
    sprintf("[%s] anualizada: %d años (%s-%s)", label, nrow(out),
            min(out$year, Inf), max(out$year, -Inf)))
  out
}

## ---------------------------------------------------------------------------
## 1) Series BCRP
## ---------------------------------------------------------------------------
bcrp <- list()
for (k in names(CFG$bcrp$series)) {
  p <- file.path(raw_dir, sprintf("bcrp_%s.json", k))
  if (!file.exists(p)) {
    log_event(STAGE, "WARN", sprintf("[bcrp_%s] archivo ausente: %s", k, p))
    next
  }
  d <- tryCatch(read_bcrp_json(p), error = function(e) NULL)
  if (is.null(d) || !nrow(d)) {
    log_event(STAGE, "WARN", sprintf("[bcrp_%s] JSON sin datos utilizables", k))
    next
  }
  bcrp[[k]] <- to_annual(d, label = paste0("bcrp_", k))
  PROV[[paste0("bcrp_", k)]] <- sprintf("BCRP — %s (serie devuelta: '%s')",
                                        CFG$bcrp$series[[k]]$label,
                                        unique(d$series_name)[1])
}

## CSV exportados a mano de BCRPData (no requieren red)
for (k in names(CFG$bcrp$csv_files %||% list())) {
  spec <- CFG$bcrp$csv_files[[k]]
  p <- here::here(spec$path)
  if (!file.exists(p)) {
    log_event(STAGE, "INFO", sprintf("[bcrp_%s] no provisto: %s", k, spec$path))
    next
  }
  d <- tryCatch(read_bcrp_csv(p), error = function(e) NULL)
  if (is.null(d) || !nrow(d)) {
    log_event(STAGE, "WARN", sprintf("[bcrp_%s] CSV ilegible o vacío: %s", k, spec$path))
    next
  }
  register_source(p, "https://estadisticas.bcrp.gob.pe/estadisticas/series/",
                  sprintf("BCRP — %s", spec$label),
                  notes = sprintf("código %s; serie '%s'; %d observaciones (%d-%d); exportado a mano de BCRPData",
                                  unique(d$series_code)[1], substr(unique(d$series_name)[1], 1, 100),
                                  nrow(d), min(d$year), max(d$year)))
  ag <- if (identical(spec$kind, "yoy_pct")) {
    chain_yoy_to_index(d, label = paste0("bcrp_", k))
  } else {
    ## El TC es diario: exigir 12 "meses" no aplica, se pide cobertura del año.
    to_annual(d, min_months = if (identical(spec$kind, "level") &&
                                  sum(!is.na(d$month)) > 0 && nrow(d) > 1000) 200L else 12L,
              label = paste0("bcrp_", k))
  }
  if (is.null(ag) || !nrow(ag)) {
    log_event(STAGE, "WARN", sprintf("[bcrp_%s] no quedaron años completos tras anualizar", k))
    next
  }
  bcrp[[k]] <- ag
  PROV[[paste0("bcrp_", k)]] <- sprintf("BCRP %s — %s [%s]",
                                        unique(d$series_code)[1], spec$label, spec$role)
  log_event(STAGE, "OK", sprintf("[bcrp_%s] %d años (%d-%d), rol: %s",
                                 k, nrow(ag), min(ag$year), max(ag$year), spec$role))
}

## ---------------------------------------------------------------------------
## 2) Ingreso: PBI de Ica (preferido) o PBI nacional (PROXY, se marca)
## ---------------------------------------------------------------------------
income_is_proxy <- NA
income <- NULL

inei_files <- unique(c(
  if (!is.null(CFG$inei$xlsx) && file.exists(here::here(CFG$inei$xlsx))) here::here(CFG$inei$xlsx),
  list.files(raw_dir, pattern = "(?i)^inei_.*\\.(xlsx|xls)$", full.names = TRUE)
))

if (length(inei_files)) {
  ## La tabla del INEI pone el departamento en el TÍTULO ("Ica: Valor Agregado
  ## Bruto..."), no en una fila de datos, así que no se busca la región fila a
  ## fila: se localiza la fila de encabezado con años y la fila cuyo rótulo es
  ## el total ("Valor Agregado Bruto").
  ##
  ## El libro trae la MISMA fila de total en varias hojas —niveles en miles de
  ## soles, estructura porcentual (todo 100) y variación porcentual—, así que la
  ## candidata debe superar CFG$inei$min_level para quedarse sólo con la de
  ## niveles. Sin ese filtro se podría tomar la hoja de porcentajes y estimar
  ## una elasticidad contra una serie de 100s.
  extract_total_row <- function(f) {
    sheets <- tryCatch(readxl::excel_sheets(f), error = function(e) character(0))
    for (sh in sheets) {
      m <- tryCatch(suppressMessages(readxl::read_excel(f, sheet = sh, col_names = FALSE)),
                    error = function(e) NULL)
      if (is.null(m) || !nrow(m)) next
      M <- as.data.frame(lapply(m, as.character), stringsAsFactors = FALSE)
      ## los encabezados pueden traer sufijos de preliminar/estimado: 2023P/, 2025E/
      is_year <- function(r) grepl("^\\s*(19|20)\\d{2}\\s*([PpEe]/)?\\s*$", r)
      yr_row <- which(apply(M, 1, function(r) sum(is_year(r), na.rm = TRUE) >= 5))
      tot_row <- which(apply(M, 1, function(r)
        grepl(CFG$inei$total_row_regex, tolower(trimws(r[1] %||% "")), perl = TRUE)))
      if (!length(yr_row) || !length(tot_row)) next
      yr_r <- yr_row[1]
      for (dat_r in tot_row) {
        if (dat_r <= yr_r) next
        yrs  <- suppressWarnings(as.integer(sub("^\\s*((19|20)\\d{2}).*$", "\\1",
                                                trimws(unlist(M[yr_r, ])))))
        vals <- suppressWarnings(as.numeric(gsub(",", "", trimws(unlist(M[dat_r, ])),
                                                 fixed = TRUE)))
        keep <- !is.na(yrs) & !is.na(vals)
        if (sum(keep) < 5) next
        if (stats::median(vals[keep]) < CFG$inei$min_level) {
          log_event(STAGE, "INFO",
                    sprintf("[inei] hoja '%s' fila %d descartada: la mediana (%.1f) está por debajo de min_level (%s), no son niveles",
                            sh, dat_r, stats::median(vals[keep]), CFG$inei$min_level))
          next
        }
        return(list(data = data.frame(year = yrs[keep], value = vals[keep]),
                    trace = sprintf("archivo=%s; hoja=%s; fila_anios=%d; fila_total=%d; rotulo='%s'",
                                    basename(f), sh, yr_r, dat_r, trimws(M[dat_r, 1]))))
      }
    }
    NULL
  }
  for (f in inei_files) {
    got <- tryCatch(extract_total_row(f), error = function(e) NULL)
    if (!is.null(got)) {
      income <- got$data %>% arrange(year) %>% distinct(year, .keep_all = TRUE) %>%
        mutate(n_obs = 1L)
      income_is_proxy <- FALSE
      PROV$income <- sprintf("INEI — Valor Agregado Bruto real de %s, precios constantes (%s)",
                             CFG$inei$region, got$trace)
      register_source(f, "", sprintf("INEI — VAB de %s por años y actividad, precios constantes",
                                     CFG$inei$region),
                      notes = sprintf("%s; %d años (%d-%d)", got$trace, nrow(income),
                                      min(income$year), max(income$year)))
      log_event(STAGE, "OK", sprintf("ingreso = VAB real de %s; %s; %d años (%d-%d)",
                                     CFG$inei$region, got$trace, nrow(income),
                                     min(income$year), max(income$year)))
      break
    }
  }
  if (is.null(income)) log_event(STAGE, "WARN",
    "hay archivos INEI pero no se pudo localizar la fila de total con años en ninguna hoja")
}

if (is.null(income)) {
  nac_key <- intersect(c("pbi_real", "pbi_nacional_yoy"), names(bcrp))[1]
  if (!is.na(nac_key)) {
    income <- bcrp[[nac_key]]
    income_is_proxy <- TRUE
    PROV$income <- paste0(PROV[[paste0("bcrp_", nac_key)]],
                          "  ** USADO COMO PROXY del PBI de Ica (el VAB departamental del INEI no se pudo obtener) **")
    log_event(STAGE, "WARN",
              "ingreso = PBI NACIONAL usado como PROXY del VAB de Ica (se marca en el informe)")
  }
}

if (is.null(income)) {
  stop_missing(
    what  = "serie de ingreso (PBI de Ica del INEI, o PBI nacional del BCRP como proxy)",
    where = c(file.path(CFG$paths$raw, "inei_pbi_departamental*.xlsx"),
              file.path(CFG$paths$raw, "bcrp_pbi_real.json")),
    how   = c("abrir el egreso de red a estadisticas.bcrp.gob.pe y www.inei.gob.pe, y re-correr `Rscript run_all.R`",
              "o descargar a mano el PBI departamental del INEI a data/raw/inei_pbi_departamental_01.xlsx",
              "o pegar una URL directa en CFG$inei$direct_urls / CFG$bcrp (config/config.R)")
  )
}

## ---------------------------------------------------------------------------
## 3) Energía de ELDU (VARIABLE DEPENDIENTE — OBLIGATORIA)
## ---------------------------------------------------------------------------
energy <- NULL; energy_src <- NA_character_

## 3a) CSV curado por el usuario (máxima confianza)
man <- here::here(CFG$eldu$manual_csv)
if (file.exists(man)) {
  e <- suppressMessages(readr::read_csv(man, show_col_types = FALSE))
  miss <- setdiff(CFG$eldu$required_cols, names(e))
  if (length(miss)) {
    log_event(STAGE, "FAIL", sprintf("%s existe pero le faltan columnas: %s",
                                     CFG$eldu$manual_csv, paste(miss, collapse = ", ")))
  } else {
    energy <- e %>% transmute(
      year        = as.integer(year),
      energia_gwh = as.numeric(energia_gwh),
      clientes    = if ("clientes" %in% names(e)) as.numeric(clientes) else NA_real_,
      energia_robustez_gwh = if ("energia_robustez_gwh" %in% names(e))
        as.numeric(energia_robustez_gwh) else NA_real_)
    energy_src <- sprintf("CSV curado por el usuario (%s)", CFG$eldu$manual_csv)
    log_event(STAGE, "OK", sprintf("energía ELDU desde %s (%d años)",
                                   CFG$eldu$manual_csv, nrow(energy)))
  }
}

## 3b) Anuario MINEM / Osinergmin (extracción validada y trazada)
if (is.null(energy) && isTRUE(CFG$minem$auto_ingest)) {
  xls <- list.files(raw_dir,
                    pattern = "(?i)^(minem_anuario|osinergmin_anuario).*\\.(xlsx|xls)$",
                    full.names = TRUE)
  trace_rows <- list()
  for (f in xls) {
    sheets <- tryCatch(readxl::excel_sheets(f), error = function(e) character(0))
    for (sh in sheets) {
      m <- tryCatch(suppressMessages(readxl::read_excel(f, sheet = sh, col_names = FALSE)),
                    error = function(e) NULL)
      if (is.null(m) || !nrow(m)) next
      M <- as.data.frame(lapply(m, as.character), stringsAsFactors = FALSE)
      row_hit <- which(apply(M, 1, function(r)
        any(grepl(CFG$eldu$company_regex, r, perl = TRUE), na.rm = TRUE)))
      yr_row <- which(apply(M, 1, function(r)
        sum(grepl("^\\s*(19|20)\\d{2}(\\.0)?\\s*$", r)) >= 5))
      if (!length(row_hit) || !length(yr_row)) next
      yr_r <- yr_row[1]; dat_r <- row_hit[1]
      yrs  <- suppressWarnings(as.integer(sub("\\..*$", "", trimws(M[yr_r, ]))))
      vals <- suppressWarnings(as.numeric(gsub(",", "", trimws(M[dat_r, ]), fixed = TRUE)))
      keep <- !is.na(yrs) & !is.na(vals) & yrs >= 1990 & yrs <= 2040
      if (sum(keep) < 5) next
      energy <- data.frame(year = yrs[keep], energia_gwh = vals[keep],
                           clientes = NA_real_)
      energy_src <- sprintf("Anuario (%s, hoja '%s', fila %d de Electro Dunas)",
                            basename(f), sh, dat_r)
      trace_rows[[length(trace_rows) + 1L]] <- data.frame(
        file = basename(f), sheet = sh, year_header_row = yr_r,
        company_row = dat_r, n_years = sum(keep),
        raw_company_line = paste(na.omit(trimws(M[dat_r, ])), collapse = " | "),
        stringsAsFactors = FALSE)
      log_event(STAGE, "OK", sprintf("energía ELDU extraída de %s", energy_src))
      break
    }
    if (!is.null(energy)) break
  }
  if (length(trace_rows)) {
    tr <- do.call(rbind, trace_rows)
    utils::write.csv(tr, here::here(CFG$paths$tables, "minem_extraccion_traza.csv"),
                     row.names = FALSE)
  }
}

## 3c) Candidatos de las Memorias, sólo si el usuario aceptó auto_ingest
if (is.null(energy) && isTRUE(CFG$memorias$auto_ingest)) {
  cp <- here::here(CFG$paths$processed, "memorias_candidates.rds")
  if (file.exists(cp)) {
    cd <- readRDS(cp)
    cd <- cd[cd$variable == "energia_gwh" & !is.na(cd$year_guess) & !is.na(cd$value_guess), ]
    if (nrow(cd)) {
      energy <- cd %>% group_by(year = year_guess) %>%
        summarise(energia_gwh = median(value_guess), .groups = "drop") %>%
        mutate(clientes = NA_real_)
      energy_src <- "Memorias Anuales ELDU (extracción por regex SIN revisión humana — auto_ingest=TRUE)"
      log_event(STAGE, "WARN", paste("energía ELDU desde candidatos de PDF sin revisar.",
                                     "Verifique output/tables/memorias_extraccion_candidatos.csv"))
    }
  }
}

if (is.null(energy) || !nrow(energy)) {
  stop_missing(
    what  = "serie anual de energía de Electro Dunas (GWh) — la variable dependiente",
    where = c(CFG$eldu$manual_csv,
              file.path(CFG$paths$raw, "minem_anuario_*.xlsx"),
              file.path(CFG$paths$raw, "osinergmin_anuario_*.xlsx"),
              file.path(CFG$memorias$dir, "*.pdf")),
    how   = c("abrir el egreso de red a www.gob.pe (MINEM/Osinergmin) y re-correr `Rscript run_all.R`",
              "o descargar a mano el Anuario Estadístico de Electricidad a data/raw/minem_anuario_01.xlsx",
              "o colocar las Memorias Anuales ELDU en data/raw/pdf/ y revisar los candidatos de 04",
              sprintf("o escribir a mano la serie verificada en %s con columnas: %s",
                      CFG$eldu$manual_csv, paste(CFG$eldu$required_cols, collapse = ",")))
  )
}

## Normaliza el esquema: las vías 3b/3c no traen todas las columnas.
for (cc in c("clientes", "energia_robustez_gwh")) {
  if (!cc %in% names(energy)) energy[[cc]] <- NA_real_
}
energy <- energy %>%
  select(year, energia_gwh, clientes, energia_robustez_gwh) %>%
  filter(!is.na(year), !is.na(energia_gwh)) %>%
  arrange(year) %>% distinct(year, .keep_all = TRUE)
PROV$energia_gwh <- sprintf("Energía ELDU (GWh/año) — %s", energy_src)

## ---- Validación de plausibilidad (guarda contra extracciones corruptas) ----
V <- CFG$validate_energy
problems <- character(0)
if (nrow(energy) < V$min_obs)
  problems <- c(problems, sprintf("sólo %d observaciones (mínimo %d)", nrow(energy), V$min_obs))
if (any(energy$energia_gwh < V$min_gwh | energy$energia_gwh > V$max_gwh))
  problems <- c(problems, sprintf("valores fuera del rango plausible [%s, %s] GWh: %s",
                                  V$min_gwh, V$max_gwh,
                                  paste(energy$energia_gwh[energy$energia_gwh < V$min_gwh |
                                                           energy$energia_gwh > V$max_gwh],
                                        collapse = ", ")))
g <- diff(log(energy$energia_gwh))
if (length(g) && any(abs(g) > log(1 + V$max_abs_growth)))
  problems <- c(problems,
                sprintf("salto(s) interanual(es) implausible(s) (> %.0f%%) en %s — señal clásica de extracción mal alineada",
                        100 * V$max_abs_growth,
                        paste(energy$year[which(abs(g) > log(1 + V$max_abs_growth)) + 1],
                              collapse = ", ")))
if (length(problems)) {
  log_event(STAGE, "BLOCKED",
            paste("la serie de energía NO pasó validación:", paste(problems, collapse = " ; ")))
  stop(sprintf(paste0("\n=== SERIE DE ENERGÍA RECHAZADA (fuente: %s) ===\n%s\n",
                      "El pipeline NO continúa con una serie dudosa. Revise la extracción\n",
                      "o provea la serie verificada en %s.\n"),
               energy_src, paste0("  - ", problems, collapse = "\n"), CFG$eldu$manual_csv),
       call. = FALSE)
}
log_event(STAGE, "OK", sprintf("serie de energía validada: %d años (%d-%d), %.1f-%.1f GWh",
                               nrow(energy), min(energy$year), max(energy$year),
                               min(energy$energia_gwh), max(energy$energia_gwh)))

## ---------------------------------------------------------------------------
## 4) Clima (opcional)
## ---------------------------------------------------------------------------
enso <- NULL
oni_p <- file.path(raw_dir, "noaa_oni.ascii.txt")
if (file.exists(oni_p)) {
  o <- tryCatch(utils::read.table(oni_p, header = TRUE, stringsAsFactors = FALSE),
                error = function(e) NULL)
  if (!is.null(o) && all(c("YR", "MON") %in% toupper(names(o)))) {
    names(o) <- toupper(names(o))
    anom_col <- intersect(c("ANOM", "ANOM.3"), names(o))[1]
    if (!is.na(anom_col)) {
      enso <- o %>%
        mutate(year = ifelse(MON == 12L, YR + 1L, YR)) %>%   # DJF pertenece al verano siguiente
        filter(MON %in% CFG$noaa$austral_summer_months) %>%
        group_by(year) %>% summarise(oni_verano = mean(.data[[anom_col]], na.rm = TRUE),
                                     .groups = "drop")
      PROV$oni_verano <- sprintf("NOAA CPC ONI — promedio de los meses %s (verano austral)",
                                 paste(CFG$noaa$austral_summer_months, collapse = ","))
      log_event(STAGE, "OK", sprintf("ONI anualizado: %d años", nrow(enso)))
    }
  }
  if (is.null(enso)) log_event(STAGE, "WARN", "archivo ONI presente pero con formato inesperado")
} else {
  log_event(STAGE, "WARN", "sin índice ENSO — el panel no tendrá variable de clima")
}

## ---------------------------------------------------------------------------
## 5) Ensamblado del panel
## ---------------------------------------------------------------------------
panel <- energy %>%
  inner_join(income %>% select(year, pbi = value), by = "year")

## Controles y driver alternativo: entran al panel como columnas, pero NO a la
## regresión. Con n cercano a 8, añadir IPC y tipo de cambio como regresores
## sería sobre-ajustar; además la energía es física y el VAB entra real, así que
## no hay nada que deflactar. Quedan disponibles para inspección y para el
## pipeline mensual futuro.
for (k in setdiff(names(bcrp), c("pbi_real"))) {
  if (identical(k, "pbi_nacional_yoy") && isTRUE(income_is_proxy)) next  # ya es el ingreso
  panel <- panel %>%
    left_join(bcrp[[k]] %>% select(year, !!k := value), by = "year")
}
if (!is.null(enso))
  panel <- panel %>% left_join(enso, by = "year")

panel <- panel %>% arrange(year) %>%
  mutate(ln_q = log(energia_gwh), ln_y = log(pbi), t = year - min(year) + 1L,
         ## Energía por cliente: separa el crecimiento por CONEXIONES del
         ## crecimiento del consumo de cada conexión. Sin esta separación, el
         ## crecimiento de clientes se cuela dentro de la elasticidad-ingreso.
         energia_por_cliente_mwh = ifelse(is.na(clientes), NA_real_,
                                          1000 * energia_gwh / clientes),
         ln_qc = ifelse(is.na(clientes), NA_real_, log(energia_gwh / clientes)),
         ln_cl = ifelse(is.na(clientes), NA_real_, log(clientes)))

## El solapamiento manda: sólo años con energía Y ingreso.
assert_no_silent_imputation(panel, c("year", "energia_gwh", "pbi", "ln_q", "ln_y"), "panel")

if (nrow(panel) < CFG$validate_energy$min_obs) {
  stop_missing(
    what  = sprintf("solapamiento suficiente energía×ingreso (hay %d años, mínimo %d)",
                    nrow(panel), CFG$validate_energy$min_obs),
    where = "intersección de la serie de energía y la de PBI",
    how   = c("extender la serie de energía hacia atrás con el Anuario MINEM (serie larga ~2000-2024)",
              "verificar que los años de ambas series coincidan en data/raw/")
  )
}

## Nota: la energía es una magnitud FÍSICA (GWh) y el PBI entra como índice de
## volumen real, así que ninguna de las dos se deflacta. El IPC queda en el
## panel sólo como control/deflactor para cualquier variable nominal futura.

save_rds(panel, file.path(CFG$paths$processed, "panel_anual.rds"))
readr::write_csv(panel, here::here(CFG$paths$processed, "panel_anual.csv"))
have_clients <- all(!is.na(panel$clientes))
log_event(STAGE, if (have_clients) "OK" else "WARN",
          sprintf("clientes %s -> especificación por cliente %s",
                  if (have_clients) "completos" else "incompletos",
                  if (have_clients) "disponible" else "NO disponible"))

save_rds(list(provenance = PROV,
              income_is_proxy = income_is_proxy,
              energy_src = energy_src,
              energy_var = CFG$eldu$memorias_variable,
              have_clients = have_clients,
              have_robustness = any(!is.na(panel$energia_robustez_gwh)),
              n = nrow(panel),
              years = range(panel$year)),
         file.path(CFG$paths$processed, "panel_meta.rds"))

## ---- Gráficos descriptivos ------------------------------------------------
fig_dir <- here::here(CFG$paths$figures)
p1 <- ggplot(panel, aes(year, energia_gwh)) +
  geom_line(linewidth = .7) + geom_point(size = 1.6) +
  labs(title = "Electro Dunas — energía anual",
       subtitle = PROV$energia_gwh, x = NULL, y = "GWh") +
  theme_minimal(base_size = 11)
ggsave(file.path(fig_dir, "01_energia_eldu.png"), p1, width = 7, height = 4, dpi = 150)

p2 <- ggplot(panel, aes(ln_y, ln_q)) +
  geom_point(size = 2) + geom_smooth(method = "lm", se = TRUE, formula = y ~ x) +
  labs(title = "ln(energía) vs ln(PBI)",
       subtitle = sprintf("n = %d años (%d-%d)%s", nrow(panel),
                          min(panel$year), max(panel$year),
                          if (isTRUE(income_is_proxy)) " — PBI nacional como PROXY" else ""),
       x = "ln(PBI)", y = "ln(energía)") +
  theme_minimal(base_size = 11)
ggsave(file.path(fig_dir, "02_dispersion_log.png"), p2, width = 6, height = 4.2, dpi = 150)

log_event(STAGE, "OK", sprintf("panel construido: n=%d (%d-%d); columnas: %s",
                               nrow(panel), min(panel$year), max(panel$year),
                               paste(names(panel), collapse = ", ")))
log_event(STAGE, "INFO", "fin")
