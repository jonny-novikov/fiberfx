---
name: mcp-e2e-figure-validator
description: mcp/e2e = headless Playwright validator for static-figure display flaws (SVG label-overflow / edge-overlap / text-outside-viewBox) — how to run + its one caveat
project: courses
metadata: 
  node_type: memory
  type: reference
  originSessionId: 957a2122-df18-4ef4-bd67-a2f8c8acf757
---

`mcp/e2e/` = a headless, zero-screenshot **Playwright validator for jonnify static SVG figures** (built 2026-06-26; the user asked for it at this path). Modeled on `docs/elixir/validator`. `Validator.svgFiguresFit()` reads each `<svg>`'s live `getBBox()` in **SVG user units** (scale-independent) and fails on: (1) a `<text>` inside a `.loc`/`.node`/`.state` group overflowing its sibling `<rect>`; (2) a `.elbl` edge label overlapping a box rect; (3) any `<text>` past the `viewBox`; plus page h-overflow.

Run:
```bash
cd mcp/e2e   # playwright 1.61.1 + chromium-1228 already installed
BASE_URL="file:///Users/jonny/dev/jonnify/html/redis-patterns" node figures.suite.js <pages…>
# broad sweep: grep -rl '<svg' html/redis-patterns --include='*.html' | sed 's#html/redis-patterns/##' > /tmp/figpages.txt
#              PAGES_FILE=/tmp/figpages.txt node figures.suite.js
```
Files: `validator.js` (the class + `svgFiguresFit`), `figures.suite.js`, `package.json`, `README.md`. Default pages = the 2 atomic-state-machine pages. Exit 0/1/2.

**CAVEAT:** the box-label check pairs each text with its group's **first** `querySelector('rect')`, so a `<g>` holding **multiple** rects+labels false-positives — fix the figure to one-rect-per-`<g>` (as `overview/redis-under-game` `#seamFig` needed), don't loosen the check.

**Sweep result 2026-06-26:** 189 redis-patterns svg pages → **58 flaws / 52 pages**. The **14 box-overflow/overlap** ones FIXED (re-layout pattern = wider viewBox + bigger boxes + bigger gaps; the model is `queues/atomic-state-machine/index.html`, 610×240 / 160w boxes / 45 gaps). The **44 long-SVG-text-outside-viewBox** ones DEFERRED (the "never long centered SVG text" anti-pattern — shorten or lift the sentence into the figcaption/`.take`). Gotcha found: a class selector `.cflow .nsub{text-anchor:middle}` overrides an inline `text-anchor="start"` attribute → use inline `style=` to win specificity.

**Polish 2026-06-26 (full sweep, user: "polish loose ends"):** the 44 deferred long-text flaws — plus the newer R7.05–07 / R8.03–07 pages — were ALL FIXED in a 5-agent fan-out over the 42 still-failing pages → course-wide **519 PASS / 0 FAIL** (was 469/50). Do-no-harm fix order: **widen the `viewBox`** to contain the text (≤~30% growth — moves nothing, the dominant fix); else **wrap** a too-long caption into two `<tspan>`s (raise the viewBox H for the 2nd line) or shorten it; never move nodes/data. Confirmed: the **text-anchor CSS-override** (the gotcha above) caused most "negative-x" spills — an inline `text-anchor="start"` beaten by a CSS class rule renders the label *centered* so it spills both edges; **gate-invisible to cms** (markup-only), render-validator-only. Re-run after edits with the same `BASE_URL=file://… node figures.suite.js <pages>`.
