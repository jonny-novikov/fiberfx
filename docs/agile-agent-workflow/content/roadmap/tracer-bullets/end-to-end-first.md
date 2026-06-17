# A3.7.1 · End to end first — dive

- **Route:** `/course/agile-agent-workflow/roadmap/tracer-bullets/end-to-end-first`
- **File:** `html/agile-agent-workflow/roadmap/tracer-bullets/end-to-end-first.html`
- **Accent:** elixir-purple. **Model:** `roadmap-anatomy/what-it-carries.html` (lesson). **Stamp:** `TSK0Ng9hnHJgW0`.

## Lead

The first slice to ship is one thin thread through every layer, not one layer built fully. Threading
end to end exercises the seams between layers on day one, so integration risk is paid down early
instead of accumulating to the end. On the Portal's web chapter F6, the tracer is rung **F6.1: the
engine served as a web app (request → facade → render)** — demo "hit the root, see a page", harnessed
by a `ConnTest` GET smoke, shipped before persistence (F6.3) or the rendered catalog (F6.5).

## Worked Portal example

The F6 ladder could be ordered breadth-first: build the whole data layer, then the whole facade
binding, then the whole view layer, integrating last. The roadmap orders it depth-first instead. F6.1
is a vertical slice: a request enters the endpoint, calls the `Portal` facade, and renders a page —
every layer touched, none of them deep. Persistence, the rendered catalog, and real-time arrive as
later rungs that grow the same thread.

## Hero interactive (framing — in the `.fig`)

**Thread-through-the-layers vs build-a-layer-fully.** A `.solid-select` chooses a delivery strategy
({thread, layer}); a fixed four-layer stack (endpoint · facade · view · persistence) is drawn; the
readout reports how many layers are exercised after the *first* shippable unit and whether the system
is live.

- Control ids: `#strat` (buttons `data-k="thread|layer"`, each `data-c`); SVG `.tl` with four layer rects.
- Pure function: `firstUnit(strategy) -> {touched, live, note}` over a frozen `STACK` dataset.
- Sample readout (thread): `Thread (the tracer) · first shippable unit touches 4 of 4 layers · system
  live: yes · the seams are exercised on day one — integration risk is paid down first.`
- Static default = the thread string.

## Content interactive (proves a consequence — in main content)

**Integration risk over time.** A range input `#rung` slides across the F6 ladder position (1..9);
the readout reports cumulative integration risk paid down under two orders — tracer-first vs
breadth-first — computed over a fixed model so the readout is always truthful.

- Control ids: `#rung` (range), SVG `.rk` with two plotted curves.
- Pure functions: `riskTracer(n) -> int`, `riskBreadth(n) -> int` over a frozen `RISK` dataset.
- Sample readout (rung 1): `After rung 1 · integration risk remaining — tracer-first: 10% (the seams
  proved at f6.1) · breadth-first: 90% (integration deferred to the end). The tracer pays the riskiest
  bill first.`

## Bridge

- **Principle:** ship one thin end-to-end thread first to de-risk integration early.
- **On the Portal:** F6.1 is the tracer — request → facade → render — the first thread, kept and grown
  into the live platform.
- **Take:** thread the system end to end before deepening any one layer.

## References / pager

- Sources: Pragmatic Programmer, Continuous Delivery, Extreme Programming Explained.
- pager prev: hub; next: `…/tracer-vs-prototype`.
