# ============================================================================
# 04_cointegration.R — Relacion de largo plazo demanda - actividad - tarifa
#
# Por segmento k se evalua el sistema (ln q_k, ln Y, ln p~_k) con:
#   (a) Engle-Granger : regresion de largo plazo + ADF sobre el residuo,
#                       con valores criticos de MacKinnon (1991).
#   (b) Johansen      : urca::ca.jo, estadisticos de traza y maximo autovalor,
#                       con dummies estacionales centradas y dummy COVID.
#
# Salidas: output/tables/cointegration.csv
#          output/tables/cointegration_johansen_beta.csv
#          output/figs/04_residuo_lp_*.png
# ============================================================================

source(here::here("R", "00_utils.R"))
suppressPackageStartupMessages(library(urca))

cfg <- load_config(); set_project_seed(cfg); ensure_dirs(cfg)
msg_step("04_cointegration: inicio")
panel <- read_panel(cfg)
df <- panel$data; segs <- panel$segmentos; act <- panel$actividad
ln_act <- paste0("ln_", act)

eg_cv <- readr::read_csv(here::here("data", "reference", "eg_mackinnon_cv.csv"),
                         comment = "#", show_col_types = FALSE)

kmax <- function(n) max(1L, floor(12 * (n / 100)^0.25))

# ---------------------------------------------------------------------------
# (a) Engle-Granger
# ---------------------------------------------------------------------------
eg_test <- function(d, dep, regs, estacional) {
  rhs <- regs
  if (estacional) rhs <- c(rhs, panel$dummies_estacionales)
  fml <- stats::as.formula(paste(dep, "~", paste(rhs, collapse = " + ")))
  sub <- d[stats::complete.cases(d[, c(dep, rhs), drop = FALSE]), ]
  fit <- stats::lm(fml, data = sub)
  u <- stats::residuals(fit)
  n <- length(u)
  adf <- try(urca::ur.df(u, type = "none", lags = kmax(n), selectlags = "AIC"),
             silent = TRUE)
  stat <- if (inherits(adf, "try-error")) NA_real_ else as.numeric(adf@teststat[1])
  lags <- if (inherits(adf, "try-error")) NA_integer_ else as.integer(adf@lags)
  nv <- 1L + length(regs)
  cv <- eg_cv[eg_cv$n_vars == nv, ]
  concl <- if (is.na(stat)) "no evaluable"
    else if (stat < cv$cv_1pct)  "cointegracion al 1%"
    else if (stat < cv$cv_5pct)  "cointegracion al 5%"
    else if (stat < cv$cv_10pct) "cointegracion al 10%"
    else "no se rechaza la no-cointegracion"
  b <- stats::coef(fit)
  list(
    resumen = tibble::tibble(
      estacional = estacional, n = n, n_vars = nv,
      adf_resid_stat = stat, adf_resid_lags = lags,
      cv_1pct = cv$cv_1pct, cv_5pct = cv$cv_5pct, cv_10pct = cv$cv_10pct,
      conclusion = concl,
      r2_lp = summary(fit)$r.squared,
      # Vector cointegrante normalizado: ln q = mu + eta*ln Y + rho*ln p~
      mu = b[["(Intercept)"]],
      eta_lp = unname(b[regs[1]]),
      rho_lp = if (length(regs) > 1) unname(b[regs[2]]) else NA_real_),
    resid = tibble::tibble(fecha = sub$fecha, u = u),
    fit = fit)
}

# ---------------------------------------------------------------------------
# (b) Johansen
# ---------------------------------------------------------------------------
#' Seleccion del orden del VAR por AIC multivariado:
#' AIC(p) = log det(Sigma_p) + 2 p K^2 / T
var_lag_aic <- function(X, pmax = 6L) {
  X <- stats::na.omit(X); K <- ncol(X); Tn <- nrow(X)
  aics <- vapply(1:pmax, function(p) {
    if (Tn - p <= p * K + 2) return(Inf)
    Y <- X[(p + 1):Tn, , drop = FALSE]
    Z <- do.call(cbind, lapply(1:p, function(i) X[(p + 1 - i):(Tn - i), , drop = FALSE]))
    Z <- cbind(1, Z)
    B <- try(qr.solve(Z, Y), silent = TRUE)
    if (inherits(B, "try-error")) return(Inf)
    U <- Y - Z %*% B
    S <- crossprod(U) / nrow(U)
    dt <- determinant(S, logarithm = TRUE)
    if (!is.finite(dt$modulus)) return(Inf)
    as.numeric(dt$modulus) + 2 * p * K^2 / nrow(U)
  }, numeric(1))
  k <- which.min(aics)
  list(K = max(2L, as.integer(k)), aic = aics)
}

joh_test <- function(d, vars_sys) {
  sub <- d[stats::complete.cases(d[, c(vars_sys, "d_covid"), drop = FALSE]), ]
  X <- as.matrix(sub[, vars_sys, drop = FALSE])
  sel <- var_lag_aic(X)
  dum <- as.matrix(sub[, "d_covid", drop = FALSE])
  # Si la dummy COVID es constante dentro de la muestra, se omite.
  if (stats::sd(dum[, 1]) == 0) dum <- NULL
  run <- function(type) {
    try(urca::ca.jo(X, type = type, ecdet = "const", K = sel$K,
                    spec = "transitory", season = 12, dumvar = dum),
        silent = TRUE)
  }
  jt <- run("trace"); je <- run("eigen")
  if (inherits(jt, "try-error") || inherits(je, "try-error")) {
    return(list(resumen = tibble::tibble(
      K_var = sel$K, n = nrow(sub), r_trace = NA_integer_, r_eigen = NA_integer_,
      nota = "ca.jo fallo (muestra corta o colinealidad)"), beta = NULL))
  }
  # Numero de relaciones de cointegracion al 5%.
  #
  # urca ordena las hipotesis de forma DESCENDENTE en r: el indice 1 es
  # "r <= m-1" y el ultimo es "r = 0". El procedimiento secuencial de Johansen
  # va al revés: se contrasta primero H0: r = 0 (ultimo indice) y se sube hasta
  # la primera hipotesis que NO se rechaza; ese es el rango estimado.
  r_of <- function(j) {
    st <- j@teststat; cv <- j@cval[, "5pct"]; m <- length(st)
    for (i in rev(seq_len(m))) {        # i = m -> H0: r = 0
      if (st[i] <= cv[i]) return(as.integer(m - i))
    }
    as.integer(m)                        # se rechazan todas: rango pleno
  }
  st_tab <- tibble::tibble(
    hipotesis = trimws(sub("\\|$", "", rownames(jt@cval))),
    trace_stat = as.numeric(jt@teststat), trace_cv5 = as.numeric(jt@cval[, "5pct"]),
    eigen_stat = as.numeric(je@teststat), eigen_cv5 = as.numeric(je@cval[, "5pct"]))
  b <- jt@V[, 1]
  b_norm <- b / b[1]
  list(
    resumen = tibble::tibble(
      K_var = sel$K, n = nrow(sub),
      r_trace = r_of(jt), r_eigen = r_of(je),
      nota = if (is.null(dum)) "sin dummy COVID (constante en la muestra)" else ""),
    stats = st_tab,
    # ln q = mu + eta ln Y + rho ln p~  =>  beta normalizado con signo invertido
    beta = tibble::tibble(
      termino = names(b_norm), beta_norm = as.numeric(b_norm),
      elasticidad_implicita = -as.numeric(b_norm)))
}

# ---------------------------------------------------------------------------
# Loop por segmento
# ---------------------------------------------------------------------------
eg_rows <- list(); joh_rows <- list(); joh_beta <- list(); joh_stats <- list()

for (i in seq_len(nrow(segs))) {
  id <- segs$id[i]
  dep <- paste0("ln_q_", id)
  pt  <- paste0("ln_ptilde_", id)
  regs <- c(ln_act, pt)
  msg_step("  segmento ", id, ": ", dep, " ~ ", paste(regs, collapse = " + "))

  for (es in c(FALSE, TRUE)) {
    eg <- eg_test(df, dep, regs, estacional = es)
    eg_rows[[length(eg_rows) + 1]] <-
      dplyr::bind_cols(tibble::tibble(segmento = id, test = "Engle-Granger"),
                       eg$resumen)
    if (es) {
      p <- ggplot2::ggplot(eg$resid, ggplot2::aes(fecha, u)) +
        ggplot2::geom_hline(yintercept = 0, colour = "grey60") +
        ggplot2::geom_line(colour = "#b03a2e", linewidth = .5) +
        ggplot2::labs(
          title = paste0("Residuo de la relacion de largo plazo — ", id),
          subtitle = paste0(dep, " ~ ", paste(regs, collapse = " + "),
                            " + dummies estacionales"),
          x = NULL, y = "u") + theme_eldu()
      save_fig(p, cfg, paste0("04_residuo_lp_", id, ".png"), height = 3.6)
    }
  }

  jo <- joh_test(df, c(dep, regs))
  joh_rows[[length(joh_rows) + 1]] <-
    dplyr::bind_cols(tibble::tibble(segmento = id, test = "Johansen"), jo$resumen)
  if (!is.null(jo$beta))
    joh_beta[[length(joh_beta) + 1]] <-
      dplyr::bind_cols(tibble::tibble(segmento = id), jo$beta)
  if (!is.null(jo$stats))
    joh_stats[[length(joh_stats) + 1]] <-
      dplyr::bind_cols(tibble::tibble(segmento = id), jo$stats)
}

eg_tab <- dplyr::bind_rows(eg_rows)
joh_tab <- dplyr::bind_rows(joh_rows)

coint <- dplyr::bind_rows(
  eg_tab %>% dplyr::mutate(dplyr::across(dplyr::everything(), as.character)),
  joh_tab %>% dplyr::mutate(dplyr::across(dplyr::everything(), as.character))
)
write_table_out(coint, cfg, "cointegration.csv")
write_table_out(eg_tab, cfg, "cointegration_engle_granger.csv")
if (length(joh_beta) > 0)
  write_table_out(dplyr::bind_rows(joh_beta), cfg, "cointegration_johansen_beta.csv")
if (length(joh_stats) > 0)
  write_table_out(dplyr::bind_rows(joh_stats), cfg, "cointegration_johansen_stats.csv")

print(as.data.frame(eg_tab[, c("segmento", "estacional", "n", "adf_resid_stat",
                               "cv_5pct", "conclusion", "eta_lp", "rho_lp")]),
      digits = 3)
print(as.data.frame(joh_tab), digits = 3)

sin_coint <- eg_tab %>%
  dplyr::filter(estacional, conclusion == "no se rechaza la no-cointegracion")
if (nrow(sin_coint) > 0) {
  msg_warn("Engle-Granger no detecta cointegracion en: ",
           paste(sin_coint$segmento, collapse = ", "),
           ". El bounds test de PSS en 05 es la prueba de referencia ",
           "(mas potente y valida con regresores I(0)/I(1) mezclados).")
}
msg_step("04_cointegration: fin")
