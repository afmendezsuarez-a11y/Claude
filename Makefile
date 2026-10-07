# Makefile — atajos del pipeline ELDU. El punto de entrada canonico sigue
# siendo `Rscript run_all.R`; esto solo envuelve los pasos mas comunes.

R        ?= Rscript
DATA_DIR ?=

export ELDU_DATA_DIR = $(DATA_DIR)

.PHONY: all setup clean demo check help
.DEFAULT_GOAL := help

help:                 ## Muestra esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	 | awk 'BEGIN{FS=":.*?## "}{printf "  \033[1m%-10s\033[0m %s\n", $$1, $$2}'

setup:                ## Instala las dependencias desde renv.lock
	$(R) -e 'if (!requireNamespace("renv", quietly=TRUE)) install.packages("renv"); renv::restore(prompt = FALSE)'

all:                  ## Corre el pipeline completo (01-08)
	$(R) run_all.R

demo:                 ## Prueba de humo con datos SINTETICOS (no son datos reales)
	$(R) R/99_make_demo_data.R
	ELDU_DATA_DIR=data/demo $(R) run_all.R

check:                ## Verifica que todos los scripts parsean
	$(R) -e 'for (f in list.files("R", pattern="[.]R$$", full.names=TRUE)) { invisible(parse(f)); cat("ok ", f, "\n") }; invisible(parse("run_all.R")); cat("ok  run_all.R\n")'

clean:                ## Borra output/ y data/processed/
	rm -rf output data/processed
	mkdir -p output/tables output/figs data/processed
