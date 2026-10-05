#!/bin/bash
# Compila el manual completo a PDF. Itera hasta que los números del índice son estables.
set -e
cd "$(dirname "$0")"
rm -f pagemap.json prev.json

for i in 1 2 3 4; do
  cp -f pagemap.json prev.json 2>/dev/null || true
  node build.mjs >/dev/null
  node render.mjs >/dev/null
  python3 pagemap.py | head -1
  if [ -f prev.json ] && diff -q prev.json pagemap.json >/dev/null 2>&1; then
    echo "índice estable tras $i pasada(s)"
    break
  fi
done

python3 - <<'PY'
from pypdf import PdfWriter, PdfReader
w = PdfWriter(); w.append("cover.pdf"); w.append("body.pdf")
w.add_metadata({
  "/Title":    "Manual Avanzado de Organización Industrial Empírica",
  "/Subject":  "De la identificación a la valuación: demanda, conducta, colusión y mercados peruanos",
  "/Keywords": "organización industrial, demanda, IV, AIDS, QUAIDS, logit, BLP, markups, fusiones, colusión, licitaciones, precios predatorios, marketing, valuation, Perú",
  "/Creator":  "markdown-it + KaTeX + Chromium",
})
w.page_mode = "/UseOutlines"
with open("Manual-OI-Empirica.pdf", "wb") as f: w.write(f)
r = PdfReader("Manual-OI-Empirica.pdf")
def n(x):
    return sum(n(i) if isinstance(i, list) else 1 for i in x)
print(f"PDF final: {len(r.pages)} páginas · {n(r.outline)} marcadores")
PY
