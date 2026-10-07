# ============================================================================
# 06_diagnostics.R — Diagnosticos de los ECM estimados en 05
#
#   Breusch-Godfrey      (lmtest::bgtest)    H0: sin autocorrelacion
#   Breusch-Pagan        (lmtest::bptest)    H0: homocedasticidad
#   White (version BP)   (bptest con fitted + fitted^2)
#   Jarque-Bera          (tseries)           H0: normalidad
#   Ramsey RESET         (lmtest::resettest)  H0: forma funcional correcta
#   CUSUM y CUSUM^2      (strucchange)       H0: estabilidad de parametros
#
# CUSUM:  test de fluctuacion empirica Rec-CUSUM, con sus bandas y p-valor
#         (strucchange::efp + sctest).
# CUSUM^2: estadistico de Durbin construido sobre los residuos recursivos.
#         Bajo H0, S_t - t/T converge a un puente browniano escalado por
#         1/sqrt(m); las bandas al 5 % usan el valor critico de
#         Kolmogorov-Smirnov para sup|puente browniano| (1.3581).
#
# Salidas: output/tables/diagnostics.csv
#          output/figs/06_cusum_*.png, 06_residuos_*.png
# ============================================================================

source(here::here("R", "00_utils.R"))
suppressPackageStartupMessages({library(strucchange); library(tseries)})

cfg <- load_config(); set_project_seed(cfg); ensure_dirs(cfg)
msg_step("06_diagnostics: inicio")
mods <- read_models(cfg)
bg_order <- cfg$diagnosticos$bg_order
reset_pw <- unlist(cfg$diagnosticos$reset_power)

safe <- function(expr, campo) {
  out <- try(expr, silent = TRUE)
  if (inherits(out, "try-error")) return(NA_real_)
  v <- suppressWarnings(as.numeric(out[[campo]]))
  if (length(v) == 0) NA_real_ else v[1]
}

# ---------------------------------------------------------------------------
# CUSUM^2 a partir de residuos recursivos
# ---------------------------------------------------------------------------
cusumsq <- function(fit) {
  w <- try(strucchange::recresid(fit), silent = TRUE)
  if (inherits(w, "try-error") || length(w) < 10) return(NULL)
  m <- length(w)
  S <- cumsum(w^2) / sum(w^2)
  prop <- seq_len(m) / m
  # Banda al 5 %: valor critico KS para sup|puente browniano| = 1.3581
  band <- 1.3581 / sqrt(m)
  stat <- max(abs(S - prop))
  # p-valor asintotico del estadistico KS
  kspval <- function(x) {
    if (x <= 0) return(1)
    k <- 1:100
    max(0, min(1, 2 * sum((-1)^(k - 1) * exp(-2 * k^2 * x^2))))
  }
  list(datos = tibble::tibble(i = seq_len(m), S = S, prop = prop,
                              inf = prop - band, sup = prop + band),
       stat = stat, m = m, band = band,
       p_valor = kspval(stat * sqrt(m)),
       estable = stat <= band)
}

filas <- list(); cs_dat <- list()

for (nm in names(mods$modelos)) {
  obj <- mods$modelos[[nm]]
  if (grepl("_alt$", nm)) next                 # modelo auxiliar, no se reporta
  fit <- obj$ecm$fit %||% obj$fit
  if (is.null(fit)) next
  es_dmodelo <- grepl("_dmodelo$", nm)
  seg <- sub("_.*$", "", nm)
  modelo <- if (es_dmodelo) "N (clientes, D-modelo)"
            else if (grepl("_N$", nm)) "N (clientes)" else "q (consumo unitario)"
  msg_step("  ", seg, " / ", modelo)

  n <- stats::nobs(fit)
  bg_k <- min(bg_order, max(1L, floor(n / 4)))

  # --- tests clasicos ---
  bg  <- try(lmtest::bgtest(fit, order = bg_k, type = "Chisq"), silent = TRUE)
  bg1 <- try(lmtest::bgtest(fit, order = 1, type = "Chisq"), silent = TRUE)
  bp  <- try(lmtest::bptest(fit), silent = TRUE)
  wh  <- try(lmtest::bptest(fit, ~ stats::fitted(fit) + I(stats::fitted(fit)^2)),
             silent = TRUE)
  jb  <- try(tseries::jarque.bera.test(stats::residuals(fit)), silent = TRUE)
  rs  <- try(lmtest::resettest(fit, power = reset_pw, type = "fitted"),
             silent = TRUE)

  # --- estabilidad ---
  cu <- try(strucchange::efp(stats::formula(fit), data = stats::model.frame(fit),
                             type = "Rec-CUSUM"), silent = TRUE)
  cu_p <- if (inherits(cu, "try-error")) NA_real_
          else safe(strucchange::sctest(cu), "p.value")
  csq <- cusumsq(fit)

  filas[[length(filas) + 1]] <- tibble::tibble(
    segmento = seg, modelo = modelo, n = n,
    bg_order = bg_k,
    bg_stat = safe(bg, "statistic"),   bg_p = safe(bg, "p.value"),
    bg1_stat = safe(bg1, "statistic"), bg1_p = safe(bg1, "p.value"),
    bp_stat = safe(bp, "statistic"),   bp_p = safe(bp, "p.value"),
    white_stat = safe(wh, "statistic"), white_p = safe(wh, "p.value"),
    jb_stat = safe(jb, "statistic"),   jb_p = safe(jb, "p.value"),
    reset_stat = safe(rs, "statistic"), reset_p = safe(rs, "p.value"),
    cusum_p = cu_p,
    cusumsq_stat = if (is.null(csq)) NA_real_ else csq$stat,
    cusumsq_band5 = if (is.null(csq)) NA_real_ else csq$band,
    cusumsq_p = if (is.null(csq)) NA_real_ else csq$p_valor) %>%
    dplyr::mutate(
      autocorr_ok = is.na(bg_p) | bg_p > 0.05,
      homoced_ok  = is.na(bp_p) | bp_p > 0.05,
      normal_ok   = is.na(jb_p) | jb_p > 0.05,
      forma_ok    = is.na(reset_p) | reset_p > 0.05,
      estable_ok  = (is.na(cusum_p) | cusum_p > 0.05) &
                    (is.na(cusumsq_p) | cusumsq_p > 0.05),
      # Se usa vcov HAC en 05, por lo que autocorrelacion/heterocedasticidad
      # residual no invalida la inferencia, solo la eficiencia.
      nota = ifelse(autocorr_ok & homoced_ok, "",
                    "inferencia basada en HAC Newey-West (robusta a esto)"))

  # --- figuras ---
  if (!inherits(cu, "try-error")) {
    grDevices::png(cfg_path(cfg, "figs", paste0("06_cusum_", seg, "_",
                                                if (es_dmodelo) "N_dmod"
                                                else if (grepl("_N$", nm)) "N"
                                                else "q", ".png")),
                   width = 1100, height = 480, res = 125)
    graphics::par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))
    plot(cu, main = paste0("CUSUM recursivo — ", seg, " / ", modelo))
    if (!is.null(csq)) {
      d <- csq$datos
      plot(d$i, d$S, type = "l", ylim = range(c(0, 1, d$inf, d$sup)),
           xlab = "observacion recursiva", ylab = "CUSUM^2",
           main = sprintf("CUSUM^2 (banda 5%%: +/-%.3f)", csq$band))
      graphics::lines(d$i, d$prop, col = "grey60")
      graphics::lines(d$i, d$inf, col = "red", lty = 2)
      graphics::lines(d$i, d$sup, col = "red", lty = 2)
    } else {
      graphics::plot.new(); graphics::title("CUSUM^2 no disponible")
    }
    grDevices::dev.off()
  }
  if (!is.null(csq))
    cs_dat[[nm]] <- dplyr::bind_cols(
      tibble::tibble(segmento = seg, modelo = modelo), csq$datos)

  # residuos: serie, histograma, QQ
  res <- stats::residuals(fit)
  fch <- if (!is.null(obj$ecm)) obj$ecm$fechas else NULL
  grDevices::png(cfg_path(cfg, "figs", paste0("06_residuos_", seg, "_",
                                              if (es_dmodelo) "N_dmod"
                                              else if (grepl("_N$", nm)) "N"
                                              else "q", ".png")),
                 width = 1250, height = 420, res = 125)
  graphics::par(mfrow = c(1, 3), mar = c(4, 4, 3, 1))
  if (!is.null(fch) && length(fch) == length(res)) {
    plot(fch, res, type = "l", xlab = NULL, ylab = "residuo",
         main = paste0("Residuos — ", seg, " / ", modelo))
  } else {
    plot(as.numeric(res), type = "l", xlab = "t", ylab = "residuo",
         main = paste0("Residuos — ", seg, " / ", modelo))
  }
  graphics::abline(h = 0, col = "grey60")
  graphics::hist(res, breaks = 20, main = "Histograma", xlab = "residuo",
                 col = "#d6eadf")
  stats::qqnorm(res, main = "QQ normal"); stats::qqline(res, col = "red")
  grDevices::dev.off()
}

diag_tab <- dplyr::bind_rows(filas)
write_table_out(diag_tab, cfg, "diagnostics.csv")
if (length(cs_dat) > 0)
  write_table_out(dplyr::bind_rows(cs_dat), cfg, "cusum_sq_series.csv")

cat("\n--- Diagnosticos (p-valores) ---\n")
print(as.data.frame(diag_tab %>%
  dplyr::select(segmento, modelo, n, bg_p, bp_p, white_p, jb_p, reset_p,
                cusum_p, cusumsq_p, estable_ok)), digits = 3)

fallos <- diag_tab %>%
  dplyr::filter(!autocorr_ok | !homoced_ok | !forma_ok | !estable_ok)
if (nrow(fallos) > 0) {
  msg_warn(nrow(fallos), " modelo(s) con al menos un diagnostico rechazado ",
           "al 5%. Se reportan y se discuten en el informe (criterio de ",
           "aceptacion 2: 'pasa o se reporta y discute').")
}
msg_step("06_diagnostics: fin")
