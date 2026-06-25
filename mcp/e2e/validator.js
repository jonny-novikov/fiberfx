/**
 * validator.js — headless Playwright validator for jonnify static figures.
 *
 * Zero-screenshot: it reads the LIVE rendered geometry (getBBox in SVG user
 * units, scale-independent) through Playwright and prints PASS/FAIL text. No
 * images captured, runs head-less anywhere. Modeled on docs/elixir/validator.
 *
 * The SVG fit-check catches the three classic figure flaws:
 *   1. a box label (<text> in a .loc/.node/.state group) overflowing its <rect>;
 *   2. an edge label (.elbl) overlapping a box <rect>;
 *   3. any <text> spilling outside the SVG's own viewBox.
 */
const { chromium } = require('playwright');

const norm = (s) => (s || '').replace(/[\s  ]+/g, ' ').trim();

class Validator {
  constructor(opts = {}) {
    this.baseUrl = process.env.BASE_URL || opts.baseUrl || '';
    this.headless = opts.headless !== false;
    this.vw = opts.viewportWidth || 1280;
    this.vh = opts.viewportHeight || 900;
    this.settleMs = opts.settleMs ?? 600;
    this.pass = 0;
    this.fail = 0;
    this.failures = [];
    this._page = '';
  }

  async start() {
    this.browser = await chromium.launch({ headless: this.headless });
    this.page = await this.browser.newPage({ viewport: { width: this.vw, height: this.vh } });
  }
  async stop() { if (this.browser) await this.browser.close(); }

  resolve(p) {
    if (/^(https?|file):\/\//.test(p)) return p;
    return this.baseUrl.replace(/\/$/, '') + '/' + String(p).replace(/^\//, '');
  }
  async open(p) {
    this._page = p;
    console.log(`\n── ${p} ──`);
    await this.page.goto(this.resolve(p), { waitUntil: 'networkidle' });
    await this.page.waitForTimeout(this.settleMs);
    // wait for webfonts so getBBox reflects the real glyph metrics
    await this.page.evaluate(() => (document.fonts && document.fonts.ready) || Promise.resolve());
  }
  check(name, condition, got) {
    if (condition) { this.pass++; console.log(`  ✓ ${name}`); }
    else {
      this.fail++;
      this.failures.push({ page: this._page, name, got });
      const detail = typeof got === 'string' ? got : JSON.stringify(got);
      console.log(`  ✗ ${name}\n      → ${detail}`);
    }
  }

  /** Document must not scroll horizontally. */
  async noHorizontalOverflow(tol = 2) {
    const px = await this.page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    this.check(`no h-overflow (≤${tol}px)`, px <= tol, px + 'px');
  }

  /**
   * Fit-check every <svg> on the page (geometry in SVG user units).
   * @param {object} [opts]
   * @param {number} [opts.tol]    user-unit slack (default 1.2)
   * @param {string} [opts.boxSel] selector for box groups (default '.loc, .node, .state')
   * @returns {Promise<number>} total violations found
   */
  async svgFiguresFit(opts = {}) {
    const tol = opts.tol ?? 1.2;
    const boxSel = opts.boxSel || '.loc, .node, .state';
    const results = await this.page.evaluate((args) => {
      const tol = args.tol, boxSel = args.boxSel;
      const reports = [];
      const overlaps = (a, b, t) =>
        a.x < b.x + b.width - t && a.x + a.width > b.x + t &&
        a.y < b.y + b.height - t && a.y + a.height > b.y + t;
      const num = (n) => Math.round(n);
      document.querySelectorAll('svg').forEach((svg, i) => {
        let texts;
        try { texts = svg.querySelectorAll('text'); } catch (e) { return; }
        if (!texts.length) return;
        const v = [];
        const vb = svg.viewBox && svg.viewBox.baseVal;
        const boxes = Array.from(svg.querySelectorAll(boxSel))
          .map((g) => ({ g: g, rect: g.querySelector('rect') }))
          .filter((x) => x.rect);

        // 1. a label inside a box must fit horizontally within its rect
        boxes.forEach((bx) => {
          const rb = bx.rect.getBBox();
          bx.g.querySelectorAll('text').forEach((t) => {
            const tb = t.getBBox();
            if (tb.x < rb.x - tol || tb.x + tb.width > rb.x + rb.width + tol) {
              v.push('OVERFLOW "' + (t.textContent || '').trim() + '" — text x[' +
                num(tb.x) + '..' + num(tb.x + tb.width) + '] exceeds box x[' +
                num(rb.x) + '..' + num(rb.x + rb.width) + ']');
            }
          });
        });

        // 2. an edge label must not overlap any box
        const rects = boxes.map((bx) => bx.rect.getBBox());
        svg.querySelectorAll('.elbl').forEach((t) => {
          const tb = t.getBBox();
          for (let k = 0; k < rects.length; k++) {
            if (overlaps(tb, rects[k], tol * 2)) {
              v.push('OVERLAP edge label "' + (t.textContent || '').trim() + '" overlaps a box rect');
              break;
            }
          }
        });

        // 3. nothing spills outside the viewBox
        if (vb && vb.width) {
          texts.forEach((t) => {
            const tb = t.getBBox();
            if (tb.x < vb.x - tol || tb.x + tb.width > vb.x + vb.width + tol ||
                tb.y < vb.y - tol || tb.y + tb.height > vb.y + vb.height + tol) {
              v.push('OUTSIDE "' + (t.textContent || '').trim() + '" — bbox x[' +
                num(tb.x) + '..' + num(tb.x + tb.width) + '] y[' + num(tb.y) + '..' +
                num(tb.y + tb.height) + '] vs viewBox ' + num(vb.width) + 'x' + num(vb.height));
            }
          });
        }

        reports.push({ svg: svg.id || svg.getAttribute('class') || ('svg#' + i), violations: v });
      });
      return reports;
    }, { tol: tol, boxSel: boxSel });

    let total = 0;
    results.forEach((r) => {
      total += r.violations.length;
      this.check('svg "' + r.svg + '" labels fit', r.violations.length === 0, r.violations.join('  |  '));
    });
    return total;
  }

  report() {
    console.log(`\n═══ ${this.pass} PASS · ${this.fail} FAIL ═══`);
    if (this.failures.length) {
      console.log('\nFailing pages:');
      const byPage = {};
      this.failures.forEach((f) => { (byPage[f.page] = byPage[f.page] || []).push(f.name); });
      Object.keys(byPage).forEach((p) => {
        console.log('  ' + p);
        byPage[p].forEach((n) => console.log('    ✗ ' + n));
      });
    }
    console.log('Images embedded: 0');
    return { pass: this.pass, fail: this.fail };
  }
}

module.exports = { Validator, norm };
