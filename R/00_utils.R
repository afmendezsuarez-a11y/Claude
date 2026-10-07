# ============================================================================
# 00_utils.R — Utilidades compartidas del pipeline ELDU
#
# Contiene: carga de configuracion, validacion del contrato de datos,
# constructores de disenio ECM, estimacion UECM, elasticidades de largo plazo
# por delta-method con vcov HAC, y helpers de I/O.
#
# Este archivo NO ejecuta nada por si mismo; se hace source() desde cada script.
# ============================================================================

suppressPackageStartupMessages({
  library(here)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(purrr)
  library(stringr)
  library(tibble)
  library(ggplot2)
  library(lubridate)
  library(sandwich)
  library(lmtest)
})

options(stringsAsFactors = FALSE, dplyr.summarise.inform = FALSE)

# El proyecto escribe texto en espanol (acentos) en tablas y figuras: se fuerza
# un locale UTF-8 si el entorno arranco en "C", que rompe la lectura de UTF-8.
if (!isTRUE(l10n_info()[["UTF-8"]])) {
  for (loc in c("C.UTF-8", "C.utf8", "en_US.UTF-8", "es_PE.UTF-8")) {
    if (suppressWarnings(nzchar(Sys.setlocale("LC_CTYPE", loc)))) break
  }
}

# ---------------------------------------------------------------------------
# Mensajeria
# ---------------------------------------------------------------------------

`%||%` <- function(x, y) if (is.null(x)) y else x

msg_step <- function(...) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%H:%M:%S"), paste0(...)))
  flush.console()
}

msg_warn <- function(...) {
  cat(sprintf("[%s] AVISO: %s\n", format(Sys.time(), "%H:%M:%S"), paste0(...)))
  flush.console()
}

#' Detiene el pipeline con un mensaje accionable (criterio de aceptacion 4:
#' nunca imputar supuestos silenciosamente).
stop_user <- function(titulo, detalle = NULL, accion = NULL) {
  partes <- c(
    "",
    strrep("=", 76),
    paste0("PIPELINE DETENIDO: ", titulo),
    strrep("=", 76)
  )
  if (!is.null(detalle)) partes <- c(partes, "", detalle)
  if (!is.null(accion)) partes <- c(partes, "", "QUE HACER:", accion)
  partes <- c(partes, strrep("=", 76), "")
  stop(paste(partes, collapse = "\n"), call. = FALSE)
}

# ---------------------------------------------------------------------------
# Configuracion
# ---------------------------------------------------------------------------

load_config <- function(file = here::here("config.yml")) {
  if (!file.exists(file)) {
    stop_user("No se encuentra config.yml",
              paste("Buscado en:", file),
              "Restaurar config.yml desde el repositorio.")
  }
  # Lectura independiente del locale (config.yml es UTF-8).
  cfg <- yaml::yaml.load(paste(readLines(file, encoding = "UTF-8", warn = FALSE),
                               collapse = "\n"))

  # El directorio de datos puede sobreescribirse por entorno (set de prueba).
  env_dir <- Sys.getenv("ELDU_DATA_DIR", unset = NA_character_)
  if (!is.na(env_dir) && nzchar(env_dir)) {
    msg_warn("ELDU_DATA_DIR activo: se leen insumos desde '", env_dir,
             "' en lugar de '", cfg$paths$data_dir, "'")
    cfg$paths$data_dir <- env_dir
  }

  cfg$segmentos <- purrr::map_dfr(cfg$segmentos, tibble::as_tibble)
  cfg$.file <- file
  cfg
}

#' Rutas absolutas derivadas de la config (siempre relativas al proyecto).
cfg_path <- function(cfg, what, ...) {
  base <- switch(what,
    data      = cfg$paths$data_dir,
    processed = cfg$paths$processed_dir,
    output    = cfg$paths$output_dir,
    tables    = file.path(cfg$paths$output_dir, "tables"),
    figs      = file.path(cfg$paths$output_dir, "figs"),
    stop("cfg_path: 'what' desconocido: ", what)
  )
  here::here(base, ...)
}

ensure_dirs <- function(cfg) {
  for (w in c("processed", "output", "tables", "figs")) {
    dir.create(cfg_path(cfg, w), recursive = TRUE, showWarnings = FALSE)
  }
  invisible(TRUE)
}

set_project_seed <- function(cfg) {
  set.seed(cfg$project$seed)
  invisible(cfg$project$seed)
}

# ---------------------------------------------------------------------------
# Contrato de datos
# ---------------------------------------------------------------------------

#' Columnas obligatorias segun el contrato de datos.
required_cols <- function(cfg) {
  c("fecha",
    cfg$segmentos$mwh, cfg$segmentos$clientes, cfg$segmentos$tarifa,
    cfg$transformaciones$actividad, "ipc")
}

#' Columnas opcionales reconocidas (mejoran el ajuste, no bloquean).
optional_cols <- function(cfg) {
  # pbi_interp NO va aqui: es una bandera que genera 01_load_clean.R, no un
  # insumo que el usuario deba proveer.
  c("vab_agro_ica", "vab_manuf_ica", "nino34", "max_dem_kw")
}

#' Valida nombres, tipos, continuidad mensual y positividad.
#' Devuelve una lista de hallazgos para el reporte de validacion.
validate_schema <- function(df, cfg) {
  req <- required_cols(cfg)
  faltan <- setdiff(req, names(df))
  if (length(faltan) > 0) {
    stop_user(
      "Faltan series obligatorias en el archivo de demanda",
      paste0("Columnas ausentes (", length(faltan), "): ",
             paste(faltan, collapse = ", "), "\n",
             "Columnas encontradas: ", paste(names(df), collapse = ", ")),
      paste0("Agregar esas columnas a ", cfg$paths$data_dir, "/",
             cfg$paths$archivo_demanda, ".xlsx|.csv.\n",
             "Ver la plantilla en data/raw/PLANTILLA_eldu_demanda.csv.\n",
             "El pipeline NO imputa series faltantes.")
    )
  }

  hallazgos <- list()

  # --- fecha ---
  if (!inherits(df$fecha, "Date")) {
    stop_user("La columna 'fecha' no se pudo interpretar como fecha",
              paste("Clase encontrada:", paste(class(df$fecha), collapse = "/")),
              "Usar formato YYYY-MM-01 (primer dia de cada mes).")
  }
  if (any(is.na(df$fecha))) {
    stop_user("Hay valores faltantes en 'fecha'",
              paste("Filas afectadas:", paste(which(is.na(df$fecha)), collapse = ", ")),
              "Completar o eliminar esas filas en el archivo de insumo.")
  }
  if (any(lubridate::day(df$fecha) != 1)) {
    malas <- head(df$fecha[lubridate::day(df$fecha) != 1], 5)
    stop_user("Hay fechas que no son el primer dia del mes",
              paste("Ejemplos:", paste(format(malas), collapse = ", ")),
              "Normalizar todas las fechas a YYYY-MM-01.")
  }
  if (anyDuplicated(df$fecha) > 0) {
    dups <- df$fecha[duplicated(df$fecha)]
    stop_user("Hay meses duplicados (se espera una fila por mes)",
              paste("Meses duplicados:", paste(format(unique(dups)), collapse = ", ")),
              "Consolidar a una sola observacion por mes.")
  }
  df <- dplyr::arrange(df, fecha)

  # --- continuidad mensual ---
  esperado <- seq(min(df$fecha), max(df$fecha), by = "month")
  huecos <- setdiff(as.character(esperado), as.character(df$fecha))
  if (length(huecos) > 0) {
    stop_user("La serie mensual tiene huecos",
              paste0("Faltan ", length(huecos), " meses entre ",
                     format(min(df$fecha)), " y ", format(max(df$fecha)), ": ",
                     paste(head(huecos, 24), collapse = ", "),
                     if (length(huecos) > 24) " ..." else ""),
              "Agregar las filas faltantes (con el dato real) al archivo de insumo.")
  }
  hallazgos$n_obs <- nrow(df)
  hallazgos$rango <- paste(format(min(df$fecha)), "a", format(max(df$fecha)))

  # --- tipos numericos ---
  num_cols <- setdiff(intersect(c(req, optional_cols(cfg)), names(df)), "fecha")
  no_num <- num_cols[!vapply(df[num_cols], is.numeric, logical(1))]
  if (length(no_num) > 0) {
    stop_user("Columnas que deberian ser numericas no lo son",
              paste("Columnas:", paste(no_num, collapse = ", ")),
              "Revisar separadores decimales, texto o celdas combinadas en el insumo.")
  }

  # --- positividad de lo que se va a logaritmar ---
  pos_cols <- c(cfg$segmentos$tarifa, cfg$transformaciones$actividad, "ipc")
  problemas <- purrr::map_dfr(intersect(pos_cols, names(df)), function(cl) {
    x <- df[[cl]]
    tibble::tibble(columna = cl,
                   n_na = sum(is.na(x)),
                   n_no_positivo = sum(!is.na(x) & x <= 0))
  })
  duros <- dplyr::filter(problemas, n_no_positivo > 0)
  if (nrow(duros) > 0) {
    stop_user("Valores <= 0 en series que se transforman a logaritmo",
              paste(capture.output(print(as.data.frame(duros))), collapse = "\n"),
              "Corregir el insumo: tarifas, IPC y actividad deben ser estrictamente positivos.")
  }
  # NA en tarifas / ipc es bloqueante; en actividad se admite si es interpolable.
  na_bloq <- dplyr::filter(problemas, n_na > 0,
                           columna %in% c(cfg$segmentos$tarifa, "ipc"))
  if (nrow(na_bloq) > 0) {
    stop_user("Valores faltantes en tarifas o IPC",
              paste(capture.output(print(as.data.frame(na_bloq))), collapse = "\n"),
              "Completar esas series. El pipeline no interpola precios ni deflactores.")
  }
  hallazgos$positividad <- problemas

  # --- energia y clientes: NA bloqueante, ceros tolerados al inicio ---
  ec <- purrr::map_dfr(c(cfg$segmentos$mwh, cfg$segmentos$clientes), function(cl) {
    x <- df[[cl]]
    tibble::tibble(columna = cl, n_na = sum(is.na(x)),
                   n_cero_o_neg = sum(!is.na(x) & x <= 0),
                   primer_positivo = if (any(!is.na(x) & x > 0))
                     format(df$fecha[which(!is.na(x) & x > 0)[1]]) else NA_character_)
  })
  if (any(ec$n_na > 0)) {
    stop_user("Valores faltantes en energia o clientes",
              paste(capture.output(print(as.data.frame(
                dplyr::filter(ec, n_na > 0)))), collapse = "\n"),
              "Completar esas series en el insumo (no se imputan).")
  }
  hallazgos$energia_clientes <- ec

  # --- opcionales ausentes ---
  hallazgos$opcionales_ausentes <- setdiff(optional_cols(cfg), names(df))
  hallazgos$opcionales_presentes <- intersect(optional_cols(cfg), names(df))

  list(df = df, hallazgos = hallazgos)
}

# ---------------------------------------------------------------------------
# Transformaciones de series
# ---------------------------------------------------------------------------

#' Rezago de n periodos sobre un vector ordenado en el tiempo.
L <- function(x, n = 1L) dplyr::lag(x, n)

#' Primera diferencia.
D <- function(x) x - dplyr::lag(x, 1L)

#' Logaritmo natural que devuelve NA (en lugar de -Inf) para x <= 0,
#' de modo que los ceros iniciales de un segmento se traten como muestra
#' no disponible y no como un valor extremo.
ln <- function(x) ifelse(!is.na(x) & x > 0, log(x), NA_real_)

#' Dummies estacionales mensuales: feb..dic (enero = categoria base).
seasonal_dummies <- function(fecha) {
  m <- lubridate::month(fecha)
  out <- purrr::map_dfc(2:12, function(k) {
    tibble::tibble(!!sprintf("m%02d", k) := as.numeric(m == k))
  })
  out
}

#' Interpolacion documentada de la serie de actividad a frecuencia mensual.
#' Devuelve el vector interpolado y la bandera de observaciones interpoladas.
interpolar_actividad <- function(fecha, x, metodo = c("spline", "denton")) {
  metodo <- match.arg(metodo)
  flag <- is.na(x)
  if (!any(flag)) return(list(x = x, interp = flag, metodo = "ninguno"))
  if (all(is.na(x))) {
    stop_user("La serie de actividad esta completamente vacia", NULL,
              "Proveer pbi_ica (o la variable configurada en transformaciones$actividad).")
  }
  obs_idx <- which(!flag)
  if (length(obs_idx) < 4) {
    stop_user("Muy pocas observaciones de actividad para interpolar",
              paste("Observaciones no faltantes:", length(obs_idx)),
              "Proveer la serie de actividad con mayor cobertura.")
  }
  # Solo se interpola DENTRO del rango observado; no se extrapola.
  rango <- range(obs_idx)
  if (metodo == "spline") {
    xi <- zoo::na.spline(zoo::zoo(x, fecha), na.rm = FALSE)
    xi <- as.numeric(xi)
  } else {
    # Denton-Cholette via tempdisagg sobre los valores de baja frecuencia.
    lf <- x[obs_idx]
    td <- tempdisagg::td(lf ~ 1, to = length(x) / length(lf),
                         method = "denton-cholette", conversion = "average")
    xi <- as.numeric(stats::predict(td))
    if (length(xi) != length(x)) {
      xi <- stats::approx(obs_idx, lf, xout = seq_along(x), rule = 1)$y
    }
  }
  xi[seq_len(rango[1] - 1)] <- NA_real_
  if (rango[2] < length(x)) xi[(rango[2] + 1):length(x)] <- NA_real_
  xi[!flag] <- x[!flag]
  list(x = xi, interp = flag & !is.na(xi), metodo = metodo)
}

# ---------------------------------------------------------------------------
# Matriz de disenio del ECM condicional
# ---------------------------------------------------------------------------

#' Especificacion de un ECM condicional (parametrizacion UECM).
#'
#' Para la ecuacion
#'   D ln q_t = c + sum_{i=1..pd} psi_i D ln q_{t-i}
#'              + sum_j sum_{i=0..qd_j} omega_ji D ln x_{j,t-i}
#'              + pi_y ln q_{t-1} + sum_j pi_j ln x_{j,t-1} + exog_t + u_t
#' se cumple:  lambda = -pi_y   y   elasticidad LP de x_j = -pi_j / pi_y.
#' Equivale a un ARDL(p = pd+1, q_j = qd_j+1) en niveles.
ecm_spec <- function(dep, lev, pd, qd, exog = character(0)) {
  stopifnot(length(qd) == length(lev))
  if (is.null(names(qd))) names(qd) <- lev
  list(dep = dep, lev = lev, pd = as.integer(pd),
       qd = stats::setNames(as.integer(qd), lev), exog = exog)
}

#' Nombres de columna generados para una especificacion (orden estable).
ecm_terms <- function(spec) {
  lev_terms <- paste0("L1_", c(spec$dep, spec$lev))
  dy <- if (spec$pd > 0) paste0("d_", spec$dep, "_L", seq_len(spec$pd)) else character(0)
  dx <- unlist(lapply(spec$lev, function(v)
    paste0("d_", v, "_L", 0:spec$qd[[v]])), use.names = FALSE)
  c(lev_terms, dy, dx, spec$exog)
}

#' Construye el data.frame de disenio (incluye 'fecha' y la dependiente en
#' diferencias) para una especificacion dada.
build_design <- function(df, spec) {
  stopifnot("fecha" %in% names(df))
  faltan <- setdiff(c(spec$dep, spec$lev, spec$exog), names(df))
  if (length(faltan) > 0) {
    stop_user("Variables ausentes al construir el disenio del ECM",
              paste("Faltan:", paste(faltan, collapse = ", ")),
              "Revisar 01_load_clean.R y el contrato de datos.")
  }
  out <- tibble::tibble(fecha = df$fecha)
  out[[paste0("d_", spec$dep)]] <- D(df[[spec$dep]])
  out[[paste0("L1_", spec$dep)]] <- L(df[[spec$dep]], 1L)
  for (v in spec$lev) out[[paste0("L1_", v)]] <- L(df[[v]], 1L)
  if (spec$pd > 0) {
    for (i in seq_len(spec$pd))
      out[[paste0("d_", spec$dep, "_L", i)]] <- L(D(df[[spec$dep]]), i)
  }
  for (v in spec$lev) {
    for (i in 0:spec$qd[[v]])
      out[[paste0("d_", v, "_L", i)]] <- L(D(df[[v]]), i)
  }
  for (e in spec$exog) out[[e]] <- df[[e]]
  out
}

#' Estima el ECM condicional por OLS. `sample_rows` permite forzar una
#' muestra comun (necesario para que el AIC sea comparable entre candidatos).
fit_ecm <- function(df, spec, sample_rows = NULL) {
  dsg <- build_design(df, spec)
  terms_i <- ecm_terms(spec)
  # Descartar exogenas constantes dentro de la muestra (p.ej. dummy COVID
  # cuando la muestra del segmento empieza despues de 2020).
  keep <- terms_i
  cols <- c(paste0("d_", spec$dep), terms_i)
  ok <- stats::complete.cases(dsg[, cols, drop = FALSE])
  if (!is.null(sample_rows)) ok <- ok & (dsg$fecha %in% sample_rows)
  sub <- dsg[ok, , drop = FALSE]
  if (nrow(sub) == 0) {
    stop_user("Muestra vacia al estimar el ECM",
              paste0("Dependiente: ", spec$dep,
                     " | ordenes pd=", spec$pd,
                     " qd=", paste(spec$qd, collapse = ",")),
              "Revisar cobertura de las series de entrada.")
  }
  const <- keep[vapply(keep, function(k) {
    v <- sub[[k]]; isTRUE(stats::sd(v, na.rm = TRUE) == 0) || all(is.na(v))
  }, logical(1))]
  if (length(const) > 0) keep <- setdiff(keep, const)
  k_tot <- length(keep) + 1L
  if (nrow(sub) <= k_tot + 2L) {
    stop_user("Grados de libertad insuficientes en el ECM",
              paste0("n = ", nrow(sub), ", parametros = ", k_tot,
                     " (dependiente: ", spec$dep, ")"),
              "Reducir ardl$max_pd / ardl$max_qd en config.yml o ampliar la muestra.")
  }
  fml <- stats::as.formula(paste0("`d_", spec$dep, "` ~ ",
                                  paste(sprintf("`%s`", keep), collapse = " + ")))
  fit <- stats::lm(fml, data = as.data.frame(sub))
  list(fit = fit, design = sub, spec = spec, terms = keep,
       dropped = const, fechas = sub$fecha)
}

#' vcov HAC (Newey-West). lag = NULL usa la regla automatica de Newey-West
#' (bwNeweyWest), que es la practica estandar.
hac_vcov <- function(fit, lag = NULL) {
  if (is.null(lag)) {
    sandwich::NeweyWest(fit, prewhite = FALSE, adjust = TRUE)
  } else {
    sandwich::NeweyWest(fit, lag = lag, prewhite = FALSE, adjust = TRUE)
  }
}

#' Seleccion de ordenes (pd, qd_1, ..., qd_k) por AIC/BIC sobre MUESTRA COMUN.
select_ecm_orders <- function(df, dep, lev, exog, max_pd, max_qd,
                              criterio = c("AIC", "BIC")) {
  criterio <- match.arg(criterio)
  # Muestra comun = la del modelo con los ordenes maximos.
  spec_max <- ecm_spec(dep, lev, max_pd, rep(max_qd, length(lev)), exog)
  dsg_max <- build_design(df, spec_max)
  cols_max <- c(paste0("d_", dep), ecm_terms(spec_max))
  ok <- stats::complete.cases(dsg_max[, cols_max, drop = FALSE])
  muestra_comun <- dsg_max$fecha[ok]
  if (length(muestra_comun) == 0) {
    stop_user("No hay muestra comun para seleccionar ordenes ARDL",
              paste0("Dependiente: ", dep, " | max_pd=", max_pd, " max_qd=", max_qd),
              "Reducir ardl$max_pd / ardl$max_qd en config.yml.")
  }
  grid <- expand.grid(c(list(pd = 0:max_pd),
                        stats::setNames(rep(list(0:max_qd), length(lev)), lev)),
                      KEEP.OUT.ATTRS = FALSE)
  res <- purrr::map_dfr(seq_len(nrow(grid)), function(i) {
    qd <- unlist(grid[i, lev, drop = TRUE])
    sp <- ecm_spec(dep, lev, grid$pd[i], qd, exog)
    f <- try(fit_ecm(df, sp, sample_rows = muestra_comun), silent = TRUE)
    if (inherits(f, "try-error")) return(NULL)
    tibble::tibble(pd = grid$pd[i],
                   !!!stats::setNames(as.list(qd), paste0("qd_", lev)),
                   n = stats::nobs(f$fit),
                   k = length(stats::coef(f$fit)),
                   AIC = stats::AIC(f$fit), BIC = stats::BIC(f$fit))
  })
  if (nrow(res) == 0) {
    stop_user("Ningun candidato ARDL pudo estimarse",
              paste("Dependiente:", dep),
              "Revisar la cobertura de las series y los ordenes maximos.")
  }
  res <- dplyr::arrange(res, .data[[criterio]])
  best <- res[1, ]
  qd_best <- stats::setNames(
    as.integer(unlist(best[paste0("qd_", lev)])), lev)
  list(spec = ecm_spec(dep, lev, best$pd, qd_best, exog),
       tabla = res, criterio = criterio,
       n_muestra_comun = length(muestra_comun),
       ardl_order = c(p = best$pd + 1L, qd_best + 1L))
}

#' Elasticidades de largo plazo y velocidad de ajuste desde el UECM,
#' por delta-method con la matriz HAC.
#'
#' lambda = -pi_y ; eta_j = -pi_j / pi_y
lr_from_ecm <- function(ecm, lag = NULL, conf = 0.95) {
  fit <- ecm$fit
  b <- stats::coef(fit)
  V <- hac_vcov(fit, lag)
  nm_y <- paste0("L1_", ecm$spec$dep)
  nm_y_q <- sprintf("`%s`", nm_y)
  key_y <- if (nm_y %in% names(b)) nm_y else nm_y_q
  if (!key_y %in% names(b)) {
    stop_user("El termino de correccion de errores no esta en el modelo",
              paste("Se buscaba:", nm_y),
              "Revisar build_design()/fit_ecm() en R/00_utils.R.")
  }
  pi_y <- b[[key_y]]
  i_y <- match(key_y, names(b))
  ct <- lmtest::coeftest(fit, vcov. = V)
  z <- stats::qnorm(1 - (1 - conf) / 2)

  lambda <- -pi_y
  se_l <- sqrt(V[i_y, i_y])
  out_lambda <- tibble::tibble(
    parametro = "lambda", variable = NA_character_, estimado = lambda,
    se = se_l, stat = lambda / se_l,
    p_valor = 2 * stats::pnorm(-abs(lambda / se_l)),
    ic_inf = lambda - z * se_l, ic_sup = lambda + z * se_l)

  out_lr <- purrr::map_dfr(ecm$spec$lev, function(v) {
    nm <- paste0("L1_", v)
    key <- if (nm %in% names(b)) nm else sprintf("`%s`", nm)
    if (!key %in% names(b)) {
      return(tibble::tibble(parametro = "lp", variable = v,
                            estimado = NA_real_, se = NA_real_, stat = NA_real_,
                            p_valor = NA_real_, ic_inf = NA_real_, ic_sup = NA_real_))
    }
    i_x <- match(key, names(b))
    pi_x <- b[[key]]
    theta <- -pi_x / pi_y
    # Gradiente del ratio respecto a (pi_x, pi_y)
    g <- c(-1 / pi_y, pi_x / pi_y^2)
    Vsub <- V[c(i_x, i_y), c(i_x, i_y)]
    se <- sqrt(as.numeric(t(g) %*% Vsub %*% g))
    tibble::tibble(parametro = "lp", variable = v, estimado = theta,
                   se = se, stat = theta / se,
                   p_valor = 2 * stats::pnorm(-abs(theta / se)),
                   ic_inf = theta - z * se, ic_sup = theta + z * se)
  })

  list(lambda = out_lambda, lp = out_lr, coeftest = ct, vcov = V,
       pi_y = pi_y, conf = conf)
}

#' Test z de una restriccion sobre una elasticidad de largo plazo
#' (usado en la seccion "supuestos vs. estimado").
test_lr_value <- function(est, se, valor_h0) {
  z <- (est - valor_h0) / se
  tibble::tibble(h0 = valor_h0, estimado = est, se = se, z = z,
                 p_valor = 2 * stats::pnorm(-abs(z)))
}

# ---------------------------------------------------------------------------
# I/O
# ---------------------------------------------------------------------------

write_table_out <- function(x, cfg, nombre) {
  path <- cfg_path(cfg, "tables", nombre)
  readr::write_csv(x, path, na = "")
  msg_step("  -> ", sub(here::here(), ".", path, fixed = TRUE))
  invisible(path)
}

save_fig <- function(p, cfg, nombre, width = 9, height = 5.2, dpi = 130) {
  path <- cfg_path(cfg, "figs", nombre)
  ggplot2::ggsave(path, p, width = width, height = height, dpi = dpi)
  invisible(path)
}

theme_eldu <- function(base_size = 11) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = base_size + 1.5),
      plot.subtitle = ggplot2::element_text(colour = "grey30"),
      panel.grid.minor = ggplot2::element_blank(),
      strip.text = ggplot2::element_text(face = "bold"),
      legend.position = "bottom"
    )
}

read_panel <- function(cfg) {
  path <- cfg_path(cfg, "processed", "panel.rds")
  if (!file.exists(path)) {
    stop_user("No existe data/processed/panel.rds",
              paste("Buscado en:", path),
              "Correr primero R/01_load_clean.R (o `Rscript run_all.R`).")
  }
  readRDS(path)
}

read_models <- function(cfg) {
  path <- cfg_path(cfg, "processed", "modelos.rds")
  if (!file.exists(path)) {
    stop_user("No existe data/processed/modelos.rds",
              paste("Buscado en:", path),
              "Correr primero R/05_ardl_ecm.R (o `Rscript run_all.R`).")
  }
  readRDS(path)
}

#' Escribe un HTML autocontenido simple (sin pandoc) para el reporte de
#' validacion de datos.
write_simple_html <- function(titulo, bloques, path) {
  css <- "
  body{font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;
       max-width:1000px;margin:2rem auto;padding:0 1rem;color:#1a1a1a;line-height:1.5}
  h1{border-bottom:3px solid #0b6; padding-bottom:.3rem}
  h2{margin-top:2rem;color:#064}
  table{border-collapse:collapse;width:100%;font-size:.9rem;margin:.6rem 0}
  th,td{border:1px solid #ddd;padding:.35rem .5rem;text-align:right}
  th{background:#f3f6f4;text-align:left}
  td:first-child,th:first-child{text-align:left}
  .ok{color:#067d3a;font-weight:600}.warn{color:#b26a00;font-weight:600}
  .meta{color:#666;font-size:.85rem}
  pre{background:#f7f7f7;padding:.6rem;overflow-x:auto;font-size:.85rem}
  "
  html <- c("<!doctype html><html lang='es'><head><meta charset='utf-8'>",
            sprintf("<title>%s</title>", titulo),
            sprintf("<style>%s</style></head><body>", css),
            sprintf("<h1>%s</h1>", titulo),
            sprintf("<p class='meta'>Generado %s &middot; %s</p>",
                    format(Sys.time(), "%Y-%m-%d %H:%M:%S"), R.version.string),
            bloques, "</body></html>")
  writeLines(html, path)
  invisible(path)
}

html_table <- function(df, digits = 4) {
  d <- as.data.frame(df)
  for (j in seq_along(d)) {
    if (is.numeric(d[[j]])) d[[j]] <- formatC(d[[j]], format = "g", digits = digits)
    d[[j]] <- ifelse(is.na(d[[j]]) | d[[j]] == "NA", "&mdash;", as.character(d[[j]]))
  }
  c("<table><thead><tr>",
    paste0("<th>", names(d), "</th>", collapse = ""),
    "</tr></thead><tbody>",
    apply(d, 1, function(r) paste0("<tr>", paste0("<td>", r, "</td>", collapse = ""), "</tr>")),
    "</tbody></table>")
}
