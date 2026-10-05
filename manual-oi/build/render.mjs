import { chromium } from 'playwright';
import path from 'node:path';

const DIR = path.resolve('.');
const browser = await chromium.launch();

const footer = `
<div style="width:100%;font-family:'DejaVu Sans',sans-serif;font-size:7.5pt;color:#7A848F;
            padding:0 18mm;display:flex;justify-content:space-between;align-items:center;">
  <span style="letter-spacing:.06em;">Manual Avanzado de Organización Industrial Empírica</span>
  <span class="pageNumber" style="font-weight:600;color:#0B4F8A;"></span>
</div>`;

async function render(file, out, opts) {
  const page = await browser.newPage();
  await page.goto('file://' + path.join(DIR, file), { waitUntil: 'networkidle' });
  await page.emulateMedia({ media: 'print' });
  await page.evaluate(() => document.fonts.ready);
  await page.pdf({ path: path.join(DIR, out), format: 'A4', printBackground: true, ...opts });
  await page.close();
}

// portada: a sangre, sin pie de página
await render('cover.html', 'cover.pdf', {
  margin: { top: '0', bottom: '0', left: '0', right: '0' },
  displayHeaderFooter: false,
  preferCSSPageSize: true,
});

// cuerpo: con pie de página y numeración desde 1
await render('manual.html', 'body.pdf', {
  margin: { top: '20mm', bottom: '18mm', left: '18mm', right: '18mm' },
  displayHeaderFooter: true,
  headerTemplate: '<span></span>',
  footerTemplate: footer,
  outline: true,
  tagged: true,
});

await browser.close();
console.log('cover.pdf + body.pdf listos');
