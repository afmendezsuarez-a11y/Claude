## ============================================================================
## R/utils.R — utilidades compartidas: logging, descarga, registro de fuentes
## ----------------------------------------------------------------------------
## Principio: toda descarga deja rastro (log + SOURCES.md). Toda falla se
## registra y es visible. Nada se rellena con datos sintéticos.
## ============================================================================

suppressPackageStartupMessages({
  library(here)
  library(httr)
})

#' Valor por defecto cuando el de la izquierda es NULL o vacío.
`%||%` <- function(a, b) if (is.null(a) || !length(a)) b else a

## ---- Logging ---------------------------------------------------------------

#' Escribe una línea en output/fetch_log.txt y en consola.
#' @param stage p.ej. "01_bcrp"
#' @param status uno de OK | FAIL | SKIP | WARN | INFO | BLOCKED
log_event <- function(stage, status, msg) {
  stopifnot(is.character(stage), is.character(status), is.character(msg))
  path <- here::here(CFG$paths$fetch_log)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  ## un evento = una línea: los mensajes multilínea se colapsan para que el log
  ## siga siendo parseable (y contable) por etapa y estado.
  msg <- gsub("\\s*\n\\s*", " / ", msg)
  msg <- gsub("[|]", "/", msg)
  msg <- gsub("\\s{2,}", " ", trimws(msg))
  line <- sprintf("%s | %-14s | %-7s | %s",
                  format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC"),
                  stage, status, msg)
  cat(line, "\n", file = path, sep = "", append = TRUE)
  cat(line, "\n", sep = "")
  invisible(line)
}

#' Reinicia el log (lo llama run_all.R al inicio de la corrida).
init_log <- function() {
  path <- here::here(CFG$paths$fetch_log)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  cat(sprintf("# fetch_log — corrida iniciada %s UTC\n# R %s\n",
              format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC"),
              getRversion()),
      file = path, append = FALSE)
  invisible(path)
}

## ---- Registro de fuentes (SOURCES.md) --------------------------------------
## Se mantiene un CSV máquina-legible y se re-renderiza SOURCES.md desde él,
## de modo que la corrida es idempotente y cada archivo crudo es trazable.

SOURCES_COLS <- c("file", "url", "description", "retrieved_at_utc",
                  "bytes", "sha256", "notes")

#' Registra un archivo crudo con su procedencia.
register_source <- function(file, url, description, notes = "") {
  csv <- here::here(CFG$paths$sources_csv)
  dir.create(dirname(csv), recursive = TRUE, showWarnings = FALSE)
  rel <- sub(paste0("^", here::here(), "/?"), "", file)
  info <- if (file.exists(file)) file.info(file) else NULL
  row <- data.frame(
    file             = rel,
    url              = url,
    description      = description,
    retrieved_at_utc = format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC"),
    bytes            = if (is.null(info)) NA_integer_ else as.integer(info$size),
    sha256           = if (file.exists(file)) sha256_file(file) else NA_character_,
    notes            = notes,
    stringsAsFactors = FALSE
  )
  old <- if (file.exists(csv)) {
    utils::read.csv(csv, stringsAsFactors = FALSE, colClasses = "character")
  } else NULL
  if (!is.null(old) && nrow(old)) {
    old <- old[old$file != rel, , drop = FALSE]      # reemplaza entrada previa
    row <- rbind(
      transform(old, bytes = suppressWarnings(as.integer(bytes))),
      row
    )
  }
  utils::write.csv(row, csv, row.names = FALSE)
  render_sources_md()
  invisible(row)
}

sha256_file <- function(path) {
  tryCatch({
    if (requireNamespace("openssl", quietly = TRUE)) {
      as.character(openssl::sha256(file(path, "rb")))
    } else {
      out <- suppressWarnings(system2("sha256sum", shQuote(path),
                                      stdout = TRUE, stderr = FALSE))
      if (length(out) == 1) sub(" .*$", "", out) else NA_character_
    }
  }, error = function(e) NA_character_)
}

#' Re-renderiza data/raw/SOURCES.md desde el registro CSV.
render_sources_md <- function() {
  csv <- here::here(CFG$paths$sources_csv)
  md  <- here::here(CFG$paths$sources_md)
  d <- if (file.exists(csv)) {
    utils::read.csv(csv, stringsAsFactors = FALSE)
  } else {
    ## Sin registro todavía: se escribe igual el archivo, en estado vacío, para
    ## que quede constancia de que no se obtuvo ninguna fuente.
    stats::setNames(data.frame(matrix(character(0), nrow = 0,
                                      ncol = length(SOURCES_COLS))), SOURCES_COLS)
  }
  dir.create(dirname(md), recursive = TRUE, showWarnings = FALSE)
  if (nrow(d)) d <- d[order(d$file), , drop = FALSE]
  con <- file(md, "w")
  on.exit(close(con))
  writeLines(c(
    "# SOURCES.md — procedencia de cada archivo en `data/raw/`",
    "",
    "Generado automáticamente por el pipeline. **No editar a mano**: se",
    "re-genera desde `data/raw/sources_registry.csv` en cada corrida.",
    "",
    "Toda cifra del informe debe ser trazable a uno de estos archivos.",
    "",
    sprintf("Última actualización: %s UTC",
            format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC")),
    "",
    "| Archivo | Descripción | URL | Descargado (UTC) | Bytes | SHA256 | Notas |",
    "|---|---|---|---|---|---|---|"
  ), con)
  if (nrow(d)) {
    for (i in seq_len(nrow(d))) {
      writeLines(sprintf("| `%s` | %s | %s | %s | %s | `%s` | %s |",
                         d$file[i], d$description[i],
                         if (nzchar(d$url[i])) sprintf("<%s>", d$url[i]) else "—",
                         d$retrieved_at_utc[i],
                         ifelse(is.na(d$bytes[i]), "—", format(d$bytes[i], big.mark = ",")),
                         substr(ifelse(is.na(d$sha256[i]), "—", d$sha256[i]), 1, 16),
                         d$notes[i]), con)
    }
  } else {
    writeLines("| _(vacío: no se obtuvo ninguna fuente)_ | | | | | | |", con)
  }
  invisible(md)
}

## ---- Descarga HTTP con reintentos -----------------------------------------

#' Descarga una URL a disco con reintentos y backoff exponencial.
#' Nunca lanza error: devuelve TRUE/FALSE y registra el resultado.
#' @return TRUE si el archivo quedó en disco con tamaño > 0.
download_to_file <- function(url, dest, stage, description = "",
                             notes = "", mandatory = FALSE) {
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  backoff <- CFG$http$backoff_s
  n_try   <- CFG$http$retries
  last_err <- "sin intentos"
  for (k in seq_len(n_try)) {
    res <- tryCatch(
      httr::GET(url,
                httr::user_agent(CFG$http$user_agent),
                httr::timeout(CFG$http$timeout_s),
                httr::write_disk(dest, overwrite = TRUE)),
      error = function(e) e
    )
    if (inherits(res, "error")) {
      last_err <- conditionMessage(res)
    } else if (httr::status_code(res) == 200 &&
               file.exists(dest) && file.info(dest)$size > 0) {
      log_event(stage, "OK",
                sprintf("descargado %s (%s bytes) <- %s",
                        basename(dest), file.info(dest)$size, url))
      register_source(dest, url, description, notes)
      return(TRUE)
    } else {
      last_err <- sprintf("HTTP %s", httr::status_code(res))
    }
    if (k < n_try) {
      log_event(stage, "WARN", sprintf("intento %d/%d falló (%s) en %s; reintento en %ds",
                                       k, n_try, last_err, url, backoff[k]))
      Sys.sleep(backoff[min(k, length(backoff))])
    }
  }
  if (file.exists(dest) && file.info(dest)$size == 0) unlink(dest)
  log_event(stage, if (mandatory) "BLOCKED" else "FAIL",
            sprintf("NO se pudo descargar %s — último error: %s", url, last_err))
  FALSE
}

#' Lee el HTML de una página y devuelve los enlaces que calzan un regex.
#' @return character(0) si la página no se pudo leer (y lo registra).
find_links <- function(page_url, link_regex, stage) {
  res <- tryCatch(
    httr::GET(page_url, httr::user_agent(CFG$http$user_agent),
              httr::timeout(CFG$http$timeout_s)),
    error = function(e) e
  )
  if (inherits(res, "error") || httr::status_code(res) != 200) {
    msg <- if (inherits(res, "error")) conditionMessage(res)
           else sprintf("HTTP %s", httr::status_code(res))
    log_event(stage, "FAIL", sprintf("no se pudo leer la página %s (%s)", page_url, msg))
    return(character(0))
  }
  html <- tryCatch(rvest::read_html(res), error = function(e) NULL)
  if (is.null(html)) {
    log_event(stage, "FAIL", sprintf("HTML ilegible en %s", page_url))
    return(character(0))
  }
  hrefs <- rvest::html_attr(rvest::html_elements(html, "a"), "href")
  hrefs <- hrefs[!is.na(hrefs)]
  hits  <- unique(hrefs[grepl(link_regex, hrefs, perl = TRUE)])
  hits  <- xml2::url_absolute(hits, page_url)
  log_event(stage, "INFO", sprintf("%d enlace(s) candidato(s) en %s", length(hits), page_url))
  hits
}

## ---- Barreras anti-invención ----------------------------------------------

#' Detiene el pipeline con un mensaje accionable cuando falta un insumo
#' OBLIGATORIO. Se usa en 05_build_panel.R. Nunca se sustituye por datos falsos.
stop_missing <- function(what, where, how) {
  msg <- paste0(
    "\n",
    "=========================================================================\n",
    "  PIPELINE DETENIDO — falta un insumo OBLIGATORIO\n",
    "=========================================================================\n",
    "  Falta        : ", what, "\n",
    "  Se buscó en  : ", paste(where, collapse = "\n                 "), "\n",
    "  Cómo proveerlo:\n", paste0("    - ", how, collapse = "\n"), "\n",
    "-------------------------------------------------------------------------\n",
    "  NO se generan datos sintéticos para continuar. Ver ",
    CFG$paths$fetch_log, "\n",
    "=========================================================================\n"
  )
  log_event("05_panel", "BLOCKED", paste("falta insumo obligatorio:", what))
  stop(msg, call. = FALSE)
}

#' Verifica que un data.frame no tenga NA en columnas críticas.
assert_no_silent_imputation <- function(df, cols, context) {
  for (cc in cols) {
    if (!cc %in% names(df)) stop(sprintf("[%s] falta la columna '%s'", context, cc))
    if (any(is.na(df[[cc]]))) {
      bad <- which(is.na(df[[cc]]))
      stop(sprintf(paste0("[%s] la columna '%s' tiene %d NA (filas: %s). ",
                          "El pipeline no imputa: corrija la fuente."),
                   context, cc, length(bad),
                   paste(utils::head(bad, 10), collapse = ", ")), call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' Guarda un RDS creando el directorio si hace falta.
save_rds <- function(obj, path) {
  path <- here::here(path)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(obj, path)
  invisible(path)
}
