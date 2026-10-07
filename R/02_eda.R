# ============================================================================
# 02_eda.R — Analisis exploratorio
# Entradas: data/processed/panel.rds
# Salidas : output/tables/descriptivos.csv, output/tables/correlaciones.csv,
#           output/figs/02_*.png
# ============================================================================

source(here::here("R", "00_utils.R"))

cfg <- load_config(); set_project_seed(cfg); ensure_dirs(cfg)
msg_step("02_eda: inicio")
panel <- read_panel(cfg)
df <- panel$data; segs <- panel$segmentos; act <- panel$actividad

# ---------------------------------------------------------------------------
# 1. Descriptivos
# ---------------------------------------------------------------------------
vars_nivel <- c(segs$mwh, segs$clientes, paste0("q_", segs$id),
                paste0("tarifa_real_", segs$id), act,
                intersect(c("vab_agro_ica", "vab_manuf_ica", "nino34",
                            "max_dem_kw", "factor_carga"), names(df)))

descr <- purrr::map_dfr(intersect(vars_nivel, names(df)), function(v) {
  x <- df[[v]]; x <- x[!is.na(x) & is.finite(x)]
  if (length(x) == 0) return(NULL)
  g <- diff(log(pmax(x, .Machine$double.eps)))
  tibble::tibble(variable = v, n = length(x),
                 media = mean(x), sd = stats::sd(x),
                 min = min(x), p25 = stats::quantile(x, .25),
                 p50 = stats::median(x), p75 = stats::quantile(x, .75),
                 max = max(x), cv = stats::sd(x) / mean(x),
                 crec_anual_prom_pct = 100 * (exp(12 * mean(g)) - 1))
})
write_table_out(descr, cfg, "descriptivos.csv")

# ---------------------------------------------------------------------------
# 2. Series en nivel y en log por segmento
# ---------------------------------------------------------------------------
long_e <- df %>%
  dplyr::select(fecha, dplyr::all_of(segs$mwh)) %>%
  tidyr::pivot_longer(-fecha, names_to = "serie", values_to = "mwh") %>%
  dplyr::left_join(dplyr::select(segs, serie = mwh, label), by = "serie")

p1 <- ggplot2::ggplot(long_e, ggplot2::aes(fecha, mwh)) +
  ggplot2::geom_line(colour = "#0b6e4f", linewidth = .5) +
  ggplot2::facet_wrap(~label, scales = "free_y", ncol = 1) +
  ggplot2::labs(title = "ELDU — Ventas de energia por segmento",
                subtitle = "MWh mensuales", x = NULL, y = "MWh") +
  theme_eldu()
save_fig(p1, cfg, "02_energia_nivel.png", height = 7)

long_q <- df %>%
  dplyr::select(fecha, dplyr::all_of(paste0("ln_q_", segs$id))) %>%
  tidyr::pivot_longer(-fecha, names_to = "serie", values_to = "ln_q") %>%
  dplyr::mutate(segmento = sub("^ln_q_", "", serie))

p2 <- ggplot2::ggplot(long_q, ggplot2::aes(fecha, ln_q)) +
  ggplot2::geom_line(colour = "#1f5fa8", linewidth = .5) +
  ggplot2::facet_wrap(~segmento, scales = "free_y", ncol = 1) +
  ggplot2::labs(title = "Consumo unitario en logaritmos: ln q = ln(MWh/cliente)",
                x = NULL, y = "ln q") + theme_eldu()
save_fig(p2, cfg, "02_ln_q.png", height = 7)

long_n <- df %>%
  dplyr::select(fecha, dplyr::all_of(paste0("ln_cli_", segs$id))) %>%
  tidyr::pivot_longer(-fecha, names_to = "serie", values_to = "v") %>%
  dplyr::mutate(segmento = sub("^ln_cli_", "", serie))
p3 <- ggplot2::ggplot(long_n, ggplot2::aes(fecha, v)) +
  ggplot2::geom_line(colour = "#8a4b9c", linewidth = .5) +
  ggplot2::facet_wrap(~segmento, scales = "free_y", ncol = 1) +
  ggplot2::labs(title = "Numero de clientes en logaritmos", x = NULL, y = "ln N") +
  theme_eldu()
save_fig(p3, cfg, "02_ln_clientes.png", height = 7)

# ---------------------------------------------------------------------------
# 3. Actividad, tarifas reales y ENSO
# ---------------------------------------------------------------------------
drivers <- df %>%
  dplyr::select(fecha, dplyr::any_of(c(act, "vab_agro_ica", "vab_manuf_ica"))) %>%
  tidyr::pivot_longer(-fecha, names_to = "serie", values_to = "v") %>%
  dplyr::filter(!is.na(v))
p4 <- ggplot2::ggplot(drivers, ggplot2::aes(fecha, v, colour = serie)) +
  ggplot2::geom_line(linewidth = .55) +
  ggplot2::labs(title = "Actividad economica de Ica",
                subtitle = "Niveles (indice o S/ constantes)",
                x = NULL, y = NULL, colour = NULL) +
  ggplot2::scale_colour_brewer(palette = "Dark2") + theme_eldu()
save_fig(p4, cfg, "02_actividad.png")

tar <- df %>%
  dplyr::select(fecha, dplyr::all_of(paste0("tarifa_real_", segs$id))) %>%
  tidyr::pivot_longer(-fecha, names_to = "serie", values_to = "v") %>%
  dplyr::mutate(segmento = sub("^tarifa_real_", "", serie))
p5 <- ggplot2::ggplot(tar, ggplot2::aes(fecha, v, colour = segmento)) +
  ggplot2::geom_line(linewidth = .55) +
  ggplot2::labs(title = "Tarifas / precios medios reales",
                subtitle = "S/ por kWh, deflactados por IPC",
                x = NULL, y = "S/ por kWh (real)", colour = NULL) +
  ggplot2::scale_colour_brewer(palette = "Set1") + theme_eldu()
save_fig(p5, cfg, "02_tarifas_reales.png")

if ("nino34" %in% names(df)) {
  p6 <- ggplot2::ggplot(df, ggplot2::aes(fecha, nino34)) +
    ggplot2::geom_hline(yintercept = c(-0.5, 0.5), linetype = 2, colour = "grey60") +
    ggplot2::geom_col(ggplot2::aes(fill = nino34 > 0), show.legend = FALSE) +
    ggplot2::scale_fill_manual(values = c(`TRUE` = "#c0392b", `FALSE` = "#2471a3")) +
    ggplot2::labs(title = "Anomalia ENSO Niño 3.4",
                  subtitle = "Lineas: umbrales +/-0.5 °C",
                  x = NULL, y = "°C") + theme_eldu()
  save_fig(p6, cfg, "02_enso.png", height = 3.6)
}

# ---------------------------------------------------------------------------
# 4. Estacionalidad del consumo unitario
# ---------------------------------------------------------------------------
estac <- long_q %>%
  dplyr::filter(!is.na(ln_q)) %>%
  dplyr::group_by(segmento) %>%
  dplyr::mutate(dev = ln_q - stats::predict(stats::lm(ln_q ~ seq_along(ln_q)))) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(mes = lubridate::month(fecha, label = TRUE, abbr = TRUE))
p7 <- ggplot2::ggplot(estac, ggplot2::aes(mes, 100 * dev)) +
  ggplot2::geom_hline(yintercept = 0, colour = "grey70") +
  ggplot2::geom_boxplot(outlier.size = .6, fill = "#d6eadf") +
  ggplot2::facet_wrap(~segmento, scales = "free_y", ncol = 1) +
  ggplot2::labs(title = "Patron estacional del consumo unitario",
                subtitle = "Desvio respecto a la tendencia lineal, en % (log x 100)",
                x = NULL, y = "%") + theme_eldu()
save_fig(p7, cfg, "02_estacionalidad.png", height = 7)

# ---------------------------------------------------------------------------
# 5. Correlaciones en diferencias logaritmicas (evita correlacion espuria)
# ---------------------------------------------------------------------------
vars_log <- c(paste0("ln_q_", segs$id), paste0("ln_cli_", segs$id),
              paste0("ln_", act), paste0("ln_ptilde_", segs$id),
              intersect(c("ln_vab_agro_ica", "ln_vab_manuf_ica"), names(df)))
vars_log <- intersect(vars_log, names(df))
dlogs <- df %>% dplyr::select(dplyr::all_of(vars_log)) %>%
  dplyr::mutate(dplyr::across(dplyr::everything(), D))
if ("nino34" %in% names(df)) dlogs$nino34 <- df$nino34
cmat <- stats::cor(dlogs, use = "pairwise.complete.obs")
corr_tab <- as.data.frame(as.table(cmat)) %>%
  stats::setNames(c("var1", "var2", "corr")) %>%
  dplyr::filter(as.character(var1) < as.character(var2)) %>%
  dplyr::arrange(dplyr::desc(abs(corr)))
write_table_out(corr_tab, cfg, "correlaciones.csv")

p8 <- ggplot2::ggplot(as.data.frame(as.table(cmat)) %>%
                        stats::setNames(c("v1", "v2", "r")),
                      ggplot2::aes(v1, v2, fill = r)) +
  ggplot2::geom_tile(colour = "white") +
  ggplot2::geom_text(ggplot2::aes(label = sprintf("%.2f", r)), size = 2.4) +
  ggplot2::scale_fill_gradient2(low = "#2166ac", mid = "white", high = "#b2182b",
                                limits = c(-1, 1)) +
  ggplot2::labs(title = "Correlaciones en primeras diferencias logaritmicas",
                x = NULL, y = NULL, fill = "r") +
  theme_eldu() +
  ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
save_fig(p8, cfg, "02_correlaciones.png", width = 9, height = 7.5)

# ---------------------------------------------------------------------------
# 6. Maxima demanda / factor de carga (si esta disponible)
# ---------------------------------------------------------------------------
if (all(c("max_dem_kw", "factor_carga") %in% names(df))) {
  p9 <- df %>%
    dplyr::select(fecha, max_dem_kw, factor_carga) %>%
    tidyr::pivot_longer(-fecha) %>%
    ggplot2::ggplot(ggplot2::aes(fecha, value)) +
    ggplot2::geom_line(colour = "#b9770e", linewidth = .5) +
    ggplot2::facet_wrap(~name, scales = "free_y", ncol = 1) +
    ggplot2::labs(title = "Maxima demanda y factor de carga", x = NULL, y = NULL) +
    theme_eldu()
  save_fig(p9, cfg, "02_max_demanda.png", height = 5.5)
  fc <- stats::lm(ln_max_dem_kw ~ I(log(mwh_total)), data = df)
  write_table_out(broom::tidy(fc) %>% dplyr::mutate(r2 = summary(fc)$r.squared),
                  cfg, "elasticidad_pico_energia.csv")
}

msg_step("02_eda: fin (", length(list.files(cfg_path(cfg, "figs"))), " figuras)")
