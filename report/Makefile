# ============================================================================
#  Informe LaTeX — Elasticidad-ingreso de la demanda eléctrica de Electro Dunas
# ----------------------------------------------------------------------------
#  make          compila el PDF
#  make datos    regenera figuras y tablas desde las salidas del pipeline
#  make todo     regenera los insumos y compila
#  make clean    borra los auxiliares de LaTeX (conserva el PDF)
#  make limpiar  borra también el PDF y los insumos generados
#
#  Requiere: pdflatex + latexmk (texlive-latex-recommended, texlive-lang-spanish)
#  y R con el pipeline ya corrido (`Rscript run_all.R` en la raíz).
# ============================================================================

TEX     := informe_eldu.tex
PDF     := $(TEX:.tex=.pdf)
RAIZ    := ..
FIGS    := $(wildcard figs/*.pdf)
TABLAS  := $(wildcard tablas/*.tex)

.PHONY: all todo datos clean limpiar

all: $(PDF)

$(PDF): $(TEX) $(FIGS) $(TABLAS)
	latexmk -pdf -interaction=nonstopmode -halt-on-error $(TEX)

datos:
	cd $(RAIZ) && Rscript -e 'source("config/config.R"); source("R/utils.R"); \
	  source("scripts/09_figuras_informe.R"); source("scripts/10_tablas_informe.R")'

todo: datos
	$(MAKE) -B all

clean:
	latexmk -c $(TEX)

limpiar: clean
	rm -f $(PDF)
	rm -rf figs tablas
