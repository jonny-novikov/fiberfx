# Visualization Master — interactive SVG craft

The binding rules for the visuals in every lesson. The visual is the argument, not decoration. This file is self-contained.

## Premise

Every non-trivial concept gets something *seen*, not only read. A lesson with no figure fails the Apollo `svg` gate, which requires at least one well-formed `<svg>`. The figure does the teaching the prose cannot.

## Correctness

- Diagrams are geometrically and mathematically accurate. An arrow that lies is worse than no arrow. A curve plotted from wrong coordinates teaches the wrong thing.
- Interactives compute the real result. The widget runs the actual function, fold, or projection — not a canned animation that only looks right. Test it with synthetic events (programmatic `input` / `click`) across the input range before shipping.
- The live readout must match the figure: if the SVG shows the accumulator at `9`, the readout and the `# => ...` line agree.

## Interactives must teach

- Respond to input, update live, and isolate one idea. One widget, one concept.
- Carry a clear prompt, a live readout, and a one-sentence takeaway *after* the widget (the `.take`). Never two widgets back to back — prose sits between them: text → widget → takeaway.
- The readout is mono and gold-bright: `.geo-readout` (`font-family: var(--mono); color: var(--gold-bright)`). It states the current input, the computed value, and a short label.
- **Counterexamples teach.** Show what the concept is *not*. The functions lesson sweeps a vertical line and labels the failing case "not a function" in burgundy. Use `--burgundy (#c4504c)` for the counterexample / warning state so the meaning colour carries the point.

## Hard constraints (Apollo-gated)

- **Pure inline JS. No external libraries** — no three.js, no D3, no framework. The course pages are 100% vanilla. Wrap the page script in an IIFE with `"use strict"`.
- **No `localStorage` / `sessionStorage`** — the `storage` gate fails on either token anywhere in the document. The widget holds state in the DOM and in closure variables only.
- **Degrade gracefully.** Content is visible without JavaScript. The reveal-on-scroll fade is JS-gated: the CSS hides `.reveal` only under `html.js .reveal`, and the bootstrap adds the `js` class. Without JS, nothing is hidden. The `degrade` gate checks that `.reveal` styling is scoped to `html.js`.
- **Respect `prefers-reduced-motion`.** Any looping animation (an animated flow dash, a pulsing edge) sits inside `@media (prefers-reduced-motion: no-preference)`, and the reveal transition is disabled under `@media (prefers-reduced-motion: reduce)`. The `motion` gate requires the string `prefers-reduced-motion` to be present.

## Craft

- SVG only, never raster. `viewBox`-based and fluid — `.fig svg { width: 100%; height: auto }`. Clean line-art with labelled axes and nodes.
- Use the design tokens (see `design-tokens.md`). Accent colour carries meaning, never random: gold for results and the primary accent, blue and sage for alternate functions or states, burgundy for the counterexample, elixir-purple for the FP/code accent. SVG `fill`/`stroke` attributes take the literal hex (e.g. `fill="#f0cd7f"`) since attributes cannot read CSS variables; CSS rules use `var(--token)`.
- Subtle motion at high-impact moments; never gratuitous.
- Provide accessibility text: `role="img"` and an `aria-label` describing what the figure shows; live regions (`aria-live="polite"`) on the readout and code block so updates are announced.

## Standard interactive shells

These classes are defined in the shared head; reuse them rather than inventing markup.

- **`.solid-select`** — toggle-button group. Buttons carry `data-c="gold|blue|sage|elixir"`; the `.active` button takes that meaning colour as its background. One button is `class="active"` at load. Use for "choose a function / combiner / mode".
- **`.fold-ctrl`** — slider row: a `label` (min-width 7.5rem) + an `<input type="range">` (flex, `accent-color: var(--gold)`) + a `.val` mono readout of the current value. Use for "step through" or "move the input".
- **`.geo-readout`** — the live readout line: mono, gold-bright, bordered. States input → computed value → label. Use `.dim` spans for separators.
- **`.controls`** — a flex row that holds the `.solid-select` and `.fold-ctrl` above the SVG.

## One worked example structure

The shape every figure follows, drawn from the built `map / filter / reduce` lesson. Prose precedes it; a `.take` and a `.bridge` follow.

```html
<figure class="fig" aria-labelledby="cmbTitle">
  <h4 id="cmbTitle" style="font-family:var(--sans);font-size:.8rem;letter-spacing:.16em;
      text-transform:uppercase;color:var(--cream-dim);margin:0 0 1rem">
    One skeleton, four results &middot; over [3, 1, 4, 1]</h4>

  <div class="controls">
    <div class="solid-select" id="cmbSel" role="group" aria-label="Choose a combiner">
      <button type="button" data-k="sum" data-c="sage" class="active">sum</button>
      <button type="button" data-k="product" data-c="blue">product</button>
      <button type="button" data-k="max" data-c="gold">max</button>
      <button type="button" data-k="count" data-c="elixir">count</button>
    </div>
  </div>

  <svg viewBox="0 0 760 160" role="img"
       aria-label="The reduce call with the chosen starting value and combiner, and its result.">
    <!-- line-art that the script updates; literal hex on fill/stroke -->
  </svg>

  <pre class="code" id="cmbCode" aria-live="polite"></pre>
  <div class="geo-readout" id="cmbOut" aria-live="polite">
    sum <span class="dim">&middot;</span> start at <b style="color:var(--gold-bright)">0</b>,
    add each element <span class="dim">&middot;</span> [3, 1, 4, 1] &rarr; 9</div>
</figure>
```

The matching script (inside the page IIFE) reads the active button, recomputes the real result, updates the SVG attributes, the `pre.code` (with a true `# => ...` line), and the `.geo-readout`, then re-renders once at load so the figure is correct before any interaction:

```js
function cmbKey() {
  var b = document.querySelector('#cmbSel button.active');
  return b ? b.getAttribute('data-k') : 'sum';
}
function renderCmb() {
  var k = cmbKey();
  /* recompute from real data, then update SVG text/attrs, pre.code, and .geo-readout */
}
document.querySelectorAll('#cmbSel button').forEach(function (b) {
  b.addEventListener('click', function () {
    document.querySelectorAll('#cmbSel button').forEach(function (o) {
      var on = o === b;
      o.classList.toggle('active', on);
      o.setAttribute('aria-pressed', on ? 'true' : 'false');
    });
    renderCmb();
  });
});
renderCmb(); // render once at load — correct without interaction
```

The counterexample variant (from the functions lesson): a second curve and a movable vertical line; when the line meets the curve twice, the readout flips to a burgundy "not a function" label. Showing the failure is the point — the widget teaches the boundary of the concept, not only its happy path.
