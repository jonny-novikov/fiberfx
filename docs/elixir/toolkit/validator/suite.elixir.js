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

  // ── F3.03 · Functions, modules & the pipe ─────────────────────────────────
  // F3.03 hub · function / module / pipe
  await block(v, 'F3.03 /modules.html', async () => {
    await v.open('/modules.html');
    await v.base('Functions');
    await v.expectText('#moRole', 'output');                         // default: function
    await v.click('#moSel button[data-k="module"]'); await v.settle(120);
    await v.expectText('#moRole', 'group');
    await v.expectText('#moExpr', '/1');
    await v.click('#moSel button[data-k="pipe"]'); await v.settle(120);
    await v.expectText('#moRole', 'thread');
    await v.expectText('#moExpr', '|>');
  });

  // F3.03.1 · defining functions
  await block(v, 'F3.03.1 /modules-functions.html', async () => {
    await v.open('/modules-functions.html');
    await v.base('Defining');
    await v.expectText('#fuForm', 'named');                          // default: def
    await v.expectText('#fuResult', ':b');
    await v.expectAttr('#fuC1', 'stroke', '#cdb8f0');
    await v.click('#fuSel button[data-k="fn"]'); await v.settle(120);
    await v.expectText('#fuForm', 'anonymous');
    await v.click('#fuSel button[data-k="capture"]'); await v.settle(120);
    await v.expectText('#fuForm', 'captur');
  });

  // F3.03.2 · organising with modules
  await block(v, 'F3.03.2 /modules-organising.html', async () => {
    await v.open('/modules-organising.html');
    await v.base('Organising');
    await v.expectText('#orRole', 'constant');                       // default: attribute
    await v.expectAttr('#orL1', 'stroke', '#cdb8f0');
    await v.click('#orSel button[data-k="alias"]'); await v.settle(120);
    await v.expectText('#orRole', 'shorten');
    await v.click('#orSel button[data-k="import"]'); await v.settle(120);
    await v.expectText('#orRole', 'prefix');
  });

  // F3.03.3 · the pipe operator
  await block(v, 'F3.03.3 /modules-pipe.html', async () => {
    await v.open('/modules-pipe.html');
    await v.base('pipe');
    await v.expectText('#piForm', 'piped');                          // default: piped
    await v.expectText('#piExpr', '|>');
    await v.expectText('#piResult', ':b');
    await v.click('#piSel button[data-k="nested"]'); await v.settle(120);
    await v.expectText('#piForm', 'nested');
    await v.expectText('#piExpr', 'grade(Portal.average');
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

  // ── F3.05 · hub (three shapes of data) ────────────────────────────────────
  await block(v, 'F3.05 /structs.html', async () => {
    await v.open('/structs.html');
    await v.base('Structs, maps');
    await v.expectText('#shBoxT', '%{email');                       // default source: map
    await v.expectText('#shOut', 'open-ended');
    await v.click('#shSel button[data-k="struct"]'); await v.settle(150);
    await v.expectText('#shBoxT', '%User{');
    await v.expectText('#shOut', '__struct__');
    await v.expectAttr('#shP2', 'fill', '#7ba387');                 // fixed-key-set property lit
    await v.click('#shSel button[data-k="kw"]'); await v.settle(150);
    await v.expectText('#shBoxT', '[email:');
  });

  // ── F3.05.1 · define (a struct is a tagged map) ───────────────────────────
  await block(v, 'F3.05 /structs-define.html', async () => {
    await v.open('/structs-define.html');
    await v.base('Defining a struct');
    await v.expectText('#dfCode', '%Portal.Accounts.User{');        // default view: literal
    await v.expectAttr('#dfTag', 'opacity', '0.35');                // __struct__ hidden by the sugar
    await v.click('#dfSel button[data-k="map"]'); await v.settle(150);
    await v.expectText('#dfCode', '__struct__');
    await v.expectAttr('#dfTag', 'opacity', '1');                   // revealed in the map view
    await v.click('#dfSel button[data-k="keys"]'); await v.settle(150);
    await v.expectText('#dfCode', ':__struct__');
  });

  // ── F3.05.2 · defaults (@enforce_keys + defaults) ─────────────────────────
  await block(v, 'F3.05 /structs-defaults.html', async () => {
    await v.open('/structs-defaults.html');
    await v.base('Enforcing keys');
    await v.expectTextEquals('#ekResT', 'struct built');            // default: email only → builds
    await v.expectText('#ekCode', 'active: true');
    await v.expectAttr('#ekR1', 'stroke', '#7ba387');               // role from a default
    await v.click('#ekSel button[data-k="emailrole"]'); await v.settle(150);
    await v.expectText('#ekCode', ':admin');
    await v.expectAttr('#ekR1', 'stroke', '#b39ddb');               // role now supplied
    await v.click('#ekSel button[data-k="noemail"]'); await v.settle(150);
    await v.expectText('#ekResT', 'ArgumentError');                 // enforced key missing → error
    await v.expectAttr('#ekR0', 'stroke', '#e08f8b');               // email row marked missing
    await v.expectText('#ekCode', 'must');
  });

  // ── F3.05.3 · matching (dispatch by the struct tag) ───────────────────────
  await block(v, 'F3.05 /structs-matching.html', async () => {
    await v.open('/structs-matching.html');
    await v.base('Matching on a struct');
    await v.expectText('#mtCode', '%User{');                        // default value: a User
    await v.expectAttr('#mtCl0', 'stroke', '#7ba387');              // first clause matches
    await v.expectText('#mtTag', 'Portal.Accounts.User');
    await v.click('#mtSel button[data-k="session"]'); await v.settle(150);
    await v.expectText('#mtCode', '%Session{');
    await v.expectAttr('#mtCl1', 'stroke', '#7ba387');              // session clause matches
    await v.click('#mtSel button[data-k="map"]'); await v.settle(150);
    await v.expectAttr('#mtCl2', 'stroke', '#7ba387');              // plain-map clause matches
    await v.expectText('#mtTag', 'none');
    await v.expectText('#mtOut', 'plain');
  });

  // ── F3.06 · hub (two kinds of polymorphism) ───────────────────────────────
  await block(v, 'F3.06 /protocols.html', async () => {
    await v.open('/protocols.html');
    await v.base('Protocols');
    await v.expectText('#poBoxT', 'Protocol');                      // default: vary by value
    await v.expectAttr('#poP0', 'fill', '#7ba387');                 // resolves at runtime
    await v.expectText('#poKey', '__struct__');
    await v.click('#poSel button[data-k="module"]'); await v.settle(150);
    await v.expectText('#poBoxT', 'Behaviour');
    await v.expectAttr('#poP1', 'fill', '#7ba387');                 // checked at compile time
    await v.expectText('#poKey', 'module name');
  });

  // ── F3.06.1 · define (a call resolves by type) ────────────────────────────
  await block(v, 'F3.06 /protocols-define.html', async () => {
    await v.open('/protocols-define.html');
    await v.base('Defining a protocol');
    await v.expectText('#dpInT', 'Portal.Accounts.User');           // default: a User
    await v.expectText('#dpImplT', 'Portal.Summary');               // resolves to the User impl
    await v.expectAttr('#dpImpl', 'stroke', '#7ba387');
    await v.click('#dpSel button[data-k="int"]'); await v.settle(150);
    await v.expectText('#dpImplT', 'UndefinedError');               // no impl for Integer
    await v.expectAttr('#dpImpl', 'stroke', '#e08f8b');
    await v.click('#dpSel button[data-k="session"]'); await v.settle(150);
    await v.expectText('#dpImplT', 'Portal.Auth.Session');
    await v.expectAttr('#dpImpl', 'stroke', '#7ba387');
  });

  // ── F3.06.2 · defimpl (the dispatch table) ────────────────────────────────
  await block(v, 'F3.06 /protocols-defimpl.html', async () => {
    await v.open('/protocols-defimpl.html');
    await v.base('Implementing for a struct');
    await v.expectText('#diResT', 'ada@portal.dev');                // default: User impl runs
    await v.expectAttr('#diR0', 'stroke', '#7ba387');
    await v.click('#diSel button[data-k="session"]'); await v.settle(150);
    await v.expectText('#diResT', 'SES0NbAb29FnXc');
    await v.expectAttr('#diR1', 'stroke', '#7ba387');
    await v.click('#diSel button[data-k="lesson"]'); await v.settle(150);
    await v.expectText('#diResT', 'LSN0NbAb2Lk9GS');
    await v.expectAttr('#diR2', 'stroke', '#7ba387');
  });

  // ── F3.06.3 · behaviours (a compile-time contract) ────────────────────────
  await block(v, 'F3.06 /protocols-behaviours.html', async () => {
    await v.open('/protocols-behaviours.html');
    await v.base('Behaviours');
    await v.expectText('#bhBoxT', 'EmailNotifier');                 // default: EmailNotifier
    await v.expectText('#bhResT', 'implemented');                   // contract satisfied
    await v.expectAttr('#bhR0', 'stroke', '#7ba387');
    await v.click('#bhSel button[data-k="incomplete"]'); await v.settle(150);
    await v.expectText('#bhResT', 'missing');                       // a required callback absent
    await v.expectAttr('#bhR1', 'stroke', '#e08f8b');               // valid_target?/1 missing
    await v.expectAttr('#bhR0', 'stroke', '#7ba387');               // deliver/2 still implemented
    await v.click('#bhSel button[data-k="sms"]'); await v.settle(150);
    await v.expectText('#bhResT', 'implemented');
    await v.expectAttr('#bhR0', 'stroke', '#7ba387');
  });

  // ── F3.07 · hub (the actor in three moves) ────────────────────────────────
  await block(v, 'F3.07 /processes.html', async () => {
    await v.open('/processes.html');
    await v.base('Processes');
    await v.expectText('#prProp', 'isolated');                      // default: spawn
    await v.expectAttr('#prProc', 'stroke', '#cdb8f0');
    await v.click('#prSel button[data-k="message"]'); await v.settle(150);
    await v.expectText('#prProp', 'mailbox');
    await v.expectAttr('#prIn', 'stroke', '#cdb8f0');
    await v.click('#prSel button[data-k="loop"]'); await v.settle(150);
    await v.expectText('#prProp', 'tail-recursive');
    await v.expectAttr('#prLoop', 'stroke', '#cdb8f0');
  });

  // ── F3.07.1 · spawn (concurrency and isolation) ───────────────────────────
  await block(v, 'F3.07 /processes-spawn.html', async () => {
    await v.open('/processes-spawn.html');
    await v.base('Spawning a process');
    await v.expectText('#spRetT', '42');                            // default: direct call returns a value
    await v.expectAttr('#spChild', 'stroke', '#2a3252');            // no child
    await v.expectAttr('#spCaller', 'stroke', '#7ba387');
    await v.click('#spSel button[data-k="spawn"]'); await v.settle(150);
    await v.expectText('#spRetT', '#PID');                          // returns a PID
    await v.expectAttr('#spChild', 'stroke', '#7ba387');            // child runs
    await v.expectAttr('#spCaller', 'stroke', '#7ba387');
    await v.click('#spSel button[data-k="crash"]'); await v.settle(150);
    await v.expectText('#spChildT', 'dies');                        // child crashes
    await v.expectAttr('#spChild', 'stroke', '#e08f8b');
    await v.expectAttr('#spCaller', 'stroke', '#7ba387');           // caller unaffected
  });

  // ── F3.07.2 · messages (mailbox + selective receive) ──────────────────────
  await block(v, 'F3.07 /processes-messages.html', async () => {
    await v.open('/processes-messages.html');
    await v.base('Sending');
    await v.expectText('#srMsg', 'summarize');                      // default: a summarize request
    await v.expectText('#srReply', 'ada@portal.dev');
    await v.expectAttr('#srC1', 'stroke', '#7ba387');               // matches the summarize clause
    await v.click('#srSel button[data-k="ping"]'); await v.settle(150);
    await v.expectText('#srReply', 'pong');
    await v.expectAttr('#srC0', 'stroke', '#7ba387');
    await v.click('#srSel button[data-k="unknown"]'); await v.settle(150);
    await v.expectText('#srReply', 'mailbox');                      // unmatched: kept in mailbox
    await v.expectAttr('#srC0', 'stroke', '#2a3252');
    await v.expectAttr('#srC1', 'stroke', '#2a3252');
  });

  // ── F3.07.3 · state loop (the recursive receive) ──────────────────────────
  await block(v, 'F3.07 /processes-state.html', async () => {
    await v.open('/processes-state.html');
    await v.base('Holding state');
    await v.expectText('#lpIn', '0');                               // msg 1: state in 0
    await v.expectText('#lpMsg', ':inc');
    await v.expectText('#lpNext', '1');                             // → loop(1)
    await v.expectAttr('#lpC0', 'stroke', '#7ba387');
    await v.click('#lpSel button[data-k="s2"]'); await v.settle(150);
    await v.expectText('#lpIn', '1');
    await v.expectText('#lpNext', '2');                             // → loop(2)
    await v.expectAttr('#lpC0', 'stroke', '#7ba387');
    await v.click('#lpSel button[data-k="s3"]'); await v.settle(150);
    await v.expectText('#lpMsg', ':get');
    await v.expectAttr('#lpC1', 'stroke', '#7ba387');               // {:get, from} clause
    await v.expectText('#lpReply', '2');                            // replies 2
    await v.expectText('#lpNext', '2');                             // state unchanged
  });

  // ── F3.08 · hub (an OTP system in three pieces) ───────────────────────────
  await block(v, 'F3.08 /otp.html', async () => {
    await v.open('/otp.html');
    await v.base('OTP');
    await v.expectText('#opRole', 'init/1');                        // default: GenServer
    await v.expectAttr('#opGen', 'stroke', '#cdb8f0');
    await v.click('#opSel button[data-k="callcast"]'); await v.settle(150);
    await v.expectText('#opRole', ':ok');
    await v.expectAttr('#opMsg', 'stroke', '#cdb8f0');
    await v.click('#opSel button[data-k="supervisor"]'); await v.settle(150);
    await v.expectText('#opRole', 'one_for_one');
    await v.expectAttr('#opSup', 'stroke', '#cdb8f0');
  });

  // ── F3.08.1 · genserver (callbacks and returns) ───────────────────────────
  await block(v, 'F3.08 /otp-genserver.html', async () => {
    await v.open('/otp-genserver.html');
    await v.base('GenServer');
    await v.expectText('#gsRet', '{:ok');                           // default: init returns {:ok, 0}
    await v.expectAttr('#gsR0', 'stroke', '#7ba387');
    await v.expectText('#gsState', '0');
    await v.click('#gsSel button[data-k="call"]'); await v.settle(150);
    await v.expectAttr('#gsR1', 'stroke', '#7ba387');
    await v.expectText('#gsRet', ':reply');
    await v.click('#gsSel button[data-k="cast"]'); await v.settle(150);
    await v.expectAttr('#gsR2', 'stroke', '#7ba387');
    await v.expectText('#gsRet', ':noreply');
  });

  // ── F3.08.2 · call vs cast (sync / async routing) ─────────────────────────
  await block(v, 'F3.08 /otp-call-cast.html', async () => {
    await v.open('/otp-call-cast.html');
    await v.base('Synchronous');
    await v.expectText('#ccRetT', '2');                             // default: call returns the count
    await v.expectText('#ccServerT', 'handle_call');
    await v.expectAttr('#ccClient', 'stroke', '#7ba387');
    await v.click('#ccSel button[data-k="cast"]'); await v.settle(150);
    await v.expectText('#ccRetT', ':ok');
    await v.expectText('#ccServerT', 'handle_cast');
    await v.click('#ccSel button[data-k="timeout"]'); await v.settle(150);
    await v.expectText('#ccRetT', 'timeout');                       // caller exits on timeout
    await v.expectAttr('#ccClient', 'stroke', '#e08f8b');
  });

  // ── F3.08.3 · supervisors (restart strategies) ────────────────────────────
  await block(v, 'F3.08 /otp-supervisors.html', async () => {
    await v.open('/otp-supervisors.html');
    await v.base('Supervisors');
    await v.expectText('#svS0', 'alive');                           // one_for_one: siblings untouched
    await v.expectText('#svS2', 'alive');
    await v.expectAttr('#svC1', 'stroke', '#e08f8b');               // the crashed child
    await v.click('#svSel button[data-k="one_for_all"]'); await v.settle(150);
    await v.expectText('#svS0', 'restarted');                       // all restart
    await v.expectText('#svS2', 'restarted');
    await v.expectAttr('#svC0', 'stroke', '#d4a85a');
    await v.click('#svSel button[data-k="rest_for_one"]'); await v.settle(150);
    await v.expectText('#svS0', 'alive');                           // started before: survives
    await v.expectText('#svS2', 'restarted');                       // started after: restarts
    await v.expectAttr('#svC2', 'stroke', '#d4a85a');
  });

  // ── F3.09 · the process playground (capstone lab) ─────────────────────────
  await block(v, 'F3.09 /playground.html', async () => {
    await v.open('/playground.html');
    await v.base('playground');
    await v.expectTextEquals('#pgSt0', '0');                        // Tally starts at 0
    await v.expectTextEquals('#pgMbox', '0');                       // mailbox empty
    await v.expectTextEquals('#pgRs0', '0');                        // no restarts
    // two casts queue in the mailbox, state still pending
    await v.click('#pgSendInc'); await v.settle(120);
    await v.click('#pgSendInc'); await v.settle(120);
    await v.expectTextEquals('#pgMbox', '2');
    await v.expectTextEquals('#pgSt0', '0');
    // process one message → depth drops, state moves
    await v.click('#pgStep'); await v.settle(120);
    await v.expectTextEquals('#pgMbox', '1');
    await v.expectTextEquals('#pgSt0', '1');
    // drain the rest → empty, state 2
    await v.click('#pgRun'); await v.settle(120);
    await v.expectTextEquals('#pgMbox', '0');
    await v.expectTextEquals('#pgSt0', '2');
    // synchronous call: send :get then process → reply is the count
    await v.click('#pgSendGet'); await v.settle(120);
    await v.click('#pgRun'); await v.settle(120);
    await v.expectText('#pgReply', '2');
    // crash Tally under one_for_one → it resets and restarts, siblings untouched
    await v.click('#pgCrash'); await v.settle(120);
    await v.expectTextEquals('#pgSt0', '0');
    await v.expectTextEquals('#pgRs0', '1');
    await v.expectText('#pgStat0', 'restarted');
    await v.expectTextEquals('#pgRs1', '0');
    // switch strategy and crash → all restart, Notifier's count increments
    await v.click('#pgStratSel button[data-s="one_for_all"]'); await v.settle(120);
    await v.click('#pgCrash'); await v.settle(120);
    await v.expectTextEquals('#pgRs1', '1');
    await v.expectTextEquals('#pgRs0', '2');
  });

  // ══ F4 · Algorithms & Data Structures ════════════════════════════════════
  // F4 chapter landing
  await block(v, 'F4 /algorithms.html (landing)', async () => {
    await v.open('/algorithms.html');
    await v.base('Algorithms');
    await v.expectText('a.mod .t', 'Lists');                        // the built module card
    await v.expectAttr('a.mod', 'href', '/elixir/algorithms/lists');
  });

  // F4.01 hub · the three angles on a list
  await block(v, 'F4.01 /lists.html', async () => {
    await v.open('/lists.html');
    await v.base('Lists');
    await v.expectText('#lsRole', 'head');                          // default: cons cells
    await v.expectAttr('#lsCell0', 'stroke', '#a7c9b1');
    await v.click('#lsSel button[data-k="recursion"]'); await v.settle(120);
    await v.expectText('#lsRole', 'recurse');
    await v.expectAttr('#lsRecArr', 'opacity', '1');
    await v.click('#lsSel button[data-k="complexity"]'); await v.settle(120);
    await v.expectText('#lsRole', 'O(1)');
    await v.expectAttr('#lsFront', 'opacity', '1');
  });

  // F4.01.1 · cons cells
  await block(v, 'F4.01.1 /lists-cons.html', async () => {
    await v.open('/lists-cons.html');
    await v.base('Cons');
    await v.expectText('#cnResult', '[0');                          // default: prepend
    await v.expectText('#cnCost', 'O(1)');
    await v.expectAttr('#cnNewFront', 'opacity', '1');
    await v.click('#cnSel button[data-k="headtail"]'); await v.settle(120);
    await v.expectText('#cnResult', 'hd');
    await v.expectText('#cnCost', 'O(1)');
    await v.click('#cnSel button[data-k="append"]'); await v.settle(120);
    await v.expectText('#cnResult', '99');
    await v.expectText('#cnCost', 'O(n)');
    await v.expectAttr('#cnNewEnd', 'opacity', '1');
  });

  // F4.01.2 · recursion over lists
  await block(v, 'F4.01.2 /lists-recursion.html', async () => {
    await v.open('/lists-recursion.html');
    await v.base('Recursion');
    await v.expectTextEquals('#rcResult', '50');                    // default: sum
    await v.expectText('#rcClause', 'sum');
    await v.click('#rcSel button[data-k="map"]'); await v.settle(120);
    await v.expectText('#rcResult', '24');
    await v.expectText('#rcClause', 'map');
    await v.click('#rcSel button[data-k="length"]'); await v.settle(120);
    await v.expectTextEquals('#rcResult', '3');
    await v.expectText('#rcClause', 'length');
  });

  // F4.01.3 · complexity & big-O
  await block(v, 'F4.01.3 /lists-big-o.html', async () => {
    await v.open('/lists-big-o.html');
    await v.base('Complexity');
    await v.expectText('#boBadge', 'O(1)');                         // default: prepend
    await v.expectText('#boTouches', '1');
    await v.expectAttr('#boFront', 'opacity', '1');
    await v.click('#boSel button[data-k="length"]'); await v.settle(120);
    await v.expectText('#boBadge', 'O(n)');
    await v.expectText('#boTouches', '4');
    await v.click('#boSel button[data-k="append"]'); await v.settle(120);
    await v.expectText('#boBadge', 'O(n)');
    await v.expectText('#boTouches', 'new');
    await v.expectAttr('#boEnd', 'opacity', '1');
  });

  // ── F4.02 · Trees & traversals ──────────────────────────────────────────
  // F4.02 hub · the tree seen three ways
  await block(v, 'F4.02 /trees.html', async () => {
    await v.open('/trees.html');
    await v.base('Trees');
    await v.expectText('#trRole', 'value');                         // default: shape
    await v.expectAttr('#trN0', 'stroke', '#cdb8f0');
    await v.click('#trSel button[data-k="depth"]'); await v.settle(120);
    await v.expectText('#trRole', 'deep');
    await v.expectText('#trSeq', 'in-order');
    await v.click('#trSel button[data-k="breadth"]'); await v.settle(120);
    await v.expectText('#trRole', 'level');
    await v.expectText('#trSeq', 'level-order');
  });

  // F4.02.1 · recursive shape
  await block(v, 'F4.02.1 /trees-shape.html', async () => {
    await v.open('/trees-shape.html');
    await v.base('Binary');
    await v.expectTextEquals('#shResult', '7');                     // default: size
    await v.expectText('#shClause', 'size');
    await v.click('#shSel button[data-k="height"]'); await v.settle(120);
    await v.expectTextEquals('#shResult', '3');
    await v.expectText('#shClause', 'height');
    await v.click('#shSel button[data-k="sum"]'); await v.settle(120);
    await v.expectTextEquals('#shResult', '127');
    await v.expectText('#shClause', 'sum');
  });

  // F4.02.2 · depth-first orders
  await block(v, 'F4.02.2 /trees-dfs.html', async () => {
    await v.open('/trees-dfs.html');
    await v.base('Depth');
    await v.expectText('#dfName', 'pre-order');                     // default: pre
    await v.expectTextEquals('#dfOrd0', '1');
    await v.click('#dfSel button[data-k="in"]'); await v.settle(120);
    await v.expectText('#dfName', 'in-order');
    await v.expectTextEquals('#dfOrd0', '4');
    await v.expectText('#dfSeq', 'sorted');
    await v.click('#dfSel button[data-k="post"]'); await v.settle(120);
    await v.expectText('#dfName', 'post-order');
    await v.expectTextEquals('#dfOrd0', '7');
  });

  // F4.02.3 · breadth-first & balance
  await block(v, 'F4.02.3 /trees-bfs.html', async () => {
    await v.open('/trees-bfs.html');
    await v.base('Breadth');
    await v.expectTextEquals('#bfSeq', '12');                       // default: level 1
    await v.expectText('#bfQueue', '8');
    await v.click('#bfSel button[data-k="l2"]'); await v.settle(120);
    await v.expectText('#bfSeq', '30');
    await v.click('#bfSel button[data-k="l3"]'); await v.settle(120);
    await v.expectText('#bfSeq', '42');
    await v.expectText('#bfQueue', 'empty');
  });

  // ── F4.03 · Sorting & searching ─────────────────────────────────────────
  // F4.03 hub · sort / search / cost
  await block(v, 'F4.03 /sorting.html', async () => {
    await v.open('/sorting.html');
    await v.base('Sorting');
    await v.expectText('#soRole', 'order');                         // default: sort
    await v.expectAttr('#soBox0', 'stroke', '#a7c9b1');
    await v.click('#soSel button[data-k="search"]'); await v.settle(120);
    await v.expectText('#soRole', 'halve');
    await v.expectText('#soSeq', 'found');
    await v.click('#soSel button[data-k="cost"]'); await v.settle(120);
    await v.expectText('#soRole', 'floor');
    await v.expectText('#soSeq', 'log n');
  });

  // F4.03.1 · merge & quicksort
  await block(v, 'F4.03.1 /sorting-sorts.html', async () => {
    await v.open('/sorting-sorts.html');
    await v.base('Merge');
    await v.expectText('#srStep', 'merge');                         // default: merge sort
    await v.expectText('#srResult', '[1, 3, 5, 8]');
    await v.expectAttr('#srDivider', 'opacity', '1');
    await v.click('#srSel button[data-k="quick"]'); await v.settle(120);
    await v.expectText('#srStep', 'pivot');
    await v.expectText('#srResult', '[1, 3, 5, 8]');
    await v.expectAttr('#srBar2', 'stroke', '#f0cd7f');
  });

  // F4.03.2 · linear & binary search
  await block(v, 'F4.03.2 /sorting-search.html', async () => {
    await v.open('/sorting-search.html');
    await v.base('Linear');
    await v.expectText('#seBadge', 'O(n)');                         // default: linear
    await v.expectText('#seSteps', 'one by one');
    await v.click('#seSel button[data-k="binary"]'); await v.settle(120);
    await v.expectText('#seBadge', 'log');
    await v.expectText('#seSteps', 'halves');
    await v.expectAttr('#seBox3', 'stroke', '#9fc0ea');
  });

  // F4.03.3 · stability & sort cost
  await block(v, 'F4.03.3 /sorting-cost.html', async () => {
    await v.open('/sorting-cost.html');
    await v.base('Stability');
    await v.expectText('#coName', 'Merge');                         // default: merge
    await v.expectText('#coStable', 'stable');
    await v.expectText('#coBadge', 'log');
    await v.click('#coSel button[data-k="quick"]'); await v.settle(120);
    await v.expectText('#coName', 'Quick');
    await v.expectText('#coStable', 'not');
    await v.click('#coSel button[data-k="insertion"]'); await v.settle(120);
    await v.expectText('#coName', 'Insertion');
    await v.expectText('#coStable', 'stable');
  });

  // ── F4.04 · Maps, sets & hashing (course data layer) ──────────────────────
  // F4.04 hub · lookup / membership / hashing over the page registry
  await block(v, 'F4.04 /maps.html', async () => {
    await v.open('/maps.html');
    await v.base('Maps');
    await v.expectText('#mpRole', 'look up');                        // default: lookup
    await v.expectText('#mpExpr', 'Map.fetch');
    await v.expectAttr('#mpRow0', 'stroke', '#a7c9b1');
    await v.click('#mpSel button[data-k="membership"]'); await v.settle(120);
    await v.expectText('#mpRole', 'built');
    await v.expectText('#mpExpr', 'member?');
    await v.click('#mpSel button[data-k="hashing"]'); await v.settle(120);
    await v.expectText('#mpRole', 'O(1)');
    await v.expectText('#mpExpr', 'phash2');
  });

  // F4.04.1 · maps & key lookup
  await block(v, 'F4.04.1 /maps-lookup.html', async () => {
    await v.open('/maps-lookup.html');
    await v.base('lookup');
    await v.expectText('#lkRole', 'nil');                            // default: get
    await v.expectText('#lkResult', 'Page');
    await v.click('#lkSel button[data-k="fetch"]'); await v.settle(120);
    await v.expectText('#lkRole', 'tagged');
    await v.expectText('#lkResult', ':ok');
    await v.click('#lkSel button[data-k="put"]'); await v.settle(120);
    await v.expectText('#lkRole', 'overwrite');
    await v.expectAttr('#lkNewRow', 'opacity', '1');
  });

  // F4.04.2 · MapSet & membership
  await block(v, 'F4.04.2 /maps-sets.html', async () => {
    await v.open('/maps-sets.html');
    await v.base('MapSet');
    await v.expectText('#msRole', 'in the set');                     // default: member?
    await v.expectText('#msResult', 'true');
    await v.expectAttr('#msChipMaps', 'stroke', '#a7c9b1');
    await v.click('#msSel button[data-k="intersection"]'); await v.settle(120);
    await v.expectText('#msRole', 'both');
    await v.expectText('#msResult', 'maps');
    await v.click('#msSel button[data-k="difference"]'); await v.settle(120);
    await v.expectText('#msRole', 'not yet built');
    await v.expectText('#msResult', 'hamt');
  });

  // F4.04.3 · hashing & collisions
  await block(v, 'F4.04.3 /maps-hashing.html', async () => {
    await v.open('/maps-hashing.html');
    await v.base('Hashing');
    await v.expectText('#hsRole', 'integer');                        // default: hash
    await v.click('#hsSel button[data-k="bucket"]'); await v.settle(120);
    await v.expectText('#hsRole', 'slot');
    await v.expectText('#hsResult', 'slot');
    await v.click('#hsSel button[data-k="collision"]'); await v.settle(120);
    await v.expectText('#hsRole', 'same slot');
    await v.expectAttr('#hsKey2', 'opacity', '1');
  });

  // ── F4.06 · CHAMP maps (compressed HAMT; course registry + branded trie) ──
  // F4.06 hub · layout / iteration / equality over a CHAMP node
  await block(v, 'F4.06 /champ.html', async () => {
    await v.open('/champ.html');
    await v.base('CHAMP');
    await v.expectText('#chRole', 'dense');                          // default: layout
    await v.expectAttr('#chDataArr', 'stroke', '#a7c9b1');
    await v.click('#chSel button[data-k="iteration"]'); await v.settle(120);
    await v.expectText('#chRole', 'contiguous');
    await v.expectText('#chExpr', 'cache');
    await v.click('#chSel button[data-k="equality"]'); await v.settle(120);
    await v.expectText('#chRole', 'canonical');
    await v.expectText('#chExpr', 'equal');
  });

  // F4.06.1 · compressed node layout
  await block(v, 'F4.06.1 /champ-layout.html', async () => {
    await v.open('/champ-layout.html');
    await v.base('layout');
    await v.expectText('#laRole', 'entries');                        // default: datamap
    await v.expectAttr('#laDataArr', 'stroke', '#a7c9b1');
    await v.click('#laSel button[data-k="nodemap"]'); await v.settle(120);
    await v.expectText('#laRole', 'sub-nodes');
    await v.expectAttr('#laNodeArr', 'stroke', '#9fc0ea');
    await v.click('#laSel button[data-k="popcount"]'); await v.settle(120);
    await v.expectText('#laRole', 'index');
    await v.expectText('#laResult', 'popcount');
  });

  // F4.06.2 · cache-friendly iteration
  await block(v, 'F4.06.2 /champ-iteration.html', async () => {
    await v.open('/champ-iteration.html');
    await v.base('Cache');
    await v.expectText('#itRole', 'contiguous');                     // default: entries
    await v.expectAttr('#itHamt', 'opacity', '0');
    await v.click('#itSel button[data-k="descend"]'); await v.settle(120);
    await v.expectText('#itRole', 'descend');
    await v.expectText('#itResult', 'recurse');
    await v.click('#itSel button[data-k="hamt"]'); await v.settle(120);
    await v.expectText('#itRole', 'scatter');
    await v.expectAttr('#itHamt', 'opacity', '1');
    await v.expectText('#itResult', 'misses');
  });

  // F4.06.3 · canonical equality
  await block(v, 'F4.06.3 /champ-equality.html', async () => {
    await v.open('/champ-equality.html');
    await v.base('Canonical');
    await v.expectText('#eqRole', 'canonical');                      // default: canonical
    await v.expectText('#eqResult', 'identical');
    await v.click('#eqSel button[data-k="equal"]'); await v.settle(120);
    await v.expectText('#eqRole', 'structure');
    await v.expectText('#eqResult', 'true');
    await v.click('#eqSel button[data-k="diff"]'); await v.settle(120);
    await v.expectText('#eqRole', 'cheap');
    await v.expectText('#eqResult', 'changed');
    await v.expectAttr('#eqBdiff', 'stroke', '#f0cd7f');
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
  for (const p of ['/modules.html', '/modules-functions.html', '/modules-organising.html', '/modules-pipe.html'])
    await block(m, 'F3.03 ' + p + ' (mobile)', async () => { await m.open(p); await m.noHorizontalOverflow(); await m.noConsoleErrors(); });
  for (const p of ['/enum-streams.html', '/enumerables.html', '/comprehensions.html', '/streams.html'])
    await block(m, 'F3.04 ' + p + ' (mobile)', async () => { await m.open(p); await m.noHorizontalOverflow(); await m.noConsoleErrors(); });
  for (const p of ['/structs.html', '/structs-define.html', '/structs-defaults.html', '/structs-matching.html'])
    await block(m, 'F3.05 ' + p + ' (mobile)', async () => { await m.open(p); await m.noHorizontalOverflow(); await m.noConsoleErrors(); });
  for (const p of ['/protocols.html', '/protocols-define.html', '/protocols-defimpl.html', '/protocols-behaviours.html'])
    await block(m, 'F3.06 ' + p + ' (mobile)', async () => { await m.open(p); await m.noHorizontalOverflow(); await m.noConsoleErrors(); });
  for (const p of ['/processes.html', '/processes-spawn.html', '/processes-messages.html', '/processes-state.html'])
    await block(m, 'F3.07 ' + p + ' (mobile)', async () => { await m.open(p); await m.noHorizontalOverflow(); await m.noConsoleErrors(); });
  for (const p of ['/otp.html', '/otp-genserver.html', '/otp-call-cast.html', '/otp-supervisors.html'])
    await block(m, 'F3.08 ' + p + ' (mobile)', async () => { await m.open(p); await m.noHorizontalOverflow(); await m.noConsoleErrors(); });
  await block(m, 'F3.09 /playground.html (mobile)', async () => { await m.open('/playground.html'); await m.noHorizontalOverflow(); await m.noConsoleErrors(); });
  for (const p of ['/algorithms.html', '/lists.html', '/lists-cons.html', '/lists-recursion.html', '/lists-big-o.html'])
    await block(m, 'F4 ' + p + ' (mobile)', async () => { await m.open(p); await m.noHorizontalOverflow(); await m.noConsoleErrors(); });
  for (const p of ['/trees.html', '/trees-shape.html', '/trees-dfs.html', '/trees-bfs.html'])
    await block(m, 'F4.02 ' + p + ' (mobile)', async () => { await m.open(p); await m.noHorizontalOverflow(); await m.noConsoleErrors(); });
  for (const p of ['/sorting.html', '/sorting-sorts.html', '/sorting-search.html', '/sorting-cost.html'])
    await block(m, 'F4.03 ' + p + ' (mobile)', async () => { await m.open(p); await m.noHorizontalOverflow(); await m.noConsoleErrors(); });
  for (const p of ['/maps.html', '/maps-lookup.html', '/maps-sets.html', '/maps-hashing.html'])
    await block(m, 'F4.04 ' + p + ' (mobile)', async () => { await m.open(p); await m.noHorizontalOverflow(); await m.noConsoleErrors(); });
  for (const p of ['/champ.html', '/champ-layout.html', '/champ-iteration.html', '/champ-equality.html'])
    await block(m, 'F4.06 ' + p + ' (mobile)', async () => { await m.open(p); await m.noHorizontalOverflow(); await m.noConsoleErrors(); });
  const rm = m.report();
  await m.stop();

  console.log(`\n████ TOTAL: ${r.pass + rm.pass} PASS, ${r.fail + rm.fail} FAIL · images embedded: 0 ████`);
  process.exit((r.fail + rm.fail) > 0 ? 1 : 0);
})();
