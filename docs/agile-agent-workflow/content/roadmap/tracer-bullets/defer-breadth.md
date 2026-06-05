# A3.7.3 · Defer breadth — dive

- **Route:** `/course/agile-agent-workflow/roadmap/tracer-bullets/defer-breadth`
- **File:** `html/agile-agent-workflow/roadmap/tracer-bullets/defer-breadth.html`
- **Accent:** elixir-purple. **Model:** `roadmap-anatomy/what-it-carries.html`. **Stamp:** `TSK0Ng9hnHJgW0`.

## Lead

Once the thread is live, depth follows it: each later rung deepens the one slice already proven, and
breadth is added deliberately, not all at once. Deferring breadth keeps the roadmap honest about
uncertainty — the seams it has not yet exercised are named as later rungs and open decisions, not
pretended away. On the Portal, F6.1 threads the system; F6.3, F6.5, F6.7 deepen it; auth and the
dashboard are deferred to F6.8–F6.9 and named as open decisions.

## Worked Portal example

After F6.1 the platform is live but shallow. The roadmap does not then build every feature at once. It
grows the thread: persistence (F6.3), the rendered catalog (F6.5), real-time (F6.7). The breadth it has
not reached — sign-in, deployment, the operations dashboard — is deferred to the third milestone and
written down as named open decisions. A roadmap that claimed all of it was done would be dishonest
about its uncertainty.

## Hero interactive (framing — in the `.fig`)

**Depth-first vs breadth-first delivery.** A `.solid-select` over {depth, breadth}; a fixed feature
grid is drawn; the readout reports, for each order, how soon the first end-to-end value ships and how
much integration is deferred to the end.

- Control ids: `#order` (buttons `data-k="depth|breadth"`, each `data-c`); SVG `.df` feature grid.
- Pure function: `orderFacts(key) -> {firstValue, deferred, note}` over a frozen `ORDER` dataset.
- Sample readout (depth): `Depth-first · first end-to-end value ships at rung 1 (f6.1) · breadth
  deferred and named as later rungs and open decisions. The thread is live early; depth follows it.`
- Static default = depth string.

## Content interactive (proves a consequence — in main content)

**The "honest about uncertainty" meter.** A range input `#named` sets how many of a fixed set of
not-yet-built seams are written down as named open decisions (0..4); the readout reports the honesty
score — a roadmap is honest when every deferred seam is named, dishonest when uncertainty is hidden.

- Control ids: `#named` (range 0..4), SVG `.hm` meter.
- Pure function: `honesty(named, total) -> {pct, verdict}` over a frozen `SEAMS` dataset (auth,
  deployment, dashboard, search) and total = 4.
- Sample readout (4): `Named open decisions: 4 of 4 deferred seams · honesty 100% · verdict: honest —
  every seam it has not reached is written down, not pretended away.`

## Bridge

- **Principle:** defer breadth deliberately and name what you defer, so the roadmap stays honest about
  uncertainty.
- **On the Portal:** F6.1 is the tracer — depth grows the one thread (F6.3, F6.5, F6.7) while auth and
  the dashboard are deferred to F6.8–F6.9 and named as open decisions; a prototype would be discarded.
- **Take:** grow the one thread; defer breadth on purpose and write down every seam you defer.

## References / pager

- Sources: Pragmatic Programmer, Continuous Delivery, Extreme Programming Explained.
- pager prev: `…/tracer-vs-prototype`; next: back to hub `…/tracer-bullets`.
