# ============================================================================
# 03_unit_roots.R — Orden de integracion de cada serie en logaritmos
#
# ADF  (urca::ur.df)   : H0 = raiz unitaria.  Rechazo => estacionaria.
# KPSS (urca::ur.kpss) : H0 = estacionaria.   Rechazo => raiz unitaria.
#
# Se corren ambos en nivel (log) y en primera diferencia; el veredicto combina
# los dos tests al 5 %. Rezagos del ADF por AIC (Schwert kmax).
#
# Salidas: output/tables/unit_roots.csv, output/figs/03_acf_*.png
# ============================================================================

source(here::here("R", "00_utils.R"))
suppressPackageStartupMessages(library(urca))

cfg <- load_config(); set_project_seed(cfg); ensure_dirs(cfg)
msg_step("03_unit_roots: inicio")
panel <- read_panel(cfg)
df <- panel$data; segs <- panel$segmentos; act <- panel$actividad

# Rezago maximo de Schwert
kmax <- function(n) max(1L, floor(12 * (n / 100)^0.25))

#' ADF con seleccion de rezagos por AIC. `type`: "drift" (con constante) o
#' "trend" (constante + tendencia).
adf_one <- function(x, type) {
  x <- x[!is.na(x)]
  n <- length(x)
  if (n < 20) return(list(stat = NA_real_, cv5 = NA_real_, lags = NA_integer_))
  tt <- try(urca::ur.df(x, type = type, lags = kmax(n), selectlags = "AIC"),
            silent = TRUE)
  if (inherits(tt, "try-error")) return(list(stat = NA_real_, cv5 = NA_real_,
                                             lags = NA_integer_))
  list(stat = as.numeric(tt@teststat[1]),
       cv5 = as.numeric(tt@cval[1, "5pct"]),
       lags = as.integer(tt@lags))
}

#' KPSS. `type`: "mu" (nivel) o "tau" (tendencia). Ancho de banda automatico.
kpss_one <- function(x, type) {
  x <- x[!is.na(x)]
  if (length(x) < 20) return(list(stat = NA_real_, cv5 = NA_real_))
  tt <- try(urca::ur.kpss(x, type = type, lags = "long"), silent = TRUE)
  if (inherits(tt, "try-error")) return(list(stat = NA_real_, cv5 = NA_real_))
  list(stat = as.numeric(tt@teststat[1]),
       cv5 = as.numeric(tt@cval[1, "5pct"]))
}

#' Veredicto al 5 %: ADF rechaza si stat < cv (cola izquierda);
#' KPSS rechaza si stat > cv.
veredicto <- function(adf_d, adf_t, kp_mu, kp_tau,
                      d_adf_d, d_kp_mu) {
  adf_rej_niv <- isTRUE(adf_d$stat < adf_d$cv5) || isTRUE(adf_t$stat < adf_t$cv5)
  kpss_rej_niv <- isTRUE(kp_mu$stat > kp_mu$cv5) && isTRUE(kp_tau$stat > kp_tau$cv5)
  adf_rej_dif <- isTRUE(d_adf_d$stat < d_adf_d$cv5)
  kpss_no_rej_dif <- isTRUE(d_kp_mu$stat <= d_kp_mu$cv5)

  if (adf_rej_niv && !kpss_rej_niv) return("I(0)")
  if (!adf_rej_niv && (adf_rej_dif || kpss_no_rej_dif)) return("I(1)")
  if (adf_rej_niv && kpss_rej_niv) return("ambiguo (ADF y KPSS rechazan)")
  if (!adf_rej_niv && !adf_rej_dif && !kpss_no_rej_dif) return("posible I(2) — revisar")
  "ambiguo"
}

# Series a testear: todas las que entran a los modelos
series <- c(
  paste0("ln_q_", segs$id),
  paste0("ln_cli_", segs$id),
  paste0("ln_mwh_", segs$id),
  paste0("ln_ptilde_", segs$id),
  paste0("ln_", act),
  intersect(c("ln_vab_agro_ica", "ln_vab_manuf_ica", "ln_max_dem_kw"), names(df))
)
series <- intersect(series, names(df))
if ("nino34" %in% names(df)) series <- c(series, "nino34")

res <- purrr::map_dfr(series, function(v) {
  x <- df[[v]]
  dx <- D(x)
  a_d <- adf_one(x, "drift");  a_t <- adf_one(x, "trend")
  k_m <- kpss_one(x, "mu");    k_t <- kpss_one(x, "tau")
  da_d <- adf_one(dx, "drift"); dk_m <- kpss_one(dx, "mu")
  tibble::tibble(
    variable = v,
    n = sum(!is.na(x)),
    adf_drift_stat = a_d$stat, adf_drift_cv5 = a_d$cv5, adf_drift_lags = a_d$lags,
    adf_trend_stat = a_t$stat, adf_trend_cv5 = a_t$cv5, adf_trend_lags = a_t$lags,
    kpss_mu_stat = k_m$stat, kpss_mu_cv5 = k_m$cv5,
    kpss_tau_stat = k_t$stat, kpss_tau_cv5 = k_t$cv5,
    d_adf_drift_stat = da_d$stat, d_adf_drift_cv5 = da_d$cv5,
    d_kpss_mu_stat = dk_m$stat, d_kpss_mu_cv5 = dk_m$cv5,
    orden_integracion = veredicto(a_d, a_t, k_m, k_t, da_d, dk_m)
  )
})

write_table_out(res, cfg, "unit_roots.csv")
print(as.data.frame(res[, c("variable", "n", "adf_drift_stat", "adf_drift_cv5",
                            "kpss_mu_stat", "kpss_mu_cv5", "orden_integracion")]),
      digits = 3)

n_i2 <- sum(grepl("I\\(2\\)", res$orden_integracion))
if (n_i2 > 0) {
  msg_warn(n_i2, " serie(s) podrian ser I(2). El enfoque ARDL/bounds asume ",
           "variables I(0) o I(1): revisar antes de interpretar las ",
           "elasticidades de largo plazo.")
}
n_amb <- sum(grepl("ambiguo", res$orden_integracion))
if (n_amb > 0) msg_warn(n_amb, " serie(s) con veredicto ambiguo (ADF vs KPSS).")

# ACF/PACF de las dependientes en nivel y diferencia (diagnostico visual)
for (id in segs$id) {
  v <- paste0("ln_q_", id)
  x <- stats::na.omit(df[[v]])
  grDevices::png(cfg_path(cfg, "figs", paste0("03_acf_ln_q_", id, ".png")),
                 width = 1100, height = 760, res = 130)
  graphics::par(mfrow = c(2, 2), mar = c(4, 4, 3, 1))
  stats::acf(x, main = paste0("ACF  ln q ", id), lag.max = 36)
  stats::pacf(x, main = paste0("PACF ln q ", id), lag.max = 36)
  stats::acf(diff(x), main = paste0("ACF  D ln q ", id), lag.max = 36)
  stats::pacf(diff(x), main = paste0("PACF D ln q ", id), lag.max = 36)
  grDevices::dev.off()
}

msg_step("03_unit_roots: fin")
