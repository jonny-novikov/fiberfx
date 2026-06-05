# F1.09 — Functions on the plane (lab)

- **Route (served):** `/elixir/algebra/plotting-lab`
- **File:** `elixir/algebra/plotting-lab.html`
- **Place in the chapter:** the ninth and final lesson of F1 · Algebra — the chapter's lab (the lone "The lab" movement). It follows `F1.08` (pattern matching) and brings everything F1 built onto a coordinate grid: plotting a function is `F1.07`'s map, chaining two functions is `F1.03`'s composition, and because order matters `f∘g` and `g∘f` are usually different curves. Its pager forwards to the course contents and F2.
- **Accent:** gold chapter accent; the eyebrow marks it `F1 · Algebra · Lab` and the chapter landing renders this module with the `.lab` (elixir) left-border treatment.
- **Status:** built and published; A+ on the nine Apollo gates.

## Lead

Eyebrow (verbatim): `F1 · Algebra · Lab`

`h1`: `Functions on the plane`

Hero lede (verbatim): "A function is a curve. Two functions are two curves — and composing them, applying one then the other, draws a third. This lab lets you plot, compose, and trace a point through f∘g."

Kicker (verbatim): "Everything F1 built comes together here on a coordinate grid. Sampling a function across a range and collecting the outputs is F1.07’s map; chaining two functions is F1.03’s composition; and because order matters, f∘g and g∘f are usually different curves. Pick two functions, choose what to overlay, and slide the trace to watch a single value make its way through the pipeline."

## Sections

Two sections (a lab page, not the three-teaching-section dive shape):

1. **Plot, compose, trace** (`#lab`) — the single interactive plotter: choose `f`, choose `g`, toggle which curves overlay, and slide the trace x to follow a value through the pipeline. Real Elixir shown in the bridge/prose: plotting is `Enum.map(xs, f)`; composition is `fn x -> f.(g.(x)) end`; the whole plot is `Enum.map(xs, fn x -> f.(g.(x)) end)`.
2. **Closing the chapter** (`#close`) — the chapter wrap, naming what F1 assembled and forwarding to F2.

## The interactives

One large interactive figure (the plotter) plus the footer build-stamp decoder.

### Figure — "The plotter · f, g, and their composites" (`#labTitle`)

- Control group `#fPal` ("Choose f"), five buttons (all `data-c="elixir"`): `data-fn="id"` "x"; `data-fn="dbl"` "2x"; `data-fn="inc"` "x + 1"; `data-fn="sq"` "x²" (active); `data-fn="neg"` "-x".
- Control group `#gPal` ("Choose g"), five buttons (all `data-c="blue"`): `data-fn="id"` "x"; `data-fn="dbl"` "2x"; `data-fn="inc"` "x + 1" (active); `data-fn="sq"` "x²"; `data-fn="neg"` "-x".
- Control group `#overlay` ("Overlays"), four toggle buttons: `data-show="f" data-c="elixir"` "f" (active); `data-show="g" data-c="blue"` "g" (active); `data-show="fg" data-c="gold"` "f∘g" (active); `data-show="gf" data-c="sage"` "g∘f".
- `.fold-ctrl` slider `#xTrace` (trace x; min −3, max 3, step 1, value 2) with its value box.
- Readout `#labOut` (verbatim default): `x = 2 · g(2) = 3 · f(3) = 9 · (f∘g)(2) = 9 · (g∘f)(2) = 5 · order matters`.
- The figure plots `f`, `g`, and the selected composites on a coordinate grid and animates the trace value through the pipeline; the function palettes (`id`, `dbl`, `inc`, `sq`, `neg`) feed both `f` and `g`.

### Degrade behaviour

Controls, the SVG grid, and the default readout render in static markup; the curves and trace are drawn by JS on init. The page respects `prefers-reduced-motion` globally; no browser storage.

### Footer build-stamp decoder (`#stamp`)

- Stamp id: `TSK0NZUCGMOzpI` (in `#stampId`); panel `#st-ts` hard-codes "2026-05-30 13:14:24 UTC" (the decoded UTC timestamp).
- Pure functions: `b62decode(s)`, `pad2(x)`, `decodeBranded(id)` (`ns = id.slice(0,3)`, `snow = b62decode(id.slice(3))`; `ts = snow >> 22n`, `node = (snow >> 12n) & 0x3FFn`, `seq = snow & 0xFFFn`; `EPOCH_MS = 1704067200000`). Toggle on click / Enter / Space.

## References (#refs, verbatim)

No `#refs` References section is present on this page. The lab's cross-links are the crumbs, toc-mini, `.note`, pager, and footer (see Wiring); the prose names F1.03 (composition) and F1.07 (map).

## Wiring

- **route-tag:** `<span class="rsep">/</span><a href="/elixir">elixir</a><span class="rsep">/</span><a href="/elixir/algebra">algebra</a><span class="rsep">/</span><span class="rcur">plotting-lab</span>`.
- **crumbs:** `F1 · Algebra` → `/elixir/algebra` · sep `/` · `F1.08` → `/elixir/algebra/pattern-matching` · sep `/` · here `F1.09 · Lab` (no link).
- **toc-mini:** `#lab` ("The plotter") · `#close` ("Closing the chapter").
- **pager:** prev → `/elixir/algebra/pattern-matching` ("← F1.08 · pattern matching"); next → `/elixir` ("Course contents · F2 is next →"). (The `#close` `.note` forwards to the next chapter, F2 · Functional Programming — not "(planned)", since it points at a chapter, not a sibling lesson.)
- **footer:** identical three-column footer — brand → `/elixir`; `Chapters` F1–F6; `The course` `/elixir`, `/elixir/course`, `/elixir/algebra/functions`.
- **Page meta:** `<title>` "Functions on the plane — F1.09 · jonnify"; `<meta description>` "The F1 lab: a coordinate plotter for f, g, and their composites, with an x-trace that follows a value through f∘g — plotting as Enum.map, composition as a pipeline."

## Build instruction

To (re)build this lab, copy the `<head>…</style>`, `<header class="site">`, `<footer class="site-foot">`, and the two trailing `<script>` blocks verbatim from a recent built gold-accent sibling — the model is `elixir/algebra/pattern-matching.html` (F1.08, the closest gold-accent lesson template for the head/header/footer/decoder and the crumbs + toc-mini + `.solid-select`/`.fold-ctrl` controls) — then change only `<title>`/`<meta>`, the route-tag (mark the current segment `plotting-lab` and the crumb `F1.09 · Lab`), and the `<main>` body (the single `#lab` plotter figure + the `#close` chapter wrap). No-invent guards: use only the real Portal surfaces as written (branded store, event-sourced engine behind one `Portal` facade, Phoenix web app); this lab is pure algebra over `Enum.map` and function composition and names no engine internals — cite the companion course for OTP internals, do not re-teach. Voice rules: no first person, no exclamation marks, no emoji, none of just/simply/obviously.
