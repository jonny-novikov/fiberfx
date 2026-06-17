# A3.4.1 · Thin, not shallow — dive 1

- **Route:** `/course/agile-agent-workflow/roadmap/thin-but-robust/thin-not-shallow`
- **File:** `html/agile-agent-workflow/roadmap/thin-but-robust/thin-not-shallow.html`
- **Numbering:** A3.4.1 (dive 1 of A3.4 · Thin but robust)
- **Accent:** elixir-purple
- **Model copied verbatim:** `html/agile-agent-workflow/roadmap/roadmap-anatomy/what-it-carries.html`
- **Stamp:** `TSK0Ng9hnHJgW0`

## Lead

Thin means a **vertical** slice — one capability threaded end to end through every layer — not a **shallow**,
horizontal layer built across the system with nothing above or below it wired up. A horizontal layer (all the
database tables, or all the templates, with no thread connecting them) demos nothing and proves nothing; it defers
every integration risk to the end. A vertical thread is small but whole: it runs from the request through the facade
to a rendered response, so it can ship, demo, and be tested on its own.

## Precise definition

- **Vertical slice (thin):** one capability that crosses every layer once. Small in breadth, complete in depth. It
  ships a usable thread and surfaces integration risk immediately.
- **Horizontal layer (shallow):** one layer built broadly with no thread through the others. Large in breadth, zero in
  depth. It cannot demo and hides integration risk until late.
- **Flimsy:** a thread that *looks* vertical but skips robustness — no contract guard, no harness, no gate. Thin is
  about shape (vertical); flimsy is about quality (untested, ungated). A slice can be thin and still flimsy; A3.4.2
  and A3.4.3 add what makes thin robust.

## The worked Portal example

F6.1 — "the engine served as a web app (endpoint, request → facade → render)" — is the thinnest possible vertical
thread: it does almost nothing (hit the root, see a page) but it runs through every layer once. It is shipped
*before* persistence (F6.3) or the rendered catalog (F6.5). The horizontal alternative — building the whole schema
first, or all the templates first — would demo nothing and defer the request → facade → render integration to the
end.

## Hero interactive — vertical vs horizontal

- **id:** `cutPick` (`.solid-select`), `cutOut` (`.geo-readout`), SVG `class="cut"` with a 3×3 cell grid (rows =
  layers, cols = capabilities).
- **Move:** choose **vertical** (highlight one column across all rows) or **horizontal** (highlight one row across all
  columns); the readout names which shape ships and demos and which defers risk. Buttons carry `data-c`.
- **Pure function:** `sliceShape(mode) -> {cells, shippable, demoable, risk}` over a fixed 3-layer × 3-capability grid.
  Vertical lights 3 cells in one column → shippable yes, risk early; horizontal lights 3 cells in one row → shippable
  no, risk late.
- **Sample readout:** `VERTICAL · capability 1 across all 3 layers (3/9 cells) → ships and demos; integration risk surfaced early.`
- **Static default:** vertical.

## Content interactive — the flimsy detector

- **id:** `flimPick` (`.solid-select`), `flimOut` (`.geo-readout`), SVG `class="flim"`.
- **Move:** select a slice from a fixed set, each vertical but varying in quality; the detector reports *thin-but-robust*
  or *flimsy* and names the missing quality (no harness / no gate / no contract guard). Buttons carry `data-c`.
- **Pure function:** `detect(key) -> {verdict, missing}` over a fixed `SLICES` dataset of vertical-shape slices with
  three quality booleans (harnessed, gated, guarded). All three true → thin-but-robust; otherwise flimsy + the first
  missing.
- **Sample readout:** `demo-only slice → FLIMSY. Vertical in shape but missing a harness — a thread with no test ships debt.`
- **Static default:** the robust slice.

## The bridge

- **principle:** Thin names a slice's *shape* — vertical, one capability end to end — not its breadth; a horizontal
  layer is not a thin slice, and a vertical thread with no test is flimsy, not robust.
- **on the Portal:** F6.1 is the vertical thread (request → facade → render), and it holds the **master invariant** —
  the web calls only the `Portal` facade and renders only the closed `%Portal.Error{}` set — which is what keeps the
  thread from inventing horizontal sprawl.
- **take:** Thin is vertical and whole; shallow is horizontal and partial — and only robustness turns a thin thread
  into a shippable rung.

## References

- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- Continuous Delivery — https://continuousdelivery.com/

Related: thin-but-robust (hub), roadmap-anatomy, why/correct, why/pragmatic/contracts, /elixir/phoenix.

## Wiring

- Crumbs end A3.4.1 · Thin, not shallow.
- Route-tag rcur = `thin-not-shallow`.
- Pager: prev hub `/course/agile-agent-workflow/roadmap/thin-but-robust`, next `…/what-robust-adds`.
