## ============================================================================
## 02_fetch_noaa.R — SOLO descarga. Índices ENSO (ONI y Niño 3.4) de NOAA CPC.
## ----------------------------------------------------------------------------
## OPCIONAL: si no descarga, el pipeline continúa SIN clima y lo deja anotado
## en el log y en el informe. No se sustituye por nada.
## ============================================================================

STAGE <- "02_noaa"
log_event(STAGE, "INFO", "inicio — descarga de índices ENSO (NOAA CPC)")

raw_dir <- here::here(CFG$paths$raw)

targets <- list(
  oni = list(url = CFG$noaa$oni,
             dest = file.path(raw_dir, "noaa_oni.ascii.txt"),
             desc = "NOAA CPC — Oceanic Niño Index (ONI), mensual, ASCII"),
  nino34 = list(url = CFG$noaa$nino34,
                dest = file.path(raw_dir, "noaa_nino34.ascii.txt"),
                desc = "NOAA CPC — SST Niño 3.4 mensual (ERSSTv5, base 91-20), ASCII")
)

ok <- vapply(names(targets), function(k) {
  t <- targets[[k]]
  download_to_file(t$url, t$dest, STAGE, description = t$desc,
                   notes = "índice climático; agregado a anual en 05_build_panel.R",
                   mandatory = FALSE)
}, logical(1))

if (!any(ok)) {
  log_event(STAGE, "FAIL",
            "ningún índice ENSO disponible — el panel se construirá SIN variable de clima")
} else {
  log_event(STAGE, "INFO", sprintf("fin — %d/%d índices ENSO obtenidos", sum(ok), length(ok)))
}
