#!/usr/bin/env Rscript
## ============================================================================
## R/make_renv_lock.R — genera renv.lock a partir de la librería instalada.
## ----------------------------------------------------------------------------
## Por qué no `renv::init()`: este contenedor no tiene salida a CRAN (bloqueada
## por política de egreso), así que renv no puede resolver paquetes contra el
## repositorio remoto. Este script produce un renv.lock equivalente leyendo las
## versiones REALES instaladas, de modo que `renv::restore()` en una máquina con
## acceso a CRAN reconstruya el mismo conjunto de versiones.
##
## Limitación honesta: al generarse sin red, las entradas NO llevan `Hash`.
## renv los resuelve al restaurar.
##
## Uso:  Rscript R/make_renv_lock.R
## ============================================================================

suppressPackageStartupMessages(library(jsonlite))

ip <- as.data.frame(utils::installed.packages(), stringsAsFactors = FALSE)
ip <- ip[!duplicated(ip$Package), c("Package", "Version", "Priority")]
## `base` y `recommended` vienen con R; renv no las instala desde CRAN.
ip <- ip[is.na(ip$Priority) | ip$Priority != "base", ]
ip <- ip[order(ip$Package), ]

pkgs <- stats::setNames(
  lapply(seq_len(nrow(ip)), function(i) list(
    Package    = ip$Package[i],
    Version    = ip$Version[i],
    Source     = "Repository",
    Repository = "CRAN")),
  ip$Package)

lock <- list(
  R = list(
    Version = paste(R.version$major, R.version$minor, sep = "."),
    Repositories = list(list(Name = "CRAN", URL = "https://cloud.r-project.org"))
  ),
  Packages = pkgs
)

jsonlite::write_json(lock, "renv.lock", auto_unbox = TRUE, pretty = TRUE)
cat(sprintf("renv.lock escrito: R %s, %d paquetes\n",
            lock$R$Version, length(pkgs)))
