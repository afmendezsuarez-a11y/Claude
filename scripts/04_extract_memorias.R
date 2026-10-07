## ============================================================================
## 04_extract_memorias.R — SOLO extracción. Memorias Anuales de Electro Dunas.
## ----------------------------------------------------------------------------
## Lee los PDF que el usuario deja en data/raw/pdf/ y extrae CANDIDATOS de
## energía (GWh) y número de clientes.
##
## DISEÑO DELIBERADO: una lectura por regex de una tabla en PDF es el punto
## donde entran los errores silenciosos. Por eso este script:
##   1. guarda el texto crudo de cada PDF (auditable) en data/raw/pdf_text/;
##   2. emite cada cifra candidata JUNTO A SU LÍNEA LITERAL de origen y su
##      página, en output/tables/memorias_extraccion_candidatos.csv;
##   3. NO inyecta nada al panel salvo que CFG$memorias$auto_ingest sea TRUE.
## El camino recomendado es revisar los candidatos contra el PDF y promover las
## cifras verificadas a data/raw/eldu_energia_anual.csv.
## ============================================================================

suppressPackageStartupMessages({ library(pdftools); library(here) })

STAGE <- "04_memorias"
log_event(STAGE, "INFO", "inicio — extracción de Memorias Anuales ELDU (PDF)")

pdf_dir  <- here::here(CFG$memorias$dir)
text_dir <- here::here(CFG$paths$raw, "pdf_text")
dir.create(pdf_dir,  recursive = TRUE, showWarnings = FALSE)
dir.create(text_dir, recursive = TRUE, showWarnings = FALSE)

pdfs <- list.files(pdf_dir, pattern = "(?i)\\.pdf$", full.names = TRUE)

if (!length(pdfs)) {
  log_event(STAGE, "FAIL",
            sprintf(paste("no hay PDF en %s — no se extrae nada.",
                          "Coloque las Memorias Anuales ELDU (2023, 2024, 2025) ahí y re-corra."),
                    CFG$memorias$dir))
  log_event(STAGE, "INFO", "fin (sin PDF)")
} else {

  YEAR_RE  <- "(?<!\\d)(19[89]\\d|20[0-3]\\d)(?!\\d)"      # 1980-2039
  ## Número con separador de miles opcional y decimales con , o .
  NUM_RE   <- "(?<!\\d)\\d{1,3}(?:[.,]\\d{3})*(?:[.,]\\d+)?(?!\\d)"

  parse_num_es <- function(x) {
    ## Convierte "1.234,56" o "1,234.56" o "1234.5" a numérico.
    x <- gsub("\\s", "", x)
    has_comma <- grepl(",", x, fixed = TRUE)
    has_dot   <- grepl(".", x, fixed = TRUE)
    if (has_comma && has_dot) {
      ## el separador decimal es el que aparece más a la derecha
      if (max(gregexpr(",", x, fixed = TRUE)[[1]]) >
          max(gregexpr(".", x, fixed = TRUE)[[1]])) {
        x <- gsub(".", "", x, fixed = TRUE); x <- sub(",", ".", x, fixed = TRUE)
      } else {
        x <- gsub(",", "", x, fixed = TRUE)
      }
    } else if (has_comma) {
      ## una sola coma: decimal si deja 1-2 dígitos, miles si deja 3
      tail_n <- nchar(sub("^.*,", "", x))
      x <- if (tail_n == 3L) gsub(",", "", x, fixed = TRUE) else sub(",", ".", x, fixed = TRUE)
    }
    suppressWarnings(as.numeric(x))
  }

  cands <- list()

  for (f in pdfs) {
    txt <- tryCatch(pdftools::pdf_text(f), error = function(e) NULL)
    if (is.null(txt)) {
      log_event(STAGE, "FAIL", sprintf("PDF ilegible: %s", basename(f)))
      next
    }
    ## 1) texto crudo auditable
    tf <- file.path(text_dir, paste0(tools::file_path_sans_ext(basename(f)), ".txt"))
    writeLines(txt, tf, useBytes = TRUE)
    register_source(f, "", sprintf("Memoria Anual Electro Dunas — %s", basename(f)),
                    notes = "PDF provisto por el usuario (no descargado)")
    register_source(tf, "", sprintf("Texto extraído de %s (auditoría de extracción)", basename(f)),
                    notes = sprintf("%d página(s); generado por pdftools::pdf_text", length(txt)))
    log_event(STAGE, "OK", sprintf("texto extraído de %s (%d páginas)",
                                   basename(f), length(txt)))

    ## 2) candidatos con línea literal
    pats <- c(setNames(CFG$memorias$energy_patterns,
                       rep("energia_gwh", length(CFG$memorias$energy_patterns))),
              setNames(CFG$memorias$clients_patterns,
                       rep("clientes", length(CFG$memorias$clients_patterns))))
    for (pg in seq_along(txt)) {
      lines <- unlist(strsplit(txt[[pg]], "\n", fixed = TRUE))
      lines <- trimws(lines)
      lines <- lines[nzchar(lines)]
      for (i in seq_along(pats)) {
        var <- names(pats)[i]; pat <- pats[[i]]
        hit <- grep(pat, lines, perl = TRUE)
        for (h in hit) {
          ln <- lines[h]
          yrs  <- regmatches(ln, gregexpr(YEAR_RE, ln, perl = TRUE))[[1]]
          nums <- regmatches(ln, gregexpr(NUM_RE,  ln, perl = TRUE))[[1]]
          ## quita de los números los que son en realidad los años detectados
          nums <- setdiff(nums, yrs)
          vals <- parse_num_es(nums)
          cands[[length(cands) + 1L]] <- data.frame(
            file       = basename(f),
            page       = pg,
            variable   = var,
            year_guess = if (length(yrs)) suppressWarnings(as.integer(yrs[1])) else NA_integer_,
            value_guess= if (length(vals)) vals[1] else NA_real_,
            all_years  = paste(yrs,  collapse = ";"),
            all_values = paste(nums, collapse = ";"),
            raw_line   = ln,
            needs_review = TRUE,
            stringsAsFactors = FALSE
          )
        }
      }
    }
  }

  out_csv <- here::here(CFG$paths$tables, "memorias_extraccion_candidatos.csv")
  dir.create(dirname(out_csv), recursive = TRUE, showWarnings = FALSE)
  if (length(cands)) {
    cd <- do.call(rbind, cands)
    utils::write.csv(cd, out_csv, row.names = FALSE)
    log_event(STAGE, "OK",
              sprintf(paste("%d línea(s) candidata(s) escrita(s) en %s —",
                            "REVISAR contra el PDF antes de usar"),
                      nrow(cd), "output/tables/memorias_extraccion_candidatos.csv"))
    if (isTRUE(CFG$memorias$auto_ingest)) {
      log_event(STAGE, "WARN",
                "auto_ingest=TRUE: los candidatos se usarán SIN revisión humana (no recomendado)")
      save_rds(cd, file.path(CFG$paths$processed, "memorias_candidates.rds"))
    } else {
      log_event(STAGE, "INFO",
                paste("auto_ingest=FALSE: los candidatos NO entran al panel.",
                      "Promueva las cifras verificadas a", CFG$eldu$manual_csv))
    }
  } else {
    log_event(STAGE, "FAIL",
              paste("ninguna línea de los PDF calzó con los patrones de energía/clientes;",
                    "revise data/raw/pdf_text/ y ajuste CFG$memorias$*_patterns"))
  }
  log_event(STAGE, "INFO", "fin")
}
