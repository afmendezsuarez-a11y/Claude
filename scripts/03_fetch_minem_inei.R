## ============================================================================
## 03_fetch_minem_inei.R — SOLO descarga.
##   - MINEM: Anuario Estadístico de Electricidad (ventas GWh y clientes por
##            empresa distribuidora) -> mejor fuente abierta de serie larga.
##   - Osinergmin: Anuario / RSMME -> respaldo y cruce.
##   - INEI: PBI departamental de Ica (VAB real, anual) -> driver preferido.
## ----------------------------------------------------------------------------
## Las URLs profundas de estos portales cambian cada año, así que NO se adivina
## un deep-link: se raspan las páginas de publicaciones buscando enlaces que
## calcen con el patrón, y se pueden forzar URLs directas vía
## CFG$<fuente>$direct_urls en config/config.R.
## ============================================================================

suppressPackageStartupMessages({ library(rvest); library(xml2); library(here) })

STAGE <- "03_minem_inei"
log_event(STAGE, "INFO", "inicio — MINEM / Osinergmin / INEI")

raw_dir <- here::here(CFG$paths$raw)

#' Intenta obtener documentos de una fuente: primero URLs directas, luego
#' raspando las landing pages. Descarga hasta `max_files`.
fetch_source <- function(key, spec, prefix, description, max_files = 4L) {
  urls <- spec$direct_urls
  if (!length(urls)) {
    for (p in spec$landing_pages) {
      urls <- c(urls, find_links(p, spec$link_regex, STAGE))
    }
    urls <- unique(urls)
  }
  if (!length(urls)) {
    log_event(STAGE, "FAIL",
              sprintf("[%s] no se halló ningún documento. Pegue una URL directa en CFG$%s$direct_urls",
                      key, key))
    return(0L)
  }
  n_ok <- 0L
  for (u in utils::head(urls, max_files)) {
    ext  <- tolower(tools::file_ext(sub("\\?.*$", "", u)))
    if (!nzchar(ext)) ext <- "bin"
    dest <- file.path(raw_dir, sprintf("%s_%02d.%s", prefix, n_ok + 1L, ext))
    if (download_to_file(u, dest, STAGE, description = description,
                         notes = sprintf("hallado automáticamente desde %s",
                                         paste(spec$landing_pages, collapse = " / ")))) {
      n_ok <- n_ok + 1L
    }
  }
  log_event(STAGE, if (n_ok > 0) "OK" else "FAIL",
            sprintf("[%s] %d documento(s) descargado(s) de %d candidato(s)",
                    key, n_ok, length(urls)))
  n_ok
}

n_minem <- fetch_source("minem", CFG$minem, "minem_anuario",
                        "MINEM — Anuario Estadístico de Electricidad (ventas GWh y clientes por distribuidora)")

n_osi <- fetch_source("osinergmin", CFG$osinergmin, "osinergmin_anuario",
                      "Osinergmin — Anuario / RSMME (ventas por distribuidora; respaldo y cruce)")

n_inei <- fetch_source("inei", CFG$inei, "inei_pbi_departamental",
                       sprintf("INEI — PBI departamental (VAB real anual), región de interés: %s",
                               CFG$inei$region))

if (n_inei == 0L) {
  log_event(STAGE, "WARN",
            paste("PBI departamental de Ica NO obtenido — 05_build_panel.R usará el PBI",
                  "nacional del BCRP como PROXY, y quedará marcado como tal en el informe"))
}
if (n_minem == 0L && n_osi == 0L) {
  log_event(STAGE, "WARN",
            paste("Ni MINEM ni Osinergmin disponibles — la energía de ELDU deberá venir de",
                  "las Memorias Anuales (04) o de", CFG$eldu$manual_csv))
}

log_event(STAGE, "INFO", "fin")
