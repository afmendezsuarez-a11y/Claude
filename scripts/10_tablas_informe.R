## ============================================================================
## 10_tablas_informe.R — fragmentos LaTeX de las tablas del informe.
## ----------------------------------------------------------------------------
## Cada tabla se emite desde la salida del pipeline que le corresponde, para que
## el .tex no contenga ni una cifra retipeada a mano: el documento compila lo
## que la corrida produjo.
## ============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(knitr); library(here)
})

STAGE <- "10_tablas"
log_event(STAGE, "INFO", "inicio — tablas LaTeX del informe")

panel <- readRDS(here::here(CFG$paths$processed, "panel_anual.rds"))
RES   <- readRDS(here::here(CFG$paths$processed, "estimacion.rds"))
FC    <- readRDS(here::here(CFG$paths$processed, "forecast.rds"))

tab_dir <- here::here("report", "tablas")
dir.create(tab_dir, recursive = TRUE, showWarnings = FALSE)

emitir <- function(x, nombre, ...) {
  tx <- knitr::kable(x, format = "latex", booktabs = TRUE, linesep = "", ...)
  writeLines(as.character(tx), file.path(tab_dir, nombre))
  log_event(STAGE, "OK", sprintf("escrita report/tablas/%s (%d filas)", nombre, nrow(x)))
}

## ---- Fuentes ---------------------------------------------------------------
per <- function(x) sprintf("%d--%d", min(x), max(x))
fuentes <- tibble::tibble(
  Serie = c("Energía distribuida (GWh) y clientes",
            "Valor Agregado Bruto real de Ica",
            "PBI nacional, var.\\ interanual",
            "IPC Lima Metropolitana",
            "Tipo de cambio venta"),
  Fuente = c("Memorias Anuales de ELDU", "INEI", "BCRP (\\texttt{PN01728AM})",
             "BCRP (\\texttt{PN38705PM})", "BCRP (\\texttt{PD04638PD})"),
  Periodo = c(per(panel$year), "2007--2025", "1995--2026", "1991--2026", "1997--2026"),
  Rol = c("variable dependiente", "driver de ingreso", "robustez",
          "registrada, no usada", "registrada, no usada"))
emitir(fuentes, "tab_fuentes.tex", escape = FALSE, align = "lllp{2.4cm}")

## ---- Panel anual -----------------------------------------------------------
pan <- panel %>% transmute(
  `Año` = year,
  `Energía (GWh)` = round(energia_gwh, 1),
  Clientes = formatC(clientes, format = "d", big.mark = " "),
  `MWh/cliente` = round(energia_por_cliente_mwh, 3),
  `VAB Ica (miles S/)` = formatC(pbi, format = "d", big.mark = " "))
emitir(pan, "tab_panel.tex", align = "lrrrr")

## ---- Descomposición --------------------------------------------------------
dc <- utils::read.csv(here::here(CFG$paths$tables, "descomposicion_crecimiento.csv"),
                      stringsAsFactors = FALSE) %>%
  transmute(Componente = c("Clientes", "Consumo por cliente",
                           "Energía distribuida", "VAB real de Ica (driver)")[
                             match(componente, c("clientes", "energia por cliente",
                                                 "energia distribuida", "ingreso (driver)"))],
            `CAGR (\\%)` = sprintf("%.2f", cagr_pct)) %>%
  arrange(match(Componente, c("Clientes", "Consumo por cliente",
                              "Energía distribuida", "VAB real de Ica (driver)")))
emitir(dc, "tab_descomposicion.tex", escape = FALSE, align = "lr")

## ---- Estimaciones ----------------------------------------------------------
el <- utils::read.csv(here::here(CFG$paths$tables, "elasticidad.csv"), stringsAsFactors = FALSE)
nom_bloque <- c(energia_por_cliente = "Por cliente", energia_total = "Energía total",
                volumen_alt = "Volumen alternativo", driver_nacional = "Driver nacional",
                ex_shock = "Sin 2020--2021")
nom_metodo <- c(`OLS log-log con tendencia` = "niveles + tend.",
                `OLS log-log sin tendencia` = "niveles",
                `Regresión en diferencias`  = "diferencias")
nom_rol <- c(PRINCIPAL = "\\textbf{principal}", corroboracion = "corrob.",
             comparacion = "compar.", robustez = "robustez")
est <- el %>%
  mutate(orden = match(rol, c("PRINCIPAL", "corroboracion", "comparacion", "robustez")),
         Bloque = unname(nom_bloque[bloque]),
         `Método` = unname(nom_metodo[metodo]),
         Rol = unname(nom_rol[rol]),
         `$\\eta$` = sprintf("%.3f", estimate),
         `EE` = sprintf("%.3f", se_hac),
         `IC 95\\%` = sprintf("[%.3f, %.3f]", ci95_low, ci95_high),
         ## Un p-valor redondeado a 0.000 engaña: se reporta como cota.
         `$p$` = ifelse(p_value < 0.0005, "$<$0.001", sprintf("%.3f", p_value)),
         `$n$` = n,
         `$R^2$` = sprintf("%.3f", r2)) %>%
  arrange(orden, Bloque, `Método`) %>%
  select(Bloque, `Método`, Rol, `$\\eta$`, `EE`, `IC 95\\%`, `$p$`, `$n$`, `$R^2$`)
emitir(est, "tab_estimaciones.tex", escape = FALSE, align = "lllrrcrrr")

## ---- Diagnósticos ----------------------------------------------------------
dg <- utils::read.csv(here::here(CFG$paths$tables, "diagnosticos.csv"), stringsAsFactors = FALSE) %>%
  transmute(Modelo = c("Niveles (con tendencia)", "Diferencias"),
            `$R^2$` = sprintf("%.3f", r2),
            `$R^2$ aj.` = sprintf("%.3f", adj_r2),
            `g.l.` = df_residual,
            `DW` = sprintf("%.3f", durbin_watson),
            `$p_{\\text{DW}}$` = sprintf("%.3f", dw_p),
            `BG` = sprintf("%.3f", breusch_godfrey),
            `$p_{\\text{BG}}$` = sprintf("%.3f", bg_p))
emitir(dg, "tab_diagnosticos.tex", escape = FALSE, align = "lrrrrrrr")

## ---- Proyección: endpoints por escenario -----------------------------------
fin <- FC$fc %>% filter(year == max(year)) %>%
  transmute(Escenario = tools::toTitleCase(escenario),
            `$g$ ingreso` = sprintf("%.1f\\%%", 100 * g_pbi),
            `GWh central` = formatC(round(gwh_central), format = "d", big.mark = " "),
            `GWh banda inf.` = formatC(round(gwh_low), format = "d", big.mark = " "),
            `GWh banda sup.` = formatC(round(gwh_high), format = "d", big.mark = " "))
emitir(fin, "tab_proyeccion_fin.tex", escape = FALSE, align = "lrrrr")

## ---- Proyección anual completa (apéndice) ----------------------------------
proy <- FC$fc %>%
  select(escenario, year, gwh_central) %>%
  tidyr::pivot_wider(names_from = escenario, values_from = gwh_central) %>%
  left_join(FC$fc %>% filter(escenario == "base") %>% select(year, gwh_low, gwh_high),
            by = "year") %>%
  arrange(year) %>%
  transmute(`Año` = year,
            Base = sprintf("%.0f", base),
            Optimista = sprintf("%.0f", optimista),
            Pesimista = sprintf("%.0f", pesimista),
            `Banda inf.` = sprintf("%.0f", gwh_low),
            `Banda sup.` = sprintf("%.0f", gwh_high))
emitir(proy, "tab_proyeccion_anual.tex", align = "lrrrrr")

log_event(STAGE, "INFO", "fin")
