## ============================================================================
## 06_estimate.R — Estimación de la elasticidad-ingreso. MÍNIMO VIABLE.
## ----------------------------------------------------------------------------
## Escalera de métodos, en orden, reportando el que corresponde al n disponible:
##   (1) preparación (logs, gráficos)              -> en 05
##   (2) raíz unitaria (ADF) si n >= 12
##   (3) OLS log-log con y sin tendencia, HAC/Newey-West  -> eta de largo plazo
##   (4) regresión en diferencias, HAC              -> eta de crecimiento
##   (5) ECM de una ecuación SÓLO si n >= 15 y hay cointegración (Engle-Granger)
##   (6) diagnósticos mínimos (R2, DW, Breusch-Godfrey, influencia)
##   (7) validación out-of-sample ligera si n lo permite
## Nada de sobre-ajustar con pocos puntos. El método reportado corresponde al n.
## ============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(sandwich); library(lmtest); library(broom)
  library(tseries); library(urca); library(here); library(readr)
})

STAGE <- "06_estimate"
log_event(STAGE, "INFO", "inicio — estimación")

panel <- readRDS(here::here(CFG$paths$processed, "panel_anual.rds"))
meta  <- readRDS(here::here(CFG$paths$processed, "panel_meta.rds"))
E     <- CFG$est
n     <- nrow(panel)
alpha <- E$alpha
log_event(STAGE, "INFO", sprintf("n = %d observaciones anuales (%d-%d)",
                                 n, min(panel$year), max(panel$year)))

RES <- list(n = n, years = range(panel$year), meta = meta)

## ---- Helper: coeficiente + IC con errores HAC (Newey-West) -----------------
hac_tidy <- function(fit, term) {
  V  <- if (is.null(E$hac_lag)) sandwich::NeweyWest(fit, prewhite = FALSE, adjust = TRUE)
        else sandwich::NeweyWest(fit, lag = E$hac_lag, prewhite = FALSE, adjust = TRUE)
  ct <- lmtest::coeftest(fit, vcov. = V)
  ci <- lmtest::coefci(fit, parm = term, vcov. = V, level = 1 - alpha)
  if (!term %in% rownames(ct)) return(NULL)
  list(estimate = unname(ct[term, 1]), se = unname(ct[term, 2]),
       t = unname(ct[term, 3]), p = unname(ct[term, 4]),
       ci_low = unname(ci[1, 1]), ci_high = unname(ci[1, 2]),
       df = stats::df.residual(fit), vcov = V)
}

## ===========================================================================
## (2) Raíz unitaria
## ===========================================================================
adf_safe <- function(x, label) {
  if (n < E$min_n_adf) return(list(skipped = TRUE,
    note = sprintf("omitido: n=%d < %d", n, E$min_n_adf)))
  k <- max(1L, floor((n - 1)^(1/3)))
  out <- tryCatch(suppressWarnings(tseries::adf.test(x, k = k)), error = function(e) NULL)
  if (is.null(out)) return(list(skipped = TRUE, note = "ADF falló numéricamente"))
  list(skipped = FALSE, statistic = unname(out$statistic), p_value = out$p.value,
       lags = k, label = label,
       note = sprintf("ADF(k=%d): stat=%.3f, p=%.3f (H0: raíz unitaria)",
                      k, out$statistic, out$p.value))
}
RES$adf <- list(ln_q = adf_safe(panel$ln_q, "ln(energía)"),
                ln_y = adf_safe(panel$ln_y, "ln(PBI)"))
for (k in names(RES$adf)) log_event(STAGE, "INFO", sprintf("ADF %s — %s", k, RES$adf[[k]]$note))

## ===========================================================================
## (3) Modelo base: OLS log-log (con y sin tendencia), HAC
## ===========================================================================
fit_trend   <- stats::lm(ln_q ~ ln_y + t, data = panel)
fit_notrend <- stats::lm(ln_q ~ ln_y,     data = panel)

RES$lr_trend   <- hac_tidy(fit_trend,   "ln_y")
RES$lr_notrend <- hac_tidy(fit_notrend, "ln_y")
RES$fit_trend <- fit_trend; RES$fit_notrend <- fit_notrend
RES$r2 <- c(trend = summary(fit_trend)$r.squared,
            notrend = summary(fit_notrend)$r.squared)

## Colinealidad ln(PBI) vs tendencia: con muestras cortas el PBI y t son casi
## la misma variable, lo que infla el error estándar de eta y puede darle signo
## perverso. Se reporta explícitamente en vez de esconderlo.
RES$collinearity <- list(
  cor_lny_t = stats::cor(panel$ln_y, panel$t),
  vif       = tryCatch(1 / (1 - summary(stats::lm(ln_y ~ t, data = panel))$r.squared),
                       error = function(e) NA_real_)
)
log_event(STAGE, if (abs(RES$collinearity$cor_lny_t) > 0.97) "WARN" else "INFO",
          sprintf("colinealidad ln(PBI)~t: cor=%.3f, VIF=%.1f",
                  RES$collinearity$cor_lny_t, RES$collinearity$vif))

## Especificación preferida: con tendencia, salvo que la colinealidad la vuelva
## inútil (VIF muy alto), caso en que se prefiere la versión sin tendencia y se
## deja dicho en el informe.
RES$lr_preferred_spec <- if (!is.na(RES$collinearity$vif) && RES$collinearity$vif > 20) {
  "notrend"
} else "trend"
RES$lr <- if (RES$lr_preferred_spec == "trend") RES$lr_trend else RES$lr_notrend
log_event(STAGE, "OK",
          sprintf("eta_LP (%s) = %.3f  IC95 [%.3f, %.3f]  (HAC, R2=%.3f)",
                  RES$lr_preferred_spec, RES$lr$estimate, RES$lr$ci_low, RES$lr$ci_high,
                  RES$r2[[RES$lr_preferred_spec]]))

## ===========================================================================
## (4) Chequeo en diferencias (elasticidad de crecimiento) — SIEMPRE
## ===========================================================================
dif <- panel %>% mutate(d_ln_q = c(NA, diff(ln_q)), d_ln_y = c(NA, diff(ln_y))) %>%
  filter(!is.na(d_ln_q), !is.na(d_ln_y))
fit_sr  <- stats::lm(d_ln_q ~ d_ln_y, data = dif)
RES$sr  <- hac_tidy(fit_sr, "d_ln_y")
RES$fit_sr <- fit_sr
RES$r2["sr"] <- summary(fit_sr)$r.squared
RES$n_sr <- nrow(dif)
log_event(STAGE, "OK", sprintf("eta_CP (diferencias) = %.3f  IC95 [%.3f, %.3f]  (n=%d, R2=%.3f)",
                               RES$sr$estimate, RES$sr$ci_low, RES$sr$ci_high,
                               RES$n_sr, RES$r2[["sr"]]))

## ===========================================================================
## (5) Engle-Granger + ECM  (sólo si n >= 15 y hay cointegración)
## ===========================================================================
RES$ecm <- list(attempted = FALSE, cointegrated = NA,
                note = sprintf("no intentado: n=%d < %d", n, E$min_n_ecm))
if (n >= E$min_n_ecm) {
  u <- stats::residuals(if (RES$lr_preferred_spec == "trend") fit_trend else fit_notrend)
  eg <- tryCatch(suppressWarnings(tseries::adf.test(u, k = max(1L, floor((n - 1)^(1/3))))),
                 error = function(e) NULL)
  if (is.null(eg)) {
    RES$ecm$note <- "ADF sobre los residuos falló numéricamente"
  } else {
    ## Aviso: los valores críticos de un ADF sobre residuos estimados NO son los
    ## de un ADF estándar (Engle-Granger son más exigentes). Se usa un umbral
    ## conservador en vez de leer el p-valor al pie de la letra.
    coint <- eg$p.value < 0.05
    RES$ecm$attempted    <- TRUE
    RES$ecm$cointegrated <- coint
    RES$ecm$eg_stat      <- unname(eg$statistic)
    RES$ecm$eg_p         <- eg$p.value
    RES$ecm$caveat <- paste("los valores críticos de Engle-Granger son más exigentes que los",
                            "del ADF estándar que reporta tseries; léase como indicativo")
    if (coint) {
      ec <- data.frame(d_ln_q = c(NA, diff(panel$ln_q)),
                       d_ln_y = c(NA, diff(panel$ln_y)),
                       ec_lag = c(NA, utils::head(u, -1)))
      ec <- ec[stats::complete.cases(ec), ]
      fit_ecm <- stats::lm(d_ln_q ~ d_ln_y + ec_lag, data = ec)
      RES$ecm$fit   <- fit_ecm
      RES$ecm$speed <- hac_tidy(fit_ecm, "ec_lag")      # velocidad de ajuste
      RES$ecm$sr    <- hac_tidy(fit_ecm, "d_ln_y")
      RES$ecm$r2    <- summary(fit_ecm)$r.squared
      RES$ecm$note  <- sprintf("ECM estimado; velocidad de ajuste = %.3f (IC95 [%.3f, %.3f])",
                               RES$ecm$speed$estimate, RES$ecm$speed$ci_low, RES$ecm$speed$ci_high)
    } else {
      RES$ecm$note <- sprintf("sin evidencia de cointegración (ADF residuos p=%.3f): se reporta (3)+(4)",
                              eg$p.value)
    }
  }
  log_event(STAGE, "INFO", paste("ECM —", RES$ecm$note))
} else {
  log_event(STAGE, "INFO", paste("ECM —", RES$ecm$note))
}

## ===========================================================================
## (6) Diagnósticos mínimos
## ===========================================================================
diag_of <- function(fit, label) {
  dw <- tryCatch(lmtest::dwtest(fit), error = function(e) NULL)
  bg <- tryCatch(lmtest::bgtest(fit, order = 1), error = function(e) NULL)
  list(label = label,
       r2 = summary(fit)$r.squared,
       adj_r2 = summary(fit)$adj.r.squared,
       dw_stat = if (is.null(dw)) NA_real_ else unname(dw$statistic),
       dw_p    = if (is.null(dw)) NA_real_ else dw$p.value,
       bg_stat = if (is.null(bg)) NA_real_ else unname(bg$statistic),
       bg_p    = if (is.null(bg)) NA_real_ else bg$p.value,
       df      = stats::df.residual(fit))
}
RES$diag <- list(lr = diag_of(if (RES$lr_preferred_spec == "trend") fit_trend else fit_notrend,
                              sprintf("OLS log-log (%s)", RES$lr_preferred_spec)),
                 sr = diag_of(fit_sr, "diferencias"))

## Estabilidad simple: ¿hay un año que, solo, mueve eta? (influencia leave-one-out)
fit_pref <- if (RES$lr_preferred_spec == "trend") fit_trend else fit_notrend
loo <- vapply(seq_len(n), function(i) {
  f <- stats::update(fit_pref, data = panel[-i, , drop = FALSE])
  unname(stats::coef(f)["ln_y"])
}, numeric(1))
RES$stability <- list(
  eta_loo_min = min(loo), eta_loo_max = max(loo),
  worst_year  = panel$year[which.max(abs(loo - RES$lr$estimate))],
  worst_shift = max(abs(loo - RES$lr$estimate))
)
log_event(STAGE, "INFO",
          sprintf("estabilidad: eta en rango [%.3f, %.3f] al excluir un año; el año más influyente es %d (Δeta=%.3f)",
                  RES$stability$eta_loo_min, RES$stability$eta_loo_max,
                  RES$stability$worst_year, RES$stability$worst_shift))

## ===========================================================================
## (7) Validación out-of-sample ligera
## ===========================================================================
RES$oos <- list(done = FALSE, note = sprintf("omitida: n=%d < %d", n, E$min_n_holdout))
if (n >= E$min_n_holdout) {
  h <- E$holdout_years
  tr <- panel[seq_len(n - h), , drop = FALSE]
  te <- panel[seq(n - h + 1L, n), , drop = FALSE]
  f_tr <- stats::lm(stats::formula(fit_pref), data = tr)
  pred <- stats::predict(f_tr, newdata = te)
  ape  <- abs(exp(pred) - te$energia_gwh) / te$energia_gwh
  RES$oos <- list(done = TRUE, holdout_years = te$year,
                  actual = te$energia_gwh, pred = exp(pred),
                  ape = ape, mape = mean(ape),
                  note = sprintf("holdout %s: MAPE = %.2f%%",
                                 paste(te$year, collapse = ","), 100 * mean(ape)))
  log_event(STAGE, "OK", paste("out-of-sample —", RES$oos$note))
} else {
  log_event(STAGE, "INFO", paste("out-of-sample —", RES$oos$note))
}

## ===========================================================================
## Regla de prudencia: ¿punto creíble o rango?
## ===========================================================================
ci_w <- RES$lr$ci_high - RES$lr$ci_low
RES$prudence <- list(
  ci_width = ci_w,
  report_as_range = ci_w > E$wide_ci_width || RES$lr$ci_low <= 0,
  threshold = E$wide_ci_width
)
RES$eta_used <- list(
  point  = RES$lr$estimate,
  low    = RES$lr$ci_low,
  high   = RES$lr$ci_high,
  source = sprintf("OLS log-log (%s), HAC Newey-West", RES$lr_preferred_spec),
  as_range = RES$prudence$report_as_range
)
log_event(STAGE, if (RES$prudence$report_as_range) "WARN" else "OK",
          sprintf("regla de prudencia: ancho IC95 = %.3f (umbral %.2f) -> reportar como %s",
                  ci_w, E$wide_ci_width,
                  if (RES$prudence$report_as_range) "RANGO" else "punto con IC"))

## ===========================================================================
## Salida: output/tables/elasticidad.csv
## ===========================================================================
row_of <- function(metodo, parametro, h, nn, r2, notas) {
  data.frame(metodo = metodo, parametro = parametro,
             estimate = if (is.null(h)) NA_real_ else h$estimate,
             se_hac   = if (is.null(h)) NA_real_ else h$se,
             ci95_low = if (is.null(h)) NA_real_ else h$ci_low,
             ci95_high= if (is.null(h)) NA_real_ else h$ci_high,
             p_value  = if (is.null(h)) NA_real_ else h$p,
             n = nn, r2 = r2, notas = notas, stringsAsFactors = FALSE)
}
tab <- rbind(
  row_of("OLS log-log con tendencia", "eta_largo_plazo", RES$lr_trend, n,
         RES$r2[["trend"]],
         sprintf("ln(Q)=a+eta*ln(PBI)+d*t; HAC Newey-West; cor(ln_PBI,t)=%.3f, VIF=%.1f",
                 RES$collinearity$cor_lny_t, RES$collinearity$vif)),
  row_of("OLS log-log sin tendencia", "eta_largo_plazo", RES$lr_notrend, n,
         RES$r2[["notrend"]], "ln(Q)=a+eta*ln(PBI); HAC Newey-West"),
  row_of("Regresión en diferencias", "eta_crecimiento", RES$sr, RES$n_sr,
         RES$r2[["sr"]], "d_ln(Q)=c+eta*d_ln(PBI); HAC Newey-West"),
  if (isTRUE(RES$ecm$cointegrated))
    row_of("ECM (Engle-Granger 2 pasos)", "velocidad_ajuste", RES$ecm$speed,
           stats::nobs(RES$ecm$fit), RES$ecm$r2,
           sprintf("término EC rezagado; %s", RES$ecm$caveat)) else NULL,
  if (isTRUE(RES$ecm$cointegrated))
    row_of("ECM (Engle-Granger 2 pasos)", "eta_corto_plazo", RES$ecm$sr,
           stats::nobs(RES$ecm$fit), RES$ecm$r2, "coeficiente de d_ln(PBI) en el ECM") else NULL
)
tab$metodo_reportado <- tab$metodo == sprintf("OLS log-log %s",
                                              if (RES$lr_preferred_spec == "trend")
                                                "con tendencia" else "sin tendencia")
tab$eta_se_reporta_como <- ifelse(tab$parametro == "eta_largo_plazo" & tab$metodo_reportado,
                                  ifelse(RES$prudence$report_as_range, "RANGO", "punto+IC95"), "")
readr::write_csv(tab, here::here(CFG$paths$tables, "elasticidad.csv"))
log_event(STAGE, "OK", sprintf("escrito output/tables/elasticidad.csv (%d filas)", nrow(tab)))

## Tabla de diagnósticos
diag_tab <- do.call(rbind, lapply(RES$diag, function(d) data.frame(
  modelo = d$label, r2 = d$r2, adj_r2 = d$adj_r2, df_residual = d$df,
  durbin_watson = d$dw_stat, dw_p = d$dw_p,
  breusch_godfrey = d$bg_stat, bg_p = d$bg_p, stringsAsFactors = FALSE)))
readr::write_csv(diag_tab, here::here(CFG$paths$tables, "diagnosticos.csv"))

save_rds(RES, file.path(CFG$paths$processed, "estimacion.rds"))
log_event(STAGE, "INFO", "fin")
