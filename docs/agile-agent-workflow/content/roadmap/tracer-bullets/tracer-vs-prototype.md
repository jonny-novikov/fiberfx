# A3.7.2 · Tracer vs prototype — dive

- **Route:** `/course/agile-agent-workflow/roadmap/tracer-bullets/tracer-vs-prototype`
- **File:** `html/agile-agent-workflow/roadmap/tracer-bullets/tracer-vs-prototype.html`
- **Accent:** elixir-purple. **Model:** `roadmap-anatomy/what-it-carries.html`. **Stamp:** `TSK0Ng9hnHJgW0`.

## Lead

Three thin-looking artifacts are easy to confuse. A **tracer** is a real thin feature, shipped end to
end and kept. A **walking skeleton** is the end-to-end structure with no feature in it yet. A
**prototype** is built to learn one thing, then discarded. They differ on two axes: does it carry real
feature value, and is it kept or thrown away. On the Portal, F6.1 is a tracer — kept and grown.

## Worked Portal example

F6.1 ships a real, if thin, feature: a request renders a real page from the real facade. It is kept —
every later rung grows it. A walking skeleton, by contrast, would wire the endpoint to the view with a
placeholder where the facade call belongs: structure, no behaviour. A prototype would be a throwaway
spike to answer one question (does LiveView suit the catalog) and then be deleted. F6.1 is neither.

## Hero interactive (framing — in the `.fig`)

**Classify the three over a fixed dataset.** A `.solid-select` over {tracer, skeleton, prototype}; the
readout reports the artifact's two-axis profile (real feature? · kept or thrown away?) and the F6
example where one fits.

- Control ids: `#cls` (buttons `data-k="tracer|skeleton|prototype"`, each `data-c`); SVG `.cl` two-axis grid.
- Pure function: `classify(key) -> {feature, fate, example, gloss}` over a frozen `KINDS` dataset.
- Sample readout (tracer): `Tracer · real feature: yes (thin) · fate: kept and grown · F6 example: f6.1
  (the engine served as a web app). A real thin slice you keep — the opposite of a discarded prototype.`
- Static default = tracer string.

## Content interactive (proves a consequence — in main content)

**Kept vs thrown away.** A `.solid-select` over the same three artifacts plus a "count" readout: how
much of each survives into the shipped platform. The readout reports the kept fraction over a fixed
model — tracer 100%, skeleton (the structure survives, no feature), prototype 0%.

- Control ids: `#fate` (buttons `data-k="tracer|skeleton|prototype"`, each `data-c`); SVG `.kp` bar.
- Pure function: `survival(key) -> {keptPct, note}` over a frozen `FATE` dataset.
- Sample readout (prototype): `Prototype · kept into the shipped platform: 0% · built to learn, then
  discarded. Reusing prototype code is how a draft becomes the product by accident.`

## Bridge

- **Principle:** a tracer is kept and grown; a prototype is discarded after it teaches.
- **On the Portal:** F6.1 is the tracer, kept and grown into the live platform — a prototype of it would
  be thrown away once it answered its question.
- **Take:** keep a tracer, throw away a prototype, and never let one become the other by accident.

## References / pager

- Sources: Pragmatic Programmer (tracer bullets vs prototypes), Continuous Delivery, Extreme Programming Explained.
- pager prev: `…/end-to-end-first`; next: `…/defer-breadth`.
