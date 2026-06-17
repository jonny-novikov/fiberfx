# A3.8.2 · Choose the tracer (dive)

- **Route:** `/course/agile-agent-workflow/roadmap/workshop/choose-the-tracer`
- **File:** `html/agile-agent-workflow/roadmap/workshop/choose-the-tracer.html`
- **Accent:** elixir-purple. **Stamp:** `TSK0Ng9hnHJgW0`.
- **Model copied:** `html/agile-agent-workflow/roadmap/roadmap-anatomy/what-it-carries.html` (lesson).

## Lead

With the ladder turned into a roadmap, the question becomes: where do you start? Apply A3.7 (tracers) and A3.4
(thin but robust): pick the first end-to-end thread — F6.1, request → facade → render — and name the seams you are
deliberately deferring (auth, deploy, the dashboard). The tracer is a real thin feature, kept and grown; it is not
a prototype.

## Worked Portal example

F6.1 is the tracer bullet: "the engine served as a web app (endpoint, request → facade → render)" — the first
thread through every layer, shipped before persistence (F6.3) or the rendered catalog (F6.5). Demo: hit the root,
see a page. Harness: a ConnTest GET smoke. Deferred behind it (named, not resolved): auth and deploy (F6.8), the
dashboard (F6.9), persistence depth (F6.3), interactivity (F6.6).

## Hero (framing) interactive — pick the tracer from the ladder

- **Move:** select a candidate first-rung; the readout classifies it as the tracer (end-to-end thread now) or as
  depth that should come later; only F6.1 is the tracer.
- **Control ids:** `.solid-select#trPick` buttons `data-k=f61|f63|f65|f66`, `data-c=elixir|blue|gold|sage`.
- **SVG:** four layer bands (router/facade/engine/render) with a thread that lights all four only for f6.1; others
  light a subset and read "depth, not the first thread".
- **Readout id:** `#trOut`. Static default = f6.1 the tracer.
- **Pure function:** `tracerVerdict(key) -> {isTracer, layers, why}` over `CANDS`.
- **Sample readout:** `f6.1 — the tracer: the engine served as a web app, request → facade → render. One thread through every layer, shipped before persistence or the rendered catalog. Kept and grown, not a prototype.`

## Content interactive — the deferred-seams board (now vs later)

- **Move:** select a seam; the readout names whether it ships in the tracer or is deferred, and to which rung — the
  roadmap is honest about what it leaves out.
- **Control ids:** `.solid-select#seamPick` buttons `data-k=render|persist|interact|auth|dash`,
  `data-c=elixir|blue|sage|gold|elixir`.
- **SVG:** a two-column board — "in the tracer" vs "deferred" — with a chip that moves to the right column and names
  the rung for deferred seams.
- **Readout id:** `#seamOut`. Static default = render (in the tracer).
- **Pure function:** `seamPlacement(key) -> {placed, rung, note}` over `SEAMS`.
- **Sample readout:** `render — in the tracer (f6.1): the first thread renders a page. Deferred seams: persistence → f6.3, interactivity → f6.6, auth & deploy → f6.8, dashboard → f6.9 — named, not resolved.`

## pre.code — the tracer line + deferred decisions as a roadmap.md fragment (markdown, NOT Elixir)

A fragment quoting the F6.1 row and the "Seams & open decisions" list (auth f6.8, deploy f6.8, dashboard f6.9).

## Bridge

- **idea:** the tracer is a real thin feature, kept and grown — distinct from a prototype, which is built to learn,
  then discarded; you ship it end to end first, then defer breadth.
- **practice:** on the Portal F6.1 is the tracer (request → facade → render, kept and grown into the live platform);
  auth, deploy, and the dashboard are named seams deferred to later rungs — all under the master invariant.
- **take:** start with one honest thread through every layer; defer the breadth, name it, and keep the thread.

## Pager

- prev `/course/agile-agent-workflow/roadmap/workshop/ladder-to-roadmap`
- next `/course/agile-agent-workflow/roadmap/workshop/the-program-view`

## References / Related — registry URLs; hub, ladder-to-roadmap, A3.7 tracer-bullets, A3.4 thin-but-robust, A3 roadmap, /elixir/phoenix.
