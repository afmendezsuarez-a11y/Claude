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

## ---------------------------------------------------------------------------
## 2) Ingreso: PBI de Ica (preferido) o PBI nacional (PROXY, se marca)
## ---------------------------------------------------------------------------
income_is_proxy <- NA
income <- NULL

inei_files <- list.files(raw_dir, pattern = "(?i)^inei_pbi_departamental.*\\.(xlsx|xls)$",
                         full.names = TRUE)
if (length(inei_files)) {
  ## Busca en todas las hojas una fila cuyo rótulo calce con la región y una
  ## fila de encabezado con años. Deja traza de lo extraído.
  extract_region_row <- function(f, region_regex) {
    sheets <- tryCatch(readxl::excel_sheets(f), error = function(e) character(0))
    for (sh in sheets) {
      m <- tryCatch(suppressMessages(readxl::read_excel(f, sheet = sh, col_names = FALSE)),
                    error = function(e) NULL)
      if (is.null(m) || !nrow(m)) next
      M <- as.data.frame(lapply(m, as.character), stringsAsFactors = FALSE)
      row_hit <- which(apply(M, 1, function(r) any(grepl(region_regex, r, perl = TRUE), na.rm = TRUE)))
      yr_row  <- which(apply(M, 1, function(r) sum(grepl("^\\s*(19|20)\\d{2}\\s*$", r)) >= 5))
      if (length(row_hit) && length(yr_row)) {
        yr_r <- yr_row[1]; dat_r <- row_hit[1]
        yrs  <- suppressWarnings(as.integer(M[yr_r, ]))
        vals <- suppressWarnings(as.numeric(gsub("[^0-9.,-]", "",
                                 gsub(",", "", M[dat_r, ], fixed = TRUE))))
        keep <- !is.na(yrs) & !is.na(vals)
        if (sum(keep) >= 5) {
          return(list(data = data.frame(year = yrs[keep], value = vals[keep]),
                      trace = sprintf("archivo=%s; hoja=%s; fila_anios=%d; fila_region=%d",
                                      basename(f), sh, yr_r, dat_r)))
        }
      }
    }
    NULL
  }
  for (f in inei_files) {
    got <- tryCatch(extract_region_row(f, sprintf("(?i)%s", CFG$inei$region)),
                    error = function(e) NULL)
    if (!is.null(got)) {
      income <- got$data %>% group_by(year) %>%
        summarise(value = mean(value), n_obs = n(), .groups = "drop")
      income_is_proxy <- FALSE
      PROV$income <- sprintf("INEI — VAB real de %s (%s)", CFG$inei$region, got$trace)
      log_event(STAGE, "OK", sprintf("ingreso = PBI de %s; %s", CFG$inei$region, got$trace))
      break
    }
  }
  if (is.null(income)) log_event(STAGE, "WARN",
    "los archivos INEI están presentes pero no se pudo localizar la fila de Ica con años")
}

if (is.null(income) && !is.null(bcrp$pbi_real)) {
  income <- bcrp$pbi_real
  income_is_proxy <- TRUE
  PROV$income <- paste0(PROV$bcrp_pbi_real,
                        "  ** USADO COMO PROXY del PBI de Ica (el PBI departamental del INEI no se pudo obtener) **")
  log_event(STAGE, "WARN",
            "ingreso = PBI NACIONAL del BCRP usado como PROXY del PBI de Ica (se marca en el informe)")
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
    energy <- e %>% transmute(year = as.integer(year),
                              energia_gwh = as.numeric(energia_gwh),
                              clientes = if ("clientes" %in% names(e)) as.numeric(clientes) else NA_real_)
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

energy <- energy %>% filter(!is.na(year), !is.na(energia_gwh)) %>%
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

if (!is.null(bcrp$ipc))
  panel <- panel %>% left_join(bcrp$ipc %>% select(year, ipc = value), by = "year")
if (!is.null(bcrp$tc))
  panel <- panel %>% left_join(bcrp$tc %>% select(year, tc = value), by = "year")
if (!is.null(enso))
  panel <- panel %>% left_join(enso, by = "year")

panel <- panel %>% arrange(year) %>%
  mutate(ln_q = log(energia_gwh), ln_y = log(pbi), t = year - min(year) + 1L)

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
save_rds(list(provenance = PROV,
              income_is_proxy = income_is_proxy,
              energy_src = energy_src,
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
