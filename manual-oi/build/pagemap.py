"""Extrae de body.pdf el número de página impreso de cada entrada del índice."""
import json, re, sys, unicodedata
from pypdf import PdfReader

def norm(s):
    s = unicodedata.normalize("NFD", str(s))
    s = "".join(c for c in s if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]", "", s.lower())

r = PdfReader("body.pdf")

flat = []
def walk(items):
    for it in items:
        if isinstance(it, list):
            walk(it)
        else:
            try:
                flat.append((norm(it.title), r.get_destination_page_number(it)))
            except Exception:
                pass
walk(r.outline)

keys = json.load(open("toc-keys.json"))

pagemap, i, misses = {}, 0, []
for k in keys:
    target = norm(k["text"])
    j = i
    while j < len(flat) and flat[j][0] != target:
        j += 1
    if j < len(flat):
        pagemap[k["key"]] = flat[j][1] + 1   # el pie numera desde 1
        i = j + 1
    else:
        misses.append(k["text"])

json.dump(pagemap, open("pagemap.json", "w"), ensure_ascii=False, indent=1)
print(f"páginas body: {len(r.pages)} · entradas índice: {len(keys)} · resueltas: {len(pagemap)} · sin resolver: {len(misses)}")
for m in misses[:12]:
    print("   sin resolver:", m)
