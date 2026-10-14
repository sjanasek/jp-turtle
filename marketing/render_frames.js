// Rendert teaser.html als PNG/JPEG-Frames (30 fps, 1080x1920).
// Aufruf: node render_frames.js <ausgabeordner> [start] [ende] [schritt]
const { chromium } = require('/opt/node-tools/node_modules/playwright');
const path = require('path');
const fs = require('fs');

(async () => {
  const out = process.argv[2];
  const fps = 30, total = 15 * fps;
  const start = +(process.argv[3] ?? 0), end = +(process.argv[4] ?? total), step = +(process.argv[5] ?? 1);
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch({ executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome' });
  const page = await browser.newPage({ viewport: { width: 540, height: 960 }, deviceScaleFactor: 2 });
  await page.goto('file://' + path.join(__dirname, 'teaser.html'));
  await page.waitForTimeout(500);
  for (let f = start; f < end; f += step) {
    await page.evaluate(t => render(t), f / fps);
    await page.screenshot({ path: path.join(out, String(f).padStart(4, '0') + '.jpg'), type: 'jpeg', quality: 92 });
  }
  await browser.close();
})();
