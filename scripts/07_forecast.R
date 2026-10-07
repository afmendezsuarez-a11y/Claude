## ============================================================================
## 07_forecast.R — Proyección de volúmenes por escenario hasta FY2035.
## ----------------------------------------------------------------------------
## Regla transparente:   Q_{t+1} = Q_t * (1 + eta * g_PBI_{t+1})
## Las bandas vienen del IC95 de eta (eta_low / eta_high), no de un supuesto.
## El reparto por segmento SÓLO se hace si el usuario provee pesos en
## CFG$segment_weights — no se inventan.
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
if (!length(horizon)) {
  log_event(STAGE, "WARN", sprintf("el último año observado (%d) ya alcanza el horizonte (%d): no hay nada que proyectar",
                                   q0_year, CFG$fy_horizon))
}

## ---- Escenarios de crecimiento del PBI ------------------------------------
esc_path <- here::here(CFG$escenarios$path)
esc_is_assumption <- FALSE
if (file.exists(esc_path)) {
  esc <- suppressMessages(readr::read_csv(esc_path, show_col_types = FALSE))
  need <- c("escenario", "year", "g_pbi")
  if (!all(need %in% names(esc))) {
    stop(sprintf("%s existe pero debe tener las columnas: %s (tiene: %s)",
                 CFG$escenarios$path, paste(need, collapse = ","),
                 paste(names(esc), collapse = ",")), call. = FALSE)
  }
  esc <- esc %>% mutate(year = as.integer(year), g_pbi = as.numeric(g_pbi)) %>%
    filter(year %in% horizon)
  log_event(STAGE, "OK", sprintf("escenarios leídos de %s (%d escenarios, %d-%d)",
                                 CFG$escenarios$path, dplyr::n_distinct(esc$escenario),
                                 min(esc$year), max(esc$year)))
  esc_src <- sprintf("%s (provisto por el usuario)", CFG$escenarios$path)
} else {
  esc_is_assumption <- TRUE
  esc <- tidyr::expand_grid(escenario = names(CFG$escenarios$defaults), year = horizon) %>%
    mutate(g_pbi = unname(CFG$escenarios$defaults[escenario]))
  log_event(STAGE, "WARN",
            sprintf(paste("%s NO existe: se usan los crecimientos por defecto (%s)",
                          "— quedan marcados como SUPUESTO en el informe"),
                    CFG$escenarios$path,
                    paste(sprintf("%s=%.1f%%", names(CFG$escenarios$defaults),
                                  100 * CFG$escenarios$defaults), collapse = ", ")))
  esc_src <- sprintf("SUPUESTO (archivo %s no provisto): %s",
                     CFG$escenarios$path,
                     paste(sprintf("%s=%.1f%%", names(CFG$escenarios$defaults),
                                   100 * CFG$escenarios$defaults), collapse = ", "))
}

## ---- Proyección ------------------------------------------------------------
etas <- c(central = RES$eta_used$point,
          low     = RES$eta_used$low,
          high    = RES$eta_used$high)

#' Aplica Q_{t+1} = Q_t * (1 + eta * g) de forma recursiva.
project <- function(g_by_year, eta, q_start) {
  q <- numeric(length(g_by_year)); prev <- q_start
  for (i in seq_along(g_by_year)) {
    prev <- prev * (1 + eta * g_by_year[i])
    q[i] <- prev
  }
  q
}

fc <- esc %>% arrange(escenario, year) %>% group_by(escenario) %>%
  group_modify(~{
    g <- .x$g_pbi
    tibble::tibble(
      year       = .x$year,
      g_pbi      = g,
      gwh_central= project(g, etas[["central"]], q0),
      gwh_low    = project(g, etas[["low"]],     q0),
      gwh_high   = project(g, etas[["high"]],    q0)
    )
  }) %>% ungroup()

## Si el IC de eta incluye valores negativos, la "banda baja" puede caer; eso es
## información, no un error: se reporta tal cual y se advierte en el informe.
if (RES$eta_used$low < 0) {
  log_event(STAGE, "WARN",
            "el IC95 de eta incluye valores negativos: la banda inferior proyecta caída de volumen (la data no descarta eta<=0)")
}

hist <- panel %>% transmute(escenario = "historico", year, g_pbi = NA_real_,
                            gwh_central = energia_gwh,
                            gwh_low = energia_gwh, gwh_high = energia_gwh)

readr::write_csv(fc, here::here(CFG$paths$tables, "forecast_volumenes.csv"))

## ---- Reparto por segmento (sólo con pesos provistos) ----------------------
seg_sheet <- NULL
if (!is.null(CFG$segment_weights)) {
  w <- CFG$segment_weights
  if (abs(sum(w) - 1) > 1e-6) {
    stop(sprintf("CFG$segment_weights debe sumar 1 (suma %.4f)", sum(w)), call. = FALSE)
  }
  seg_sheet <- fc %>% tidyr::crossing(segmento = names(w)) %>%
    mutate(peso = unname(w[segmento]),
           gwh_central = gwh_central * peso,
           gwh_low     = gwh_low * peso,
           gwh_high    = gwh_high * peso) %>%
    arrange(escenario, segmento, year)
  log_event(STAGE, "OK", sprintf("reparto por segmento aplicado con pesos provistos: %s",
                                 paste(sprintf("%s=%.1f%%", names(w), 100 * w), collapse = ", ")))
} else {
  log_event(STAGE, "INFO",
            paste("sin reparto por segmento: CFG$segment_weights es NULL.",
                  "No se inventan pesos BT/MT/libres — provéalos en config/config.R si los necesita."))
}

## ---- Hoja de supuestos (todo lo que no es dato, explícito) ----------------
supuestos <- tibble::tibble(
  concepto = c("eta usada (central)", "eta banda baja (IC95)", "eta banda alta (IC95)",
               "método de eta", "eta se reporta como",
               "Q base (GWh)", "año base", "horizonte",
               "fuente de escenarios de PBI",
               "PBI usado es proxy nacional",
               "reparto por segmento",
               "supuesto DCF actual (BT)", "supuesto DCF actual (MT)",
               "n observaciones", "regla de proyección"),
  valor = c(sprintf("%.4f", RES$eta_used$point),
            sprintf("%.4f", RES$eta_used$low),
            sprintf("%.4f", RES$eta_used$high),
            RES$eta_used$source,
            if (isTRUE(RES$eta_used$as_range)) "RANGO (IC ancho: la data no da un punto creíble)"
              else "punto con IC95",
            sprintf("%.1f", q0), as.character(q0_year),
            sprintf("FY%d", CFG$fy_horizon),
            esc_src,
            if (isTRUE(RES$meta$income_is_proxy)) "SÍ — PBI nacional BCRP como proxy del PBI de Ica" else "No",
            if (is.null(CFG$segment_weights)) "no aplicado (pesos no provistos; no se inventan)"
              else paste(sprintf("%s=%.1f%%", names(CFG$segment_weights),
                                 100 * CFG$segment_weights), collapse = ", "),
            sprintf("%.2f", CFG$dcf_benchmark[["BT"]]),
            sprintf("%.2f", CFG$dcf_benchmark[["MT"]]),
            as.character(RES$n),
            "Q_{t+1} = Q_t * (1 + eta * g_PBI_{t+1})")
)

sheets <- list(supuestos = supuestos,
               historico = hist,
               proyeccion = fc)
if (!is.null(seg_sheet)) sheets$proyeccion_por_segmento <- seg_sheet
writexl::write_xlsx(sheets, here::here(CFG$paths$output, "forecast_volumenes.xlsx"))
log_event(STAGE, "OK", sprintf("escrito output/forecast_volumenes.xlsx (%d hojas)", length(sheets)))

## ---- Gráfico ---------------------------------------------------------------
plt <- dplyr::bind_rows(
  hist %>% mutate(tipo = "histórico"),
  fc   %>% mutate(tipo = "proyección")
)
p <- ggplot(plt, aes(year, gwh_central, colour = escenario)) +
  geom_ribbon(data = dplyr::filter(plt, tipo == "proyección"),
              aes(ymin = gwh_low, ymax = gwh_high, fill = escenario),
              alpha = .15, colour = NA) +
  geom_line(linewidth = .7) +
  labs(title = sprintf("Electro Dunas — volúmenes proyectados a FY%d", CFG$fy_horizon),
       subtitle = sprintf("eta = %.3f (IC95 %.3f a %.3f); bandas = IC95 de eta",
                          RES$eta_used$point, RES$eta_used$low, RES$eta_used$high),
       x = NULL, y = "GWh", colour = NULL, fill = NULL) +
  theme_minimal(base_size = 11)
ggsave(here::here(CFG$paths$figures, "03_proyeccion.png"), p,
       width = 7.5, height = 4.2, dpi = 150)

save_rds(list(fc = fc, hist = hist, supuestos = supuestos,
              esc_src = esc_src, esc_is_assumption = esc_is_assumption,
              q0 = q0, q0_year = q0_year, seg = seg_sheet),
         file.path(CFG$paths$processed, "forecast.rds"))
log_event(STAGE, "INFO", "fin")
