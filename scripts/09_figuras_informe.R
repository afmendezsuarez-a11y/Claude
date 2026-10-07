## ============================================================================
## 09_figuras_informe.R — figuras vectoriales (PDF) para el informe LaTeX.
## ----------------------------------------------------------------------------
## Se construyen desde las MISMAS salidas del pipeline que alimentan el informe
## HTML (`panel_anual.rds`, `estimacion.rds`, `forecast.rds`), no desde cifras
## retipeadas: si cambia la data, cambian las figuras.
##
## Convención visual, igual en las tres: una sola tinta de acento (azul) sobre
## lo que dice el título, el resto en grises distinguidos por tono y etiqueta.
## ============================================================================

suppressPackageStartupMessages({
  library(dplyr); library(tidyr); library(ggplot2); library(here)
})

STAGE <- "09_figuras"
log_event(STAGE, "INFO", "inicio — figuras del informe LaTeX")

panel <- readRDS(here::here(CFG$paths$processed, "panel_anual.rds"))
RES   <- readRDS(here::here(CFG$paths$processed, "estimacion.rds"))
FC    <- readRDS(here::here(CFG$paths$processed, "forecast.rds"))

fig_dir <- here::here("report", "figs")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

AZUL  <- "#2563EB"
GRIS  <- "#9AA0A6"
GRIS2 <- "#6B7280"
TINTA <- "#1F2328"

tema <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(colour = "grey90", linewidth = .3),
        axis.title = element_text(colour = GRIS2, size = 9),
        axis.text = element_text(colour = GRIS2),
        plot.title = element_text(colour = TINTA, size = 11, face = "bold"),
        plot.subtitle = element_text(colour = GRIS2, size = 9),
        plot.caption = element_text(colour = GRIS, size = 7.5, hjust = 0),
        plot.margin = margin(6, 10, 6, 6))

guardar <- function(p, nombre, w, h) {
  f <- file.path(fig_dir, nombre)
  ok <- tryCatch({
    ggsave(f, p, width = w, height = h, device = grDevices::cairo_pdf); TRUE
  }, error = function(e) {
    ggsave(f, p, width = w, height = h); TRUE
  })
  ## PNG de control, para poder mirar la figura sin abrir el PDF
  ggsave(sub("\\.pdf$", ".png", f), p, width = w, height = h, dpi = 170)
  log_event(STAGE, "OK", sprintf("escrita %s", file.path("report/figs", nombre)))
  invisible(f)
}

#' Separa etiquetas que caerían una encima de otra, en unidades del eje y.
separar <- function(v, minimo) {
  o <- order(-v); out <- v
  for (i in seq_along(o)) {
    if (i == 1) next
    prev <- out[o[i - 1]]
    if (prev - out[o[i]] < minimo) out[o[i]] <- prev - minimo
  }
  out
}

## ---------------------------------------------------------------------------
## Figura 1 — descomposición del crecimiento, índice base = primer año
## ---------------------------------------------------------------------------
b <- panel %>% arrange(year)
largo <- bind_rows(
  tibble::tibble(year = b$year, slug = "energia",    serie = "Energía distribuida", valor = b$energia_gwh),
  tibble::tibble(year = b$year, slug = "clientes",   serie = "Clientes",            valor = b$clientes),
  tibble::tibble(year = b$year, slug = "porcliente", serie = "Consumo/cliente",     valor = b$energia_por_cliente_mwh),
  tibble::tibble(year = b$year, slug = "vab",        serie = "VAB de Ica",          valor = b$pbi)
) %>% group_by(slug) %>% mutate(idx = 100 * valor / valor[which.min(year)]) %>% ungroup()

fin <- largo %>% filter(year == max(year)) %>%
  mutate(ly = separar(idx, 0.045 * diff(range(largo$idx))))

p1 <- ggplot(largo, aes(year, idx, group = slug)) +
  geom_hline(yintercept = 100, colour = "grey70", linewidth = .3) +
  geom_line(aes(colour = slug == "clientes", linetype = slug == "vab",
                linewidth = slug == "clientes")) +
  geom_point(aes(colour = slug == "clientes"), size = .9) +
  geom_text(data = fin, aes(x = max(largo$year) + 0.12, y = ly,
                            label = sprintf("%s %.0f", serie, idx),
                            colour = slug == "clientes"),
            hjust = 0, size = 3) +
  scale_colour_manual(values = c(`FALSE` = GRIS, `TRUE` = AZUL), guide = "none") +
  scale_linetype_manual(values = c(`FALSE` = "solid", `TRUE` = "22"), guide = "none") +
  scale_linewidth_manual(values = c(`FALSE` = .5, `TRUE` = .9), guide = "none") +
  scale_x_continuous(breaks = b$year, expand = expansion(mult = c(.02, .34))) +
  labs(title = "Las conexiones llevan el crecimiento del volumen",
       subtitle = sprintf("Índice %d = 100. Los clientes suben en rampa; el consumo por cliente apenas se mueve.",
                          min(b$year)),
       x = NULL, y = "Índice") +
  tema
guardar(p1, "fig1_descomposicion.pdf", 6.4, 3.3)

## ---------------------------------------------------------------------------
## Figura 2 — elasticidad estimada por especificación
## ---------------------------------------------------------------------------
el <- utils::read.csv(here::here(CFG$paths$tables, "elasticidad.csv"), stringsAsFactors = FALSE)
etq <- function(bloque, metodo) {
  bl <- c(energia_por_cliente = "Por cliente", energia_total = "Energía total",
          volumen_alt = "Volumen alternativo", driver_nacional = "Driver nacional",
          ex_shock = "Sin 2020–2021")[bloque]
  mt <- c(`OLS log-log con tendencia` = "niveles + tend.",
          `OLS log-log sin tendencia` = "niveles",
          `Regresión en diferencias`  = "diferencias")[metodo]
  ifelse(bloque %in% c("energia_por_cliente", "energia_total"),
         sprintf("%s, %s", bl, mt), bl)
}
el <- el %>%
  mutate(etiqueta = etq(bloque, metodo),
         orden = match(rol, c("PRINCIPAL", "corroboracion", "comparacion", "robustez")),
         principal = rol == "PRINCIPAL") %>%
  arrange(orden, bloque, metodo) %>%
  mutate(etiqueta = factor(etiqueta, levels = rev(etiqueta)))

pr <- el %>% filter(principal) %>% slice(1)
p2 <- ggplot(el, aes(estimate, etiqueta, colour = principal)) +
  annotate("rect", xmin = pr$ci95_low, xmax = pr$ci95_high,
           ymin = -Inf, ymax = Inf, fill = GRIS, alpha = .13) +
  geom_vline(xintercept = 0, colour = "grey55", linewidth = .35) +
  geom_errorbarh(aes(xmin = ci95_low, xmax = ci95_high), height = .22, linewidth = .45) +
  geom_point(aes(size = principal)) +
  geom_text(aes(x = max(el$ci95_high) + 0.12, label = sprintf("%.2f", estimate)),
            hjust = 0, size = 3) +
  scale_colour_manual(values = c(`FALSE` = GRIS, `TRUE` = AZUL), guide = "none") +
  scale_size_manual(values = c(`FALSE` = 1.5, `TRUE` = 2.4), guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(.03, .14))) +
  labs(title = "La elasticidad se concentra entre 0.2 y 0.5",
       subtitle = sprintf("Punto e IC 95%% con errores HAC. Banda gris = rango reportado (%.2f–%.2f).",
                          pr$ci95_low, pr$ci95_high),
       x = "Elasticidad-ingreso estimada", y = NULL) +
  tema + theme(panel.grid.major.y = element_blank(),
               panel.grid.major.x = element_line(colour = "grey92", linewidth = .3))
guardar(p2, "fig2_elasticidades.pdf", 6.4, 3.4)

## ---------------------------------------------------------------------------
## Figura 3 — proyección con banda de eta
## ---------------------------------------------------------------------------
hist3 <- panel %>% transmute(year, gwh = energia_gwh, escenario = "Observado")
base3 <- FC$fc %>% filter(escenario == "base") %>% select(year, gwh_low, gwh_high)
ancla <- tibble::tibble(year = max(panel$year),
                        gwh_low = panel$energia_gwh[which.max(panel$year)],
                        gwh_high = panel$energia_gwh[which.max(panel$year)])
banda <- bind_rows(ancla, base3)

proy <- FC$fc %>% select(year, escenario, gwh = gwh_central) %>%
  mutate(escenario = tools::toTitleCase(escenario)) %>%
  group_by(escenario) %>%
  group_modify(~bind_rows(tibble::tibble(year = max(panel$year),
                                         gwh = panel$energia_gwh[which.max(panel$year)]), .x)) %>%
  ungroup()
fin3 <- proy %>% group_by(escenario) %>% filter(year == max(year)) %>% ungroup() %>%
  mutate(ly = separar(gwh, 0.055 * diff(range(c(proy$gwh, hist3$gwh)))))

p3 <- ggplot() +
  geom_ribbon(data = banda, aes(year, ymin = gwh_low, ymax = gwh_high),
              fill = AZUL, alpha = .13) +
  geom_vline(xintercept = max(panel$year) + .5, colour = "grey60",
             linetype = "22", linewidth = .35) +
  geom_line(data = hist3, aes(year, gwh), colour = GRIS, linewidth = .9) +
  geom_point(data = hist3, aes(year, gwh), colour = GRIS, size = .9) +
  ## `group = escenario` es imprescindible: sin él ggplot agrupa por las
  ## estéticas discretas (colour/linewidth), funde Optimista con Pesimista en
  ## una sola serie y dibuja una sierra entre ambas.
  geom_line(data = proy, aes(year, gwh, group = escenario,
                             colour = escenario == "Base",
                             linewidth = escenario == "Base")) +
  geom_text(data = fin3, aes(x = max(fin3$year) + 0.2, y = ly,
                             label = sprintf("%s %s", escenario, format(round(gwh), big.mark = ".")),
                             colour = escenario == "Base"),
            hjust = 0, size = 3) +
  annotate("text", x = max(panel$year) + .8, y = Inf, label = "proyectado",
           hjust = 0, vjust = 1.6, size = 2.9, colour = GRIS2) +
  annotate("text", x = max(panel$year) + .2, y = Inf, label = "observado",
           hjust = 1, vjust = 1.6, size = 2.9, colour = GRIS2) +
  scale_colour_manual(values = c(`FALSE` = GRIS, `TRUE` = AZUL), guide = "none") +
  scale_linewidth_manual(values = c(`FALSE` = .5, `TRUE` = .9), guide = "none") +
  scale_x_continuous(breaks = seq(min(panel$year), CFG$fy_horizon, 3),
                     expand = expansion(mult = c(.02, .22))) +
  labs(title = sprintf("A FY%d la banda de la elasticidad supera la distancia entre escenarios",
                       CFG$fy_horizon),
       subtitle = sprintf("Base %s GWh; banda de la elasticidad %s a %s; escenarios %s a %s.",
                          format(round(max(FC$fc$gwh_central[FC$fc$escenario == "base"])), big.mark = "."),
                          format(round(min(tail(base3$gwh_low, 1))), big.mark = "."),
                          format(round(max(tail(base3$gwh_high, 1))), big.mark = "."),
                          format(round(min(FC$fc$gwh_central[FC$fc$year == CFG$fy_horizon])), big.mark = "."),
                          format(round(max(FC$fc$gwh_central[FC$fc$year == CFG$fy_horizon])), big.mark = ".")),
       x = NULL, y = "GWh") +
  tema
guardar(p3, "fig3_proyeccion.pdf", 6.4, 3.4)

log_event(STAGE, "INFO", "fin")
