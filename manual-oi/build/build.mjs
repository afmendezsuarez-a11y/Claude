import fs from 'node:fs';
import path from 'node:path';
import MarkdownIt from 'markdown-it';
import anchor from 'markdown-it-anchor';
import kp from '@vscode/markdown-it-katex';
const katexPlugin = kp.default ?? kp;

const SRC = '/home/user/Claude/manual-oi';
const OUT = path.resolve('.');

const FILES = [
  { f: 'README.md',                               num: '',   kind: 'front', title: 'Presentación y mapa del manual' },
  { f: '00-guia-de-uso.md',                       num: '0',  kind: 'cap' },
  { f: '01-teoria-consumidor-productor.md',       num: '1',  kind: 'cap' },
  { f: '02-identificacion.md',                    num: '2',  kind: 'cap' },
  { f: '03-estimacion-demanda-ecuacion-unica.md', num: '3',  kind: 'cap' },
  { f: '04-sistemas-de-demanda.md',               num: '4',  kind: 'cap' },
  { f: '05-eleccion-discreta.md',                 num: '5',  kind: 'cap' },
  { f: '06-logit-agregado-blp.md',                num: '6',  kind: 'cap' },
  { f: '07-oferta-markups-fusiones.md',           num: '7',  kind: 'cap' },
  { f: '08-colusion-y-licitaciones.md',           num: '8',  kind: 'cap' },
  { f: '09-precios-predatorios.md',               num: '9',  kind: 'cap' },
  { f: '10-marketing.md',                         num: '10', kind: 'cap' },
  { f: '11-valuation-finanzas.md',                num: '11', kind: 'cap' },
  { f: '12-macro.md',                             num: '12', kind: 'cap' },
  { f: '13-peru.md',                              num: '13', kind: 'cap' },
  { f: '14-uso-diario.md',                        num: '14', kind: 'cap' },
  { f: '15-agenda-investigacion.md',              num: '15', kind: 'cap' },
  { f: 'A-apendice-demostraciones.md',            num: 'A',  kind: 'apx' },
  { f: 'B-apendice-codigo.md',                    num: 'B',  kind: 'apx' },
];
const FILE2ID = Object.fromEntries(FILES.map((c, i) => [c.f, `cap-${i}`]));

const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const slug = s => s.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')
  .replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
// texto plano para el índice: sin negritas, sin math, sin código
const plain = s => s
  .replace(/\$[^$]*\$/g, '')
  .replace(/\*\*(.+?)\*\*/g, '$1')
  .replace(/\*(.+?)\*/g, '$1')
  .replace(/`(.+?)`/g, '$1')
  .replace(/\s{2,}/g, ' ')
  .trim();

// ------------------------------------------------- preprocesado por capítulo
function preprocess(raw, cap) {
  let t = raw;
  const lines = t.split('\n');
  let h1 = '';
  for (let i = 0; i < lines.length; i++) {
    if (/^#\s+/.test(lines[i])) { h1 = lines[i].replace(/^#\s+/, '').trim(); lines.splice(i, 1); break; }
  }
  t = lines.join('\n');
  const title = cap.title ?? h1.replace(/^[0-9AB]+\s*·\s*/, '').trim();

  if (/^[0-9]+$/.test(cap.num)) {
    // "### 2.1 Texto" -> "### {cap}.2.1 Texto"   (antes que los H2, por el patrón)
    t = t.replace(/^###\s+(\d+)\.(\d+)\s+/gm, (_, a, b) => `### ${cap.num}.${a}.${b} `);
    // "## 3. Texto" -> "## {cap}.3 Texto"
    t = t.replace(/^##\s+(\d+)\.\s+/gm, (_, n) => `## ${cap.num}.${n} `);
  }

  t = t.replace(/\(([0-9AB][^)\s]*\.md)(#[^)]*)?\)/g, (m, f) => (FILE2ID[f] ? `(#${FILE2ID[f]})` : '(#)'));
  t = t.replace(/\(README\.md\)/g, `(#${FILE2ID['README.md']})`);
  t = t.replace(/<a name="([^"]+)"><\/a>/g, '<span id="apx-$1"></span>');
  t = t.replace(/\(#(a\d+)\)/g, '(#apx-$1)');

  return { title, body: t };
}

// --------------------------------------------- postprocesado del HTML final
const TAGS = { trampa: 'Trampa', peru: 'Perú', idea: 'Investigación', teorema: 'Teoría' };

function postprocess(html) {
  // callouts: se clasifican por el marcador que abre el blockquote
  const chip = k => `<blockquote class="${k}"><p><span class="tag ${k}">${TAGS[k]}</span><strong>`;
  html = html.replace(/<blockquote>\s*<p><strong>⚠️\s*/g, chip('trampa'));
  html = html.replace(/<blockquote>\s*<p><strong>🇵🇪\s*/g, chip('peru'));
  html = html.replace(/<blockquote>\s*<p><strong>💡\s*/g, chip('idea'));
  // esta sí tiene grupo de captura: hay que conservar la palabra
  html = html.replace(/<blockquote>\s*<p><strong>(Teorema|Resultado|Proposición|Lema)\b/g,
    (m, word) => chip('teorema') + word);
  // etiquetas duplicadas ("Trampa." / "Perú —" ya cubiertos por el chip)
  html = html.replace(/(<span class="tag trampa">Trampa<\/span><strong>)Trampa\.?\s*/g, '$1');
  html = html.replace(/(<span class="tag peru">Perú<\/span><strong>)Perú\s*(—|-|\.)?\s*/g, '$1');
  html = html.replace(/(<span class="tag idea">Investigación<\/span><strong>)Idea de investigación\.?\s*/g, '$1');
  html = html.replace(/<strong>\s*<\/strong>\s*/g, '');
  // emojis sobrantes en el cuerpo
  html = html.replace(/⚠️\s*/g, '').replace(/🇵🇪\s*/g, '').replace(/💡\s*/g, '');

  // diagramas ASCII
  html = html.replace(/<pre>(<code[^>]*>)([\s\S]*?)<\/code><\/pre>/g, (m, open, code) =>
    `<pre${/[─│┌┐└┘├┤┬┴┼▼▲►◄╔╗╚╝═║]/.test(code) ? ' class="diagram"' : ''}>${open}${code}</code></pre>`);

  return html;
}

// ----------------------------------------------------------------- capítulos
const chapters = [];
for (const cap of FILES) {
  const raw = fs.readFileSync(path.join(SRC, cap.f), 'utf8');
  const { title, body } = preprocess(raw, cap);
  const id = FILE2ID[cap.f];

  const mdi = new MarkdownIt({ html: true, linkify: false })
    .use(katexPlugin, { throwOnError: false, errorColor: '#cc0000', strict: false, trust: true })
    .use(anchor, { slugify: s => `${id}-${slug(s)}`, level: [2, 3] });

  const html = postprocess(mdi.render(body));

  const secs = [...body.matchAll(/^##\s+(.+)$/gm)]
    .map(m => ({ raw: m[1].trim(), text: plain(m[1]) }))
    .filter(s => !/^([\d.]+\s+)?(Lecturas|Referencias|Glosario)/i.test(s.text));

  chapters.push({ ...cap, id, title, html, secs });
}

// --------------------------------------------------------------- índice
const pmFile = path.join(OUT, 'pagemap.json');
const pagemap = fs.existsSync(pmFile) ? JSON.parse(fs.readFileSync(pmFile, 'utf8')) : {};
const pg = k => (pagemap[k] !== undefined ? pagemap[k] : '');

const label = c => c.kind === 'front' ? '' : (c.kind === 'apx' ? `Apéndice ${c.num} · ` : `${c.num} · `);

let toc = `<section class="toc"><h1>Contenido</h1>
<p class="lead">Las referencias cruzadas del texto son enlaces activos dentro del PDF.</p>
<table class="toctab"><tbody>`;
for (const c of chapters) {
  toc += `<tr class="t1"><td class="ttl"><a href="#${c.id}">${esc(label(c) + c.title)}</a></td><td class="pg">${pg(c.id)}</td></tr>`;
  for (const s of c.secs) {
    const sid = `${c.id}-${slug(s.raw)}`;
    toc += `<tr class="t2"><td class="ttl"><a href="#${sid}">${esc(s.text)}</a></td><td class="pg">${pg(sid)}</td></tr>`;
  }
}
toc += `</tbody></table></section>`;

// --------------------------------------------------------------- portada
const HOY = new Date().toLocaleDateString('es-PE', { year: 'numeric', month: 'long' });
const coverBody = `
<section class="cover"><div class="grid"></div><div class="inner">
  <div class="kicker">Economía · Nivel doctorado</div>
  <h1>Manual Avanzado de<br>Organización Industrial<br>Empírica</h1>
  <div class="rule"></div>
  <div class="sub">De la identificación a la valuación: demanda, conducta, colusión y mercados peruanos</div>
  <div class="meta">
    <b>Base:</b> Topics in Empirical Industrial Organization, Semanas 3–7<br>
    <b>Extensión:</b> 19 capítulos · 60 ideas de investigación · demostraciones completas<br>
    <b>Fecha:</b> ${HOY}
  </div>
  <div class="chips">
    <span class="chip">Identificación e IV</span><span class="chip">AIDS / QUAIDS</span>
    <span class="chip">Logit · IIA · GEV</span><span class="chip">BLP</span>
    <span class="chip">Markups y fusiones</span><span class="chip">Colusión</span>
    <span class="chip">Licitaciones públicas</span><span class="chip">Precios predatorios</span>
    <span class="chip">Marketing</span><span class="chip">Valuation</span>
    <span class="chip">Macro y markups</span><span class="chip">Mercado peruano</span>
  </div>
  <div class="pie">Documento de trabajo · Las cifras de casos peruanos deben verificarse contra las resoluciones originales de INDECOPI y los organismos reguladores antes de usarse en trabajo formal o litigio.</div>
</div></section>`;

const head = (extra = '') => `<!doctype html><html lang="es"><head><meta charset="utf-8">
<title>Manual Avanzado de Organización Industrial Empírica</title>
<link rel="stylesheet" href="katexdist/katex.min.css">
<link rel="stylesheet" href="style.css">${extra}</head><body>`;

fs.writeFileSync(path.join(OUT, 'cover.html'),
  head('<style>@page{size:A4;margin:0}body{margin:0}.cover{page-break-after:auto}</style>') + coverBody + '</body></html>');

let body = toc;
for (const c of chapters) {
  const eyebrow = c.kind === 'front' ? 'Manual' : (c.kind === 'apx' ? `Apéndice ${c.num}` : `Capítulo ${c.num}`);
  body += `<section class="chapter" id="${c.id}">
    <div class="eyebrow">${eyebrow}</div><h1>${esc(c.title)}</h1>${c.html}</section>`;
}
body += `<section class="chapter colofon"><div class="eyebrow">Colofón</div><h1>Sobre este documento</h1>
<p>Manual compilado a partir de 19 documentos fuente en Markdown. Las fórmulas están tipografiadas con KaTeX; el índice remite a páginas reales y todas las referencias cruzadas son enlaces activos.</p>
<p>El material parte de las sesiones 3 a 7 del curso <em>Topics in Empirical Industrial Organization</em> (identificación, estimación de demanda, sistemas de demanda, elección discreta y logit agregado) y las extiende con fundamentos avanzados de teoría del consumidor y del productor, el lado de la oferta, colusión y licitaciones públicas, precios predatorios, marketing cuantitativo, valuation, vínculos macroeconómicos, aplicación al mercado peruano y una agenda de investigación.</p>
<p><strong>Advertencia.</strong> Las cifras, umbrales normativos y detalles de casos peruanos deben verificarse contra las fuentes primarias —resoluciones de INDECOPI, normas vigentes y publicaciones de INEI y BCRP— antes de usarse en trabajo formal, publicación o litigio.</p>
<p style="color:#5A6572;font-size:9pt;margin-top:8mm">Generado en ${HOY}.</p></section>`;

fs.writeFileSync(path.join(OUT, 'manual.html'), head() + body + '</body></html>');

fs.writeFileSync(path.join(OUT, 'toc-keys.json'), JSON.stringify(
  chapters.flatMap(c => [
    { key: c.id, text: c.title, level: 1 },
    ...c.secs.map(s => ({ key: `${c.id}-${slug(s.raw)}`, text: s.text, level: 2 })),
  ]), null, 1));

console.log(`HTML listo · ${chapters.length} capítulos · índice con ${Object.keys(pagemap).length} páginas resueltas`);
