# A3.7 · Tracer bullets and walking skeletons — module hub

- **Route:** `/course/agile-agent-workflow/roadmap/tracer-bullets`
- **File:** `html/agile-agent-workflow/roadmap/tracer-bullets/index.html`
- **Accent:** elixir-purple (`<span class="ex">` in `<h1>`; `.cell.elix` bridge cell)
- **Model copied verbatim:** `html/agile-agent-workflow/roadmap/roadmap-anatomy/index.html` (hub)
- **Stamp:** `TSK0Ng9hnHJgW0` (reused verbatim)

## Lead

A roadmap is honest about uncertainty when it threads one thin slice end to end first. The tracer
bullet — the first vertical thread through every layer — proves the integration before any layer is
deepened. On the Portal's web chapter F6, that thread is rung **F6.1: the engine served as a web app
(request → facade → render)** — shipped before persistence (F6.3) or the rendered catalog (F6.5).

## Precise framing

- A **tracer bullet** is a real thin feature, shipped end to end, kept and grown.
- It de-risks integration early: the seams between layers are exercised on day one, not at the end.
- It is not a prototype (built to learn, then discarded) and not a walking skeleton (end-to-end
  structure with no feature yet).

## Framing interactive (in the hero `.fig`)

**Walk the F6 ladder and identify the tracer.** A `.solid-select` over a fixed slice of the F6 ladder
({f6.1, f6.3, f6.5, f6.7}); for each rung the readout reports whether it is the first end-to-end
thread. Only F6.1 is the tracer; F6.3 adds persistence depth, F6.5 adds the rendered catalog, F6.7
adds real-time — each grows the thread, none is the first thread.

- Control ids: `#tbPick` (buttons `data-k="f61|f63|f65|f67"`, each with `data-c`).
- Pure function: `rungFacts(key) -> {rung, role, isTracer, ships}` over a frozen `LADDER` dataset.
- Sample readout: `f6.1 · the engine served as a web app — the tracer bullet: the first end-to-end
  thread (request → facade → render), shipped before persistence (f6.3) or the rendered catalog
  (f6.5). Kept and grown, not discarded.`
- Static default readout = F6.1's string (correct without JS).

## The three dives (`.mods` grid)

1. **A3.7.1 · End to end first** — `end-to-end-first` — the tracer bullet: a thin thread through every
   layer first (F6.1), to de-risk integration early.
2. **A3.7.2 · Tracer vs prototype** — `tracer-vs-prototype` — tracer vs walking skeleton vs prototype.
3. **A3.7.3 · Defer breadth** — `defer-breadth` — defer breadth deliberately; depth follows the thread.

## Bridge

- **Principle:** ship a thin end-to-end thread first; keep it and grow it.
- **On the Portal:** F6.1 is the tracer — the engine served as a web app, kept and grown into the live
  platform; a prototype would be discarded.
- **Take:** the tracer is the rung you keep; the prototype is the rung you throw away.

## References

- Sources: The Pragmatic Programmer (tracer bullets), Continuous Delivery (thin demoable slices),
  Extreme Programming Explained (small releases over an ordered backlog).
- Related: the three dives, `/course/agile-agent-workflow/roadmap`,
  `/course/agile-agent-workflow/roadmap/roadmap-anatomy`,
  `/course/agile-agent-workflow/why/pragmatic`, `/elixir/phoenix`, `/elixir/phoenix/lifecycle`.

## Pager

- prev: `/course/agile-agent-workflow/roadmap` (A3 chapter landing)
- next: `/course/agile-agent-workflow/roadmap/tracer-bullets/end-to-end-first`
