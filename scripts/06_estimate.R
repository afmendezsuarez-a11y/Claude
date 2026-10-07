## ============================================================================
## 06_estimate.R — Elasticidad-ingreso de la demanda de ELDU. MÍNIMO VIABLE.
## ----------------------------------------------------------------------------
## MODELO PRINCIPAL: descomposición, no una elasticidad única.
##
## En una distribuidora el volumen crece por dos vías que no responden a lo
## mismo:
##     Q = clientes x (energía por cliente)
##     g_Q ≈ g_clientes + g_(Q/cliente)
## Las conexiones responden a política de expansión y demografía; el consumo por
## conexión responde al ingreso. Estimar UNA elasticidad sobre la energía total
## mete el crecimiento de clientes dentro de "elasticidad-ingreso" y la infla.
## Por eso eta se estima sobre energía POR CLIENTE, y el crecimiento de clientes
## entra como supuesto explícito en 07.
##
## Se reporta además la elasticidad sobre energía TOTAL, porque es lo que el
## supuesto vigente del DCF (0.8 BT / 0.9 MT) pretende ser, para que el comité
## vea de dónde viene la diferencia.
##
## Escalera de métodos, según el n disponible:
##   (2) ADF si n >= CFG$est$min_n_adf
##   (3) OLS log-log con y sin tendencia, EE HAC/Newey-West
##   (4) regresión en diferencias, HAC  -> principal si n es corto
##   (5) Engle-Granger + ECM sólo si n >= CFG$est$min_n_ecm y hay cointegración
##   (6) diagnósticos + estabilidad leave-one-out
##   (7) out-of-sample si n >= CFG$est$min_n_holdout
##   (8) robustez: variable alternativa de volumen, exclusión del choque COVID,
##       y driver nacional en vez de regional
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
HAVE_PC <- isTRUE(meta$have_clients) && isTRUE(E$per_client)

## ---- Helper: coeficiente + IC con errores HAC (Newey-West) -----------------
hac_tidy <- function(fit, term) {
  V <- tryCatch(
    if (is.null(E$hac_lag)) sandwich::NeweyWest(fit, prewhite = FALSE, adjust = TRUE)
    else sandwich::NeweyWest(fit, lag = E$hac_lag, prewhite = FALSE, adjust = TRUE),
    warning = function(w) sandwich::NeweyWest(fit, lag = 1, prewhite = FALSE, adjust = TRUE))
  ct <- lmtest::coeftest(fit, vcov. = V)
  if (!term %in% rownames(ct)) return(NULL)
  ci <- lmtest::coefci(fit, parm = term, vcov. = V, level = 1 - alpha)
  list(estimate = unname(ct[term, 1]), se = unname(ct[term, 2]),
       t = unname(ct[term, 3]), p = unname(ct[term, 4]),
       ci_low = unname(ci[1, 1]), ci_high = unname(ci[1, 2]),
       df = stats::df.residual(fit), r2 = summary(fit)$r.squared,
       nobs = stats::nobs(fit))
}

#' Estima las tres especificaciones (niveles+tend, niveles, diferencias) de
#' log(dep) contra log(inc) y devuelve los tres resultados HAC.
#' @param dep vector de la variable dependiente en NIVEL (no log)
fit_trio <- function(dep, inc, years, tag) {
  d <- data.frame(ln_q = log(dep), ln_y = log(inc), year = years)
  d <- d[stats::complete.cases(d), , drop = FALSE]
  if (nrow(d) < 4) {
    log_event(STAGE, "WARN", sprintf("[%s] insuficientes observaciones (%d)", tag, nrow(d)))
    return(NULL)
  }
  d$t <- d$year - min(d$year) + 1L
  f_tr <- stats::lm(ln_q ~ ln_y + t, data = d)
  f_nt <- stats::lm(ln_q ~ ln_y,     data = d)
  dd <- data.frame(d_ln_q = diff(d$ln_q), d_ln_y = diff(d$ln_y))
  f_df <- stats::lm(d_ln_q ~ d_ln_y, data = dd)
  list(
    tag = tag, n = nrow(d),
    trend   = hac_tidy(f_tr, "ln_y"),
    notrend = hac_tidy(f_nt, "ln_y"),
    diff    = hac_tidy(f_df, "d_ln_y"),
    ## La constante de la ecuación en diferencias es el crecimiento AUTÓNOMO:
    ## lo que crece el volumen con ingreso plano. Es la pieza que una regla
    ## Q*(1+eta*g) sin constante tira a la basura.
    diff_const = unname(stats::coef(f_df)[1]),
    fits = list(trend = f_tr, notrend = f_nt, diff = f_df),
    data = d
  )
}

## ===========================================================================
## (1) Descomposición histórica del crecimiento
## ===========================================================================
yrs_span <- n - 1L
cagr <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) < 2) return(NA_real_)
  log(utils::tail(x, 1) / x[1]) / (length(x) - 1)
}
RES$decomp <- list(
  g_energia  = cagr(panel$energia_gwh),
  g_clientes = if (HAVE_PC) cagr(panel$clientes) else NA_real_,
  g_por_cl   = if (HAVE_PC) cagr(panel$energia_gwh / panel$clientes) else NA_real_,
  g_ingreso  = cagr(panel$pbi),
  anios      = yrs_span
)
log_event(STAGE, "OK",
          sprintf("descomposición (CAGR %%/año): energía %.2f = clientes %.2f + por-cliente %.2f ; ingreso %.2f",
                  100 * RES$decomp$g_energia, 100 * RES$decomp$g_clientes,
                  100 * RES$decomp$g_por_cl, 100 * RES$decomp$g_ingreso))
if (HAVE_PC && !is.na(RES$decomp$g_clientes) &&
    RES$decomp$g_clientes > 0.5 * RES$decomp$g_energia) {
  log_event(STAGE, "WARN",
            sprintf("las conexiones explican %.0f%% del crecimiento del volumen: una elasticidad-ingreso única NO es el driver dominante",
                    100 * RES$decomp$g_clientes / RES$decomp$g_energia))
}

## ===========================================================================
## (2) Raíz unitaria
## ===========================================================================
adf_safe <- function(x, label) {
  x <- x[!is.na(x)]
  if (length(x) < E$min_n_adf) return(list(skipped = TRUE,
    note = sprintf("omitido: n=%d < %d", length(x), E$min_n_adf)))
  k <- max(1L, floor((length(x) - 1)^(1/3)))
  out <- tryCatch(suppressWarnings(tseries::adf.test(x, k = k)), error = function(e) NULL)
  if (is.null(out)) return(list(skipped = TRUE, note = "ADF falló numéricamente"))
  list(skipped = FALSE, statistic = unname(out$statistic), p_value = out$p.value,
       lags = k, label = label,
       note = sprintf("ADF(k=%d): stat=%.3f, p=%.3f (H0: raíz unitaria)",
                      k, out$statistic, out$p.value))
}
RES$adf <- list(ln_q = adf_safe(panel$ln_q, "ln(energía)"),
                ln_y = adf_safe(panel$ln_y, "ln(ingreso)"))
if (HAVE_PC) RES$adf$ln_qc <- adf_safe(panel$ln_qc, "ln(energía por cliente)")
for (k in names(RES$adf)) log_event(STAGE, "INFO", sprintf("ADF %s — %s", k, RES$adf[[k]]$note))

## ===========================================================================
## (3)-(4) Estimaciones: PRINCIPAL por cliente, COMPARACIÓN en total
## ===========================================================================
RES$pc    <- if (HAVE_PC) fit_trio(panel$energia_gwh / panel$clientes, panel$pbi,
                                   panel$year, "por_cliente") else NULL
RES$total <- fit_trio(panel$energia_gwh, panel$pbi, panel$year, "energia_total")

## Colinealidad ingreso-tendencia: con series cortas y crecientes, ln(PBI) y t
## son casi la misma variable y eta en niveles queda mal identificado.
RES$collinearity <- list(
  cor_lny_t = stats::cor(panel$ln_y, panel$t),
  vif       = tryCatch(1 / (1 - summary(stats::lm(ln_y ~ t, data = panel))$r.squared),
                       error = function(e) NA_real_))
log_event(STAGE, if (abs(RES$collinearity$cor_lny_t) > 0.97) "WARN" else "INFO",
          sprintf("colinealidad ln(ingreso)~t: cor=%.3f, VIF=%.1f",
                  RES$collinearity$cor_lny_t, RES$collinearity$vif))

## ---- Qué especificación se reporta como principal -------------------------
short_sample <- n < E$prefer_differences_below_n
vif_bad <- !is.na(RES$collinearity$vif) && RES$collinearity$vif > 20
RES$lr_preferred_spec <- if (short_sample) "diff" else if (vif_bad) "notrend" else "trend"
RES$preferred_reason <- if (short_sample) {
  sprintf("n=%d < %d: en niveles la separación ingreso/tendencia es frágil, así que se reporta la de DIFERENCIAS y los niveles quedan como corroboración",
          n, E$prefer_differences_below_n)
} else if (vif_bad) {
  sprintf("VIF(ln_ingreso~t)=%.1f > 20: la tendencia absorbe el ingreso, se prefiere sin tendencia", RES$collinearity$vif)
} else "n suficiente y colinealidad tolerable: niveles con tendencia"
log_event(STAGE, "INFO", paste("especificación principal:", RES$lr_preferred_spec,
                               "—", RES$preferred_reason))

## El bloque principal es el de por-cliente si está disponible; si no, el total.
MAIN <- if (HAVE_PC) RES$pc else RES$total
RES$main_block <- if (HAVE_PC) "por_cliente" else "energia_total"
RES$eta_main <- MAIN[[RES$lr_preferred_spec]]
RES$eta_corrob <- MAIN[setdiff(c("trend", "notrend", "diff"), RES$lr_preferred_spec)]

log_event(STAGE, "OK",
          sprintf("eta PRINCIPAL (%s, %s) = %.3f  IC95 [%.3f, %.3f]  (HAC, R2=%.3f, n=%d)",
                  RES$main_block, RES$lr_preferred_spec, RES$eta_main$estimate,
                  RES$eta_main$ci_low, RES$eta_main$ci_high,
                  RES$eta_main$r2, RES$eta_main$nobs))
if (!is.null(RES$total$diff))
  log_event(STAGE, "INFO",
            sprintf("eta sobre energía TOTAL (diferencias) = %.3f IC95 [%.3f, %.3f]; constante = %.4f (%.2f%%/año autónomo)",
                    RES$total$diff$estimate, RES$total$diff$ci_low, RES$total$diff$ci_high,
                    RES$total$diff_const, 100 * RES$total$diff_const))

## Compatibilidad con el resto del pipeline (07 y el informe)
RES$lr <- MAIN[[if (RES$lr_preferred_spec == "diff") "notrend" else RES$lr_preferred_spec]]
RES$sr <- MAIN$diff
RES$n_sr <- if (is.null(MAIN$diff)) NA_integer_ else MAIN$diff$nobs
RES$r2 <- c(trend   = if (is.null(MAIN$trend)) NA_real_ else MAIN$trend$r2,
            notrend = if (is.null(MAIN$notrend)) NA_real_ else MAIN$notrend$r2,
            sr      = if (is.null(MAIN$diff)) NA_real_ else MAIN$diff$r2)

## ===========================================================================
## (5) Engle-Granger + ECM (sólo si n >= min_n_ecm y hay cointegración)
## ===========================================================================
RES$ecm <- list(attempted = FALSE, cointegrated = NA,
                note = sprintf("no intentado: n=%d < %d", n, E$min_n_ecm))
if (n >= E$min_n_ecm && !is.null(MAIN$fits)) {
  u <- stats::residuals(MAIN$fits$trend)
  eg <- tryCatch(suppressWarnings(tseries::adf.test(u, k = max(1L, floor((n - 1)^(1/3))))),
                 error = function(e) NULL)
  if (is.null(eg)) {
    RES$ecm$note <- "ADF sobre los residuos falló numéricamente"
  } else {
    coint <- eg$p.value < 0.05
    RES$ecm$attempted <- TRUE; RES$ecm$cointegrated <- coint
    RES$ecm$eg_stat <- unname(eg$statistic); RES$ecm$eg_p <- eg$p.value
    RES$ecm$caveat <- paste("los valores críticos de Engle-Granger son más exigentes que los",
                            "del ADF estándar que reporta tseries; léase como indicativo")
    if (coint) {
      dm <- MAIN$data
      ec <- data.frame(d_ln_q = c(NA, diff(dm$ln_q)), d_ln_y = c(NA, diff(dm$ln_y)),
                       ec_lag = c(NA, utils::head(u, -1)))
      ec <- ec[stats::complete.cases(ec), ]
      f_ecm <- stats::lm(d_ln_q ~ d_ln_y + ec_lag, data = ec)
      RES$ecm$fit <- f_ecm
      RES$ecm$speed <- hac_tidy(f_ecm, "ec_lag")
      RES$ecm$sr    <- hac_tidy(f_ecm, "d_ln_y")
      RES$ecm$r2    <- summary(f_ecm)$r.squared
      RES$ecm$note  <- sprintf("ECM estimado; velocidad de ajuste = %.3f (IC95 [%.3f, %.3f])",
                               RES$ecm$speed$estimate, RES$ecm$speed$ci_low,
                               RES$ecm$speed$ci_high)
    } else {
      RES$ecm$note <- sprintf("sin evidencia de cointegración (ADF residuos p=%.3f): se reportan (3)+(4)",
                              eg$p.value)
    }
  }
}
log_event(STAGE, "INFO", paste("ECM —", RES$ecm$note))

## ===========================================================================
## (6) Diagnósticos y estabilidad
## ===========================================================================
diag_of <- function(fit, label) {
  dw <- tryCatch(lmtest::dwtest(fit), error = function(e) NULL)
  bg <- tryCatch(lmtest::bgtest(fit, order = 1), error = function(e) NULL)
  list(label = label, r2 = summary(fit)$r.squared, adj_r2 = summary(fit)$adj.r.squared,
       dw_stat = if (is.null(dw)) NA_real_ else unname(dw$statistic),
       dw_p    = if (is.null(dw)) NA_real_ else dw$p.value,
       bg_stat = if (is.null(bg)) NA_real_ else unname(bg$statistic),
       bg_p    = if (is.null(bg)) NA_real_ else bg$p.value,
       df      = stats::df.residual(fit))
}
RES$diag <- list(
  niveles     = diag_of(MAIN$fits$trend, sprintf("OLS log-log con tendencia (%s)", RES$main_block)),
  diferencias = diag_of(MAIN$fits$diff,  sprintf("diferencias (%s)", RES$main_block)))

## Estabilidad: ¿hay un año que, solo, mueve eta?
stab_fit <- MAIN$fits[[if (RES$lr_preferred_spec == "diff") "diff" else RES$lr_preferred_spec]]
stab_dat <- stats::model.frame(stab_fit)
trm <- if (RES$lr_preferred_spec == "diff") "d_ln_y" else "ln_y"
loo <- vapply(seq_len(nrow(stab_dat)), function(i) {
  f <- try(stats::update(stab_fit, data = stab_dat[-i, , drop = FALSE]), silent = TRUE)
  if (inherits(f, "try-error")) NA_real_ else unname(stats::coef(f)[trm])
}, numeric(1))
yrs_stab <- if (RES$lr_preferred_spec == "diff") MAIN$data$year[-1] else MAIN$data$year
RES$stability <- list(
  eta_loo_min = min(loo, na.rm = TRUE), eta_loo_max = max(loo, na.rm = TRUE),
  worst_year  = yrs_stab[which.max(abs(loo - RES$eta_main$estimate))],
  worst_shift = max(abs(loo - RES$eta_main$estimate), na.rm = TRUE))
log_event(STAGE, "INFO",
          sprintf("estabilidad: eta en [%.3f, %.3f] al excluir un año; el más influyente es %d (Δeta=%.3f)",
                  RES$stability$eta_loo_min, RES$stability$eta_loo_max,
                  RES$stability$worst_year, RES$stability$worst_shift))

## ===========================================================================
## (7) Validación out-of-sample
## ===========================================================================
RES$oos <- list(done = FALSE, note = sprintf("omitida: n=%d < %d", n, E$min_n_holdout))
if (n >= E$min_n_holdout) {
  h <- E$holdout_years
  tr <- panel[seq_len(n - h), , drop = FALSE]; te <- panel[seq(n - h + 1L, n), , drop = FALSE]
  f_tr <- stats::lm(ln_q ~ ln_y + t, data = tr)
  pred <- stats::predict(f_tr, newdata = te)
  ape  <- abs(exp(pred) - te$energia_gwh) / te$energia_gwh
  RES$oos <- list(done = TRUE, holdout_years = te$year, actual = te$energia_gwh,
                  pred = exp(pred), ape = ape, mape = mean(ape),
                  note = sprintf("holdout %s: MAPE = %.2f%%",
                                 paste(te$year, collapse = ","), 100 * mean(ape)))
}
log_event(STAGE, "INFO", paste("out-of-sample —", RES$oos$note))

## ===========================================================================
## (8) Robustez
## ===========================================================================
RES$robust <- list()

## 8a) variable alternativa de volumen (incluye peaje de terceros)
if (isTRUE(meta$have_robustness)) {
  alt <- if (HAVE_PC) panel$energia_robustez_gwh / panel$clientes else panel$energia_robustez_gwh
  RES$robust$volumen_alt <- fit_trio(alt, panel$pbi, panel$year, "volumen_alternativo")
  if (!is.null(RES$robust$volumen_alt[[RES$lr_preferred_spec]]))
    log_event(STAGE, "INFO", sprintf("robustez volumen alternativo: eta=%.3f IC95 [%.3f, %.3f]",
      RES$robust$volumen_alt[[RES$lr_preferred_spec]]$estimate,
      RES$robust$volumen_alt[[RES$lr_preferred_spec]]$ci_low,
      RES$robust$volumen_alt[[RES$lr_preferred_spec]]$ci_high))
}

## 8b) exclusión del choque COVID: en n=8 el desplome y el rebote pueden
##     determinar eta por sí solos. Si al sacarlos eta cambia de signo o se
##     dispara, la identificación descansa en esos dos años y hay que decirlo.
shock <- intersect(E$shock_years, panel$year)
if (length(shock) && n - length(shock) >= 4) {
  pe <- panel[!panel$year %in% shock, , drop = FALSE]
  dep <- if (HAVE_PC) pe$energia_gwh / pe$clientes else pe$energia_gwh
  RES$robust$ex_shock <- fit_trio(dep, pe$pbi, pe$year, "sin_choque_covid")
  RES$robust$ex_shock_years <- shock
  e_ex <- RES$robust$ex_shock[[RES$lr_preferred_spec]]
  if (!is.null(e_ex)) {
    flip <- sign(e_ex$estimate) != sign(RES$eta_main$estimate)
    RES$robust$ex_shock_flips <- flip
    log_event(STAGE, if (flip) "WARN" else "INFO",
              sprintf("robustez sin %s: eta=%.3f IC95 [%.3f, %.3f]%s",
                      paste(shock, collapse = "/"), e_ex$estimate, e_ex$ci_low, e_ex$ci_high,
                      if (flip) " — CAMBIA DE SIGNO: la identificación descansa en el choque" else ""))
  }
}

## 8c) driver nacional en vez de regional
if ("pbi_nacional_yoy" %in% names(panel) && !isTRUE(meta$income_is_proxy) &&
    sum(!is.na(panel$pbi_nacional_yoy)) >= 5) {
  dep <- if (HAVE_PC) panel$energia_gwh / panel$clientes else panel$energia_gwh
  RES$robust$driver_nacional <- fit_trio(dep, panel$pbi_nacional_yoy, panel$year, "driver_nacional")
  e_na <- RES$robust$driver_nacional[[RES$lr_preferred_spec]]
  if (!is.null(e_na))
    log_event(STAGE, "INFO", sprintf("robustez driver nacional: eta=%.3f IC95 [%.3f, %.3f]",
                                     e_na$estimate, e_na$ci_low, e_na$ci_high))
}

## ===========================================================================
## Regla de prudencia: punto creíble o rango
## ===========================================================================
spread_pool <- c(RES$eta_main$estimate,
                 vapply(RES$eta_corrob, function(z) if (is.null(z)) NA_real_ else z$estimate,
                        numeric(1)))
spread_pool <- spread_pool[is.finite(spread_pool)]
ci_w <- RES$eta_main$ci_high - RES$eta_main$ci_low
spec_spread <- if (length(spread_pool) > 1) diff(range(spread_pool)) else 0
RES$prudence <- list(
  ci_width = ci_w, spec_spread = spec_spread,
  threshold = E$wide_ci_width, spread_threshold = E$spec_spread_range,
  report_as_range = ci_w > E$wide_ci_width || RES$eta_main$ci_low <= 0 ||
                    spec_spread > E$spec_spread_range,
  reason = if (ci_w > E$wide_ci_width) "IC de muestreo demasiado ancho"
           else if (RES$eta_main$ci_low <= 0) "el IC incluye cero"
           else if (spec_spread > E$spec_spread_range)
             sprintf("eta varía %.2f entre especificaciones razonables (umbral %.2f): la incertidumbre es de especificación",
                     spec_spread, E$spec_spread_range)
           else "IC estrecho y especificaciones consistentes")
RES$eta_used <- list(
  point = RES$eta_main$estimate,
  low   = min(c(RES$eta_main$ci_low, spread_pool)),
  high  = max(c(RES$eta_main$ci_high, spread_pool)),
  ci_low = RES$eta_main$ci_low, ci_high = RES$eta_main$ci_high,
  source = sprintf("OLS %s sobre %s, HAC Newey-West",
                   switch(RES$lr_preferred_spec,
                          diff = "en diferencias", trend = "log-log con tendencia",
                          notrend = "log-log sin tendencia"),
                   if (HAVE_PC) "energía POR CLIENTE" else "energía total"),
  applies_to = if (HAVE_PC) "energia_por_cliente" else "energia_total",
  as_range = RES$prudence$report_as_range)
log_event(STAGE, if (RES$prudence$report_as_range) "WARN" else "OK",
          sprintf("prudencia: IC=%.3f, dispersión entre especificaciones=%.3f -> reportar como %s (%s)",
                  ci_w, spec_spread,
                  if (RES$prudence$report_as_range) "RANGO" else "punto con IC",
                  RES$prudence$reason))

## ===========================================================================
## ¿El modelo reproduce la historia? (chequeo de coherencia)
## ===========================================================================
if (HAVE_PC) {
  g_impl <- RES$decomp$g_clientes + RES$eta_used$point * RES$decomp$g_ingreso
  RES$coherence <- list(
    g_observado = RES$decomp$g_energia, g_implicado = g_impl,
    g_regla_simple = RES$eta_used$point * RES$decomp$g_ingreso,
    g_dcf = mean(CFG$dcf_benchmark) * RES$decomp$g_ingreso,
    note = sprintf(paste("dos términos: %.2f%%/año implicado vs %.2f%%/año observado.",
                         "La regla de una sola elasticidad sin término de clientes daría %.2f%%/año."),
                   100 * g_impl, 100 * RES$decomp$g_energia,
                   100 * RES$eta_used$point * RES$decomp$g_ingreso))
  log_event(STAGE, "OK", paste("coherencia —", RES$coherence$note))
}

## ===========================================================================
## Salidas
## ===========================================================================
row_of <- function(bloque, rol, metodo, h, notas) {
  if (is.null(h)) return(NULL)
  data.frame(bloque = bloque, rol = rol, metodo = metodo,
             estimate = h$estimate, se_hac = h$se,
             ci95_low = h$ci_low, ci95_high = h$ci_high, p_value = h$p,
             n = h$nobs, r2 = h$r2, notas = notas, stringsAsFactors = FALSE)
}
spec_name <- c(trend = "OLS log-log con tendencia", notrend = "OLS log-log sin tendencia",
               diff = "Regresión en diferencias")
rows <- list()
for (sp in c("trend", "notrend", "diff")) {
  if (HAVE_PC)
    rows[[length(rows)+1L]] <- row_of("energia_por_cliente",
      if (sp == RES$lr_preferred_spec) "PRINCIPAL" else "corroboracion",
      spec_name[[sp]], RES$pc[[sp]],
      "eta-ingreso del consumo por conexion; el crecimiento de clientes va aparte en 07")
  ## Sin clientes no hay descomposicion posible: la energia total ES el bloque
  ## principal. Con clientes, queda sólo como comparación contra el supuesto DCF.
  rows[[length(rows)+1L]] <- row_of("energia_total",
    if (HAVE_PC) "comparacion"
    else if (sp == RES$lr_preferred_spec) "PRINCIPAL" else "corroboracion",
    spec_name[[sp]], RES$total[[sp]],
    if (HAVE_PC) "es lo que el supuesto 0.8/0.9 del DCF pretende ser; mezcla clientes con ingreso"
    else "sin numero de clientes no se puede separar conexiones de consumo por conexion")
}
for (rb in names(RES$robust)) {
  if (!is.list(RES$robust[[rb]]) || is.null(RES$robust[[rb]][[RES$lr_preferred_spec]])) next
  rows[[length(rows)+1L]] <- row_of(rb, "robustez", spec_name[[RES$lr_preferred_spec]],
                                    RES$robust[[rb]][[RES$lr_preferred_spec]],
                                    sprintf("chequeo de robustez: %s", rb))
}
if (isTRUE(RES$ecm$cointegrated)) {
  rows[[length(rows)+1L]] <- row_of("ECM", "largo_plazo", "ECM Engle-Granger 2 pasos",
                                    RES$ecm$speed, paste("velocidad de ajuste;", RES$ecm$caveat))
}
tab <- do.call(rbind, rows)
tab$eta_se_reporta_como <- ifelse(tab$rol == "PRINCIPAL",
                                  ifelse(RES$prudence$report_as_range, "RANGO", "punto+IC95"), "")
readr::write_csv(tab, here::here(CFG$paths$tables, "elasticidad.csv"))
log_event(STAGE, "OK", sprintf("escrito output/tables/elasticidad.csv (%d filas)", nrow(tab)))

## Descomposición del crecimiento, como tabla propia
readr::write_csv(data.frame(
  componente = c("energia distribuida", "clientes", "energia por cliente", "ingreso (driver)"),
  cagr_pct   = 100 * c(RES$decomp$g_energia, RES$decomp$g_clientes,
                       RES$decomp$g_por_cl, RES$decomp$g_ingreso),
  periodo    = sprintf("%d-%d", RES$years[1], RES$years[2])),
  here::here(CFG$paths$tables, "descomposicion_crecimiento.csv"))

diag_tab <- do.call(rbind, lapply(RES$diag, function(d) data.frame(
  modelo = d$label, r2 = d$r2, adj_r2 = d$adj_r2, df_residual = d$df,
  durbin_watson = d$dw_stat, dw_p = d$dw_p,
  breusch_godfrey = d$bg_stat, bg_p = d$bg_p, stringsAsFactors = FALSE)))
readr::write_csv(diag_tab, here::here(CFG$paths$tables, "diagnosticos.csv"))

save_rds(RES, file.path(CFG$paths$processed, "estimacion.rds"))
log_event(STAGE, "INFO", "fin")
