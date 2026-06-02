import { chromium } from 'playwright';
const b = await chromium.launch();
async function go(url, sels) {
  const p = await b.newPage({ viewport: { width: 1440, height: 1300 }, deviceScaleFactor: 2 });
  await p.goto(url, { waitUntil: 'networkidle' }); await p.waitForTimeout(700);
  const out = await p.evaluate((sels) => {
    const g = (s)=>{const e=document.querySelector(s); if(!e) return null; const c=getComputedStyle(e); return {fontSize:c.fontSize, style:c.fontStyle, family:c.fontFamily.split(',')[0].replace(/["']/g,'')};};
    const r={}; for(const [k,s] of Object.entries(sels)) r[k]=g(s); return r;
  }, sels);
  return { p, out };
}
// HUB heex: subheader lede vs main-content prose — must be EQUAL size now
let { p, out } = await go('http://localhost:8765/elixir/phoenix/heex', { lede:'.hero-lede .lede', prose:'#pieces .prose p, .prose p' });
console.log('HUB heex:', JSON.stringify(out), '  lede==prose size:', out.lede && out.prose && out.lede.fontSize===out.prose.fontSize);
const hero = await p.$('section.hero'); if (hero) await hero.screenshot({ path: '/tmp/heex-final.png' });
await p.close();
// DIVE templates: lede now upright body size
({ p, out } = await go('http://localhost:8765/elixir/phoenix/heex/templates', { lede:'.lede', prose:'.prose p' }));
console.log('DIVE templates:', JSON.stringify(out));
const h2 = await p.$('section.hero'); if (h2) await h2.screenshot({ path: '/tmp/templates-final.png' });
await p.close();
await b.close();
