# jonnify-e2e — Playwright figure validator

Headless, zero-screenshot e2e validation for the static figures in the jonnify
courses. It reads each `<svg>`'s **live rendered geometry** (`getBBox`, in SVG
user units, so it is scale-independent) and fails on the classic display flaws:

| Check | Catches |
|---|---|
| **label overflow** | a `<text>` inside a `.loc` / `.node` / `.state` box wider than its `<rect>` (e.g. `hash · state, attempts` spilling past the box) |
| **edge-label overlap** | a `.elbl` transition label sitting on top of a box (e.g. `claim` / `retry` colliding with `active`) |
| **outside viewBox** | any `<text>` whose bounding box leaves the SVG's own `viewBox` |
| **h-overflow** | the page scrolling sideways |

No images are captured or embedded — output is plain `PASS` / `FAIL` text.

## Install (once)

```bash
cd mcp/e2e
npm install            # postinstall runs `playwright install chromium`
```

## Run

```bash
# the default focused set (the redis-patterns box-figure pages)
BASE_URL="file:///Users/jonny/dev/jonnify/html/redis-patterns" npm run figures

# specific pages (paths relative to BASE_URL)
BASE_URL="file:///Users/jonny/dev/jonnify/html/redis-patterns" \
  node figures.suite.js queues/atomic-state-machine/index.html

# broad sweep — feed a newline-delimited list (e.g. every page with an <svg>)
cd /Users/jonny/dev/jonnify
grep -rl '<svg' html/redis-patterns --include='*.html' | sed 's#html/redis-patterns/##' > /tmp/figpages.txt
BASE_URL="file:///Users/jonny/dev/jonnify/html/redis-patterns" \
  PAGES_FILE=/tmp/figpages.txt node mcp/e2e/figures.suite.js
```

Exit code: `0` = all passed, `1` = at least one figure flaw, `2` = misconfig.

## Files

| File | Role |
|---|---|
| `validator.js` | the `Validator` class + the `svgFiguresFit()` assertion |
| `figures.suite.js` | the runnable suite (page list → checks → report) |
| `package.json` | `playwright` dependency + `npm run figures` |
