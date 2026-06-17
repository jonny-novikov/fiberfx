# A3.4.2 · What robust adds — dive 2

- **Route:** `/course/agile-agent-workflow/roadmap/thin-but-robust/what-robust-adds`
- **File:** `html/agile-agent-workflow/roadmap/thin-but-robust/what-robust-adds.html`
- **Numbering:** A3.4.2 (dive 2 of A3.4 · Thin but robust)
- **Accent:** elixir-purple
- **Model copied verbatim:** `html/agile-agent-workflow/roadmap/roadmap-anatomy/what-it-carries.html`
- **Stamp:** `TSK0Ng9hnHJgW0`

## Lead

Thin sets the *size* of a slice; robust sets the *bar* it has to clear. The F6 roadmap names seven "thin but robust
for the web" properties — each a concrete move a rung makes — and a thin thread becomes a shippable rung only when it
holds them. This dive reads the seven and scores a slice against them.

## Precise definition — the seven properties (verbatim from the F6 roadmap)

1. **Over the facade** — every controller, LiveView, and template calls only `Portal` and renders only the closed
   `%Portal.Error{}` set; the web invents no domain logic and no new error vocabulary.
2. **Harnessed** — controllers via `ConnTest`, LiveViews via `LiveViewTest`, enrollment against the in-memory adapter,
   so the suite is fast and needs no live browser.
3. **Verified and safe** — `~p` verified routes (a path typo fails to compile), HEEx-escaped interpolation, declared
   component `attr`s.
4. **Rendered in the system** — dynamic pages emitted through a shared root layout and a single token stylesheet, the
   tokens declared once.
5. **Honest real-time** — broadcasts fire only after a successful write, so clients only ever learn of facts.
6. **Supervised** — new runtime pieces (endpoint, PubSub, Presence) are supervised children; the engine's crash
   isolation is untouched.
7. **Always live** — every rung leaves the dev node booting clean and serving (`GET /health` answers `200` and the
   rung's route renders) — the liveness criterion (its own dive, A3.4.3).

## The worked Portal example

A slice that "renders the catalog" is thin and vertical, but it is not robust until it is over the facade (no
controller names `Portal.Engine`), harnessed (a `ConnTest` GET smoke), verified and safe (`~p` route, escaped
interpolation), rendered in the system (the shared layout), supervised, and always live. Strip a property and the
slice regresses to flimsy: drop "honest real-time" and clients can learn of facts that did not happen; drop
"supervised" and one crash takes the node down.

## Hero interactive — the property checklist scores a slice

- **id:** `propPick` (`.solid-select`), `propOut` (`.geo-readout`), SVG `class="prop"` listing the seven properties
  as rows.
- **Move:** select a slice from a fixed set; the checklist lights the properties it holds and scores it N/7, naming
  the verdict (robust at 7/7, flimsy below). Buttons carry `data-c`.
- **Pure function:** `score(key) -> {held, total, verdict}` over a fixed `SLICES` dataset where each slice carries a
  7-bit property vector; `held` = popcount, `total` = 7, `verdict` is robust at 7, flimsy otherwise.
- **Sample readout:** `the rendered catalog → 7/7 properties held → ROBUST. Over the facade, harnessed, verified, rendered in the system, honest real-time, supervised, always live.`
- **Static default:** the full 7/7 slice.

## Content interactive — before/after a missing property

- **id:** `dropPick` (`.solid-select`), `dropOut` (`.geo-readout`), SVG `class="drop"`.
- **Move:** select one of the seven properties to *drop* from a 7/7 slice; the readout names what breaks when that
  property is missing (the "after"), against the "before" of 7/7. Buttons carry `data-c`.
- **Pure function:** `whatBreaks(prop) -> {score, breaks}` over a fixed `BREAKS` dataset (property → the failure it
  prevents). Dropping one leaves 6/7 and names the specific regression.
- **Sample readout:** `drop "honest real-time" → 6/7 → clients can learn of a fact that did not happen; a broadcast firing before the write succeeds is a lie.`
- **Static default:** drop "harnessed".

## The bridge

- **principle:** Robust is the bar a thin slice clears: over the facade, harnessed, verified and safe, rendered in
  the system, honest real-time, supervised, always live — seven concrete moves, not a feeling.
- **on the Portal:** the first property *is* the **master invariant** — the web layer calls only the `Portal` facade
  and renders only the closed `%Portal.Error{}` set — and the other six hang off it; that is what makes every F6 rung
  robust without re-deciding the architecture.
- **take:** Thin is the slice; robust is the seven properties it holds — and the first of them is the master
  invariant.

## References

- Continuous Delivery — https://continuousdelivery.com/
- Extreme Programming Explained — https://www.oreilly.com/library/view/extreme-programming-explained/0201616416/
- The Pragmatic Programmer — https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/

Related: thin-but-robust (hub), thin-not-shallow (prev dive), why/correct, why/pragmatic/contracts, /elixir/phoenix.

## Wiring

- Crumbs end A3.4.2 · What robust adds.
- Route-tag rcur = `what-robust-adds`.
- Pager: prev `…/thin-not-shallow`, next `…/always-live`.
