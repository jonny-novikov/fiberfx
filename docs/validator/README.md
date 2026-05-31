# page-validator

Headless, **zero-screenshot** page validation. It checks rendered pages by reading the
live DOM and computed styles through Playwright, asserts against expected values, and
prints `PASS` / `FAIL` as text. No images are captured or embedded, so it consumes no
image/preview budget and runs head-less in any environment (CI, local shell, container).

Works against any URL scheme Playwright supports: `file://`, `http://`, `https://`.

## Files

| File               | Purpose |
|--------------------|---------|
| `validator.js`     | Reusable library: the `Validator` class + `norm` / `nospace` helpers. |
| `suite.example.js` | Example suite — copy and adapt the checks for your pages. |
| `package.json`     | Dependency (`playwright`) + scripts. |

## Install (once)

```bash
npm install
npx playwright install chromium   # runs automatically via postinstall too
```

## Run

```bash
# Validate a local folder (file://)
BASE_URL="file:///absolute/path/to/site" node suite.example.js

# ...or a dev server / live site (http/https)
BASE_URL="http://localhost:3000" node suite.example.js

# npm script (uses BASE_URL from the environment)
BASE_URL="http://localhost:3000" npm run validate
```

Exit code: `0` = all passed, `1` = at least one failure (CI-friendly).

## Minimal usage

```js
const { Validator } = require('./validator');

(async () => {
  const v = new Validator({ baseUrl: process.env.BASE_URL });
  await v.start();

  await v.open('/page.html');
  await v.title('My Page');
  await v.noKatexErrors();
  await v.noHorizontalOverflow();
  await v.fill('#weight', '92');
  await v.settle(750);                       // wait past debounce
  await v.expectTextEquals('#result', '-12');

  v.report();
  await v.stop();
  process.exit(v.fail > 0 ? 1 : 0);
})();
```

## Assertion reference

| Method | Checks |
|--------|--------|
| `title(sub)` | `<title>` contains substring |
| `noKatexErrors()` | zero `.katex-error` nodes (math rendered cleanly) |
| `noHorizontalOverflow(tol = 2)` | no horizontal scroll (`scrollWidth − clientWidth ≤ tol`) |
| `text(sel)` | returns normalized `textContent` |
| `expectText(sel, exp)` | text **contains** `exp` (whitespace-insensitive) |
| `expectTextEquals(sel, exp)` | text **equals** `exp` (all whitespace stripped) |
| `fill(sel, val)` | type into input / textarea |
| `click(sel)` | click button / tab / option |
| `computedStyle(sel, prop)` | returns a computed CSS property |
| `expectStyle(sel, prop, exp)` | computed CSS property equals `exp` (e.g. `rgb(224, 118, 114)`) |
| `count(sel)` | returns element count |
| `expectCount(sel, op, n)` | count comparison: `==`, `>=`, `>`, `<=`, `<` (e.g. SVG `<path>` count) |
| `expectVisible(sel)` | element is visible |
| `settle(ms = 750)` | pause longer than a debounce window before reading state |
| `localStorage(key)` | read + JSON-parse a `localStorage` key |
| `expectStored(key, field, value)` | `localStorage` key exists (optionally a field equals a value) |
| `report()` | print summary, return `{ pass, fail }` |

## Two gotchas (already handled in the library)

1. **Locale thousands separators.** `ru-RU` / many locales use a non-breaking space
   (`U+00A0`) or narrow no-break space (`U+202F`) between digit groups (e.g. `5 500`).
   `expectText` / `expectTextEquals` compare via `nospace()`, so `"5 500"` matches `"5500"`.

2. **Debounced autosave.** If a page debounces writes to `localStorage`, read the key
   only **after** `settle(ms)` with `ms` greater than the debounce window (e.g. `750`
   for a `600 ms` debounce), or the value reads back empty.

## Extending

Add new assertions to the `Validator` class following the same pattern — do the DOM read,
then call `this.check(name, condition, got)`:

```js
/** Assert an attribute value. */
async expectAttr(sel, attr, exp) {
  const got = await this.page.locator(sel).first().getAttribute(attr);
  this.check(`${sel}[${attr}] == ${exp}`, got === exp, got);
}
```

## Options

`new Validator({ ... })`:

| Option | Default | Meaning |
|--------|---------|---------|
| `baseUrl` | `''` (env `BASE_URL` wins) | prefix joined to relative page paths |
| `headless` | `true` | run head-less |
| `viewportWidth` | `1280` | viewport width (px) |
| `viewportHeight` | `900` | viewport height (px) |
| `settleMs` | `1300` | pause after navigation for async render / KaTeX |
