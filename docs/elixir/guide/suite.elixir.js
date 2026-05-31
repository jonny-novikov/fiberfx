/**
 * suite.elixir.js — headless validation for the jonnify Elixir course.
 *
 * Replaces the screenshot-and-view step: every check below reads the live DOM,
 * computed styles, or element attributes and prints PASS/FAIL as text. No images
 * are captured or embedded, so it consumes zero image budget.
 *
 * Run:
 *   BASE_URL="file:///home/claude/elixir-course" node validator/suite.elixir.js
 *
 * Validate ONLY a newly-built page (tiny output, for after-every-page checks):
 *   ONLY=modules-streams node validator/suite.elixir.js
 *   (any block whose label does not contain the ONLY substring is skipped)
 */
const { Validator } = require('./validator');

/** Validator + console/page-error capture + a couple of course-specific helpers. */
class CourseValidator extends Validator {
  async start() {
    await super.start();
    this._errs = [];
    this.page.on('console', (m) => { if (m.type() === 'error') this._errs.push(m.text()); });
    this.page.on('pageerror', (e) => this._errs.push('PAGEERROR ' + e.message));
  }
  async open(p) { this._errs = []; await super.open(p); }

  /** Zero JS console errors / uncaught exceptions on the current page. */
  async noConsoleErrors() { this.check('no console / page errors', this._errs.length === 0, this._errs.slice(0, 3)); }
  /** An element attribute equals an expected value (e.g. an SVG stroke colour). */
  async expectAttr(sel, attr, exp) {
    const g = await this.page.locator(sel).first().getAttribute(attr);
    this.check(`${sel}[${attr}] == ${exp}`, g === exp, g);
  }
  /** The branded-Snowflake footer stamp decoded: namespace TSK + a numeric snowflake. */
  async expectDecoded() {
    const ns = await this.text('#st-ns');
    const snow = await this.text('#st-snow');
    this.check('branded stamp decoded (TSK + snowflake)', ns === 'TSK' && /^[0-9]{6,}$/.test(snow), { ns, snow });
  }
  /** Universal gates every course page must clear. */
  async base(titleSub) {
    await this.title(titleSub || 'jonnify');
    await this.expectCount('svg', '>=', 1);   // the interactive SVG is present
    await this.expectDecoded();               // footer decoder ran
    await this.noHorizontalOverflow();         // layout fits (was a visual check)
    await this.noConsoleErrors();              // no runtime JS errors
  }
}

const BASE = process.env.BASE_URL || 'file:///home/claude/elixir-course';
const ONLY = process.env.ONLY || '';   // when set, only run blocks whose label contains it

/** Run one page's block, converting an unexpected throw into a recorded failure. */
async function block(v, label, fn) {
  if (ONLY && !label.includes(ONLY)) return;
  try { await fn(); }
  catch (e) { v.fail++; console.log(`  ✗ ${label} (threw)  →  ${String(e.message).split('\n')[0]}`); }
}

(async () => {
  const v = new CourseValidator({ baseUrl: BASE, settleMs: 500 });
  await v.start();

  // ── generic sweep: universal gates across a representative set ────────────
  const generic = [
    ['/index.html', 'Functional Programming in Elixir'],
    ['/language.html', 'jonnify'],
    ['/values.html', 'jonnify'],
    ['/match.html', 'jonnify'],
    ['/functional.html', 'jonnify'],
  ];
  for (const [p, t] of generic) await block(v, p, async () => { await v.open(p); await v.base(t); });

  // ── F0 · course / contents landing ────────────────────────────────────────
  await block(v, '/course.html', async () => {
    await v.open('/course.html');
    await v.base('Course contents');
    await v.expectCount('.contents .chap', '==', 7);                 // F0..F6 directory rendered
    await v.click('#startSel button[data-k="csharp"]'); await v.settle(200);
    await v.expectText('#startOut', 'onramp');                        // recommendation switched
    await v.expectCount('#startOut a', '>=', 1);                      // links to the onramp
  });

  // ── F0 · Elixir for C# developers (runtime compare + concept translator) ──
  await block(v, '/course-csharp.html', async () => {
    await v.open('/course-csharp.html');
    await v.base('Elixir for C# developers');
    await v.expectTextEquals('#rtDim', 'CONCURRENCY');               // default dimension
    await v.expectText('#rtBeam', 'millions of processes');
    await v.click('#rtSel button[data-k="mem"]'); await v.settle(150);
    await v.expectText('#rtDim', 'MEMORY'); await v.expectText('#rtClr', 'shared heap');
    await v.click('#rtSel button[data-k="fail"]'); await v.settle(150);
    await v.expectText('#rtBeam', 'let it crash');
    await v.expectText('#csCode', 'Option'); await v.expectText('#exCode', 'nil');   // default concept
    await v.click('#ctSel button[data-k="either"]'); await v.settle(150);
    await v.expectText('#csCode', 'Either'); await v.expectText('#exCode', ':ok');
    await v.click('#ctSel button[data-k="actor"]'); await v.settle(150);
    await v.expectText('#csCode', 'spawn'); await v.expectText('#exCode', 'GenServer');
  });

  // ── F3.03 · hub (portal module browser) ───────────────────────────────────
  await block(v, '/modules.html', async () => {
    await v.open('/modules.html');
    await v.base('Functions, modules');
    await v.click('.mod-node[data-m="progress"]'); await v.settle(150);
    await v.expectText('#modCode', 'percent_complete');
    await v.expectAttr('#box-progress', 'stroke', '#f0cd7f');         // selected box highlighted
  });

  // ── F3.03 · functions (clause dispatch) ───────────────────────────────────
  await block(v, '/modules-functions.html', async () => {
    await v.open('/modules-functions.html');
    await v.base('Defining functions');
    await v.expectTextEquals('#clChipT', ':in_progress');            // default 45%
    await v.click('#cSel button[data-p="0"]'); await v.settle(120);
    await v.expectTextEquals('#clChipT', ':not_started');
    await v.expectAttr('#cl0', 'stroke', '#7ba387');                 // matched clause turns green
    await v.click('#cSel button[data-p="100"]'); await v.settle(120);
    await v.expectTextEquals('#clChipT', ':complete');
  });

  // ── F3.03 · organising (directive resolver) ───────────────────────────────
  await block(v, '/modules-organising.html', async () => {
    await v.open('/modules-organising.html');
    await v.base('Organising with modules');
    await v.expectTextEquals('#orgCallT', 'Accounts.get_user(id)');  // default: alias
    await v.click('#oSel button[data-k="import"]'); await v.settle(120);
    await v.expectTextEquals('#orgCallT', 'get_user(id)');
    await v.click('#oSel button[data-k="require"]'); await v.settle(120);
    await v.expectText('#orgDirT', 'require Logger');
  });

  // ── F3.03 · pipe (pipeline builder) ───────────────────────────────────────
  await block(v, '/modules-pipe.html', async () => {
    await v.open('/modules-pipe.html');
    await v.base('The pipe operator');
    await v.expectText('#pipeOut', 'returns 3');                      // all stages on → count 3
    await v.click('#pSel button[data-s="count"]'); await v.settle(120);
    await v.expectText('#pipeOut', 'list of 3');                      // count off → 3 ids
  });

  // ── F3.04 · hub (Enumerable protocol) ─────────────────────────────────────
  await block(v, 'F3.04 /enum-streams.html', async () => {
    await v.open('/enum-streams.html');
    await v.base('Enumerables & streams');
    await v.expectText('#esSrcT', '[1, 2, 3]');                      // default source: list
    await v.click('#esSel button[data-k="range"]'); await v.settle(150);
    await v.expectText('#esSrcT', '1..3');
    await v.click('#esSel button[data-k="stream"]'); await v.settle(150);
    await v.expectText('#esSrcT', 'Stream.take'); await v.expectText('#esOut', '[1, 4, 9]');
  });

  // ── F3.04 · Enum (summary builder) ────────────────────────────────────────
  await block(v, 'F3.04 /enumerables.html', async () => {
    await v.open('/enumerables.html');
    await v.base('Enum, the eager workhorse');
    await v.expectText('#enCode', 'Enum.count');                     // default op
    await v.click('#enSel button[data-k="group"]'); await v.settle(150);
    await v.expectText('#enCode', 'group_by');
    await v.click('#enSel button[data-k="freq"]'); await v.settle(150);
    await v.expectText('#enCode', 'frequencies_by');
  });

  // ── F3.04 · comprehensions (for builder) ──────────────────────────────────
  await block(v, 'F3.04 /comprehensions.html', async () => {
    await v.open('/comprehensions.html');
    await v.base('Comprehensions');
    await v.expectText('#coCode', 'for r <- progress, do: r.lesson_id');  // default basic
    await v.click('#coSel button[data-k="into"]'); await v.settle(150);
    await v.expectText('#coCode', 'into: %{}');
    await v.click('#coSel button[data-k="nested"]'); await v.settle(150);
    await v.expectText('#coCode', 'c <- courses');
  });

  // ── F3.04 · streams (eager vs lazy) ───────────────────────────────────────
  await block(v, 'F3.04 /streams.html', async () => {
    await v.open('/streams.html');
    await v.base('Lazy streams');
    await v.expectText('#stCount', 'examined: 8 of 8');              // default eager
    await v.expectText('#stCode', 'Enum.filter');
    await v.click('#stSel button[data-k="lazy"]'); await v.settle(150);
    await v.expectText('#stCount', 'examined: 5 of 8');              // lazy stops early
    await v.expectText('#stCode', 'Stream.filter');
    await v.expectAttr('#srec7', 'opacity', '0.32');                // last record never examined
  });

  const r = v.report();
  await v.stop();

  // ── mobile overflow sweep at 390px (layout sanity, still zero images) ─────
  console.log('\n──────── mobile sweep · 390px ────────');
  const m = new CourseValidator({ baseUrl: BASE, settleMs: 400, viewportWidth: 390, viewportHeight: 844 });
  await m.start();
  const mobile = ['/index.html', '/course.html', '/course-csharp.html', '/modules.html',
    '/modules-functions.html', '/modules-organising.html', '/modules-pipe.html',
    '/language.html', '/values.html', '/match.html'];
  for (const p of mobile) await block(m, p + ' (mobile)', async () => { await m.open(p); await m.noHorizontalOverflow(); await m.noConsoleErrors(); });
  for (const p of ['/enum-streams.html', '/enumerables.html', '/comprehensions.html', '/streams.html'])
    await block(m, 'F3.04 ' + p + ' (mobile)', async () => { await m.open(p); await m.noHorizontalOverflow(); await m.noConsoleErrors(); });
  const rm = m.report();
  await m.stop();

  console.log(`\n████ TOTAL: ${r.pass + rm.pass} PASS, ${r.fail + rm.fail} FAIL · images embedded: 0 ████`);
  process.exit((r.fail + rm.fail) > 0 ? 1 : 0);
})();
