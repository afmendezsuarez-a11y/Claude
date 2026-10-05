# Jacobianos en el espacio de secuencias — manual metodológico

Manual de 80 páginas sobre el método de jacobianos secuenciales (Auclert,
Bardóczy, Rognlie y Straub, 2021, *Econometrica*), escrito para un estudiante de
pregrado en economía, con una aplicación completa a un modelo dinámico de bancos
heterogéneos con encaje, mercado interbancario y dolarización.

**El PDF compilado está en `latex/manual.pdf`.**

## Qué hay aquí

```
latex/        el manual (LaTeX + PDF compilado)
figuras/      las 13 figuras, todas generadas por el código
code/
  ssj/        implementación propia del algoritmo fake news
  models/     Krusell–Smith (referencia) y el modelo bancario
  tests/      verificación contra el método directo
  figures/    generación de figuras
```

## Lo importante: nada está inventado

Todas las cifras del manual salen de ejecutar el código. La implementación del
algoritmo está escrita desde cero (sin usar la librería `sequence-jacobian`) y
verificada contra el método directo, que es lento pero no depende del resultado
teórico que se quiere comprobar.

Resultados de la verificación:

| bloque | pares insumo–producto | peor error relativo |
|---|---|---|
| hogares (Krusell–Smith) | 4 | 5.5 × 10⁻⁸ |
| bancos heterogéneos | 78 | 2.9 × 10⁻⁸ |

El residuo es el límite de la diferenciación numérica de dos lados, no un error
del algoritmo.

## Correr el código

```bash
pip install numpy scipy matplotlib
cd code
python3 tests/test_fakenews.py    # verificación: debe decir TODO OK
python3 figures/fig_metodo.py     # figuras 1–8
python3 figures/fig_bancos.py     # figuras 9–13
```

La primera corrida del modelo bancario tarda un par de minutos (resuelve el
punto fijo del estado estacionario); después usa un caché en disco.

## Compilar el manual

```bash
cd latex
pdflatex manual.tex && pdflatex manual.tex
```

Requiere `texlive-latex-recommended`, `texlive-latex-extra`,
`texlive-fonts-recommended` y `texlive-lang-spanish`.

## Advertencia sobre el modelo bancario

El modelo de la parte V es un **prototipo pedagógico**: sirve para mostrar cómo
se traduce un modelo estático al espacio de secuencias y qué preguntas nuevas
aparecen al hacerlo. No es una calibración del sistema bancario peruano. La
sección 14.9 del manual lista explícitamente qué habría que cambiar antes de
usar sus números cuantitativamente.
