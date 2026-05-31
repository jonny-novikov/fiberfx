/**
 * validator.js — Headless page-validation toolkit (zero-screenshot).
 *
 * Validates rendered pages by reading the LIVE DOM and computed styles through
 * Playwright, asserting against expected values, and printing PASS/FAIL text.
 * It never captures or embeds images, so it consumes no image/preview budget
 * and runs head-less in any environment (CI, local shell, container).
 *
 * Works with any URL scheme Playwright supports: file://, http://, https://.
 */
const { chromium } = require('playwright');

/** Collapse every whitespace run (incl. NBSP U+00A0 / narrow NBSP U+202F) to one space. */
const norm = (s) => (s || '').replace(/[\s\u00a0\u202f]+/g, ' ').trim();
/** Strip ALL whitespace — for comparing locale numbers like "5 500" → "5500". */
const nospace = (s) => (s || '').replace(/[\s\u00a0\u202f]+/g, '');

class Validator {
  constructor(opts = {}) {
    this.baseUrl  = process.env.BASE_URL || opts.baseUrl || '';
    this.headless = opts.headless !== false;          // head-less by default
    this.vw = opts.viewportWidth  || 1280;
    this.vh = opts.viewportHeight || 900;
    this.settleMs = opts.settleMs ?? 1300;            // pause for async render / KaTeX
    this.pass = 0; this.fail = 0;
    this.pageErrors = []; this.consoleErrors = [];     // captured per page; reset in open()
  }

  async start() {
    this.browser = await chromium.launch({ headless: this.headless });
    this.page = await this.browser.newPage({ viewport: { width: this.vw, height: this.vh } });
    // Capture runtime failures cms can't see: uncaught JS exceptions + console errors.
    this.page.on('pageerror', (e) => this.pageErrors.push(String((e && e.message) || e)));
    this.page.on('console', (m) => {
      if (m.type() !== 'error') return;
      const t = m.text();
      if (!/favicon|net::ERR|ERR_|Failed to load resource/i.test(t)) this.consoleErrors.push(t); // drop resource-load noise
    });
  }
  async stop() { if (this.browser) await this.browser.close(); }

  /** Join baseUrl + path (absolute http/file URLs are passed through untouched). */
  resolve(path) {
    if (/^(https?|file):\/\//.test(path)) return path;
    return this.baseUrl.replace(/\/$/, '') + '/' + String(path).replace(/^\//, '');
  }
  /** Navigate, wait for network idle, then settle for async widgets/KaTeX. */
  async open(path) {
    console.log(`\n── ${path} ──`);
    this.pageErrors = []; this.consoleErrors = [];
    await this.page.goto(this.resolve(path), { waitUntil: 'networkidle' });
    await this.page.waitForTimeout(this.settleMs);
  }
  /** Record one assertion. */
  check(name, condition, got) {
    if (condition) { this.pass++; console.log(`  ✓ ${name}`); }
    else { this.fail++; console.log(`  ✗ ${name}  →  got: ${JSON.stringify(got)}`); }
  }

  // ---- ready-made assertions ------------------------------------------------
  /** <title> contains substring. */
  async title(sub) { const t = await this.page.title(); this.check(`title ~ "${sub}"`, t.includes(sub), t); }
  /** No `.katex-error` nodes — math rendered cleanly. */
  async noKatexErrors() { const n = await this.page.locator('.katex-error').count(); this.check('no KaTeX errors', n === 0, n); }
  /** Document does not scroll horizontally. */
  async noHorizontalOverflow(tol = 2) {
    const px = await this.page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    this.check(`no h-overflow (≤${tol}px)`, px <= tol, px + 'px');
  }
  /** Normalized textContent of a selector. */
  async text(sel) { return norm(await this.page.locator(sel).first().textContent()); }
  /** Text CONTAINS expected (whitespace-insensitive). */
  async expectText(sel, exp) { const g = nospace(await this.page.locator(sel).first().textContent()); this.check(`${sel} ~ "${exp}"`, g.includes(nospace(exp)), g); }
  /** Text EQUALS expected after stripping whitespace. */
  async expectTextEquals(sel, exp) { const g = nospace(await this.page.locator(sel).first().textContent()); this.check(`${sel} == "${exp}"`, g === nospace(exp), g); }
  /** Type into input/textarea. */
  async fill(sel, val) { await this.page.fill(sel, val); }
  /** Click element (button/tab/option). */
  async click(sel) { await this.page.click(sel); }
  /** Computed CSS property of first match. */
  async computedStyle(sel, prop) { return this.page.evaluate(([s, p]) => { const e = document.querySelector(s); return e ? getComputedStyle(e)[p] : null; }, [sel, prop]); }
  /** Computed CSS property EQUALS expected (e.g. "rgb(224, 118, 114)"). */
  async expectStyle(sel, prop, exp) { const g = await this.computedStyle(sel, prop); this.check(`${sel} ${prop} == ${exp}`, g === exp, g); }
  /** Element count. */
  async count(sel) { return this.page.locator(sel).count(); }
  /** Count comparison: '==', '>=', '>', '<=', '<'. */
  async expectCount(sel, op, n) {
    const c = await this.count(sel);
    const ok = { '==': c === n, '>=': c >= n, '>': c > n, '<=': c <= n, '<': c < n }[op];
    this.check(`count(${sel}) ${op} ${n}`, !!ok, c);
  }
  /** Element is visible. */
  async expectVisible(sel) { const v = await this.page.locator(sel).first().isVisible(); this.check(`${sel} visible`, v, v); }
  /** Wait past a debounce window before reading persisted state. */
  async settle(ms = 750) { await this.page.waitForTimeout(ms); }
  /** Read & JSON-parse a localStorage key (null if missing). */
  async localStorage(key) { return this.page.evaluate((k) => { const r = localStorage.getItem(k); try { return r ? JSON.parse(r) : null; } catch { return r; } }, key); }
  /** localStorage key exists (optionally a field equals a value). */
  async expectStored(key, field, value) {
    const d = await this.localStorage(key);
    let ok = !!d; if (ok && field !== undefined) ok = d[field] === value;
    this.check(`localStorage["${key}"]${field !== undefined ? '.' + field : ''} set`, ok, d);
  }
  // ---- runtime assertions (what cms's static gates cannot see) --------------
  /** No uncaught JS exceptions or console errors fired on this page. */
  async noJsErrors() {
    const errs = [...this.pageErrors, ...this.consoleErrors];
    this.check('no JS / console errors', errs.length === 0, errs.slice(0, 3));
  }
  /** Resize the viewport (e.g. to a ~390px mobile width) for a follow-up check. */
  async setViewport(w, h) { await this.page.setViewportSize({ width: w, height: h || this.vh }); }
  /** body background equals the expected token colour (e.g. ink "rgb(10, 14, 26)"). */
  async expectBackground(rgb) {
    const bg = await this.page.evaluate(() => getComputedStyle(document.body).backgroundColor);
    this.check(`body background == ${rgb}`, bg === rgb, bg);
  }
  /** The branded Snowflake build stamp decodes on-page: #stampId is a 14-char id and #st-ts a date. */
  async stampDecodes() {
    const r = await this.page.evaluate(() => ({
      id: (document.querySelector('#stampId') || {}).textContent ? document.querySelector('#stampId').textContent.trim() : '',
      ts: (document.querySelector('#st-ts') || {}).textContent ? document.querySelector('#st-ts').textContent.trim() : '',
    }));
    const ok = /^[A-Za-z]{3}[0-9A-Za-z]{11}$/.test(r.id) && /^\d{4}-\d{2}-\d{2} /.test(r.ts);
    this.check('build stamp decodes (id → timestamp)', ok, r);
  }
  /** Scroll the page to trigger reveal-on-scroll, then assert no .reveal stays hidden. */
  async revealsVisible() {
    await this.page.evaluate(async () => {
      const step = 400, h = document.body.scrollHeight;
      for (let y = 0; y <= h; y += step) { window.scrollTo(0, y); await new Promise((r) => setTimeout(r, 25)); }
      window.scrollTo(0, 0);
    });
    await this.settle(300);
    const hidden = await this.page.evaluate(() =>
      [...document.querySelectorAll('.reveal')].filter((e) => parseFloat(getComputedStyle(e).opacity) < 0.5).length);
    this.check('all .reveal content visible after scroll', hidden === 0, hidden + ' still hidden');
  }
  /** A toggle group responds: clicking a button sets .active and throws no error. */
  async toggleWorks(groupSel) {
    const btns = this.page.locator(`${groupSel} button`);
    const n = await btns.count();
    if (n < 2) { this.check(`toggle ${groupSel} present`, false, `${n} buttons`); return; }
    const before = this.pageErrors.length + this.consoleErrors.length;
    await btns.nth(n - 1).click();
    await this.settle(200);
    const active = await this.page.locator(`${groupSel} button.active`).count();
    const newErrs = (this.pageErrors.length + this.consoleErrors.length) - before;
    this.check(`toggle ${groupSel} responds (active set, no error)`, active >= 1 && newErrs === 0, { active, newErrs });
  }

  /** Print summary; return counts. */
  report() {
    console.log(`\n═══ RESULT: ${this.pass} PASS, ${this.fail} FAIL ═══`);
    console.log('Images embedded: 0');
    return { pass: this.pass, fail: this.fail };
  }
}
module.exports = { Validator, norm, nospace };
