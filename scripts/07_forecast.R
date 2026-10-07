## ============================================================================
## 07_forecast.R — Proyección de volúmenes por escenario hasta FY2035.
## ----------------------------------------------------------------------------
## Regla PRINCIPAL (dos términos, acorde al modelo de 06):
##     Q_{t+1} = Q_t * (1 + g_clientes) * (1 + eta_pc * g_ingreso)
## donde eta_pc es la elasticidad-ingreso del consumo POR CLIENTE y g_clientes
## es un supuesto explícito (no se estima contra el PBI porque no responde a él).
##
## Se calculan además, para que el comité vea la diferencia:
##   - "una_elasticidad"  : Q_t*(1+eta*g), la regla original, SIN término de
##                          clientes -> subestima si las conexiones crecen.
##   - "supuesto_dcf"     : Q_t*(1+0.85*g) con el 0.8/0.9 vigente.
## Las bandas vienen del intervalo de eta, no de un supuesto.
## ============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(readr); library(writexl); library(here)
  library(ggplot2)
})

STAGE <- "07_forecast"
log_event(STAGE, "INFO", "inicio — proyección de volúmenes")

panel <- readRDS(here::here(CFG$paths$processed, "panel_anual.rds"))
RES   <- readRDS(here::here(CFG$paths$processed, "estimacion.rds"))

q0_year <- max(panel$year)
q0      <- panel$energia_gwh[panel$year == q0_year]
horizon <- seq(q0_year + 1L, CFG$fy_horizon)
if (!length(horizon))
  log_event(STAGE, "WARN", sprintf("el último año observado (%d) ya alcanza el horizonte (%d)",
                                   q0_year, CFG$fy_horizon))

## ---- Escenarios de crecimiento del ingreso --------------------------------
esc_path <- here::here(CFG$escenarios$path)
esc_is_assumption <- FALSE
if (file.exists(esc_path)) {
  esc <- suppressMessages(readr::read_csv(esc_path, show_col_types = FALSE))
  need <- c("escenario", "year", "g_pbi")
  if (!all(need %in% names(esc)))
    stop(sprintf("%s debe tener las columnas: %s (tiene: %s)", CFG$escenarios$path,
                 paste(need, collapse = ","), paste(names(esc), collapse = ",")), call. = FALSE)
  esc <- esc %>% mutate(year = as.integer(year), g_pbi = as.numeric(g_pbi)) %>%
    filter(year %in% horizon)
  esc_src <- sprintf("%s (provisto por el usuario)", CFG$escenarios$path)
  log_event(STAGE, "OK", sprintf("escenarios leídos de %s (%d escenarios)",
                                 CFG$escenarios$path, dplyr::n_distinct(esc$escenario)))
} else {
  esc_is_assumption <- TRUE
  esc <- tidyr::expand_grid(escenario = names(CFG$escenarios$defaults), year = horizon) %>%
    mutate(g_pbi = unname(CFG$escenarios$defaults[escenario]))
  esc_src <- sprintf("SUPUESTO (no se proveyó %s): %s", CFG$escenarios$path,
                     paste(sprintf("%s=%.1f%%", names(CFG$escenarios$defaults),
                                   100 * CFG$escenarios$defaults), collapse = ", "))
  log_event(STAGE, "WARN", paste("escenarios por defecto —", esc_src))
}

## ---- Crecimiento de clientes: supuesto explícito --------------------------
TWO_TERM <- identical(RES$eta_used$applies_to, "energia_por_cliente") &&
            is.finite(RES$decomp$g_clientes)
g_cl_base <- if (!is.null(CFG$clientes$g_override)) {
  CFG$clientes$g_override
} else if (identical(CFG$clientes$g_source, "escenarios") && "g_clientes" %in% names(esc)) {
  NA_real_          # viene por año desde el CSV
} else {
  RES$decomp$g_clientes
}
if ("g_clientes" %in% names(esc)) {
  esc$g_cl <- as.numeric(esc$g_clientes)
  g_cl_src <- sprintf("%s (columna g_clientes)", CFG$escenarios$path)
} else {
  ## Opcional: convergencia lineal desde la tasa histórica hacia taper_to.
  k <- match(esc$year, sort(unique(esc$year)))
  if (!is.null(CFG$clientes$taper_to) && !is.null(CFG$clientes$taper_years)) {
    w <- pmin(1, k / CFG$clientes$taper_years)
    esc$g_cl <- (1 - w) * g_cl_base + w * CFG$clientes$taper_to
    g_cl_src <- sprintf("SUPUESTO: %.2f%%/año histórico convergiendo a %.2f%%/año en %d años",
                        100 * g_cl_base, 100 * CFG$clientes$taper_to, CFG$clientes$taper_years)
  } else {
    esc$g_cl <- g_cl_base
    g_cl_src <- sprintf("SUPUESTO: se sostiene el CAGR histórico de clientes, %.2f%%/año (%d-%d)",
                        100 * g_cl_base, RES$years[1], RES$years[2])
  }
}
if (TWO_TERM) {
  log_event(STAGE, "OK", paste("crecimiento de clientes —", g_cl_src))
  log_event(STAGE, "WARN",
            "sostener el crecimiento de clientes hasta el horizonte es el supuesto MÁS FUERTE de la proyección: es decisión del comité, no del modelo")
} else {
  log_event(STAGE, "WARN",
            "sin clientes completos: se proyecta con una sola elasticidad sobre la energía total")
}

## ---- Proyección ------------------------------------------------------------
#' Q_{t+1} = Q_t * (1 + g_cl) * (1 + eta * g_y) ; con g_cl = 0 es la regla simple.
project <- function(g_y, g_cl, eta, q_start) {
  q <- numeric(length(g_y)); prev <- q_start
  for (i in seq_along(g_y)) {
    prev <- prev * (1 + g_cl[i]) * (1 + eta * g_y[i])
    q[i] <- prev
  }
  q
}

eta_c <- RES$eta_used$point
eta_l <- RES$eta_used$low
eta_h <- RES$eta_used$high
dcf   <- mean(CFG$dcf_benchmark)

fc <- esc %>% arrange(escenario, year) %>% group_by(escenario) %>%
  group_modify(~{
    g <- .x$g_pbi; gc <- if (TWO_TERM) .x$g_cl else rep(0, nrow(.x))
    tibble::tibble(
      year = .x$year, g_pbi = g, g_clientes = gc,
      gwh_central = project(g, gc, eta_c, q0),
      gwh_low     = project(g, gc, eta_l, q0),
      gwh_high    = project(g, gc, eta_h, q0),
      ## comparaciones metodológicas (no son escenarios de negocio)
      gwh_una_elasticidad = project(g, rep(0, length(g)), eta_c, q0),
      gwh_supuesto_dcf    = project(g, rep(0, length(g)), dcf,   q0))
  }) %>% ungroup()

if (RES$eta_used$low < 0)
  log_event(STAGE, "WARN",
            "el intervalo de eta incluye valores negativos: la banda inferior proyecta caída del consumo por cliente (la data no descarta eta<=0)")

hist <- panel %>% transmute(escenario = "historico", year, g_pbi = NA_real_,
                            g_clientes = NA_real_, gwh_central = energia_gwh,
                            gwh_low = energia_gwh, gwh_high = energia_gwh)
readr::write_csv(fc, here::here(CFG$paths$tables, "forecast_volumenes.csv"))

## CAGR implícito de cada regla, que es lo que el comité compara
cagr_of <- function(x) 100 * ((utils::tail(x, 1) / q0)^(1 / length(x)) - 1)
base <- fc %>% filter(escenario == names(CFG$escenarios$defaults)[1] |
                      escenario == "base") %>% arrange(year)
comp <- if (nrow(base)) tibble::tibble(
  regla = c("dos terminos (clientes + eta por cliente)",
            "una sola elasticidad, sin clientes",
            sprintf("supuesto DCF vigente (%.2f)", dcf),
            "observado historico"),
  cagr_pct = c(cagr_of(base$gwh_central), cagr_of(base$gwh_una_elasticidad),
               cagr_of(base$gwh_supuesto_dcf), 100 * RES$decomp$g_energia),
  gwh_2035 = c(utils::tail(base$gwh_central, 1), utils::tail(base$gwh_una_elasticidad, 1),
               utils::tail(base$gwh_supuesto_dcf, 1), NA_real_)) else NULL
if (!is.null(comp)) {
  readr::write_csv(comp, here::here(CFG$paths$tables, "comparacion_reglas.csv"))
  log_event(STAGE, "OK", sprintf("comparación de reglas (escenario base, CAGR %%/año): %s",
                                 paste(sprintf("%s=%.2f", comp$regla, comp$cagr_pct),
                                       collapse = " | ")))
}

## ---- Reparto por segmento (sólo con pesos provistos) ----------------------
seg_sheet <- NULL
if (!is.null(CFG$segment_weights)) {
  w <- CFG$segment_weights
  if (abs(sum(w) - 1) > 1e-6)
    stop(sprintf("CFG$segment_weights debe sumar 1 (suma %.4f)", sum(w)), call. = FALSE)
  seg_sheet <- fc %>% tidyr::crossing(segmento = names(w)) %>%
    mutate(peso = unname(w[segmento]),
           gwh_central = gwh_central * peso, gwh_low = gwh_low * peso,
           gwh_high = gwh_high * peso) %>%
    arrange(escenario, segmento, year)
  log_event(STAGE, "OK", sprintf("reparto por segmento con pesos provistos: %s",
                                 paste(sprintf("%s=%.1f%%", names(w), 100 * w), collapse = ", ")))
} else {
  log_event(STAGE, "INFO",
            "sin reparto por segmento: CFG$segment_weights es NULL. No se inventan pesos BT/MT/libres.")
}

## ---- Hoja de supuestos -----------------------------------------------------
supuestos <- tibble::tibble(
  concepto = c("modelo", "eta (central)", "eta banda baja", "eta banda alta",
               "eta se aplica a", "metodo de eta", "eta se reporta como",
               "motivo de la regla de prudencia",
               "crecimiento de clientes", "Q base (GWh)", "anio base", "horizonte",
               "fuente de escenarios de ingreso", "driver de ingreso",
               "ingreso es proxy nacional", "variable de volumen",
               "reparto por segmento", "supuesto DCF vigente (BT)",
               "supuesto DCF vigente (MT)", "n observaciones", "regla de proyeccion"),
  valor = c(
    if (TWO_TERM) "dos terminos: clientes + elasticidad-ingreso por cliente"
      else "una elasticidad sobre energia total",
    sprintf("%.4f", eta_c), sprintf("%.4f", eta_l), sprintf("%.4f", eta_h),
    RES$eta_used$applies_to, RES$eta_used$source,
    if (isTRUE(RES$eta_used$as_range)) "RANGO" else "punto con IC95",
    RES$prudence$reason,
    if (TWO_TERM) g_cl_src else "no aplicado",
    sprintf("%.1f", q0), as.character(q0_year), sprintf("FY%d", CFG$fy_horizon),
    esc_src,
    RES$meta$provenance$income %||% "n/d",
    if (isTRUE(RES$meta$income_is_proxy)) "SI — PBI nacional como proxy" else "No",
    RES$meta$energy_var %||% "n/d",
    if (is.null(CFG$segment_weights)) "no aplicado (pesos no provistos; no se inventan)"
      else paste(sprintf("%s=%.1f%%", names(CFG$segment_weights),
                         100 * CFG$segment_weights), collapse = ", "),
    sprintf("%.2f", CFG$dcf_benchmark[["BT"]]), sprintf("%.2f", CFG$dcf_benchmark[["MT"]]),
    as.character(RES$n),
    if (TWO_TERM) "Q_{t+1} = Q_t * (1 + g_clientes) * (1 + eta * g_ingreso)"
      else "Q_{t+1} = Q_t * (1 + eta * g_ingreso)"))

sheets <- list(supuestos = supuestos, historico = hist, proyeccion = fc)
if (!is.null(comp)) sheets$comparacion_reglas <- comp
if (!is.null(seg_sheet)) sheets$proyeccion_por_segmento <- seg_sheet
writexl::write_xlsx(sheets, here::here(CFG$paths$output, "forecast_volumenes.xlsx"))
log_event(STAGE, "OK", sprintf("escrito output/forecast_volumenes.xlsx (%d hojas)", length(sheets)))

## ---- Gráficos --------------------------------------------------------------
plt <- dplyr::bind_rows(hist %>% mutate(tipo = "histórico"),
                        fc %>% mutate(tipo = "proyección"))
p <- ggplot(plt, aes(year, gwh_central, colour = escenario)) +
  geom_ribbon(data = dplyr::filter(plt, tipo == "proyección"),
              aes(ymin = gwh_low, ymax = gwh_high, fill = escenario),
              alpha = .15, colour = NA) +
  geom_line(linewidth = .7) +
  labs(title = sprintf("Electro Dunas — volúmenes proyectados a FY%d", CFG$fy_horizon),
       subtitle = sprintf("%s; eta = %.3f (banda %.3f a %.3f)",
                          if (TWO_TERM) "dos términos: clientes + eta por cliente"
                          else "una elasticidad sobre energía total",
                          eta_c, eta_l, eta_h),
       x = NULL, y = "GWh", colour = NULL, fill = NULL) +
  theme_minimal(base_size = 11)
ggsave(here::here(CFG$paths$figures, "03_proyeccion.png"), p, width = 7.5, height = 4.2, dpi = 150)

if (nrow(base)) {
  cmp <- base %>%
    select(year, `dos términos` = gwh_central,
           `una elasticidad` = gwh_una_elasticidad,
           `supuesto DCF` = gwh_supuesto_dcf) %>%
    tidyr::pivot_longer(-year, names_to = "regla", values_to = "gwh")
  p2 <- ggplot(cmp, aes(year, gwh, colour = regla)) +
    geom_line(linewidth = .7) +
    geom_line(data = panel %>% transmute(year, gwh = energia_gwh, regla = "observado"),
              linewidth = .9, colour = "grey25") +
    labs(title = "Qué cambia según la regla de proyección (escenario base)",
         subtitle = "La regla de una sola elasticidad omite el crecimiento de conexiones",
         x = NULL, y = "GWh", colour = NULL) +
    theme_minimal(base_size = 11)
  ggsave(here::here(CFG$paths$figures, "04_comparacion_reglas.png"), p2,
         width = 7.5, height = 4.2, dpi = 150)
}

save_rds(list(fc = fc, hist = hist, supuestos = supuestos, comp = comp,
              esc_src = esc_src, esc_is_assumption = esc_is_assumption,
              two_term = TWO_TERM, g_cl_src = g_cl_src,
              q0 = q0, q0_year = q0_year, seg = seg_sheet),
         file.path(CFG$paths$processed, "forecast.rds"))
log_event(STAGE, "INFO", "fin")
