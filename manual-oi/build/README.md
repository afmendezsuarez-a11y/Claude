# Compilación del PDF

Genera `Manual-OI-Empirica.pdf` (A4, ~170 páginas) a partir de los 19 documentos Markdown de `manual-oi/`.

## Cadena

```
*.md  →  markdown-it + KaTeX (fórmulas renderizadas del lado servidor)
      →  HTML + CSS de impresión
      →  Chromium / Playwright  →  cover.pdf + body.pdf
      →  pypdf (fusión, metadatos, marcadores)  →  Manual-OI-Empirica.pdf
```

La portada se renderiza aparte, a sangre completa y sin pie de página; el cuerpo lleva pie
con numeración desde 1. `all.sh` itera build→render→`pagemap.py` hasta que los números de
página del índice son estables (normalmente 2 pasadas).

## Requisitos

```bash
npm install markdown-it markdown-it-anchor @vscode/markdown-it-katex katex
pip install pypdf
# Playwright con Chromium disponible (PLAYWRIGHT_BROWSERS_PATH)
cp -r node_modules/katex/dist katexdist    # KaTeX local: fuentes y CSS
```

## Uso

```bash
./all.sh
```

## Notas de implementación

- **`box-sizing: content-box` es obligatorio dentro de `.katex`.** Un reset global
  `* { box-sizing: border-box }` colapsa `\boxed`, `\underbrace` y las matrices.
- **El índice usa `<table>`, no flexbox.** Las filas flex no paginan y el contenido se
  desborda sobre el pie de página.
- **`.katex-display` con `overflow: visible`.** Con `hidden` se recortan los exponentes.
  Verificado con `measure.mjs` que ninguna fórmula, tabla ni bloque de código desborda
  horizontalmente.
- Los números de página del índice se extraen del *outline* del PDF con `pypdf`, emparejando
  las entradas en orden de documento sobre texto normalizado (sin acentos ni espacios).
