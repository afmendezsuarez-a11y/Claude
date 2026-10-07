## ============================================================================
## 01_fetch_bcrp.R — SOLO descarga. Guarda crudo en data/raw/ y registra fuente.
## ----------------------------------------------------------------------------
## Descarga PBI real, IPC y tipo de cambio desde la API pública del BCRP.
##
## Los códigos de serie NO se asumen:
##   (a) se intenta resolverlos contra el catálogo de metadatos del BCRP;
##   (b) si (a) falla, se prueban los códigos candidato de config/config.R;
##   (c) en ambos casos se VALIDA el nombre que devuelve la API contra
##       `name_regex`. Si no calza, la serie se descarta y se registra.
## Así nunca se guarda "una serie cualquiera" bajo el nombre de otra.
## ============================================================================

suppressPackageStartupMessages({
  library(httr); library(jsonlite); library(here)
})

STAGE <- "01_bcrp"
log_event(STAGE, "INFO", "inicio — descarga de series BCRP")

raw_dir <- here::here(CFG$paths$raw)

## ---- (a) Catálogo de metadatos (best-effort) -------------------------------
meta_path <- file.path(raw_dir, "bcrp_metadata.csv")
meta_ok <- FALSE
for (u in CFG$bcrp$metadata_urls) {
  if (download_to_file(u, meta_path, STAGE,
                       description = "Catálogo de metadatos de series BCRPData",
                       notes = "usado para resolver códigos de serie por nombre")) {
    meta_ok <- TRUE; break
  }
}
meta <- NULL
if (meta_ok) {
  meta <- tryCatch({
    for (sep in c(";", ",", "\t")) {
      m <- try(utils::read.csv(meta_path, sep = sep, stringsAsFactors = FALSE,
                               fileEncoding = "latin1"), silent = TRUE)
      if (!inherits(m, "try-error") && ncol(m) >= 3) return_m <- m else return_m <- NULL
      if (!is.null(return_m)) break
    }
    return_m
  }, error = function(e) NULL)
  if (is.null(meta)) log_event(STAGE, "WARN", "catálogo descargado pero ilegible como CSV")
}

#' Busca códigos en el catálogo cuyo nombre contenga todos los términos.
resolve_from_catalog <- function(meta, search_terms, freq_hint = NULL) {
  if (is.null(meta)) return(character(0))
  name_col <- names(meta)[grepl("(?i)nombre|name", names(meta), perl = TRUE)][1]
  code_col <- names(meta)[grepl("(?i)c[oó]digo|code", names(meta), perl = TRUE)][1]
  if (is.na(name_col) || is.na(code_col)) return(character(0))
  keep <- rep(TRUE, nrow(meta))
  for (t in search_terms) {
    keep <- keep & grepl(t, meta[[name_col]], ignore.case = TRUE, perl = TRUE)
  }
  utils::head(unique(as.character(meta[[code_col]][keep])), 8)
}

## ---- Descarga + validación de una serie -----------------------------------
fetch_series <- function(key, spec) {
  dest <- file.path(raw_dir, sprintf("bcrp_%s.json", key))
  codes <- unique(c(resolve_from_catalog(meta, spec$search_terms), spec$candidates))
  if (!length(codes)) {
    log_event(STAGE, if (isTRUE(spec$mandatory)) "BLOCKED" else "FAIL",
              sprintf("[%s] sin códigos candidato (catálogo no disponible)", key))
    return(FALSE)
  }
  for (code in codes) {
    url <- sprintf("%s/%s/json/%s/%s", CFG$bcrp$api_base, code,
                   CFG$bcrp$start, CFG$bcrp$end)
    tmp <- tempfile(fileext = ".json")
    if (!download_to_file(url, tmp, STAGE,
                          description = sprintf("BCRP %s (código %s)", spec$label, code),
                          notes = "descarga temporal, pendiente de validación de nombre")) {
      next
    }
    j <- tryCatch(jsonlite::fromJSON(tmp, simplifyVector = FALSE),
                  error = function(e) NULL)
    if (is.null(j) || is.null(j$periods) || !length(j$periods)) {
      log_event(STAGE, "WARN", sprintf("[%s] código %s devolvió JSON sin datos", key, code))
      next
    }
    nm <- tryCatch(paste(vapply(j$config$series, function(s) s$name %||% "", ""),
                         collapse = " | "), error = function(e) "")
    if (!grepl(spec$name_regex, nm, perl = TRUE)) {
      log_event(STAGE, "WARN",
                sprintf("[%s] código %s DESCARTADO: el nombre devuelto ('%s') no calza con el patrón esperado",
                        key, code, substr(nm, 1, 120)))
      next
    }
    file.copy(tmp, dest, overwrite = TRUE)
    register_source(dest, url,
                    description = sprintf("BCRP — %s", spec$label),
                    notes = sprintf("código=%s; nombre devuelto por la API='%s'; n_periodos=%d",
                                    code, substr(nm, 1, 160), length(j$periods)))
    log_event(STAGE, "OK",
              sprintf("[%s] serie aceptada: código=%s, nombre='%s', %d periodos",
                      key, code, substr(nm, 1, 80), length(j$periods)))
    return(TRUE)
  }
  log_event(STAGE, if (isTRUE(spec$mandatory)) "BLOCKED" else "FAIL",
            sprintf("[%s] ninguna de las %d URL/código candidato entregó una serie válida",
                    key, length(codes)))
  FALSE
}

`%||%` <- function(a, b) if (is.null(a)) b else a

results <- vapply(names(CFG$bcrp$series),
                  function(k) fetch_series(k, CFG$bcrp$series[[k]]),
                  logical(1))

log_event(STAGE, "INFO",
          sprintf("fin — %d/%d series BCRP obtenidas (%s)",
                  sum(results), length(results),
                  paste(names(results)[results], collapse = ", ")))
