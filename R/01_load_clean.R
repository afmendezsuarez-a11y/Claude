# ============================================================================
# 01_load_clean.R — Carga, validacion y construccion del panel mensual
#
# Entradas : <data_dir>/eldu_demanda.xlsx  (o .csv)
# Salidas  : data/processed/panel.rds, data/processed/panel.csv
#            output/00_data_check.html
#
# Reglas aplicadas (contrato de datos):
#   - tarifa_real_k = tarifa_k / (ipc/100)
#   - q_k           = mwh_k / cli_k            (consumo unitario, MWh/cliente)
#   - logs naturales de energia, clientes, consumo unitario, actividad y
#     tarifa real
#   - 11 dummies estacionales (feb..dic; enero = base)
#   - dummy COVID (config: 2020-03 a 2020-12)
# ============================================================================

source(here::here("R", "00_utils.R"))
suppressPackageStartupMessages({library(zoo); library(tempdisagg)})

cfg <- load_config()
set_project_seed(cfg)
ensure_dirs(cfg)
msg_step("01_load_clean: inicio")

# ---------------------------------------------------------------------------
# 1. Localizar y leer el archivo de demanda
# ---------------------------------------------------------------------------
base_name <- cfg$paths$archivo_demanda
cands <- c(cfg_path(cfg, "data", paste0(base_name, ".xlsx")),
           cfg_path(cfg, "data", paste0(base_name, ".xls")),
           cfg_path(cfg, "data", paste0(base_name, ".csv")))
found <- cands[file.exists(cands)]

if (length(found) == 0) {
  stop_user(
    "No se encuentra el archivo de demanda",
    paste0("Se busco (en este orden):\n  - ",
           paste(sub(here::here(), ".", cands, fixed = TRUE), collapse = "\n  - "),
           "\n\nEl pipeline NO genera ni simula datos."),
    paste0("Colocar el archivo con los datos reales en ",
           cfg$paths$data_dir, "/.\n",
           "La plantilla con el esquema exacto esta en ",
           "data/raw/PLANTILLA_eldu_demanda.csv.\n",
           "Para una corrida de humo del pipeline con datos SINTETICOS:\n",
           "  Rscript R/99_make_demo_data.R && ELDU_DATA_DIR=data/demo Rscript run_all.R")
  )
}
src <- found[1]
msg_step("  insumo: ", sub(here::here(), ".", src, fixed = TRUE))

raw <- if (grepl("\\.xlsx?$", src)) {
  suppressWarnings(readxl::read_excel(src, guess_max = 10000))
} else {
  readr::read_csv(src, show_col_types = FALSE, guess_max = 10000)
}
raw <- as.data.frame(raw)
names(raw) <- tolower(trimws(names(raw)))

# fecha -> Date (acepta Date, POSIXct o texto YYYY-MM-DD / YYYY-MM)
if (!"fecha" %in% names(raw)) {
  stop_user("El archivo no tiene columna 'fecha'",
            paste("Columnas encontradas:", paste(names(raw), collapse = ", ")),
            "Renombrar la columna de periodo a 'fecha' (YYYY-MM-01).")
}
parse_fecha <- function(x) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXct")) return(as.Date(x))
  s <- trimws(as.character(x))
  s <- ifelse(grepl("^\\d{4}-\\d{2}$", s), paste0(s, "-01"), s)
  suppressWarnings(as.Date(s))
}
raw$fecha <- parse_fecha(raw$fecha)
raw$fecha <- as.Date(format(raw$fecha, "%Y-%m-01"))

# ---------------------------------------------------------------------------
# 2. Validar el contrato de datos (se detiene con mensaje si algo falta)
# ---------------------------------------------------------------------------
val <- validate_schema(raw, cfg)
df <- val$df
hz <- val$hallazgos
msg_step("  esquema OK | n=", hz$n_obs, " meses | ", hz$rango)
if (length(hz$opcionales_ausentes) > 0) {
  msg_warn("series opcionales ausentes: ",
           paste(hz$opcionales_ausentes, collapse = ", "))
}

# ---------------------------------------------------------------------------
# 3. Actividad regional: interpolacion explicita si viene en baja frecuencia
# ---------------------------------------------------------------------------
act <- cfg$transformaciones$actividad
itp <- interpolar_actividad(df$fecha, df[[act]],
                            metodo = cfg$transformaciones$metodo_interpolacion)
df[[act]] <- itp$x
df$pbi_interp <- as.integer(itp$interp)
if (any(itp$interp)) {
  msg_warn("actividad '", act, "': ", sum(itp$interp),
           " de ", nrow(df), " meses interpolados (metodo: ", itp$metodo,
           "). Marcados en la bandera 'pbi_interp'.")
}
if (all(is.na(df[[act]]))) {
  stop_user("La serie de actividad quedo vacia tras la interpolacion", NULL,
            paste0("Revisar la columna '", act, "' en el insumo."))
}
# Misma interpolacion para la actividad alternativa, si existe.
act_alt <- cfg$transformaciones$actividad_alternativa
if (!is.null(act_alt) && act_alt %in% names(df)) {
  itp_alt <- interpolar_actividad(df$fecha, df[[act_alt]],
                                  metodo = cfg$transformaciones$metodo_interpolacion)
  df[[act_alt]] <- itp_alt$x
  df$vab_agro_interp <- as.integer(itp_alt$interp)
}

# ---------------------------------------------------------------------------
# 4. Transformaciones: deflactar, consumo unitario, logaritmos
# ---------------------------------------------------------------------------
segs <- cfg$segmentos
deflactor <- df$ipc / 100

for (i in seq_len(nrow(segs))) {
  s <- segs[i, ]
  id <- s$id
  df[[paste0("tarifa_real_", id)]] <- df[[s$tarifa]] / deflactor
  # q = MWh por cliente; NA si no hay clientes (segmento aun inexistente)
  df[[paste0("q_", id)]] <- ifelse(df[[s$clientes]] > 0,
                                   df[[s$mwh]] / df[[s$clientes]], NA_real_)
  df[[paste0("ln_mwh_", id)]]        <- ln(df[[s$mwh]])
  df[[paste0("ln_cli_", id)]]        <- ln(df[[s$clientes]])
  df[[paste0("ln_q_", id)]]          <- ln(df[[paste0("q_", id)]])
  df[[paste0("ln_ptilde_", id)]]     <- ln(df[[paste0("tarifa_real_", id)]])
}

df$ln_act <- ln(df[[act]])
names(df)[names(df) == "ln_act"] <- paste0("ln_", act)
if (!is.null(act_alt) && act_alt %in% names(df)) {
  df[[paste0("ln_", act_alt)]] <- ln(df[[act_alt]])
}
if ("vab_manuf_ica" %in% names(df)) df$ln_vab_manuf_ica <- ln(df$vab_manuf_ica)
if ("max_dem_kw" %in% names(df))    df$ln_max_dem_kw    <- ln(df$max_dem_kw)

# Energia total y factor de carga (informativo)
df$mwh_total <- rowSums(df[segs$mwh], na.rm = TRUE)
if ("max_dem_kw" %in% names(df)) {
  horas <- lubridate::days_in_month(df$fecha) * 24
  df$factor_carga <- (df$mwh_total * 1000) / (df$max_dem_kw * horas)
}

# ENSO: opcional. Si no viene, se excluye de los exogenos (no se imputa 0).
if (!"nino34" %in% names(df)) {
  msg_warn("no se encontro 'nino34': ENSO queda FUERA de los modelos ",
           "(no se imputa ningun valor).")
} else if (any(is.na(df$nino34))) {
  msg_warn("'nino34' tiene ", sum(is.na(df$nino34)),
           " valores faltantes; esos meses se excluiran de las regresiones ",
           "que usen ENSO.")
}

# ---------------------------------------------------------------------------
# 5. Dummies estacionales y COVID
# ---------------------------------------------------------------------------
if (isTRUE(cfg$transformaciones$dummies_estacionales)) {
  df <- dplyr::bind_cols(df, seasonal_dummies(df$fecha))
}
cov_ini <- as.Date(cfg$transformaciones$covid_inicio)
cov_fin <- as.Date(cfg$transformaciones$covid_fin)
df$d_covid <- as.numeric(df$fecha >= cov_ini & df$fecha <= cov_fin)
msg_step("  dummy COVID: ", sum(df$d_covid), " meses (",
         format(cov_ini), " a ", format(cov_fin), ")")

# ---------------------------------------------------------------------------
# 6. Muestra efectiva por segmento (primer mes con energia y clientes > 0)
# ---------------------------------------------------------------------------
muestras <- purrr::map_dfr(seq_len(nrow(segs)), function(i) {
  s <- segs[i, ]
  ok <- !is.na(df[[paste0("ln_q_", s$id)]])
  tibble::tibble(
    segmento = s$id, label = s$label,
    inicio = if (any(ok)) format(min(df$fecha[ok])) else NA_character_,
    fin    = if (any(ok)) format(max(df$fecha[ok])) else NA_character_,
    n_obs  = sum(ok),
    n_huecos_internos = if (any(ok))
      sum(!ok & df$fecha > min(df$fecha[ok]) & df$fecha < max(df$fecha[ok])) else NA_integer_)
})
print(as.data.frame(muestras))
if (any(muestras$n_obs < 36, na.rm = TRUE)) {
  cortos <- muestras$segmento[muestras$n_obs < 36]
  msg_warn("segmentos con menos de 36 observaciones utiles (",
           paste(cortos, collapse = ", "),
           "): las elasticidades de largo plazo seran poco precisas.")
}
if (any(muestras$n_huecos_internos > 0, na.rm = TRUE)) {
  stop_user("Hay huecos internos en energia/clientes de algun segmento",
            paste(capture.output(print(as.data.frame(muestras))), collapse = "\n"),
            "Completar los meses con valor cero o faltante dentro del rango activo.")
}

# ---------------------------------------------------------------------------
# 7. Guardar panel y metadatos
# ---------------------------------------------------------------------------
panel <- list(
  data = tibble::as_tibble(df),
  cfg = cfg,
  segmentos = segs,
  actividad = act,
  muestras = muestras,
  interpolacion = list(variable = act, metodo = itp$metodo,
                       n_interp = sum(itp$interp)),
  exogenos = intersect(cfg$ardl$exogenos, names(df)),
  dummies_estacionales = intersect(sprintf("m%02d", 2:12), names(df)),
  fuente = sub(here::here(), ".", src, fixed = TRUE),
  creado = Sys.time()
)
saveRDS(panel, cfg_path(cfg, "processed", "panel.rds"))
readr::write_csv(panel$data, cfg_path(cfg, "processed", "panel.csv"), na = "")
msg_step("  -> data/processed/panel.rds (+ .csv)")

# ---------------------------------------------------------------------------
# 8. Reporte de validacion (HTML autocontenido, sin pandoc)
# ---------------------------------------------------------------------------
resumen <- df %>%
  dplyr::select(dplyr::any_of(c(segs$mwh, segs$clientes, segs$tarifa,
                                paste0("tarifa_real_", segs$id),
                                paste0("q_", segs$id), act, "ipc", "nino34",
                                "max_dem_kw"))) %>%
  tidyr::pivot_longer(dplyr::everything(), names_to = "variable",
                      values_to = "v") %>%
  dplyr::group_by(variable) %>%
  dplyr::summarise(n = sum(!is.na(v)), n_na = sum(is.na(v)),
                   min = min(v, na.rm = TRUE), p50 = stats::median(v, na.rm = TRUE),
                   media = mean(v, na.rm = TRUE), max = max(v, na.rm = TRUE),
                   .groups = "drop")

bloques <- c(
  "<h2>1. Insumo y cobertura</h2>",
  html_table(tibble::tibble(
    campo = c("archivo", "observaciones", "rango", "actividad usada",
              "meses interpolados (actividad)", "metodo de interpolacion",
              "exogenos activos", "dummies estacionales",
              "opcionales presentes", "opcionales ausentes", "semilla"),
    valor = c(panel$fuente, as.character(hz$n_obs), hz$rango, act,
              as.character(panel$interpolacion$n_interp),
              panel$interpolacion$metodo,
              paste(panel$exogenos, collapse = ", "),
              as.character(length(panel$dummies_estacionales)),
              paste(hz$opcionales_presentes, collapse = ", "),
              paste(hz$opcionales_ausentes, collapse = ", "),
              as.character(cfg$project$seed)))),
  "<h2>2. Chequeos bloqueantes superados</h2>",
  "<ul>",
  "<li class='ok'>Una fila por mes, sin duplicados</li>",
  "<li class='ok'>Serie mensual continua, sin huecos</li>",
  "<li class='ok'>Todas las columnas obligatorias presentes y numericas</li>",
  "<li class='ok'>Tarifas, IPC y actividad estrictamente positivos</li>",
  "<li class='ok'>Sin valores faltantes en energia, clientes, tarifas ni IPC</li>",
  "</ul>",
  "<h2>3. Muestra efectiva por segmento</h2>",
  html_table(muestras),
  "<h2>4. Descriptivos de las series de entrada</h2>",
  html_table(resumen, digits = 5),
  "<h2>5. Positividad / faltantes por serie logaritmada</h2>",
  html_table(hz$positividad),
  "<h2>6. Energia y clientes</h2>",
  html_table(hz$energia_clientes),
  "<h2>7. Transformaciones aplicadas</h2>",
  "<pre>",
  paste0("tarifa_real_k = tarifa_k / (ipc/100)\n",
         "q_k           = mwh_k / cli_k\n",
         "ln_*          = log natural\n",
         "dummies       = m02..m12 (enero base) + d_covid [",
         format(cov_ini), " .. ", format(cov_fin), "]"),
  "</pre>")

write_simple_html("ELDU — Reporte de validacion de datos (01_load_clean)",
                  bloques, cfg_path(cfg, "output", "00_data_check.html"))
msg_step("  -> output/00_data_check.html")
msg_step("01_load_clean: fin")
