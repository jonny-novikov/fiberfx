# Apollo A+ gates — author checklist

Every page ships only when all nine Apollo gates pass. The builder runs them on the assembled document after wrapping the fragment; any `STATUS: FAIL` is a hard stop. The gates can also be run standalone on an existing file with `check FILE`. Below: each gate, in order, what it checks, and how to pass it. The check column reflects the builder's actual logic.

| # | Gate | What it checks | How to pass |
|---|---|---|---|
| 1 | **containers** | Block-level container tags (`div, section, main, header, footer, nav, article, figure, aside`) are balanced — the gate pushes opens onto a stack and fails on the first close that does not match the top, or on any tag left open. SVG and `<script>`/`<style>` bodies are stripped before the scan. | Close every container you open, in nesting order. Watch for an unclosed `.wrap` inside a `section` — close it before `</section>`. Self-closing tags are exempt. |
| 2 | **svg** | At least one `<svg>` is present, and every `<svg` has a matching `</svg>`. Zero SVG fails ("no seen argument"); an open/close count mismatch fails. | Carry at least one figure with a real `<svg>`. Make sure each SVG is explicitly closed. The visual is required, not optional. |
| 3 | **no-future** | The literal string `/future` does not appear anywhere in the document. | Never link to the `/future` section. Course pages link only within `/elixir` (and external `https://` for fonts). |
| 4 | **voice** | None of the forbidden words appear in *visible* text (scripts, styles, and SVG content are stripped first): `revolutionary`, `blazing-fast` / `blazing fast`, `magical`, `simply`, `just`, `obviously`, `effortless` (case-insensitive, word-boundaried). | Write in the plain, confident voice. Drop hype and dismissive words. If a sentence leans on "just" or "simply" or "obviously", rewrite it to state the thing directly. |
| 5 | **storage** | The tokens `localStorage` and `sessionStorage` appear nowhere in the document. | Hold widget state in DOM attributes and closure variables only. No browser storage of any kind. |
| 6 | **motion** | The string `prefers-reduced-motion` is present. | Gate every looping animation behind `@media (prefers-reduced-motion: no-preference)` and disable the reveal transition under `@media (prefers-reduced-motion: reduce)`. The shared head already includes both; keep them if you author head-level CSS, and add the media query around any new animation. |
| 7 | **degrade** | If `.reveal` is used at all, its hiding styles are scoped to `html.js .reveal` (or `.js .reveal`) — so content is visible without JavaScript. Pages with no `.reveal` pass trivially. | When you use the reveal-on-scroll fade, only hide under `html.js`. Never hide content with a bare `.reveal { opacity: 0 }`. The builder's bootstrap adds `html.js` and reveals on scroll. |
| 8 | **links** | Every internal `href` (anything not starting with `#`, `http://`, `https://`, `mailto:`, `tel:`, `//`) resolves to a route in the allow-list: `/elixir`, the linkable chapters, the linkable modules, and the subpages of linkable modules. `live` and `built` are linkable; `planned` and `soon` are not. | Link only to routes whose status is live or built (see `course-map.md`). A planned module is shown as a non-linking card, never an `<a href>`. Anchor links (`#id`) and external links are always fine. |
| 9 | **pager** | A `class="pager"` block exists, and at least one `href` in the whole document resolves to an allowed route. | Include the `.pager` nav with a prev and a next `.btn`, each pointing at a real built route. |

## Running the gates

The builder assembles and checks in one step (`build --page KEY`), or check an already-built file directly (`check path/to/file.html`). A passing run prints, per gate, `[PASS] name detail`, then `grade: A+` and `STATUS: PASS`. Treat any `[FAIL]` as a stop and fix it before presenting.

## Beyond the gates (the A+ bar the machine cannot check)

The gates are necessary, not sufficient. A page is A+ only when, in addition:

- the prose is precise, confident, and plain, in the Technical Writer voice;
- every code sample is idiomatic Elixir, compiles, and shows its output with `# => ...`;
- math is rigorous KaTeX with every symbol defined;
- the bridge is explicit on every concept — the idea and its Elixir form, paired, not inferred;
- each interactive computes the real result, isolates one idea, and was exercised with synthetic events across its input range;
- the page render-tests cleanly on desktop and at ~390px mobile.

Run the human checks alongside the nine gates; both must hold.
