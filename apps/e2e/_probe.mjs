import { chromium } from 'playwright';
const b = await chromium.launch();
const p = await b.newPage({ viewport: { width: 1440, height: 1024 } });
await p.goto('http://localhost:8765/elixir/algebra', { waitUntil: 'domcontentloaded' });
const r = await p.evaluate(() => {
  const noSpace = 'clamp(3rem,2rem+5vw,6rem)';
  const spaced  = 'clamp(3rem, 2rem + 5vw, 6rem)';
  // apply each to a probe element and read back the computed px
  const probe = document.createElement('h1');
  document.body.appendChild(probe);
  const measure = (val) => { probe.style.fontSize = ''; probe.style.fontSize = val; return getComputedStyle(probe).fontSize; };
  const out = {
    innerWidth: window.innerWidth,
    supports_noSpace: CSS.supports('font-size', noSpace),
    supports_spaced: CSS.supports('font-size', spaced),
    computed_noSpace: measure(noSpace),
    computed_spaced: measure(spaced),
    h1_default: (() => { probe.style.fontSize=''; return getComputedStyle(probe).fontSize; })(),
  };
  probe.remove();
  return out;
});
console.log(JSON.stringify(r, null, 2));
await b.close();
