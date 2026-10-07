# ============================================================================
# 05_ardl_ecm.R — NUCLEO: ARDL / Modelo de Correccion de Errores
#
# Por segmento k se estima:
#
#  (A) Consumo unitario — ECM condicional (parametrizacion UECM del ARDL):
#      D ln q_t = c + sum psi_i D ln q_{t-i} + sum omega_ji D ln x_{j,t-i}
#                 + pi_y ln q_{t-1} + sum pi_j ln x_{j,t-1} + phi ENSO + exog
#      con   lambda = -pi_y   y   elasticidad LP de x_j = -pi_j / pi_y
#      (equivalente a   -lambda ( ln q_{t-1} - mu - eta ln Y_{t-1}
#                                 - rho ln p~_{t-1} )   del planteamiento).
#
#  (B) Clientes — (B1) D ln N_t = alpha + beta D ln ACT_t + e_t   [especificado]
#                 (B2) ECM para ln N (misma maquinaria que A)      [largo plazo]
#
# Pasos: seleccion de ordenes por AIC/BIC sobre muestra comun -> bounds test de
# Pesaran-Shin-Smith -> estimacion UECM -> elasticidades de largo plazo por
# delta-method con vcov HAC (Newey-West).
#
# Salidas: output/tables/elasticidades.csv            (tidy, con IC 95%)
#          output/tables/elasticidades_resumen.csv    (una fila por modelo)
#          output/tables/ardl_seleccion.csv
#          output/tables/bounds_test.csv
#          output/tables/coeficientes_corto_plazo.csv
#          output/tables/enso_relevancia.csv
#          output/tables/actividad_alternativa.csv
#          data/processed/modelos.rds
# ============================================================================

source(here::here("R", "00_utils.R"))
suppressPackageStartupMessages(library(ARDL))

cfg <- load_config(); set_project_seed(cfg); ensure_dirs(cfg)
msg_step("05_ardl_ecm: inicio")
panel <- read_panel(cfg)
df <- panel$data; segs <- panel$segmentos; act <- panel$actividad
ln_act <- paste0("ln_", act)

#' Etiqueta legible del orden ARDL. Se evita "1,1,1" porque readr lo
#' re-interpreta como el numero 111 al leer el CSV.
fmt_order <- function(o) paste0("ARDL(", paste(as.integer(o), collapse = "-"), ")")

conf     <- cfg$forecast$nivel_confianza
crit     <- cfg$ardl$criterio_seleccion
max_pd   <- cfg$ardl$max_pd
max_qd   <- cfg$ardl$max_qd
hac_lag  <- cfg$ardl$hac_lag
bcase    <- cfg$ardl$bounds_case
estac    <- panel$dummies_estacionales
exog_cfg <- panel$exogenos                      # nino34 / d_covid si existen
exog_all <- c(exog_cfg, estac)

# ---------------------------------------------------------------------------
# Bounds test de Pesaran-Shin-Smith via paquete ARDL (implementacion de
# referencia, replica PSS 2001). Se le pasa el mismo ARDL(p, q) seleccionado.
# ---------------------------------------------------------------------------
ventana_ts <- function(d, vars) {
  ok <- stats::complete.cases(d[, vars, drop = FALSE])
  if (!any(ok)) return(NULL)
  r <- range(which(ok))
  if (any(!ok[r[1]:r[2]])) {            # huecos internos: usar el bloque final
    rl <- rle(ok); fin <- cumsum(rl$lengths)
    ini <- fin - rl$lengths + 1
    sel <- which(rl$values)
    j <- sel[which.max(rl$lengths[sel])]
    r <- c(ini[j], fin[j])
  }
  sub <- d[r[1]:r[2], vars, drop = FALSE]
  f0 <- d$fecha[r[1]]
  stats::ts(as.matrix(sub), frequency = 12,
            start = c(lubridate::year(f0), lubridate::month(f0)))
}

bounds_ardl <- function(d, dep, lev, exog, ardl_order, case) {
  vars <- c(dep, lev, exog)
  tsd <- ventana_ts(d, vars)
  if (is.null(tsd)) return(NULL)
  # Exogenas constantes en la ventana rompen la estimacion: se omiten.
  exog_ok <- exog[vapply(exog, function(e)
    stats::sd(as.numeric(tsd[, e])) > 0, logical(1))]
  fml_txt <- paste(dep, "~", paste(lev, collapse = " + "))
  if (length(exog_ok) > 0)
    fml_txt <- paste(fml_txt, "|", paste(exog_ok, collapse = " + "))
  fit <- try(ARDL::ardl(stats::as.formula(fml_txt), data = tsd,
                        order = as.integer(ardl_order)), silent = TRUE)
  if (inherits(fit, "try-error")) {
    msg_warn("ARDL::ardl fallo para ", dep, ": ",
             conditionMessage(attr(fit, "condition")))
    return(NULL)
  }
  # Los valores criticos de PSS se derivan con la matriz de covarianzas
  # convencional; por eso el bounds test se reporta con vcov estandar y la
  # inferencia sobre las elasticidades con HAC (practica habitual).
  ft <- try(ARDL::bounds_f_test(fit, case = case, alpha = 0.05, pvalue = TRUE),
            silent = TRUE)
  tt <- try(ARDL::bounds_t_test(fit, case = case, alpha = 0.05, pvalue = TRUE),
            silent = TRUE)
  mult <- try(ARDL::multipliers(fit), silent = TRUE)

  # Extraccion segura: siempre devuelve un escalar (NA si no esta disponible).
  sc1 <- function(x) {
    x <- suppressWarnings(as.numeric(x))
    if (length(x) == 0 || !is.finite(x[1])) NA_real_ else x[1]
  }
  getn <- function(o, f) if (inherits(o, "try-error")) NA_real_ else
    sc1(tryCatch(f(o), error = function(e) NA_real_))
  tab_col <- function(o, col) {
    if (inherits(o, "try-error") || is.null(o$tab)) return(NA_real_)
    sc1(o$tab[[col]])
  }
  list(
    fit = fit,
    tabla = tibble::tibble(
      ardl_order = fmt_order(ardl_order),
      case = case,
      F_stat = getn(ft, function(o) o$statistic),
      F_pvalue = getn(ft, function(o) o$p.value),
      F_I0_5pct = tab_col(ft, "Lower-bound I(0)"),
      F_I1_5pct = tab_col(ft, "Upper-bound I(1)"),
      t_stat = getn(tt, function(o) o$statistic),
      t_pvalue = getn(tt, function(o) o$p.value),
      t_I0_5pct = tab_col(tt, "Lower-bound I(0)"),
      t_I1_5pct = tab_col(tt, "Upper-bound I(1)"),
      fuente_cv = "paquete ARDL (Pesaran, Shin & Smith 2001)",
      vcov_bounds = "convencional (CV de PSS)"),
    multipliers = if (inherits(mult, "try-error")) NULL else
      tibble::as_tibble(mult))
}

#' Lee un campo de la tabla de bounds devolviendo siempre un escalar.
bget <- function(bt, campo) {
  if (is.null(bt) || is.null(bt$tabla) || nrow(bt$tabla) == 0) return(NA_real_)
  v <- bt$tabla[[campo]]
  if (is.null(v) || length(v) == 0) return(NA_real_)
  as.numeric(v[1])
}

interpretar_bounds <- function(Fs, p) {
  Fs <- if (length(Fs) == 0) NA_real_ else Fs[1]
  p  <- if (length(p) == 0) NA_real_ else p[1]
  if (is.na(Fs)) return("no evaluable")
  if (is.na(p)) return("ver estadistico F contra los bounds")
  if (p < 0.01) "cointegracion al 1%"
  else if (p < 0.05) "cointegracion al 5%"
  else if (p < 0.10) "cointegracion al 10%"
  else "no se rechaza la ausencia de relacion de nivel"
}

# ---------------------------------------------------------------------------
# Estimacion completa de un bloque ECM
# ---------------------------------------------------------------------------
estimar_bloque <- function(d, segmento, modelo, dep, lev, exog, etiquetas) {
  msg_step("  [", segmento, "/", modelo, "] ", dep, " <- ",
           paste(lev, collapse = ", "))

  sel <- select_ecm_orders(d, dep, lev, exog, max_pd, max_qd, crit)
  ecm <- fit_ecm(d, sel$spec)
  lr  <- lr_from_ecm(ecm, lag = hac_lag, conf = conf)

  bt <- bounds_ardl(d, dep, lev, exog, sel$ardl_order, bcase)

  sm <- summary(ecm$fit)
  n  <- stats::nobs(ecm$fit)

  # --- tabla tidy de elasticidades de largo plazo + lambda ---
  lp <- lr$lp %>%
    dplyr::mutate(
      segmento = segmento, modelo = modelo,
      concepto = etiquetas[match(variable, names(etiquetas))],
      .before = 1)
  lam <- lr$lambda %>%
    dplyr::mutate(segmento = segmento, modelo = modelo,
                  concepto = "velocidad de ajuste", .before = 1)
  tidy_lr <- dplyr::bind_rows(lp, lam) %>%
    dplyr::mutate(n = n, r2 = sm$r.squared, r2_adj = sm$adj.r.squared,
                  ardl_order = fmt_order(sel$ardl_order),
                  criterio = crit, se_tipo = "HAC Newey-West")

  # --- coeficientes de corto plazo con HAC ---
  ct <- lr$coeftest
  corto <- tibble::tibble(
    segmento = segmento, modelo = modelo,
    termino = gsub("`", "", rownames(ct)),
    estimado = ct[, 1], se_hac = ct[, 2], stat = ct[, 3], p_valor = ct[, 4]) %>%
    dplyr::mutate(bloque = dplyr::case_when(
      grepl("^L1_", termino) ~ "nivel (largo plazo)",
      grepl("^d_", termino)  ~ "diferencias (corto plazo)",
      termino == "(Intercept)" ~ "constante",
      TRUE ~ "exogena"))

  # --- resumen de una fila ---
  pick <- function(v, col) {
    x <- lr$lp[[col]][lr$lp$variable == v]
    if (length(x) == 0) NA_real_ else x[1]
  }
  resumen <- tibble::tibble(
    segmento = segmento, modelo = modelo, dependiente = dep,
    n = n, muestra_ini = format(min(ecm$fechas)), muestra_fin = format(max(ecm$fechas)),
    ardl_order = fmt_order(sel$ardl_order), criterio = crit,
    n_muestra_comun_seleccion = sel$n_muestra_comun,
    eta_lp = pick(lev[1], "estimado"), eta_se = pick(lev[1], "se"),
    eta_ic_inf = pick(lev[1], "ic_inf"), eta_ic_sup = pick(lev[1], "ic_sup"),
    eta_p = pick(lev[1], "p_valor"),
    rho_lp = if (length(lev) > 1) pick(lev[2], "estimado") else NA_real_,
    rho_se = if (length(lev) > 1) pick(lev[2], "se") else NA_real_,
    rho_ic_inf = if (length(lev) > 1) pick(lev[2], "ic_inf") else NA_real_,
    rho_ic_sup = if (length(lev) > 1) pick(lev[2], "ic_sup") else NA_real_,
    rho_p = if (length(lev) > 1) pick(lev[2], "p_valor") else NA_real_,
    lambda = lr$lambda$estimado, lambda_se = lr$lambda$se,
    lambda_ic_inf = lr$lambda$ic_inf, lambda_ic_sup = lr$lambda$ic_sup,
    lambda_p = lr$lambda$p_valor,
    r2 = sm$r.squared, r2_adj = sm$adj.r.squared,
    sigma = sm$sigma,
    bounds_F   = bget(bt, "F_stat"),
    bounds_F_p = bget(bt, "F_pvalue"),
    bounds_F_I0_5pct = bget(bt, "F_I0_5pct"),
    bounds_F_I1_5pct = bget(bt, "F_I1_5pct"),
    bounds_t   = bget(bt, "t_stat"),
    bounds_t_p = bget(bt, "t_pvalue")) %>%
    dplyr::mutate(bounds_conclusion = interpretar_bounds(bounds_F, bounds_F_p),
                  signo_eta_ok = !is.na(eta_lp) & eta_lp > 0,
                  signo_rho_ok = is.na(rho_lp) | rho_lp <= 0,
                  lambda_ok = lambda > 0 & lambda_p < 0.10)

  # Cruce de control: multiplicadores del paquete ARDL vs delta-method propio
  cruce <- NULL
  if (!is.null(bt) && !is.null(bt$multipliers)) {
    mm <- bt$multipliers
    nm_col <- intersect(c("term", "Term"), names(mm))[1]
    est_col <- intersect(c("estimate", "Estimate"), names(mm))[1]
    if (!is.na(nm_col) && !is.na(est_col)) {
      cruce <- tibble::tibble(
        segmento = segmento, modelo = modelo,
        termino = as.character(mm[[nm_col]]),
        lp_paquete_ARDL = as.numeric(mm[[est_col]])) %>%
        dplyr::left_join(
          tibble::tibble(termino = lr$lp$variable,
                         lp_delta_method = lr$lp$estimado),
          by = "termino")
    }
  }

  list(resumen = resumen, tidy = tidy_lr, corto = corto,
       seleccion = dplyr::bind_cols(
         tibble::tibble(segmento = segmento, modelo = modelo), sel$tabla),
       bounds = if (is.null(bt)) NULL else
         dplyr::bind_cols(tibble::tibble(segmento = segmento, modelo = modelo),
                          bt$tabla),
       cruce = cruce,
       objeto = list(ecm = ecm, lr = lr, spec = sel$spec,
                     ardl_order = sel$ardl_order,
                     dep = dep, lev = lev, exog = exog,
                     terms = ecm$terms, dropped = ecm$dropped))
}

# ---------------------------------------------------------------------------
# Loop principal
# ---------------------------------------------------------------------------
acc <- list(resumen = list(), tidy = list(), corto = list(), seleccion = list(),
            bounds = list(), cruce = list())
modelos <- list()
cli_simple <- list()
alt_act <- list()

for (i in seq_len(nrow(segs))) {
  id <- segs$id[i]

  # ---------------- (A) consumo unitario ----------------
  dep_q <- paste0("ln_q_", id)
  pt    <- paste0("ln_ptilde_", id)
  et <- stats::setNames(c("elasticidad-ingreso de largo plazo",
                          "elasticidad-precio de largo plazo"),
                        c(ln_act, pt))
  bq <- estimar_bloque(df, id, "q (consumo unitario)", dep_q, c(ln_act, pt),
                       exog_all, et)
  for (k in names(acc)) if (!is.null(bq[[k]])) acc[[k]][[length(acc[[k]]) + 1]] <- bq[[k]]
  modelos[[paste0(id, "_q")]] <- bq$objeto

  # ---------------- (B2) clientes, ECM ----------------
  dep_n <- paste0("ln_cli_", id)
  etn <- stats::setNames("elasticidad-actividad de largo plazo (clientes)", ln_act)
  bn <- estimar_bloque(df, id, "N (clientes)", dep_n, ln_act,
                       exog_all, etn)
  for (k in names(acc)) if (!is.null(bn[[k]])) acc[[k]][[length(acc[[k]]) + 1]] <- bn[[k]]
  modelos[[paste0(id, "_N")]] <- bn$objeto

  # ---------------- (B1) clientes, especificacion en diferencias ----------------
  dsub <- tibble::tibble(fecha = df$fecha,
                         dN = D(df[[dep_n]]), dACT = D(df[[ln_act]]),
                         d_covid = df$d_covid)
  dsub <- dsub[stats::complete.cases(dsub), ]
  fml <- if (stats::sd(dsub$d_covid) > 0) dN ~ dACT + d_covid else dN ~ dACT
  f_cli <- stats::lm(fml, data = as.data.frame(dsub))
  V <- hac_vcov(f_cli, hac_lag)
  ctc <- lmtest::coeftest(f_cli, vcov. = V)
  z <- stats::qnorm(1 - (1 - conf) / 2)
  cli_simple[[id]] <- tibble::tibble(
    segmento = id, modelo = "N (clientes, D-modelo)",
    termino = rownames(ctc), estimado = ctc[, 1], se_hac = ctc[, 2],
    stat = ctc[, 3], p_valor = ctc[, 4],
    ic_inf = ctc[, 1] - z * ctc[, 2], ic_sup = ctc[, 1] + z * ctc[, 2],
    n = stats::nobs(f_cli), r2 = summary(f_cli)$r.squared)
  modelos[[paste0(id, "_N_dmodelo")]] <-
    list(fit = f_cli, vcov = V, dep = dep_n, act = ln_act,
         sigma = summary(f_cli)$sigma)

  # ---------------- actividad alternativa (VAB agro) ----------------
  act_alt <- cfg$transformaciones$actividad_alternativa
  ln_alt <- if (!is.null(act_alt)) paste0("ln_", act_alt) else NA_character_
  if (!is.na(ln_alt) && ln_alt %in% names(df)) {
    ba <- try(estimar_bloque(df, id, "q con VAB agro", dep_q, c(ln_alt, pt),
                             exog_all,
                             stats::setNames(c("elasticidad-VAB agro LP",
                                               "elasticidad-precio LP"),
                                             c(ln_alt, pt))), silent = TRUE)
    if (!inherits(ba, "try-error")) {
      alt_act[[id]] <- tibble::tibble(
        segmento = id,
        actividad_base = act, AIC_base = stats::AIC(bq$objeto$ecm$fit),
        eta_base = bq$resumen$eta_lp,
        actividad_alt = act_alt, AIC_alt = stats::AIC(ba$objeto$ecm$fit),
        eta_alt = ba$resumen$eta_lp,
        mejor = ifelse(stats::AIC(ba$objeto$ecm$fit) <
                         stats::AIC(bq$objeto$ecm$fit), act_alt, act),
        nota = "AIC comparable solo si ambas muestras coinciden",
        n_base = bq$resumen$n, n_alt = ba$resumen$n)
      modelos[[paste0(id, "_q_alt")]] <- ba$objeto
    }
  }
}

# ---------------------------------------------------------------------------
# Exportar
# ---------------------------------------------------------------------------
tidy_all <- dplyr::bind_rows(acc$tidy) %>%
  dplyr::select(segmento, modelo, parametro, concepto, variable,
                estimado, se, ic_inf, ic_sup, stat, p_valor,
                n, r2, r2_adj, ardl_order, criterio, se_tipo)
write_table_out(tidy_all, cfg, "elasticidades.csv")

resumen_all <- dplyr::bind_rows(acc$resumen)
write_table_out(resumen_all, cfg, "elasticidades_resumen.csv")
write_table_out(dplyr::bind_rows(acc$seleccion), cfg, "ardl_seleccion.csv")
write_table_out(dplyr::bind_rows(acc$corto), cfg, "coeficientes_corto_plazo.csv")
write_table_out(dplyr::bind_rows(cli_simple), cfg, "clientes_modelo_diferencias.csv")
if (length(acc$bounds) > 0)
  write_table_out(dplyr::bind_rows(acc$bounds), cfg, "bounds_test.csv")
if (length(acc$cruce) > 0)
  write_table_out(dplyr::bind_rows(acc$cruce), cfg,
                  "control_multiplicadores_ARDL_vs_delta.csv")
if (length(alt_act) > 0)
  write_table_out(dplyr::bind_rows(alt_act), cfg, "actividad_alternativa.csv")

# Relevancia de ENSO: coeficiente y p-valor HAC en cada ecuacion
if ("nino34" %in% exog_cfg) {
  enso <- dplyr::bind_rows(acc$corto) %>%
    dplyr::filter(termino == "nino34") %>%
    dplyr::mutate(relevante_5pct = p_valor < 0.05)
  write_table_out(enso, cfg, "enso_relevancia.csv")
  if (nrow(enso) > 0)
    msg_step("  ENSO significativo al 5% en ", sum(enso$relevante_5pct),
             " de ", nrow(enso), " ecuaciones")
}

saveRDS(list(modelos = modelos, resumen = resumen_all, tidy = tidy_all,
             cfg = cfg, panel_meta = panel[c("segmentos", "actividad",
                                             "exogenos", "dummies_estacionales",
                                             "muestras", "fuente")],
             creado = Sys.time()),
        cfg_path(cfg, "processed", "modelos.rds"))
msg_step("  -> data/processed/modelos.rds")

# ---------------------------------------------------------------------------
# Resumen en consola + chequeo de los criterios de aceptacion
# ---------------------------------------------------------------------------
cat("\n--- Elasticidades de largo plazo (consumo unitario) ---\n")
print(as.data.frame(resumen_all %>%
  dplyr::filter(grepl("^q ", modelo)) %>%
  dplyr::select(segmento, n, ardl_order, eta_lp, eta_ic_inf, eta_ic_sup,
                rho_lp, rho_ic_inf, rho_ic_sup, lambda, lambda_p,
                bounds_F, bounds_conclusion)), digits = 3)

prob <- resumen_all %>% dplyr::filter(!signo_eta_ok | !signo_rho_ok | !lambda_ok)
if (nrow(prob) > 0) {
  msg_warn("modelos que NO cumplen los signos esperados (eta>0, rho<=0, ",
           "lambda>0 y significativo):")
  print(as.data.frame(prob %>% dplyr::select(segmento, modelo, eta_lp, rho_lp,
                                             lambda, lambda_p, signo_eta_ok,
                                             signo_rho_ok, lambda_ok)), digits = 3)
  msg_warn("se reportan igual; la discusion va en output/informe_demanda_ELDU.html")
}
msg_step("05_ardl_ecm: fin")
