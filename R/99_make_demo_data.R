# ============================================================================
# 99_make_demo_data.R — GENERADOR DE DATOS SINTETICOS (SOLO PRUEBA DE HUMO)
#
#   *** ESTOS DATOS SON INVENTADOS. NO SON DATOS DE ELECTRO DUNAS. ***
#
# Unico proposito: permitir verificar que el pipeline corre de punta a punta
# sin errores antes de tener los insumos reales. Escribe en data/demo/ y NUNCA
# en data/raw/, para que no se confundan con los insumos reales.
#
# Uso:
#   Rscript R/99_make_demo_data.R
#   ELDU_DATA_DIR=data/demo Rscript run_all.R
#
# Los datos se simulan desde un DGP que SI cumple la estructura del modelo
# (cointegracion con elasticidades conocidas), de modo que tambien sirve como
# prueba de que el estimador recupera los parametros verdaderos. Los valores
# verdaderos quedan en data/demo/PARAMETROS_VERDADEROS.csv.
# ============================================================================

source(here::here("R", "00_utils.R"))

cfg <- load_config(here::here("config.yml"))
set.seed(cfg$project$seed)

out_dir <- here::here("data", "demo")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

fecha <- seq(as.Date("2012-01-01"), as.Date("2025-12-01"), by = "month")
n <- length(fecha)
t <- seq_len(n)
mes <- lubridate::month(fecha)

# --- Macro: actividad de Ica (tendencia + choque COVID + ruido persistente) --
d_covid <- as.numeric(fecha >= as.Date("2020-03-01") & fecha <= as.Date("2020-12-01"))
u_act <- as.numeric(stats::filter(stats::rnorm(n, 0, 0.011), 0.6, "recursive"))
ln_pbi <- log(100) + 0.0035 * t - 0.16 * d_covid + u_act
pbi_ica <- exp(ln_pbi)

# El PBI de Ica real suele publicarse trimestral: se dejan NA los meses no
# terminales de trimestre para ejercitar la rama de interpolacion.
pbi_pub <- pbi_ica
pbi_pub[mes %% 3 != 0] <- NA_real_

# VAB agropecuario: mas estacional y mas sensible a ENSO
nino34 <- as.numeric(stats::filter(stats::rnorm(n, 0, 0.42), 0.85, "recursive"))
vab_agro <- exp(log(95) + 0.0042 * t + 0.09 * sin(2 * pi * mes / 12) -
                  0.13 * nino34 - 0.12 * d_covid + stats::rnorm(n, 0, 0.03))
vab_manuf <- exp(log(90) + 0.0025 * t - 0.10 * d_covid + stats::rnorm(n, 0, 0.035))

# --- IPC y tarifas nominales ------------------------------------------------
ipc <- 100 * cumprod(c(1, rep(1 + 0.0028, n - 1)))

# La tarifa real se mueve por dos canales independientes del PBI: saltos
# regulatorios discretos (pliegos que se reajustan cada ~4 meses) y erosion
# real por inflacion entre reajustes. Asi la tarifa tiene variacion propia y
# la elasticidad-precio queda identificada (de lo contrario seria colineal con
# la tendencia de la actividad).
tarifa_real_sim <- function(nivel0, sd_salto, cada = 4L) {
  salto <- rep(0, n)
  idx <- seq(cada + 1L, n, by = cada)
  salto[idx] <- stats::rnorm(length(idx), 0, sd_salto)
  exp(log(nivel0) + 0.0006 * t + cumsum(salto) + stats::rnorm(n, 0, 0.006))
}
tar_real <- list(
  BT     = tarifa_real_sim(0.62, 0.035),
  MT     = tarifa_real_sim(0.41, 0.040),
  LIBRES = tarifa_real_sim(0.28, 0.055)
)

# --- Parametros verdaderos del DGP -----------------------------------------
par_true <- tibble::tribble(
  ~segmento, ~eta,  ~rho,  ~lambda, ~beta_cli, ~phi_enso,
  "BT",      0.55, -0.18,  0.22,    0.35,      -0.02,
  "MT",      1.05, -0.32,  0.28,    0.55,      -0.04,
  "LIBRES",  1.35, -0.45,  0.18,    0.80,      -0.09
)
cli0 <- c(BT = 165000, MT = 980, LIBRES = 14)
q0   <- c(BT = 0.115,  MT = 9.6, LIBRES = 820)
seas <- c(BT = 0.045, MT = 0.055, LIBRES = 0.035)

sim_seg <- function(id) {
  p <- par_true[par_true$segmento == id, ]
  ltar <- log(tar_real[[id]])
  s_eff <- seas[[id]] * sin(2 * pi * (mes - 2) / 12)

  # Clientes: D ln N = a + b * D ln ACT + ruido
  dlnN <- 0.0018 + p$beta_cli * c(0, diff(ln_pbi)) + stats::rnorm(n, 0, 0.004)
  lnN <- log(cli0[[id]]) + cumsum(dlnN)

  # Consumo unitario: ECM con elasticidades de largo plazo conocidas
  mu <- log(q0[[id]]) - p$eta * ln_pbi[1] - p$rho * ltar[1]
  lnq <- numeric(n); lnq[1] <- log(q0[[id]])
  e <- stats::rnorm(n, 0, 0.022)
  for (i in 2:n) {
    ect <- lnq[i - 1] - (mu + p$eta * ln_pbi[i - 1] + p$rho * ltar[i - 1])
    lnq[i] <- lnq[i - 1] +
      0.45 * p$eta * (ln_pbi[i] - ln_pbi[i - 1]) +
      0.60 * p$rho * (ltar[i] - ltar[i - 1]) +
      p$phi_enso * nino34[i] - 0.05 * d_covid[i] -
      p$lambda * ect + (s_eff[i] - s_eff[i - 1]) + e[i]
  }
  list(mwh = exp(lnq) * exp(lnN), cli = exp(lnN))
}

sims <- lapply(c("BT", "MT", "LIBRES"), sim_seg)
names(sims) <- c("BT", "MT", "LIBRES")

# Clientes libres: no existen antes de 2014 (ejercita la rama de ceros)
pre <- fecha < as.Date("2014-01-01")
sims$LIBRES$mwh[pre] <- 0
sims$LIBRES$cli[pre] <- 0

dat <- tibble::tibble(
  fecha        = fecha,
  mwh_bt       = round(sims$BT$mwh, 2),
  mwh_mt       = round(sims$MT$mwh, 2),
  mwh_libres   = round(sims$LIBRES$mwh, 2),
  cli_bt       = round(sims$BT$cli),
  cli_mt       = round(sims$MT$cli),
  cli_libres   = round(sims$LIBRES$cli),
  pbi_ica      = round(pbi_pub, 3),
  vab_agro_ica = round(vab_agro, 3),
  vab_manuf_ica = round(vab_manuf, 3),
  tarifa_bt     = round(tar_real$BT     * ipc / 100, 5),
  tarifa_mt     = round(tar_real$MT     * ipc / 100, 5),
  tarifa_libres = round(tar_real$LIBRES * ipc / 100, 5),
  ipc           = round(ipc, 3),
  nino34        = round(nino34, 3),
  max_dem_kw    = round((sims$BT$mwh + sims$MT$mwh + sims$LIBRES$mwh) * 1000 /
                          (as.numeric(lubridate::days_in_month(fecha)) * 24 * 0.62))
)

readr::write_csv(dat, file.path(out_dir, "eldu_demanda.csv"), na = "")

# --- Escenarios ------------------------------------------------------------
anios <- 2026:lubridate::year(as.Date(cfg$forecast$fin))
esc <- tidyr::expand_grid(escenario = c("base", "optimista", "pesimista"),
                          anio = anios) |>
  dplyr::mutate(
    g_pbi_ica = dplyr::case_when(escenario == "base" ~ 0.035,
                                 escenario == "optimista" ~ 0.055,
                                 TRUE ~ 0.012),
    g_tarifa_real_bt = dplyr::case_when(escenario == "base" ~ 0.000,
                                        escenario == "optimista" ~ -0.010,
                                        TRUE ~ 0.015),
    g_tarifa_real_mt = g_tarifa_real_bt,
    g_tarifa_real_libres = g_tarifa_real_bt,
    nino34 = dplyr::case_when(escenario == "pesimista" & anio %in% c(2026, 2027) ~ 1.2,
                              TRUE ~ 0.0))
readr::write_csv(esc, file.path(out_dir, "escenarios.csv"))

readr::write_csv(par_true, file.path(out_dir, "PARAMETROS_VERDADEROS.csv"))
writeLines(c(
  "DATOS SINTETICOS — NO SON DATOS DE ELECTRO DUNAS",
  "",
  "Generados por R/99_make_demo_data.R con semilla 20261007, unicamente para",
  "verificar que el pipeline corre de punta a punta y que el estimador recupera",
  "los parametros del DGP. No usar para ninguna conclusion de negocio.",
  "",
  "Parametros verdaderos del DGP: PARAMETROS_VERDADEROS.csv",
  "",
  "Correr con:  ELDU_DATA_DIR=data/demo Rscript run_all.R"
), file.path(out_dir, "ADVERTENCIA_DATOS_SINTETICOS.txt"))

msg_step("datos sinteticos de prueba -> data/demo/ (", n, " meses)")
msg_step("ADVERTENCIA: datos inventados, solo para prueba de humo del pipeline.")
