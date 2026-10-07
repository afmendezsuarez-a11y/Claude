# ============================================================================
# 07_forecast.R — Proyeccion mensual de volumenes por segmento (insumo DCF)
#
# Q_k,t = N_k,t * q_k,t  proyectado recursivamente con el ECM estimado en 05,
# condicionado a escenarios de actividad de Ica y tarifa real leidos de
# <data_dir>/escenarios.csv (base / optimista / pesimista).
#
# Recursion del consumo unitario (identica a la ecuacion estimada):
#   ln q_t = ln q_{t-1} + x_t' beta ,  con x_t el mismo vector de disenio del
#   UECM. Imponer eta = eta_0 equivale a fijar pi_x = -eta_0 * pi_y, lo que
#   se usa en la seccion "supuestos vs. estimado".
#
# Clientes: se usa el ECM si lambda_N > 0 y significativo al 10 %; en caso
# contrario el D-modelo (regla deterministica, documentada).
#
# Bandas: bootstrap parametrico — coeficientes ~ N(beta_hat, V_HAC) y choques
# remuestreados iid de los residuos estimados. Los escenarios son sendas
# DETERMINISTICAS: las bandas reflejan incertidumbre del modelo, no de los
# supuestos macro.
#
# Salidas: output/forecast_volumenes.xlsx  (mensual, anual, supuestos, metodo)
#          output/tables/forecast_anual.csv
#          output/tables/supuestos_vs_estimado.csv
#          output/figs/07_*.png
# ============================================================================

source(here::here("R", "00_utils.R"))

cfg <- load_config(); set_project_seed(cfg); ensure_dirs(cfg)
msg_step("07_forecast: inicio")
panel <- read_panel(cfg); mods <- read_models(cfg)
df <- panel$data; segs <- panel$segmentos; act <- panel$actividad
ln_act <- paste0("ln_", act)

H_fin   <- as.Date(cfg$forecast$fin)
n_boot  <- cfg$forecast$n_boot
h_back  <- cfg$forecast$backtest_meses %||% 24
conf    <- cfg$forecast$nivel_confianza
lam_min <- cfg$forecast$lambda_min
lam_max <- cfg$forecast$lambda_max
fy_m0   <- cfg$forecast$fy_inicio_mes

# ---------------------------------------------------------------------------
# 1. Escenarios
# ---------------------------------------------------------------------------
esc_path <- cfg_path(cfg, "data", cfg$paths$archivo_escenarios)
if (!file.exists(esc_path)) {
  stop_user("No se encuentra el archivo de escenarios",
            paste0("Buscado en: ", sub(here::here(), ".", esc_path, fixed = TRUE)),
            paste0("Crear ", cfg$paths$data_dir, "/", cfg$paths$archivo_escenarios,
                   " con los supuestos de proyeccion.\n",
                   "Plantilla y documentacion: data/raw/PLANTILLA_escenarios.csv ",
                   "y data/raw/LEEME.md."))
}
esc <- readr::read_csv(esc_path, show_col_types = FALSE)
names(esc) <- tolower(trimws(names(esc)))

g_cols <- paste0("g_tarifa_real_", tolower(segs$id))
req_esc <- c("escenario", "anio", "g_pbi_ica", g_cols)
falta_esc <- setdiff(req_esc, names(esc))
if (length(falta_esc) > 0) {
  stop_user("El archivo de escenarios no cumple el esquema",
            paste0("Columnas ausentes: ", paste(falta_esc, collapse = ", "), "\n",
                   "Columnas encontradas: ", paste(names(esc), collapse = ", ")),
            "Ver data/raw/PLANTILLA_escenarios.csv y data/raw/LEEME.md.")
}
if (!"nino34" %in% names(esc)) {
  if ("nino34" %in% panel$exogenos) {
    stop_user("Los modelos usan ENSO pero los escenarios no traen 'nino34'",
              "El ECM incluye nino34 como regresor y no se puede proyectar sin un supuesto.",
              "Agregar la columna 'nino34' a escenarios.csv (p.ej. 0 = condiciones neutras).")
  }
  esc$nino34 <- NA_real_
}

ult <- max(df$fecha[!is.na(df[[ln_act]])])
f_ini <- seq(ult, by = "month", length.out = 2)[2]
if (f_ini > H_fin) {
  stop_user("El horizonte de proyeccion ya esta cubierto por los datos",
            paste0("Ultimo mes observado: ", format(ult),
                   " | forecast$fin: ", format(H_fin)),
            "Ampliar forecast$fin en config.yml.")
}
anios_req <- seq(lubridate::year(f_ini), lubridate::year(H_fin))
escenarios <- unique(esc$escenario)
if (length(escenarios) == 0) {
  stop_user("El archivo de escenarios esta vacio",
            paste0("Archivo: ", sub(here::here(), ".", esc_path, fixed = TRUE)),
            "Agregar al menos un escenario (p.ej. 'base') con un anio por fila.")
}

# Cobertura POR ESCENARIO: que todos tengan todos los anios del horizonte.
cobertura <- purrr::map_dfr(escenarios, function(e) {
  a <- esc$anio[esc$escenario == e]
  tibble::tibble(escenario = e,
                 faltan = paste(setdiff(anios_req, a), collapse = ", "),
                 duplicados = paste(unique(a[duplicated(a)]), collapse = ", "))
})
mal <- dplyr::filter(cobertura, faltan != "" | duplicados != "")
if (nrow(mal) > 0) {
  stop_user("Los escenarios no cubren el horizonte de proyeccion",
            paste0("Horizonte requerido: ", min(anios_req), "-", max(anios_req),
                   "\n\n",
                   paste(capture.output(print(as.data.frame(mal))), collapse = "\n")),
            paste0("Completar los anios faltantes (y eliminar duplicados) en ",
                   cfg$paths$archivo_escenarios, ", para CADA escenario."))
}

# Valores faltantes en los supuestos: no se imputan.
col_sup <- c("g_pbi_ica", g_cols, if ("nino34" %in% panel$exogenos) "nino34")
na_sup <- purrr::map_dfr(col_sup, function(c0) {
  tibble::tibble(columna = c0, n_na = sum(is.na(esc[[c0]])))
}) %>% dplyr::filter(n_na > 0)
if (nrow(na_sup) > 0) {
  stop_user("Hay valores faltantes en los supuestos de escenario",
            paste(capture.output(print(as.data.frame(na_sup))), collapse = "\n"),
            paste0("Completar esas celdas en ", cfg$paths$archivo_escenarios,
                   ". El pipeline no imputa supuestos."))
}
msg_step("  escenarios: ", paste(escenarios, collapse = ", "),
         " | horizonte ", format(f_ini), " a ", format(H_fin))

# ---------------------------------------------------------------------------
# 2. Sendas exogenas futuras por escenario
# ---------------------------------------------------------------------------
fechas_f <- seq(f_ini, H_fin, by = "month")

senda_exogena <- function(nombre_esc) {
  e <- esc[esc$escenario == nombre_esc, ]
  e <- e[match(lubridate::year(fechas_f), e$anio), ]
  mcrec <- function(g) (1 + g)^(1 / 12) - 1
  out <- tibble::tibble(fecha = fechas_f)
  # Actividad
  out[[ln_act]] <- log(df[[act]][df$fecha == ult]) +
    cumsum(log1p(mcrec(e$g_pbi_ica)))
  # Tarifas reales por segmento
  for (i in seq_len(nrow(segs))) {
    id <- segs$id[i]
    col_t <- paste0("tarifa_real_", id)
    g <- e[[paste0("g_tarifa_real_", tolower(id))]]
    out[[paste0("ln_ptilde_", id)]] <- log(df[[col_t]][df$fecha == ult]) +
      cumsum(log1p(mcrec(g)))
  }
  if ("nino34" %in% names(df)) out$nino34 <- e$nino34
  out$d_covid <- 0
  out <- dplyr::bind_cols(out, seasonal_dummies(out$fecha))
  out
}

# ---------------------------------------------------------------------------
# 3. Recursion del ECM
# ---------------------------------------------------------------------------
#' "Compila" cada nombre de coeficiente en una receta (tipo, variable, rezago)
#' UNA sola vez, para que la recursion del bootstrap no haga trabajo de cadenas
#' dentro del bucle.
compile_ecm <- function(spec, nombres) {
  dep <- spec$dep
  out <- lapply(nombres, function(nm) {
    if (nm == "(Intercept)") return(list(k = "const"))
    if (nm == paste0("L1_", dep)) return(list(k = "ylag1"))
    m <- regmatches(nm, regexec(paste0("^d_", dep, "_L(\\d+)$"), nm))[[1]]
    if (length(m) == 2) return(list(k = "ydiff", j = as.integer(m[2])))
    for (x in spec$lev) {
      if (nm == paste0("L1_", x)) return(list(k = "xlag1", v = x))
      mm <- regmatches(nm, regexec(paste0("^d_", x, "_L(\\d+)$"), nm))[[1]]
      if (length(mm) == 2) return(list(k = "xdiff", v = x, j = as.integer(mm[2])))
    }
    list(k = "exog", v = nm)
  })
  names(out) <- nombres
  out
}

#' Matriz de disenio de la parte EXOGENA sobre el tramo proyectado.
#' Las columnas autorregresivas (dependen de y) se dejan en cero y se tratan
#' en el bucle escalar de la recursion.
exo_matrix <- function(full, recipes, idx) {
  nz <- length(idx)
  cols <- lapply(recipes, function(r) {
    switch(r$k,
      const = rep(1, nz),
      ylag1 = rep(0, nz),
      ydiff = rep(0, nz),
      xlag1 = full[[r$v]][idx - 1],
      xdiff = full[[r$v]][idx - r$j] - full[[r$v]][idx - r$j - 1],
      exog  = if (r$v %in% names(full)) {
        v <- full[[r$v]][idx]; ifelse(is.na(v), 0, v)
      } else rep(0, nz))
  })
  m <- do.call(cbind, cols)
  colnames(m) <- names(recipes)
  if (anyNA(m)) {
    stop_user("Hay NA en la matriz de disenio de la proyeccion",
              paste("Columnas con NA:",
                    paste(colnames(m)[apply(m, 2, anyNA)], collapse = ", ")),
              "Revisar que las sendas de escenario cubran todo el horizonte.")
  }
  m
}

#' Recursion del ECM: y_t = y_{t-1} + z_t + pi_y y_{t-1}
#'                           + sum_j psi_j (y_{t-j} - y_{t-j-1}) + shock_t
#' `Xexo` ya incorpora niveles rezagados de las x, diferencias de las x,
#' exogenas y constante.
recursion_ecm <- function(y_full, Xexo, b, recipes, idx, shocks = NULL) {
  z <- as.numeric(Xexo %*% b)
  i_y <- which(vapply(recipes, function(r) r$k == "ylag1", logical(1)))
  pi_y <- if (length(i_y) == 1) b[[i_y]] else 0
  i_d <- which(vapply(recipes, function(r) r$k == "ydiff", logical(1)))
  psi <- if (length(i_d)) b[i_d] else numeric(0)
  jj  <- if (length(i_d)) vapply(recipes[i_d], function(r) r$j, integer(1)) else integer(0)
  y <- y_full
  for (k in seq_along(idx)) {
    i <- idx[k]
    ar <- pi_y * y[i - 1]
    if (length(psi)) for (m in seq_along(psi))
      ar <- ar + psi[m] * (y[i - jj[m]] - y[i - jj[m] - 1])
    y[i] <- y[i - 1] + z[k] + ar + (if (is.null(shocks)) 0 else shocks[k])
  }
  y[idx]
}

#' Solucion de largo plazo estatica (fallback si lambda no es utilizable):
#' ln q_t = mu + eta ln Y_t + rho ln p~_t
recursion_estatica <- function(full, spec, eta_rho, mu, i_start, i_end) {
  y <- full[[spec$dep]]
  for (i in i_start:i_end) {
    y[i] <- mu + sum(vapply(seq_along(spec$lev), function(j)
      eta_rho[j] * full[[spec$lev[j]]][i], numeric(1)))
  }
  y
}

#' Normal multivariada estable incluso si V no es definida positiva.
rmvn <- function(n, mu, V) {
  ev <- eigen((V + t(V)) / 2, symmetric = TRUE)
  lam <- pmax(ev$values, 0)
  A <- ev$vectors %*% diag(sqrt(lam), length(lam))
  matrix(rep(mu, each = n), n) + matrix(stats::rnorm(n * length(mu)), n) %*% t(A)
}

coef_norm <- function(fit) {
  b <- stats::coef(fit); names(b) <- gsub("`", "", names(b)); b
}

#' Proyeccion (puntual + bootstrap) de una ecuacion ECM.
proyectar_ecm <- function(obj, hist, fut, B, forzar_eta = NULL) {
  spec <- obj$spec
  b <- coef_norm(obj$ecm$fit)
  V <- obj$lr$vcov
  dimnames(V) <- list(gsub("`", "", rownames(V)), gsub("`", "", colnames(V)))
  V <- V[names(b), names(b), drop = FALSE]
  res <- as.numeric(stats::residuals(obj$ecm$fit))

  cols <- unique(c(spec$dep, spec$lev, spec$exog))
  full <- dplyr::bind_rows(
    hist[, intersect(c("fecha", cols), names(hist)), drop = FALSE],
    fut[, intersect(c("fecha", cols), names(fut)), drop = FALSE])
  for (c0 in cols) if (!c0 %in% names(full)) full[[c0]] <- NA_real_
  idx <- (nrow(hist) + 1L):nrow(full)

  nm_y <- paste0("L1_", spec$dep)
  pi_y <- b[[nm_y]]
  lambda <- -pi_y
  metodo <- if (lambda > lam_min && lambda < lam_max) "ECM" else "LP estatico"

  # Imponer una elasticidad-ingreso dada (contrafactual de supuestos del DCF).
  #
  # Cambiar solo pi_x moveria tambien el NIVEL del atractor de largo plazo
  # (mu = -c/pi_y queda fijo), lo que confunde un cambio de pendiente con un
  # salto de nivel. Por eso se reajusta la constante para que el equilibrio de
  # largo plazo en el ultimo punto observado sea el mismo:
  #   mu* + eta_0 x_ref = mu + eta_hat x_ref  =>  c* = c + pi_y (eta_0 - eta_hat) x_ref
  # Asi la diferencia proyectada refleja unicamente la distinta RESPUESTA al
  # crecimiento de la actividad, que es lo que el supuesto del DCF fija.
  x_ref <- hist[[spec$lev[1]]][nrow(hist)]
  forzar <- function(bb) {
    if (is.null(forzar_eta)) return(bb)
    nm_x <- paste0("L1_", spec$lev[1])
    eta_hat <- -bb[[nm_x]] / bb[[nm_y]]
    bb[[nm_x]] <- -forzar_eta * bb[[nm_y]]
    if ("(Intercept)" %in% names(bb))
      bb[["(Intercept)"]] <- bb[["(Intercept)"]] +
        bb[[nm_y]] * (forzar_eta - eta_hat) * x_ref
    bb
  }

  recipes <- compile_ecm(spec, names(b))

  if (metodo == "ECM") {
    Xexo <- exo_matrix(full, recipes, idx)
    y_hat <- recursion_ecm(full[[spec$dep]], Xexo, forzar(b), recipes, idx)
  } else {
    eta_rho <- vapply(spec$lev, function(v) -b[[paste0("L1_", v)]] / pi_y, numeric(1))
    fitted_lp <- hist[[spec$dep]] -
      Reduce(`+`, lapply(seq_along(spec$lev), function(j)
        eta_rho[j] * hist[[spec$lev[j]]]))
    mu <- mean(fitted_lp, na.rm = TRUE)
    if (!is.null(forzar_eta)) {
      # Mismo reanclaje que en la rama ECM: solo cambia la pendiente.
      mu <- mu + (eta_rho[1] - forzar_eta) * x_ref
      eta_rho[1] <- forzar_eta
    }
    y_all <- recursion_estatica(full, spec, eta_rho, mu, min(idx), max(idx))
    y_hat <- y_all[idx]
  }

  # ---- bootstrap: coeficientes ~ N(beta_hat, V_HAC) + choques remuestreados --
  sims <- NULL; descartes <- 0L
  if (B > 0 && metodo == "ECM") {
    Xexo <- exo_matrix(full, recipes, idx)
    y_full <- full[[spec$dep]]
    draws <- rmvn(B, b, V)
    colnames(draws) <- names(b)
    nf <- length(idx)
    sims <- matrix(NA_real_, nrow = B, ncol = nf)
    for (r in seq_len(B)) {
      br <- forzar(draws[r, ])
      # Un lambda* fuera de (lam_min, lam_max) da una recursion explosiva:
      # esas replicas se descartan y se reporta cuantas fueron.
      if (!(-br[[nm_y]] > lam_min && -br[[nm_y]] < lam_max)) {
        descartes <- descartes + 1L; next
      }
      sims[r, ] <- recursion_ecm(y_full, Xexo, br, recipes, idx,
                                 shocks = sample(res, nf, replace = TRUE))
    }
    sims <- sims[stats::complete.cases(sims), , drop = FALSE]
  }
  list(fecha = full$fecha[idx], y = y_hat,
       sims = sims, metodo = metodo, lambda = lambda,
       descartes = descartes, B_util = if (is.null(sims)) 0L else nrow(sims))
}

#' Proyeccion del D-modelo de clientes: D ln N = a + b D ln ACT (+ c d_covid)
proyectar_dmodelo <- function(obj, hist, fut, B) {
  b <- coef_norm(obj$fit); V <- obj$vcov
  dimnames(V) <- list(gsub("`", "", rownames(V)), gsub("`", "", colnames(V)))
  res <- as.numeric(stats::residuals(obj$fit))
  dACT <- c(fut[[ln_act]][1] - hist[[ln_act]][nrow(hist)],
            diff(fut[[ln_act]]))
  n_f <- length(dACT)
  X <- cbind(`(Intercept)` = 1, dACT = dACT)
  if ("d_covid" %in% names(b)) X <- cbind(X, d_covid = 0)
  colnames(X)[2] <- "dACT"
  # El coeficiente de la pendiente se llama "dACT" en el ajuste
  b <- b[colnames(X)]
  y0 <- hist[[obj$dep]][nrow(hist)]
  y_hat <- y0 + cumsum(as.numeric(X %*% b))
  sims <- NULL
  if (B > 0) {
    draws <- rmvn(B, b, V[colnames(X), colnames(X), drop = FALSE])
    sims <- t(vapply(seq_len(B), function(r) {
      y0 + cumsum(as.numeric(X %*% draws[r, ]) +
                    sample(res, n_f, replace = TRUE))
    }, numeric(n_f)))
  }
  list(fecha = fut$fecha, y = y_hat, sims = sims, metodo = "D-modelo",
       lambda = NA_real_, descartes = 0L,
       B_util = if (is.null(sims)) 0L else nrow(sims))
}

# ---------------------------------------------------------------------------
# 4. Loop: segmento x escenario
# ---------------------------------------------------------------------------
#' Regla deterministica de eleccion del modelo de clientes.
elegir_modelo_N <- function(id) {
  r <- mods$resumen %>%
    dplyr::filter(segmento == id, modelo == "N (clientes)")
  usa_ecm <- nrow(r) == 1 && !is.na(r$lambda) && r$lambda > lam_min &&
    r$lambda < lam_max && !is.na(r$lambda_p) && r$lambda_p < 0.10
  list(usa_ecm = usa_ecm,
       razon = if (usa_ecm) "ECM: lambda_N > 0 y significativo al 10%"
               else sprintf("D-modelo: lambda_N = %.3f (p = %.3f) no cumple la regla",
                            if (nrow(r) == 1) r$lambda else NA_real_,
                            if (nrow(r) == 1) r$lambda_p else NA_real_))
}

q_alpha <- c((1 - conf) / 2, 1 - (1 - conf) / 2)

mensual <- list(); meta <- list()

for (nombre_esc in escenarios) {
  fut0 <- senda_exogena(nombre_esc)
  for (i in seq_len(nrow(segs))) {
    id <- segs$id[i]
    obj_q <- mods$modelos[[paste0(id, "_q")]]
    hist <- df[!is.na(df[[paste0("ln_q_", id)]]) & !is.na(df[[ln_act]]), ]

    pq <- proyectar_ecm(obj_q, hist, fut0, n_boot)

    sel_N <- elegir_modelo_N(id)
    pn <- if (sel_N$usa_ecm)
      proyectar_ecm(mods$modelos[[paste0(id, "_N")]], hist, fut0, n_boot)
    else
      proyectar_dmodelo(mods$modelos[[paste0(id, "_N_dmodelo")]], hist, fut0, n_boot)

    # Energia = q * N  (puntual y por replica)
    mwh <- exp(pq$y) * exp(pn$y)
    Bq <- if (is.null(pq$sims)) 0L else nrow(pq$sims)
    Bn <- if (is.null(pn$sims)) 0L else nrow(pn$sims)
    Bu <- min(Bq, Bn)
    if (Bu > 0) {
      # Replicas independientes de q y N (supuesto declarado en el informe)
      Qs <- exp(pq$sims[seq_len(Bu), , drop = FALSE]) *
            exp(pn$sims[seq_len(Bu), , drop = FALSE])
      lo <- apply(Qs, 2, stats::quantile, probs = q_alpha[1], na.rm = TRUE)
      hi <- apply(Qs, 2, stats::quantile, probs = q_alpha[2], na.rm = TRUE)
      md <- apply(Qs, 2, stats::median, na.rm = TRUE)
    } else { lo <- hi <- md <- rep(NA_real_, length(mwh)) }

    mensual[[length(mensual) + 1]] <- tibble::tibble(
      escenario = nombre_esc, segmento = id, label = segs$label[i],
      fecha = pq$fecha,
      q_mwh_cliente = exp(pq$y), clientes = exp(pn$y),
      mwh = mwh, mwh_mediana_boot = md, mwh_ic_inf = lo, mwh_ic_sup = hi,
      ln_actividad = fut0[[ln_act]], tarifa_real = exp(fut0[[paste0("ln_ptilde_", id)]]),
      metodo_q = pq$metodo, metodo_N = pn$metodo)

    meta[[length(meta) + 1]] <- tibble::tibble(
      escenario = nombre_esc, segmento = id,
      metodo_q = pq$metodo, lambda_q = pq$lambda,
      metodo_N = pn$metodo, regla_N = sel_N$razon,
      B_solicitado = n_boot, B_util_q = pq$B_util, B_util_N = pn$B_util,
      B_util_Q = Bu, descartes_lambda_q = pq$descartes,
      nivel_confianza = conf)
  }
  msg_step("  escenario '", nombre_esc, "' listo")
}

mensual <- dplyr::bind_rows(mensual)
meta <- dplyr::bind_rows(meta)

if (any(meta$metodo_q != "ECM"))
  msg_warn("algun segmento usa el fallback 'LP estatico' porque lambda no cae ",
           "en (", lam_min, ", ", lam_max, "): ver hoja 'metodologia'.")

# ---------------------------------------------------------------------------
# 4b. Backtest pseudo-fuera-de-muestra
#
# Se re-estima el modelo COMPLETO (seleccion de ordenes incluida) excluyendo
# los ultimos `backtest_meses`, y se proyecta ese tramo de forma dinamica
# usando los valores OBSERVADOS de actividad, tarifa real y ENSO. Mide el
# error de la mecanica de proyeccion, no el de los supuestos macro.
# ---------------------------------------------------------------------------
backtest_segmento <- function(id, h) {
  dep_q <- paste0("ln_q_", id); pt <- paste0("ln_ptilde_", id)
  dep_n <- paste0("ln_cli_", id)
  obs <- df[!is.na(df[[dep_q]]) & !is.na(df[[ln_act]]), ]
  if (nrow(obs) < h + 60) return(NULL)             # muestra insuficiente
  corte <- nrow(obs) - h
  train <- obs[seq_len(corte), ]
  exog_all <- c(panel$exogenos, panel$dummies_estacionales)

  armar <- function(dep, lev) {
    sel <- try(select_ecm_orders(train, dep, lev, exog_all,
                                 cfg$ardl$max_pd, cfg$ardl$max_qd,
                                 cfg$ardl$criterio_seleccion), silent = TRUE)
    if (inherits(sel, "try-error")) return(NULL)
    ecm <- try(fit_ecm(train, sel$spec), silent = TRUE)
    if (inherits(ecm, "try-error")) return(NULL)
    list(ecm = ecm, lr = lr_from_ecm(ecm, lag = cfg$ardl$hac_lag),
         spec = sel$spec)
  }
  mq <- armar(dep_q, c(ln_act, pt)); mn <- armar(dep_n, ln_act)
  if (is.null(mq) || is.null(mn)) return(NULL)

  # "Futuro" = tramo reservado, con exogenas observadas
  fut <- obs[(corte + 1):nrow(obs), ]
  pq <- proyectar_ecm(mq, train, fut, 0)
  pn <- proyectar_ecm(mn, train, fut, 0)
  real <- exp(obs[[dep_q]][(corte + 1):nrow(obs)]) *
          exp(obs[[dep_n]][(corte + 1):nrow(obs)])
  proy <- exp(pq$y) * exp(pn$y)
  # Referencia ingenua: random walk estacional (mismo mes del anio anterior)
  mwh_obs <- exp(obs[[dep_q]]) * exp(obs[[dep_n]])
  naive <- mwh_obs[(corte + 1 - 12):(nrow(obs) - 12)]
  tibble::tibble(
    segmento = id, h = h,
    desde = format(fut$fecha[1]), hasta = format(fut$fecha[nrow(fut)]),
    n_entrenamiento = nrow(train),
    mape_pct = 100 * mean(abs(proy / real - 1)),
    mape_naive_pct = 100 * mean(abs(naive / real - 1)),
    sesgo_pct = 100 * mean(proy / real - 1),
    rmse_mwh = sqrt(mean((proy - real)^2)),
    error_acumulado_pct = 100 * (sum(proy) / sum(real) - 1),
    metodo_q = pq$metodo, metodo_N = pn$metodo)
}

bt_tab <- purrr::map_dfr(segs$id, function(id) {
  r <- try(backtest_segmento(id, h_back), silent = TRUE)
  if (inherits(r, "try-error") || is.null(r)) {
    msg_warn("backtest no disponible para ", id,
             " (muestra insuficiente para reservar ", h_back, " meses)")
    return(NULL)
  }
  r
})
if (nrow(bt_tab) > 0) {
  bt_tab <- dplyr::mutate(bt_tab,
    mejor_que_naive = mape_pct < mape_naive_pct)
  write_table_out(bt_tab, cfg, "backtest.csv")
  cat("\n--- Backtest pseudo-fuera-de-muestra (", h_back, " meses) ---\n", sep = "")
  print(as.data.frame(bt_tab %>% dplyr::select(
    segmento, desde, hasta, mape_pct, mape_naive_pct, mejor_que_naive,
    sesgo_pct, error_acumulado_pct)), digits = 3)
  mal <- bt_tab %>% dplyr::filter(!mejor_que_naive)
  if (nrow(mal) > 0)
    msg_warn("en ", paste(mal$segmento, collapse = ", "),
             " el ECM no supera al random walk estacional en el backtest: ",
             "tratar esa proyeccion con cautela.")
}

# ---------------------------------------------------------------------------
# 5. Agregacion anual (anio fiscal configurable) + historico
# ---------------------------------------------------------------------------
fy <- function(fecha) {
  if (fy_m0 == 1) lubridate::year(fecha)
  else lubridate::year(fecha) + as.integer(lubridate::month(fecha) >= fy_m0)
}

anual <- mensual %>%
  dplyr::mutate(anio_fiscal = fy(fecha)) %>%
  dplyr::group_by(escenario, segmento, label, anio_fiscal) %>%
  dplyr::summarise(meses = dplyr::n(), mwh = sum(mwh),
                   mwh_ic_inf = sum(mwh_ic_inf), mwh_ic_sup = sum(mwh_ic_sup),
                   clientes_fin = dplyr::last(clientes),
                   q_prom = mean(q_mwh_cliente), .groups = "drop") %>%
  dplyr::arrange(escenario, segmento, anio_fiscal)

hist_anual <- df %>%
  dplyr::select(fecha, dplyr::all_of(segs$mwh)) %>%
  tidyr::pivot_longer(-fecha, names_to = "serie", values_to = "mwh") %>%
  dplyr::left_join(dplyr::select(segs, serie = mwh, segmento = id, label),
                   by = "serie") %>%
  dplyr::mutate(anio_fiscal = fy(fecha)) %>%
  dplyr::group_by(segmento, label, anio_fiscal) %>%
  dplyr::summarise(meses = dplyr::n(), mwh = sum(mwh), .groups = "drop") %>%
  dplyr::mutate(escenario = "historico (observado)") %>%
  dplyr::arrange(segmento, anio_fiscal)

anual_total <- anual %>%
  dplyr::group_by(escenario, anio_fiscal) %>%
  dplyr::summarise(meses = max(meses), mwh = sum(mwh),
                   mwh_ic_inf = sum(mwh_ic_inf), mwh_ic_sup = sum(mwh_ic_sup),
                   .groups = "drop") %>%
  dplyr::mutate(segmento = "TOTAL", label = "Total ELDU", .before = 1)

write_table_out(dplyr::bind_rows(anual, anual_total), cfg, "forecast_anual.csv")
write_table_out(mensual, cfg, "forecast_mensual.csv")

# ---------------------------------------------------------------------------
# 5b. Consistencia: crecimiento historico vs. proyectado
#
# Una brecha grande no es un error: suele venir de que el escenario rompe con
# la trayectoria observada de la tarifa real o del ENSO. La tabla la hace
# explicita para que quede documentada en el DCF.
# ---------------------------------------------------------------------------
cagr <- function(v, anios) if (length(v) < 2 || head(v, 1) <= 0) NA_real_ else
  100 * ((tail(v, 1) / head(v, 1))^(1 / anios) - 1)

consist <- purrr::map_dfr(seq_len(nrow(segs)), function(i) {
  id <- segs$id[i]
  qh <- df[[paste0("q_", id)]]; nh <- df[[segs$clientes[i]]]
  ok <- !is.na(qh) & qh > 0
  k <- min(60L, sum(ok))
  qh <- utils::tail(qh[ok], k); nh <- utils::tail(nh[ok], k)
  purrr::map_dfr(escenarios, function(e) {
    x <- mensual %>% dplyr::filter(segmento == id, escenario == e) %>%
      dplyr::arrange(fecha)
    a_f <- nrow(x) / 12
    tibble::tibble(
      segmento = id, escenario = e,
      anios_historia = k / 12, anios_proyeccion = a_f,
      q_hist_cagr_pct = cagr(qh, k / 12), q_proy_cagr_pct = cagr(x$q_mwh_cliente, a_f),
      N_hist_cagr_pct = cagr(nh, k / 12), N_proy_cagr_pct = cagr(x$clientes, a_f),
      Q_hist_cagr_pct = cagr(qh * nh, k / 12), Q_proy_cagr_pct = cagr(x$mwh, a_f))
  })
}) %>%
  dplyr::mutate(brecha_Q_pp = Q_proy_cagr_pct - Q_hist_cagr_pct,
                alerta = abs(brecha_Q_pp) > 3)
write_table_out(consist, cfg, "forecast_consistencia.csv")
if (any(consist$alerta, na.rm = TRUE)) {
  msg_warn("brecha > 3 pp entre crecimiento historico y proyectado en ",
           sum(consist$alerta, na.rm = TRUE), " de ", nrow(consist),
           " combinaciones segmento-escenario. Causas habituales: la senda de ",
           "tarifa real del escenario rompe con la trayectoria observada, o el ",
           "ultimo dato de ENSO difiere del supuesto. Ver ",
           "output/tables/forecast_consistencia.csv")
}

# ---------------------------------------------------------------------------
# 6. "Supuestos vs. estimado": elasticidades a dedo del modelo de valorizacion
# ---------------------------------------------------------------------------
sup <- cfg$supuestos_valorizacion$elasticidad_ingreso
sup <- sup[!vapply(sup, is.null, logical(1))]
svs <- list()
esc_base <- if ("base" %in% escenarios) "base" else escenarios[1]
fut_base <- senda_exogena(esc_base)

for (id in names(sup)) {
  if (!id %in% segs$id) next
  eta0 <- as.numeric(sup[[id]])
  r <- mods$resumen %>%
    dplyr::filter(segmento == id, startsWith(modelo, "q ("))
  if (nrow(r) != 1 || is.na(r$eta_se)) next
  tst <- test_lr_value(r$eta_lp, r$eta_se, eta0)

  obj_q <- mods$modelos[[paste0(id, "_q")]]
  hist <- df[!is.na(df[[paste0("ln_q_", id)]]) & !is.na(df[[ln_act]]), ]
  sel_N <- elegir_modelo_N(id)
  pn <- if (sel_N$usa_ecm) proyectar_ecm(mods$modelos[[paste0(id, "_N")]],
                                         hist, fut_base, 0)
        else proyectar_dmodelo(mods$modelos[[paste0(id, "_N_dmodelo")]],
                               hist, fut_base, 0)
  p_est <- proyectar_ecm(obj_q, hist, fut_base, 0)
  p_sup <- proyectar_ecm(obj_q, hist, fut_base, 0, forzar_eta = eta0)
  Q_est <- exp(p_est$y) * exp(pn$y)
  Q_sup <- exp(p_sup$y) * exp(pn$y)
  ult_fy <- max(fy(p_est$fecha))
  sel_ult <- fy(p_est$fecha) == ult_fy

  svs[[id]] <- tibble::tibble(
    segmento = id,
    eta_estimada = r$eta_lp, eta_se = r$eta_se,
    eta_ic_inf = r$eta_ic_inf, eta_ic_sup = r$eta_ic_sup,
    eta_supuesto_dcf = eta0,
    diferencia = r$eta_lp - eta0,
    supuesto_dentro_del_IC95 = eta0 >= r$eta_ic_inf & eta0 <= r$eta_ic_sup,
    z = tst$z, p_valor_h0 = tst$p_valor,
    escenario = esc_base,
    mwh_acum_estimado = sum(Q_est), mwh_acum_supuesto = sum(Q_sup),
    dif_pct_acumulado = 100 * (sum(Q_sup) / sum(Q_est) - 1),
    anio_final = ult_fy,
    mwh_final_estimado = sum(Q_est[sel_ult]),
    mwh_final_supuesto = sum(Q_sup[sel_ult]),
    dif_pct_anio_final = 100 * (sum(Q_sup[sel_ult]) / sum(Q_est[sel_ult]) - 1))
}
svs_tab <- dplyr::bind_rows(svs)
if (nrow(svs_tab) > 0) {
  write_table_out(svs_tab, cfg, "supuestos_vs_estimado.csv")
  cat("\n--- Supuestos del DCF vs. elasticidades estimadas ---\n")
  print(as.data.frame(svs_tab %>% dplyr::select(
    segmento, eta_estimada, eta_ic_inf, eta_ic_sup, eta_supuesto_dcf,
    supuesto_dentro_del_IC95, p_valor_h0, dif_pct_acumulado,
    dif_pct_anio_final)), digits = 3)
}

# ---------------------------------------------------------------------------
# 7. Excel de entregables
# ---------------------------------------------------------------------------
metodologia <- tibble::tibble(
  campo = c("fecha de generacion", "insumo de datos", "semilla",
            "ultimo mes observado", "horizonte", "anio fiscal",
            "nivel de confianza", "replicas bootstrap solicitadas",
            "actividad usada", "exogenos de los modelos",
            "escenarios", "uso de bandas", "supuesto de independencia",
            "advertencia clientes libres"),
  valor = c(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), panel$fuente,
            as.character(cfg$project$seed), format(ult),
            paste(format(f_ini), "a", format(H_fin)),
            if (fy_m0 == 1) "anio calendario" else paste("inicia en mes", fy_m0),
            sprintf("%.0f%%", 100 * conf), as.character(n_boot), act,
            paste(panel$exogenos, collapse = ", "),
            paste(escenarios, collapse = ", "),
            paste("las bandas reflejan incertidumbre de estimacion y de los",
                  "choques; las sendas de actividad y tarifa son deterministicas",
                  "dentro de cada escenario"),
            "las replicas de q y N se extraen de forma independiente",
            paste("la demanda de clientes libres depende de contratos y",
                  "migracion, no solo de actividad: tratar su proyeccion con",
                  "mayor incertidumbre que la implicada por las bandas")))

hojas <- list(
  mensual = mensual,
  anual = dplyr::bind_rows(anual, anual_total),
  historico_anual = hist_anual,
  escenarios_input = esc,
  metodologia = metodologia,
  diagnostico_proyeccion = meta,
  consistencia = consist)
if (nrow(bt_tab) > 0) hojas$backtest <- bt_tab
if (nrow(svs_tab) > 0) hojas$supuestos_vs_estimado <- svs_tab

xlsx_path <- cfg_path(cfg, "output", "forecast_volumenes.xlsx")
writexl::write_xlsx(hojas, xlsx_path)
msg_step("  -> output/forecast_volumenes.xlsx (", length(hojas), " hojas)")

# ---------------------------------------------------------------------------
# 8. Figuras
# ---------------------------------------------------------------------------
hist_long <- df %>%
  dplyr::select(fecha, dplyr::all_of(segs$mwh)) %>%
  tidyr::pivot_longer(-fecha, names_to = "serie", values_to = "mwh") %>%
  dplyr::left_join(dplyr::select(segs, serie = mwh, segmento = id, label),
                   by = "serie")

p1 <- ggplot2::ggplot() +
  ggplot2::geom_ribbon(data = mensual,
    ggplot2::aes(fecha, ymin = mwh_ic_inf, ymax = mwh_ic_sup, fill = escenario),
    alpha = .18) +
  ggplot2::geom_line(data = mensual,
    ggplot2::aes(fecha, mwh, colour = escenario), linewidth = .5) +
  ggplot2::geom_line(data = hist_long, ggplot2::aes(fecha, mwh),
                     colour = "grey25", linewidth = .4) +
  ggplot2::facet_wrap(~label, scales = "free_y", ncol = 1) +
  ggplot2::scale_colour_brewer(palette = "Dark2") +
  ggplot2::scale_fill_brewer(palette = "Dark2") +
  ggplot2::labs(title = "ELDU — Proyeccion mensual de energia por segmento",
                subtitle = sprintf("Gris: observado. Bandas: IC %.0f%% del modelo",
                                   100 * conf),
                x = NULL, y = "MWh", colour = NULL, fill = NULL) +
  theme_eldu()
save_fig(p1, cfg, "07_forecast_mensual.png", height = 8)

p2 <- dplyr::bind_rows(
    anual %>% dplyr::select(escenario, label, anio_fiscal, mwh),
    hist_anual %>% dplyr::filter(meses == 12) %>%
      dplyr::select(escenario, label, anio_fiscal, mwh)) %>%
  ggplot2::ggplot(ggplot2::aes(anio_fiscal, mwh / 1000, colour = escenario)) +
  ggplot2::geom_line(linewidth = .6) + ggplot2::geom_point(size = .9) +
  ggplot2::facet_wrap(~label, scales = "free_y", ncol = 1) +
  ggplot2::scale_colour_brewer(palette = "Set2") +
  ggplot2::labs(title = "Volumenes anuales por segmento y escenario",
                subtitle = "GWh por anio fiscal (solo anios completos en el historico)",
                x = NULL, y = "GWh", colour = NULL) + theme_eldu()
save_fig(p2, cfg, "07_forecast_anual.png", height = 8)

p3 <- anual_total %>%
  ggplot2::ggplot(ggplot2::aes(anio_fiscal, mwh / 1000, colour = escenario)) +
  ggplot2::geom_ribbon(ggplot2::aes(ymin = mwh_ic_inf / 1000,
                                    ymax = mwh_ic_sup / 1000, fill = escenario),
                       alpha = .15, colour = NA) +
  ggplot2::geom_line(linewidth = .7) +
  ggplot2::scale_colour_brewer(palette = "Dark2") +
  ggplot2::scale_fill_brewer(palette = "Dark2") +
  ggplot2::labs(title = "Energia total ELDU proyectada",
                subtitle = sprintf("GWh por anio fiscal, IC %.0f%%", 100 * conf),
                x = NULL, y = "GWh", colour = NULL, fill = NULL) + theme_eldu()
save_fig(p3, cfg, "07_forecast_total.png", height = 4.6)

msg_step("07_forecast: fin")
